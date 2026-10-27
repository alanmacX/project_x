import { relationalStore } from '@kit.ArkData';
import { artworkKey } from './LibraryValidation';
import { fileIo } from '@kit.CoreFileKit';
import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { util } from '@kit.ArkTS';
import { validateLibraryValues } from './LibraryValidation';
export interface LibraryBackup {version:number;sequence:number;values:Record<string,string>;}
interface BackupEnvelope {payload:string;sha256:string;}
function digest(value:string):string {
  const md=cryptoFramework.createMd('SHA256');md.updateSync({data:new util.TextEncoder().encodeInto(value)});
  return Array.from(md.digestSync().data).map(n=>n.toString(16).padStart(2,'0')).join('');
}
/** Independent of SQLite/WAL. Atomic generations; never overwrite the last good snapshot in place. */
export async function writeLibraryBackup(dir:string,backup:LibraryBackup):Promise<void>{
  validateLibraryValues(backup.values);
  try{await fileIo.mkdir(dir);}catch(_){}
  const payload=JSON.stringify(backup),name='library_'+backup.sequence+'.json',path=dir+'/'+name;
  const temp=path+'.'+Date.now()+'_'+Math.floor(Math.random()*1000000)+'.tmp';
  try{
    const file=await fileIo.open(temp,fileIo.OpenMode.CREATE|fileIo.OpenMode.WRITE_ONLY|fileIo.OpenMode.TRUNC);
    try{await fileIo.write(file.fd,JSON.stringify({payload:payload,sha256:digest(payload)}));await fileIo.fsync(file.fd);}finally{await fileIo.close(file);}
    await fileIo.rename(temp,path);
  }catch(e){try{await fileIo.unlink(temp);}catch(_){}throw e as Error;}
  const names=await fileIo.listFile(dir),generations=names.filter(n=>/^library_[0-9]+\.json$/.test(n)).sort((a,b)=>Number(b.slice(8,-5))-Number(a.slice(8,-5)));
  // Keep three committed generations. A late older process must never prune a newer snapshot.
  for(const old of generations.slice(3)){try{await fileIo.unlink(dir+'/'+old);}catch(_){}}
}
export async function readLibraryBackup(dir:string):Promise<LibraryBackup|null>{
  let names:string[];try{names=await fileIo.listFile(dir);}catch(_){return null;}
  const generations=names.filter(n=>/^library_[0-9]+\.json$/.test(n)).sort((a,b)=>Number(b.slice(8,-5))-Number(a.slice(8,-5)));
  for(const name of generations){try{
    const envelope=JSON.parse(await fileIo.readText(dir+'/'+name)) as BackupEnvelope;
    if(typeof envelope.payload!=='string'||digest(envelope.payload)!==envelope.sha256)continue;
    const backup=JSON.parse(envelope.payload) as LibraryBackup;
    if(backup.version!==1||!Number.isSafeInteger(backup.sequence)||backup.sequence<1||backup.sequence!==Number(name.slice(8,-5)))continue;
    validateLibraryValues(backup.values);return backup;
  }catch(_){}}
  throw new Error('恢复备份无法校验，已停止写入');
}

interface PendingBackup {db:relationalStore.RdbStore;timer:number;started:number;running:boolean;again:boolean;}
const pending:Map<string,PendingBackup>=new Map();
/** Coalesce a gesture's commits; capture a consistent snapshot without delaying the save acknowledgement. */
export function queueLibraryBackup(db:relationalStore.RdbStore,dir:string):void {
  let work=pending.get(dir);
  if(!work){work={db:db,timer:-1,started:Date.now(),running:false,again:false};pending.set(dir,work);}
  if(work.running){work.again=true;return;}
  if(work.timer>=0)clearTimeout(work.timer);
  work.timer=setTimeout(()=>{
    work!.timer=-1;work!.running=true;
    captureLibraryBackup(work!.db,dir).catch((e:Error)=>console.error('Library backup unavailable: '+e.message)).finally(()=>{
      const again=work!.again;pending.delete(dir);if(again)queueLibraryBackup(db,dir);
    });
  },Math.max(0,Math.min(1000,5000-(Date.now()-work.started))));
}
async function captureLibraryBackup(db:relationalStore.RdbStore,dir:string):Promise<void>{
  const transaction=await db.createTransaction();let backup:LibraryBackup;
  try{
    const records=await transaction.querySql('SELECT key,value FROM library_values');const values:Record<string,string>={};let sequence=0;
    try{while(records.goToNextRow()){
      const key=records.getString(0),value=records.getString(1);if(key==='__commit_sequence')sequence=JSON.parse(value) as number;
      else if(artworkKey(key))values[key]=JSON.parse(value) as string;
    }}finally{records.close();}
    // The legacy single-document alias duplicates an existing catalog document.
    if(values['fridge_canvases_json'])values['fridge_state_json']='';
    validateLibraryValues(values);backup={version:1,sequence:Math.max(1,sequence),values:values};
    await transaction.commit();
  }catch(e){await transaction.rollback();throw e as Error;}
  await writeLibraryBackup(dir,backup!);
}
