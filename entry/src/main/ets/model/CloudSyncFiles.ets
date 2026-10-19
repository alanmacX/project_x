import { cloudSync, fileIo, fileUri, hash } from '@kit.CoreFileKit';
import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { util } from '@kit.ArkTS';
import { CloudRevision, validateCloudRevision } from './CloudSyncProtocol';
import { privateAssetPaths, privateSyncScene, replacePrivateAssets } from './PrivateSyncCodec';
export function privateDigest(text:string):string{
  const md=cryptoFramework.createMd('SHA256');md.updateSync({data:new util.TextEncoder().encodeInto(text)});
  return Array.from(md.digestSync().data).map(value=>value.toString(16).padStart(2,'0')).join('');
}
export function revisionDigest(record:CloudRevision):string{return privateDigest(JSON.stringify([record.kind,record.name,record.deleted,record.data,record.assets]));}
async function ensureDirectory(path:string):Promise<void>{if(!await fileIo.access(path))await fileIo.mkdir(path);}
async function download(path:string):Promise<void>{
  const stat=await fileIo.stat(path);if(stat.location!==2)return;
  const cache=new cloudSync.CloudFileCache(),uri=fileUri.getUriFromPath(path);
  await new Promise<void>((resolve:()=>void,reject:(reason:Error)=>void)=>{
    let finished=false,timer:number=-1;
    const done=(error:Error|null):void=>{if(finished)return;finished=true;if(timer>=0)clearTimeout(timer);try{cache.off('progress',progress);}catch(_){}if(error)reject(error);else resolve();};
    const progress=(event:cloudSync.DownloadProgress):void=>{if(event.uri!==uri)return;if(event.state===cloudSync.State.COMPLETED)done(null);else if(event.state===cloudSync.State.FAILED||event.state===cloudSync.State.STOPPED)done(new Error('云文件下载未完成，请稍后重试'));};
    cache.on('progress',progress);timer=setTimeout(()=>{cache.stop(uri).catch(()=>{});done(new Error('云文件仍在下载，请稍后重试'));},20000);
    cache.start(uri).catch(()=>done(new Error('云文件暂时无法下载')));
  });
  if((await fileIo.stat(path)).location===2)throw new Error('云文件内容尚未下载');
}
export async function initializeCloudFiles(root:string):Promise<void>{await ensureDirectory(root+'/fridge_sync_v1');await ensureDirectory(root+'/fridge_sync_v1/assets');await ensureDirectory(root+'/fridge_sync_v1/revisions');}
export async function writeCloudRevision(root:string,record:CloudRevision):Promise<void>{
  validateCloudRevision(record);if(revisionDigest(record)!==record.digest)throw new Error('同步记录校验失败');
  const dir=root+'/fridge_sync_v1/revisions',path=dir+'/'+record.revision+'.json';if(await fileIo.access(path))return;
  const temp=path+'.tmp',file=await fileIo.open(temp,fileIo.OpenMode.CREATE|fileIo.OpenMode.READ_WRITE|fileIo.OpenMode.TRUNC);
  try{const bytes=new util.TextEncoder().encodeInto(JSON.stringify(record));let offset=0;while(offset<bytes.length){const count=await fileIo.write(file.fd,bytes.slice(offset).buffer as ArrayBuffer,{offset});if(count<=0)throw new Error('云文件写入未完成');offset+=count;}}finally{await fileIo.close(file.fd);}
  await fileIo.rename(temp,path);
}
export async function readCloudRevisions(root:string):Promise<CloudRevision[]>{
  const dir=root+'/fridge_sync_v1/revisions',names=await fileIo.listFile(dir);if(names.length>10000)throw new Error('同步历史过多，请先备份后整理');
  const records:CloudRevision[]=[];let total=0;
  for(const name of names){if(!/^[-a-zA-Z0-9_]{1,96}\.json$/.test(name))continue;const path=dir+'/'+name;await download(path);
    const size=(await fileIo.stat(path)).size;total+=size;if(size>20*1024*1024||total>64*1024*1024)throw new Error('云端历史元数据过大，请先保留备份后整理');
    const record=validateCloudRevision(JSON.parse(await fileIo.readText(path)) as CloudRevision);
    if(name!==record.revision+'.json'||revisionDigest(record)!==record.digest)throw new Error('云端记录校验失败，未修改本机作品');records.push(record);
  }return records;
}
/** Runs in TaskPool. Assets close before the immutable revision is published. */
@Concurrent
export async function encodePrivateCanvas(json:string,filesDir:string,root:string):Promise<string>{
  const state=privateSyncScene(json);let data=JSON.stringify(state);const assets:string[]=[];let total=0;
  for(const src of privateAssetPaths(state)){
    if(!src.startsWith('file://'+filesDir+'/')||src.includes('/../'))throw new Error('作品包含尚未导入的图片');
    const path=src.slice(7),size=(await fileIo.stat(path)).size;if(size<=0||size>32*1024*1024)throw new Error('单张同步图片需在32MB以内');total+=size;if(total>128*1024*1024)throw new Error('单个画布同步素材超过128MB');
    const ext=path.toLowerCase().match(/\.(png|jpg|jpeg|gif|webp)$/);if(!ext)throw new Error('同步素材格式暂不支持');
    const key=(await hash.hash(path,'sha256')).toLowerCase()+ext[0],destination=root+'/fridge_sync_v1/assets/'+key;
    const exists=await fileIo.access(destination),intact=exists&&((await fileIo.stat(destination)).location===2||(await hash.hash(destination,'sha256')).toLowerCase()===key.slice(0,64));
    if(!intact){const temp=destination+'.tmp';await fileIo.copyFile(path,temp);if((await hash.hash(temp,'sha256')).toLowerCase()!==key.slice(0,64))throw new Error('图片写入不完整');await fileIo.rename(temp,destination);}
    if(!assets.includes(key))assets.push(key);data=replacePrivateAssets(data,src,'sync-asset://'+key);
  }return JSON.stringify({data,assets});
}
export async function decodePrivateCanvas(record:CloudRevision,filesDir:string,root:string):Promise<string>{
  let data=record.data,total=0;const target=filesDir+'/cloud_assets_v1';await ensureDirectory(target);
  for(const key of record.assets){
    const path=root+'/fridge_sync_v1/assets/'+key;await download(path);const size=(await fileIo.stat(path)).size;
    total+=size;if(total>128*1024*1024)throw new Error('云端画布素材超过128MB');
    if(size<=0||size>32*1024*1024||(await hash.hash(path,'sha256')).toLowerCase()!==key.slice(0,64))throw new Error('云端图片校验失败，保留本机作品');
    const local=target+'/'+key;
    if(!await fileIo.access(local)||(await hash.hash(local,'sha256')).toLowerCase()!==key.slice(0,64)){await fileIo.copyFile(path,local+'.tmp');if((await hash.hash(local+'.tmp','sha256')).toLowerCase()!==key.slice(0,64))throw new Error('本机同步图片写入不完整');await fileIo.rename(local+'.tmp',local);}
    data=replacePrivateAssets(data,'sync-asset://'+key,'file://'+local);
  }
  const state=privateSyncScene(data);for(const src of privateAssetPaths(state))if(!src.startsWith('file://'+target+'/')||src.includes('/../'))throw new Error('云端素材引用不完整');return JSON.stringify(state);
}

/** The marker lives in the system's account-scoped cloud directory. Cursor state
 * is isolated by vault, so switching system accounts cannot reuse old receipts. */
export async function cloudVault(root:string):Promise<string>{
  const path=root+'/fridge_sync_v1/vault.json';
  if(await fileIo.access(path)){await download(path);const id=await fileIo.readText(path);if(!/^[a-f0-9]{32}$/.test(id))throw new Error('云空间标识暂未就绪');return id;}
  const id=util.generateRandomUUID().replace(/-/g,''),file=await fileIo.open(path,fileIo.OpenMode.CREATE|fileIo.OpenMode.READ_WRITE);
  try{const bytes=new util.TextEncoder().encodeInto(id);let offset=0;while(offset<bytes.length){const count=await fileIo.write(file.fd,bytes.slice(offset).buffer as ArrayBuffer,{offset});if(count<=0)throw new Error('云空间标识写入失败');offset+=count;}}finally{await fileIo.close(file.fd);}return id;
}
