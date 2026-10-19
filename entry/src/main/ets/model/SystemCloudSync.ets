import { BusinessError } from '@kit.BasicServicesKit';
import { cloudSync, fileIo } from '@kit.CoreFileKit';
import preferences from '@ohos.data.preferences';
import { taskpool, util } from '@kit.ArkTS';
import { CanvasDocument } from './CanvasLibrary';
import { TimetableData, useSavedTimetable } from './TimetableLibrary';
import { FridgeState } from './CardSchema';
import { FridgeStore } from './FridgeModel';
import { CloudRevision, cloudResolution, cloudClock, validateCloudRevision } from './CloudSyncProtocol';
import { initializeCloudFiles, cloudVault, encodePrivateCanvas, decodePrivateCanvas, readCloudRevisions, writeCloudRevision, revisionDigest } from './CloudSyncFiles';
interface EncodedCanvas {data:string;assets:string[];}
interface SyncCursor {version:number;device:string;records:CloudRevision[];}
export interface CloudSyncResult {changed:number;conflicts:number;published:number;message:string;}
function emptyRecord(entity:string,kind:string,name:string,data:string,assets:string[],deleted:boolean=false):CloudRevision{
  return {version:1,entity,kind,name,revision:'r_'+util.generateRandomUUID().replace(/-/g,''),clock:{},deleted,data,assets,digest:''};
}
/** Explicit one-shot sync. Each invocation is user consent for the current system account.
 * No background publishing across an account switch, private server, login token or Form-ID sync. */
export class SystemCloudSync {
  private running:boolean=false;
  private scope:string='';
  async archived(context:Context):Promise<CloudRevision[]>{
    const prefs=await preferences.getPreferences(context,'fridge_cloud_sync_v1');if(!this.scope)this.scope=await prefs.get('lastVault','') as string;if(!this.scope)return [];const all=await prefs.getAll(),records:CloudRevision[]=[];
    for(const key of Object.keys(all))if(key.startsWith(this.scope+'_conflict_')){const json=await prefs.get(key,'') as string;const record=validateCloudRevision(JSON.parse(json) as CloudRevision);if(!records.some(item=>item.revision===record.revision))records.push(record);}return records;
  }
  async restoreArchive(context:Context,store:FridgeStore,id:string):Promise<string>{
    if(this.running)throw new Error('同步正在进行');const record=(await this.archived(context)).find(item=>item.revision===id);if(!record)throw new Error('保留的数据不存在');
    if(record.kind==='timetable'){await store.rememberTimetable(useSavedTimetable({k:'timetable'},JSON.parse(record.data) as TimetableData));return '已设为保存的课表，可在课程卡中选择复用';}
    if(record.kind==='policy'){await store.applyCloudDocuments([],[],[],'',record.data);return '已恢复这份定时设置';}
    throw new Error('此数据类型请从冲突画布副本中恢复');
  }
  async synchronize(context:Context,store:FridgeStore,onStatus:(message:string)=>void):Promise<CloudSyncResult>{
    if(this.running)throw new Error('同步正在进行');this.running=true;
    let session:cloudSync.FileSync|null=null,listening=false,pullComplete=false,pullTimer:number=-1;
    let finishPull:()=>void=()=>{};const pulled=new Promise<void>((resolve:()=>void)=>finishPull=resolve);
    const progress=(value:cloudSync.SyncProgress):void=>{if(value.state===cloudSync.SyncState.COMPLETED){pullComplete=true;finishPull();}onStatus(value.error===0?'系统云空间正在同步文件':'系统云空间暂未完成，错误 '+value.error);};
    try{
      onStatus('检查系统云空间');session=new cloudSync.FileSync();session.on('progress',progress);listening=true;
      // Refuse writes when the system account/switch is unavailable. start is a
      // request, not evidence that every file has already uploaded.
      await session.start();onStatus('等待系统拉取其他设备的修改');
      await Promise.race([pulled,new Promise<void>((resolve:()=>void)=>{pullTimer=setTimeout(resolve,8000);})]);if(pullTimer>=0){clearTimeout(pullTimer);pullTimer=-1;}
      const root=context.cloudFileDir;if(!root)throw new Error('系统云文件目录尚未就绪');
      await initializeCloudFiles(root);await store.save(false);
      const prefs=await preferences.getPreferences(context,'fridge_cloud_sync_v1');
      const cursorKey='cursor_'+await cloudVault(root);this.scope=cursorKey;await prefs.put('lastVault',cursorKey);
      const old=await prefs.get(cursorKey,'') as string;
      const cursor:SyncCursor=old?JSON.parse(old) as SyncCursor:{version:1,device:'d_'+util.generateRandomUUID().replace(/-/g,''),records:[]};
      if(cursor.version!==1||!Array.isArray(cursor.records))throw new Error('同步游标无法读取，未修改本机作品');
      const local:CloudRevision[]=[],all=store.catalog.canvases.concat(store.catalog.scenes);
      onStatus('读取其他设备的修改');const remote=await readCloudRevisions(root);
      onStatus('准备画布和原始素材');
      for(const entry of all){
        const scene=await store.canvasSnapshot(entry.id);
        if(entry.id==='canvas_main'&&!old&&scene.cards.length===0&&scene.background.mode==='solid'&&scene.background.color==='#FFFFFF'&&remote.some(record=>record.entity===entry.id&&!record.deleted))continue;
        const encoded=JSON.parse(await taskpool.execute(new taskpool.Task(encodePrivateCanvas,JSON.stringify(scene),context.filesDir,root)) as string) as EncodedCanvas;
        local.push(emptyRecord(entry.id,store.catalog.scenes.some(item=>item.id===entry.id)?'scene':'canvas',entry.name,encoded.data,encoded.assets));
      }
      const timetable=await store.savedTimetable();if(timetable)local.push(emptyRecord('shared_timetable','timetable','已保存的课表',JSON.stringify(timetable),[]));
      if(old||store.catalog.sceneRules.length||store.catalog.rotation.enabled||!remote.some(record=>record.entity==='library_policy'&&!record.deleted))local.push(emptyRecord('library_policy','policy','画布定时设置',JSON.stringify({rotation:store.catalog.rotation,sceneRules:store.catalog.sceneRules}),[]));
      for(const previous of cursor.records)if(!local.some(record=>record.entity===previous.entity))local.push(previous.kind==='archive'?previous:emptyRecord(previous.entity,previous.kind,previous.name,'',[],true));
      const outgoing:CloudRevision[]=[];
      for(const record of local){
        record.digest=revisionDigest(record);const previous=cursor.records.find(item=>item.entity===record.entity);
        if(previous?.digest===record.digest){record.clock=previous.clock;record.revision=previous.revision;}
        else{record.clock=previous?JSON.parse(JSON.stringify(previous.clock)) as Record<string,number>:{};record.clock[cursor.device]=(record.clock[cursor.device]??0)+1;outgoing.push(record);}
      }
      // Read/validate every remote record before altering local artwork.
      for(const record of local)await writeCloudRevision(root,record);
      // Persist publication intent before applying incoming data. Retrying a
      // failed download must not create another independent offline edit.
      await prefs.put(cursorKey,JSON.stringify({version:1,device:cursor.device,records:local}));await prefs.flush();
      const records=remote.concat(local),entities=Array.from(new Set(records.map(record=>record.entity))),resolved:CloudRevision[]=[],incoming:CanvasDocument[]=[],removed:string[]=[],sceneIds:string[]=[];
      const resolutions:CloudRevision[]=[];
      let conflicts=0,timetableJson='',policyJson='',changed=0;
      for(const entity of entities){
        const candidates=records.filter(record=>record.entity===entity),result=cloudResolution(candidates),winner=result.primary;
        const prior=local.find(record=>record.entity===entity);
        const primary=JSON.parse(JSON.stringify(winner)) as CloudRevision;primary.clock=result.clock;
        // Keep every concurrent authored alternative as a deterministic canvas.
        // Shared data/policy conflicts are also archived for explicit recovery.
        for(const alternative of result.copies){
          conflicts++;
          if(alternative.kind==='canvas'||alternative.kind==='scene'){
            const forkId='fork_'+alternative.revision;
            if(!all.some(entry=>entry.id===forkId)&&!incoming.some(doc=>doc.id===forkId)&&!records.some(record=>record.entity===forkId)){
              const doc=new CanvasDocument();doc.id=forkId;doc.name=alternative.name+' · 冲突副本';doc.state=JSON.parse(await decodePrivateCanvas(alternative,context.filesDir,root)) as FridgeState;doc.state.canvasId=forkId;incoming.push(doc);
              const fork=emptyRecord(forkId,'canvas',doc.name,alternative.data,alternative.assets);fork.clock[cursor.device]=1;fork.digest=revisionDigest(fork);await writeCloudRevision(root,fork);resolved.push(fork);
            }
          }else{const archiveId='archive_'+alternative.revision;if(!records.some(record=>record.entity===archiveId)){const archive=emptyRecord(archiveId,'archive',alternative.name,JSON.stringify(alternative),[]);archive.clock[cursor.device]=1;archive.digest=revisionDigest(archive);await writeCloudRevision(root,archive);resolved.push(archive);}await prefs.put(cursorKey+'_conflict_'+alternative.revision,JSON.stringify(alternative));}
        }
        if(!prior||winner.digest!==prior.digest){
          if(winner.deleted){if(winner.kind==='canvas'||winner.kind==='scene')removed.push(entity);}
          else if(winner.kind==='canvas'||winner.kind==='scene'){
            const doc=new CanvasDocument();doc.id=entity;doc.name=winner.name;doc.state=JSON.parse(await decodePrivateCanvas(winner,context.filesDir,root)) as FridgeState;doc.state.canvasId=entity;incoming.push(doc);if(winner.kind==='scene')sceneIds.push(entity);
          }else if(winner.kind==='timetable')timetableJson=winner.data;else if(winner.kind==='policy')policyJson=winner.data;else if(winner.kind==='archive')await prefs.put(cursorKey+'_conflict_'+winner.entity,winner.data);
          changed++;
        }
        // A resolving version observes all branches. Its body is deterministic;
        // simultaneous identical resolutions are equivalent, not new conflicts.
        if(candidates.some(record=>record.digest!==winner.digest&&!Object.keys(record.clock).every(key=>(winner.clock[key]??0)>=record.clock[key]))){
          primary.revision='r_'+util.generateRandomUUID().replace(/-/g,'');primary.clock=cloudClock(candidates);primary.clock[cursor.device]=(primary.clock[cursor.device]??0)+1;
          resolutions.push(primary);
        }
        resolved.push(primary);
      }
      onStatus('保存完整作品到本机');
      await store.applyCloudDocuments(incoming,removed,sceneIds,timetableJson,policyJson);
      // Only resolve original heads once every alternative has its own durable cloud record and the local batch is committed.
      for(const record of resolutions)await writeCloudRevision(root,record);
      await prefs.put(cursorKey,JSON.stringify({version:1,device:cursor.device,records:resolved}));await prefs.flush();
      let widgetWarning='';try{await store.refreshSyncedWidgets(incoming.map(doc=>doc.id));}catch(_){widgetWarning=' 部分桌面预览稍后重试。';}
      return {changed,conflicts,published:outgoing.length,message:widgetWarning+(pullComplete?'本机已合并；上传和其他设备下载由系统云空间继续完成。':'已合并当前可用版本；系统仍在拉取，请稍后再同步一次。')};
    }catch(e){const code=(e as BusinessError).code;if(code===22400001)throw new Error('请先登录华为账号，并在系统设置 → 云空间中开启本应用同步');if(code===801)throw new Error('当前设备暂不支持系统云文件同步');if(code===13600001)throw new Error('暂时无法连接系统云空间，请确认系统开关后重试');if(code===22400002)throw new Error('当前网络不可用，本机作品已保留');throw e as Error;}
    finally{if(pullTimer>=0)clearTimeout(pullTimer);if(listening&&session)try{session.off('progress',progress);}catch(_){}this.running=false;}
  }
}
