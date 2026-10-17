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
    if(!item.path.startsWith('file://'+dir+'/gallery_v2_')||!await fileIo.access(item.path.slice(7)))return null;
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
