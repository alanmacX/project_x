import { importAlbumCover } from '../model/AlbumWorker';
import { albumLibrary } from '../model/AlbumRotation';
import { CanvasElement, CapBlock } from '../model/CardSchema';
import { fileIo } from '@kit.CoreFileKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { image } from '@kit.ImageKit';
import { taskpool } from '@kit.ArkTS';
import { ElementBox } from '../model/CardSchema';
import { extractSubject } from '../model/SubjectShape';

export class DemoAsset {
  id:string=''; name:string=''; original:string=''; subject:string=''; aspect:number=1;
  photoSource:boolean=true;
  albumCover:string='';albumBackground:string='';albumTitle:string='';albumArtist:string='';
  crop:ElementBox=new ElementBox(); category:string='照片'; tones:string[]=[];
}
export function writeDemoFile(path:string,value:string):void {
  const temporary=path+'.tmp',file=fileIo.openSync(temporary,fileIo.OpenMode.CREATE|fileIo.OpenMode.READ_WRITE|fileIo.OpenMode.TRUNC);
  try{fileIo.writeSync(file.fd,value);fileIo.fsyncSync(file.fd);}finally{fileIo.closeSync(file);}
  fileIo.renameSync(temporary,path);
}
export class DemoAssets {
  items:DemoAsset[]=[];
  private context:Context|null=null;
  private save():void {writeDemoFile(this.context!.filesDir+'/demo-materials.json',JSON.stringify(this.items));}
  async init(context:Context):Promise<void>{
    this.context=context;const path=context.filesDir+'/demo-materials.json';
    if(fileIo.accessSync(path)){this.items=JSON.parse(fileIo.readTextSync(path)) as DemoAsset[];return;}
    const item=new DemoAsset();item.id='sample-tabby';item.name='窗边的猫';item.category='示例';item.aspect=960/1480;
    item.original=await this.resource('demo-tabby.jpg');item.subject=await this.resource('demo-tabby-cutout.png');
    item.crop.x=0;item.crop.y=0;item.crop.w=1;item.crop.h=1;this.items=[item];this.save();
  }
  private async resource(name:string):Promise<string>{
    const path=this.context!.filesDir+'/'+name;
    if(!fileIo.accessSync(path)){const bytes=await this.context!.resourceManager.getRawFileContent(name),file=await fileIo.open(path,fileIo.OpenMode.CREATE|fileIo.OpenMode.READ_WRITE);try{await fileIo.write(file.fd,bytes.buffer);}finally{await fileIo.close(file);}}
    return 'file://'+path;
  }
  async importPhoto():Promise<DemoAsset|null>{
    const result=await new photoAccessHelper.PhotoViewPicker().select({MIMEType:photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE,maxSelectNumber:1});
    if(!result.photoUris.length)return null;
    const item=new DemoAsset();item.id='material_'+Date.now();item.name='照片 '+(this.items.length+1);
    const path=this.context!.filesDir+'/'+item.id+'.jpg',source=await fileIo.open(result.photoUris[0],fileIo.OpenMode.READ_ONLY);
    try{const target=await fileIo.open(path,fileIo.OpenMode.CREATE|fileIo.OpenMode.READ_WRITE);try{await fileIo.copyFile(source.fd,target.fd);}finally{await fileIo.close(target);}}finally{await fileIo.close(source);}
    const file=await fileIo.open(path,fileIo.OpenMode.READ_ONLY),decoder=image.createImageSource(file.fd);
    try{const info=await decoder.getImageInfo();item.aspect=info.size.width/info.size.height;}finally{await decoder.release();await fileIo.close(file);}
    item.original='file://'+path;item.crop.x=0;item.crop.y=0;item.crop.w=1;item.crop.h=1;
    this.items.push(item);this.save();return item;
  }
  async cutout(id:string):Promise<void>{const item=this.items.find(a=>a.id===id);if(!item)return;
    const result=await extractSubject(item.original,this.context!.filesDir);item.subject=result.src;item.crop=result.crop;item.aspect=result.sourceAspect;item.tones=[];this.save();
  }
  remember(element:CanvasElement):void{
    if(!element.src||this.match(element.src))return;
    const item=new DemoAsset();item.id='saved_'+Date.now();item.name='作品中的照片';item.original=element.src;item.subject=element.depthForeground;item.aspect=element.depthSourceAspect||1;item.crop=JSON.parse(JSON.stringify(element.depthCrop)) as ElementBox;
    this.items.push(item);this.save();
  }
  rememberAlbums(cap:CapBlock):void{
    if(cap.k!=='album')return;
    let changed=false;
    for(const album of albumLibrary(cap)){
      if(!album.cover)continue;
      let item=this.match(album.cover);
      if(!item){item=new DemoAsset();item.id='album_'+Date.now()+'_'+this.items.length;item.original=album.cover;item.photoSource=false;item.aspect=1;item.crop.w=1;item.crop.h=1;this.items.push(item);}
      item.category='专辑';if(!item.name)item.name=album.title||'专辑封面';item.albumCover=album.cover;item.albumBackground=album.background;item.albumTitle=album.title;item.albumArtist=album.artist;changed=true;
    }
    if(changed)this.save();
  }
  categorizeAlbum(item:DemoAsset):void{if(item.category!=='专辑')item.photoSource=true;item.category='专辑';this.save();}
  async prepareAlbum(item:DemoAsset):Promise<void>{
    if(!item.albumCover||!item.albumBackground){
      const cap=JSON.parse(await taskpool.execute(new taskpool.Task(prepareDemoAlbum,item.original,this.context!.filesDir)) as string) as CapBlock;
      item.albumCover=cap.albumCover??'';item.albumBackground=cap.albumBackground??'';
    }
    this.categorizeAlbum(item);
  }
  match(src:string):DemoAsset|undefined{return this.items.find(a=>a.original===src||a.subject===src||a.albumCover===src||a.tones.includes(src));}
  async tone(item:DemoAsset,index:number):Promise<string>{
    if(index===0)return item.original;if(item.tones[index])return item.tones[index];
    const target=this.context!.filesDir+'/'+item.id+'_tone_'+index+'.png';
    item.tones[index]=await taskpool.execute(new taskpool.Task(tonePhoto,item.original,item.subject,JSON.stringify(item.crop),index,target)) as string;this.save();return item.tones[index];
  }
}
@Concurrent
async function tonePhoto(src:string,maskSrc:string,cropJson:string,index:number,target:string):Promise<string>{
  const file=fileIo.openSync(src.slice(7),fileIo.OpenMode.READ_ONLY),decoder=image.createImageSource(file.fd);
  let pixel:image.PixelMap|null=null,mask:image.PixelMap|null=null,maskFile:fileIo.File|null=null,maskDecoder:image.ImageSource|null=null,packer:image.ImagePacker|null=null;
  try{
    const info=await decoder.getImageInfo(),ratio=Math.min(1,1024/Math.max(info.size.width,info.size.height)),w=Math.round(info.size.width*ratio),h=Math.round(info.size.height*ratio);
    pixel=await decoder.createPixelMap({desiredSize:{width:w,height:h},desiredPixelFormat:image.PixelMapFormat.RGBA_8888,editable:true});
    const stride=pixel.getBytesNumberPerRow(),buffer=new ArrayBuffer(stride*h);await pixel.readPixelsToBuffer(buffer);const bytes=new Uint8Array(buffer);
    const crop=JSON.parse(cropJson) as ElementBox;let maskBytes=new Uint8Array(0),mw=1,mh=1,ms=4;
    if(maskSrc){maskFile=fileIo.openSync(maskSrc.slice(7),fileIo.OpenMode.READ_ONLY);maskDecoder=image.createImageSource(maskFile.fd);mask=await maskDecoder.createPixelMap({desiredSize:{width:Math.max(1,Math.round(w*crop.w)),height:Math.max(1,Math.round(h*crop.h))},desiredPixelFormat:image.PixelMapFormat.RGBA_8888});const mi=await mask.getImageInfo();mw=mi.size.width;mh=mi.size.height;ms=mask.getBytesNumberPerRow();const mb=new ArrayBuffer(ms*mh);await mask.readPixelsToBuffer(mb);maskBytes=new Uint8Array(mb);}
    for(let y=0;y<h;y++)for(let x=0;x<w;x++){
      const p=y*stride+x*4,r=bytes[p],g=bytes[p+1],b=bytes[p+2],l=r*.2126+g*.7152+b*.0722;
      const mx=Math.floor((x/w-crop.x)/crop.w*mw),my=Math.floor((y/h-crop.y)/crop.h*mh);
      const alpha=maskBytes.length&&mx>=0&&mx<mw&&my>=0&&my<mh?maskBytes[my*ms+mx*4+3]/255:0;
      const nr=index===4?l:index===1?r*1.05+12:index===2?r*.8:r*1.02+10;
      const ng=index===4?l:index===1?g*.96+4:index===2?g*.96+5:g*.86;
      const nb=index===4?l:index===1?b*.82:index===2?b*1.08+15:b*1.03+8;
      bytes[p]=Math.min(255,r*alpha+nr*(1-alpha));bytes[p+1]=Math.min(255,g*alpha+ng*(1-alpha));bytes[p+2]=Math.min(255,b*alpha+nb*(1-alpha));
    }
    await pixel.writeBufferToPixels(buffer);packer=image.createImagePacker();const output=fileIo.openSync(target,fileIo.OpenMode.CREATE|fileIo.OpenMode.READ_WRITE|fileIo.OpenMode.TRUNC);
    try{await packer.packToFile(pixel,output.fd,{format:'image/png',quality:100});}finally{fileIo.closeSync(output);}
    return 'file://'+target;
  }finally{if(packer)await packer.release();if(pixel)await pixel.release();if(mask)await mask.release();if(maskDecoder)await maskDecoder.release();if(maskFile)fileIo.closeSync(maskFile);await decoder.release();fileIo.closeSync(file);}
}

/** Derive a square cover without modifying the reusable source photograph. */
@Concurrent
async function prepareDemoAlbum(src:string,filesDir:string):Promise<string>{
  const input=fileIo.openSync(src.startsWith('file://')?src.slice(7):src,fileIo.OpenMode.READ_ONLY),decoder=image.createImageSource(input.fd);
  const temporary=filesDir+'/material_cover_'+Date.now()+'.jpg';let pixel:image.PixelMap|null=null,packer:image.ImagePacker|null=null;
  try{
    const info=await decoder.getImageInfo(),ratio=Math.min(1,1000/Math.max(info.size.width,info.size.height));
    const w=Math.max(1,Math.round(info.size.width*ratio)),h=Math.max(1,Math.round(info.size.height*ratio)),edge=Math.min(w,h);
    pixel=await decoder.createPixelMap({desiredSize:{width:w,height:h}});await pixel.crop({x:Math.floor((w-edge)/2),y:Math.floor((h-edge)/2),size:{width:edge,height:edge}});
    packer=image.createImagePacker();const file=fileIo.openSync(temporary,fileIo.OpenMode.CREATE|fileIo.OpenMode.READ_WRITE|fileIo.OpenMode.TRUNC);
    try{await packer.packToFile(pixel,file.fd,{format:'image/jpeg',quality:94});}finally{fileIo.closeSync(file);}
    return await importAlbumCover('file://'+temporary,JSON.stringify({k:'album'}),filesDir);
  }finally{if(pixel)await pixel.release();if(packer)await packer.release();await decoder.release();fileIo.closeSync(input);if(fileIo.accessSync(temporary))fileIo.unlinkSync(temporary);}
}
