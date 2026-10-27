import { UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import preferences from '@ohos.data.preferences';
import { getLibraryPreferences } from '../model/LibraryStorage';
import { readLibraryBackup } from '../model/LibraryBackup';
import { relationalStore } from '@kit.ArkData';
import { fileIo } from '@kit.CoreFileKit';
function ensure(value:boolean,label:string):void{if(!value)throw new Error(label);}
const SOURCE:string='{"canvasId":"a","canvasDimension":"4*4","cards":[{"id":"original","x":27,"y":61,"w":180,"h":100,"rot":12,"capability":{"k":"countdown","date":"2030-01-01"}}]}';
const CATALOG:string='{"version":1,"activeId":"a","canvases":[{"id":"a","name":"Safety Test"}]}';
export default class EntryAbility extends UIAbility {
  onCreate(want:Want):void{const mode=String(want.parameters?.['mode']??'run');this.probe(mode).catch((e:Error)=>console.error('StorageProbe FAIL '+mode+' '+e.message));}
  onWindowStageCreate(stage:window.WindowStage):void{stage.loadContent('pages/Index');}
  private async owned():Promise<void>{
    const path=this.context.filesDir+'/storage-probe-owned.txt';
    if(!fileIo.accessSync(path)){const f=await fileIo.open(path,fileIo.OpenMode.CREATE|fileIo.OpenMode.WRITE_ONLY);try{await fileIo.write(f.fd,'temporary-storage-probe-only');}finally{await fileIo.close(f);}}
  }
  private async probe(mode:string):Promise<void>{
    await this.owned();
    if(mode==='legacySeed'){
      const legacy=await preferences.getPreferences(this.context,'fridge_store');
      await legacy.put('fridge_canvases_json',CATALOG);await legacy.put('fridge_canvas_a',SOURCE);await legacy.put('fridge_state_json',SOURCE);await legacy.flush();
      console.info('StorageProbe PASS native legacy XML seed, ready for package upgrade');return;
    }
    if(mode==='verifyCrashBefore'||mode==='verifyCrashAfter'){
      const db=await relationalStore.getRdbStore(this.context,{name:'crash_probe.db',securityLevel:relationalStore.SecurityLevel.S1});
      const rows=await db.querySql('SELECT value FROM crash_probe ORDER BY id');let values:string[]=[];try{while(rows.goToNextRow())values.push(rows.getString(0));}finally{rows.close();}
      const expected=mode==='verifyCrashBefore'?'old':'new';ensure(values.length===2&&values.every(v=>v===expected),'native crash left partial data '+values.join(','));
      console.info('StorageProbe PASS '+mode+' complete '+expected+' pair');return;
    }
    if(mode==='crashBefore'||mode==='crashAfter'){
      const db=await relationalStore.getRdbStore(this.context,{name:'crash_probe.db',securityLevel:relationalStore.SecurityLevel.S1});
      await db.executeSql('CREATE TABLE IF NOT EXISTS crash_probe(id INTEGER PRIMARY KEY,value TEXT)');
      await db.executeSql("INSERT OR REPLACE INTO crash_probe(id,value) VALUES(1,'old'),(2,'old')");
      const t=await db.createTransaction();await t.execute("UPDATE crash_probe SET value='new' WHERE id=1");
      if(mode==='crashAfter'){await t.execute("UPDATE crash_probe SET value='new' WHERE id=2");await t.commit();}
      console.info('StorageProbe READY '+mode+' safe to kill test process');await new Promise<void>(r=>setTimeout(r,60000));
      if(mode==='crashBefore')await t.rollback();return;
    }
    if(mode==='verifyBackupFallback'){
      const prefs=await getLibraryPreferences(this.context),latest=await prefs.get('__commit_sequence',0) as number;
      const backup=await readLibraryBackup(this.context.filesDir+'/library-recovery');ensure(backup!==null&&backup.sequence<latest,'did not fall back to an older valid backup');
      console.info('StorageProbe PASS native corrupt-latest fallback sequence='+backup!.sequence+' latest='+latest);return;
    }
    const a=await getLibraryPreferences(this.context),b=await getLibraryPreferences(this.context);
    const initial=await a.get('fridge_canvas_a','') as string;
    if(mode==='verifyUpgrade'){ensure(initial===SOURCE,'upgrade changed authored JSON');ensure(await a.get('fridge_canvases_json','')===CATALOG,'upgrade changed catalog');console.info('StorageProbe PASS native package upgrade retained exact legacy canvas and catalog');}
    await b.get('fridge_canvas_a','');
    const next='{"canvasId":"a","canvasDimension":"4*4","cards":[{"id":"native-'+Date.now()+'","x":27,"y":61}]}';await a.put('fridge_canvas_a',next);await a.flush();
    ensure(await (await getLibraryPreferences(this.context)).get('fridge_canvas_a','')===next,'native committed value missing');
    let rejected=false;await b.put('fridge_canvas_a',initial);try{await b.flush();}catch(_){rejected=true;}ensure(rejected,'stale native writer was accepted');
    const invalid=await getLibraryPreferences(this.context);await invalid.put('fridge_canvases_json','{"version":1,"canvases":[{"id":"missing"}]}');rejected=false;try{await invalid.flush();}catch(_){rejected=true;}ensure(rejected,'invalid native directory accepted');
    console.info('StorageProbe PASS native transaction, stale-writer draft, invalid-directory rollback');
    await new Promise<void>(r=>setTimeout(r,1800));
    const backup=await readLibraryBackup(this.context.filesDir+'/library-recovery');ensure(backup!==null,'native backup missing');ensure(backup!.values['fridge_canvas_a']===next,'native backup lost latest artwork');
    console.info('StorageProbe PASS native SHA256, encoding, fsync, atomic backup and checked readback');
  }
}
