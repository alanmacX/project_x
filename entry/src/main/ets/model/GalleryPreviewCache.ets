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
  await Promise.all(ids.map((id:string)=>cachedGalleryPreview(dir,id)));
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
