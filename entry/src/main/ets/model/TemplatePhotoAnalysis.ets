import { image } from '@kit.ImageKit';
import { fileIo } from '@kit.CoreFileKit';
import { PhotoSamples } from './TemplatePhotoComposition';
/** Decode a bounded thumbnail once per composition session, never on gesture frames. */
export async function readPhotoSamples(src:string):Promise<PhotoSamples>{
 const out=new PhotoSamples();if(!src)return out;let file:fileIo.File|null=null,source:image.ImageSource|null=null,pixel:image.PixelMap|null=null;
 try{file=await fileIo.open(src.startsWith('file:///')?src.slice(7):src,fileIo.OpenMode.READ_ONLY);source=image.createImageSource(file.fd);const info=await source.getImageInfo(),ratio=Math.min(1,48/Math.max(info.size.width,info.size.height));
  pixel=await source.createPixelMap({desiredSize:{width:Math.max(1,Math.round(info.size.width*ratio)),height:Math.max(1,Math.round(info.size.height*ratio))},desiredPixelFormat:image.PixelMapFormat.RGBA_8888});
  const actual=await pixel.getImageInfo(),stride=pixel.getBytesNumberPerRow(),buffer=new ArrayBuffer(stride*actual.size.height);await pixel.readPixelsToBuffer(buffer);const data=new Uint8Array(buffer);out.width=actual.size.width;out.height=actual.size.height;
  for(let y=0;y<out.height;y++)for(let x=0;x<out.width*4;x++)out.rgba.push(data[y*stride+x]);
 }finally{if(pixel)await pixel.release();if(source)await source.release();if(file)await fileIo.close(file);}
 return out;
}
