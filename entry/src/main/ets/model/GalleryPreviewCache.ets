import { fileIo } from '@kit.CoreFileKit';
export class GalleryThumbnail { source:string=''; path:string=''; dimension:string=''; aspect:number=1; rects:Record<string,number[]>={}; }
const memory:Map<string,GalleryThumbnail>=new Map();
function memoryKey(dir:string,id:string):string{return dir+'/'+id;}
export function rememberedGalleryPreview(dir:string,id:string):GalleryThumbnail|null{return memory.get(memoryKey(dir,id))??null;}
export function rememberedGalleryRects(dir:string,ids:string[]):Record<string,number[]>{
  for(const id of ids){const rects=rememberedGalleryPreview(dir,id)?.rects;if(rects&&Object.keys(rects).length)return rects;}return {};
}
/** Read every cache index before first gallery construction, independent of document/IPC work. */
export async function primeGalleryPreviews(dir:string,ids:string[]):Promise<void>{
  let next=0;const worker=async():Promise<void>=>{while(next<ids.length)await cachedGalleryPreview(dir,ids[next++]);};
  const workers:Promise<void>[]=[];for(let i=0;i<Math.min(4,ids.length);i++)workers.push(worker());await Promise.all(workers);
}
function indexPath(dir:string,id:string):string{return dir+'/gallery_v2_'+id+'.json';}
export async function cachedGalleryPreview(dir:string,id:string):Promise<GalleryThumbnail|null>{
  const cached=memory.get(memoryKey(dir,id));if(cached)return cached;
  try {const item=JSON.parse(await fileIo.readText(indexPath(dir,id))) as GalleryThumbnail;
    const prefix='file://'+dir+'/gallery_v2_';
    if(!item||typeof item.path!=='string'||!item.path.startsWith(prefix)||item.path.slice(prefix.length).includes('/')||
      typeof item.source!=='string'||!['2*2','2*4','4*4','6*4'].includes(item.dimension)||!Number.isFinite(item.aspect)||item.aspect<.3||item.aspect>3||
      !await fileIo.access(item.path.slice(7)))return null;
    const rects:Record<string,number[]>={};
    if(item.rects&&typeof item.rects==='object')for(const dimension of ['2*2','2*4','4*4','6*4']){
      const rect=item.rects[dimension];if(Array.isArray(rect)&&rect.length===2&&rect.every(value=>Number.isFinite(value)&&value>0))rects[dimension]=rect;
    }
    item.rects=rects;
    memory.set(memoryKey(dir,id),item);return item;
  }catch(_){return null;}
}
export async function saveGalleryPreview(dir:string,id:string,item:GalleryThumbnail):Promise<void>{
  const previous=memory.get(memoryKey(dir,id));const path=indexPath(dir,id),temp=path+'.tmp';
  const file=await fileIo.open(temp,fileIo.OpenMode.CREATE|fileIo.OpenMode.READ_WRITE|fileIo.OpenMode.TRUNC);
  try{await fileIo.write(file.fd,JSON.stringify(item));}finally{await fileIo.close(file.fd);}
  await fileIo.rename(temp,path);memory.set(memoryKey(dir,id),item);
  if(previous&&previous.path!==item.path)fileIo.unlink(previous.path.slice(7)).catch(()=>{});
}
export async function removeGalleryPreview(dir:string,id:string):Promise<void>{
  const previous=memory.get(memoryKey(dir,id));memory.delete(memoryKey(dir,id));
  if(previous)fileIo.unlink(previous.path.slice(7)).catch(()=>{});
  fileIo.unlink(indexPath(dir,id)).catch(()=>{});
}

export class GalleryCleanup { scanned:number=0;removed:number=0;bytes:number=0; }
const sweeps:Map<string,Promise<GalleryCleanup>>=new Map();
/** Only this module's disposable flat files. No traversal, source assets or shared exports. */
export async function pruneGalleryPreviews(dir:string,ids:string[],retained:string[]=[],now:number=Date.now()):Promise<GalleryCleanup>{
  const pending=sweeps.get(dir);if(pending)return pending;
  const work=(async():Promise<GalleryCleanup>=>{
    const result=new GalleryCleanup(),live=new Set(ids),protectedPaths=new Set(retained);
    for(const item of memory.values())protectedPaths.add(item.path);
    let names:string[];try{names=await fileIo.listFile(dir);}catch(_){return result;}
    const owned=names.filter((name:string)=>/^gallery_v2_[A-Za-z0-9_-]+\.(png|json)(\.tmp)?$/.test(name));
    const indexes=owned.filter((name:string)=>name.endsWith('.json'));
    for(const name of indexes){
      const id=name.slice('gallery_v2_'.length,-5);if(!live.has(id))continue;
      try{
        const stat=await fileIo.stat(dir+'/'+name);
        // A very large/unreadable current index is ambiguous: leave the cache intact.
        if(stat.size>8*1024*1024)return result;
        const item=JSON.parse(await fileIo.readText(dir+'/'+name)) as GalleryThumbnail;
        if(item?.path?.startsWith('file://'+dir+'/gallery_v2_')&&!item.path.slice(('file://'+dir+'/').length).includes('/'))protectedPaths.add(item.path);
      }catch(_){return result;}
    }
    for(const name of owned){
      const path=dir+'/'+name;if(protectedPaths.has('file://'+path))continue;
      if(name.endsWith('.json')&&live.has(name.slice('gallery_v2_'.length,-5)))continue;
      try{const stat=await fileIo.stat(path);result.scanned++;
        // New/in-flight writes and recently replaced pixels survive concurrent navigation.
        if(!stat.isFile()||now-stat.mtime*1000<10*60*1000)continue;
        await fileIo.unlink(path);result.removed++;result.bytes+=stat.size;
      }catch(_){/* Cache eviction never blocks artwork or navigation. */}
    }
    return result;
  })();
  sweeps.set(dir,work);try{return await work;}finally{if(sweeps.get(dir)===work)sweeps.delete(dir);}
}
