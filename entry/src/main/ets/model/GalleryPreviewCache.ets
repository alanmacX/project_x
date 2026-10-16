import { fileIo } from '@kit.CoreFileKit';
export class GalleryThumbnail { source:string=''; path:string=''; dimension:string=''; aspect:number=1; }
const memory:Map<string,GalleryThumbnail>=new Map();
function indexPath(dir:string,id:string):string{return dir+'/gallery_v2_'+id+'.json';}
export async function cachedGalleryPreview(dir:string,id:string):Promise<GalleryThumbnail|null>{
  const cached=memory.get(id);if(cached)return cached;
  try {const item=JSON.parse(await fileIo.readText(indexPath(dir,id))) as GalleryThumbnail;
    if(!item.path.startsWith('file://'+dir+'/gallery_v2_')||!await fileIo.access(item.path.slice(7)))return null;
    memory.set(id,item);return item;
  }catch(_){return null;}
}
export async function saveGalleryPreview(dir:string,id:string,item:GalleryThumbnail):Promise<void>{
  const previous=memory.get(id);const path=indexPath(dir,id),temp=path+'.tmp';
  const file=await fileIo.open(temp,fileIo.OpenMode.CREATE|fileIo.OpenMode.READ_WRITE|fileIo.OpenMode.TRUNC);
  try{await fileIo.write(file.fd,JSON.stringify(item));}finally{await fileIo.close(file.fd);}
  await fileIo.rename(temp,path);memory.set(id,item);
  if(previous&&previous.path!==item.path)fileIo.unlink(previous.path.slice(7)).catch(()=>{});
}
export async function removeGalleryPreview(dir:string,id:string):Promise<void>{
  const previous=memory.get(id);memory.delete(id);
  if(previous)fileIo.unlink(previous.path.slice(7)).catch(()=>{});
  fileIo.unlink(indexPath(dir,id)).catch(()=>{});
}
