import { ColorRaster } from './CardColorDistribution';
import { image } from '@kit.ImageKit';
import { fileIo } from '@kit.CoreFileKit';
import { FridgeState, FridgeCard, materialColors } from './CardSchema';
import { representativeSwatches, WeightedColor } from './BackgroundPalette';

export async function imageSwatches(src:string):Promise<WeightedColor[]> {
  let file:fileIo.File|null=null,source:image.ImageSource|null=null,pixel:image.PixelMap|null=null;
  try {
    file=await fileIo.open(src.slice(7),fileIo.OpenMode.READ_ONLY);source=image.createImageSource(file.fd);
    pixel=await source.createPixelMap({desiredSize:{width:48,height:48},desiredPixelFormat:image.PixelMapFormat.RGBA_8888});
    const info=await pixel.getImageInfo(),stride=pixel.getBytesNumberPerRow(),data=new ArrayBuffer(stride*info.size.height);await pixel.readPixelsToBuffer(data);
    const packed=new Uint8Array(info.size.width*info.size.height*4),input=new Uint8Array(data);
    for(let y=0;y<info.size.height;y++)packed.set(input.subarray(y*stride,y*stride+info.size.width*4),y*info.size.width*4);
    return representativeSwatches(packed,info.alphaType===image.AlphaType.PREMUL);
  } finally { if(pixel!==null)await pixel.release();if(source!==null)await source.release();if(file!==null)fileIo.closeSync(file.fd); }
}
/** Bounded decode with source aspect retained for the card's Cover crop. */
export async function imageColorRaster(src:string):Promise<ColorRaster> {
  let file:fileIo.File|null=null,source:image.ImageSource|null=null,pixel:image.PixelMap|null=null;
  try {
    file=await fileIo.open(src.slice(7),fileIo.OpenMode.READ_ONLY);source=image.createImageSource(file.fd);
    const original=await source.getImageInfo(),ratio=Math.min(1,96/Math.max(original.size.width,original.size.height));
    pixel=await source.createPixelMap({desiredSize:{width:Math.max(1,Math.round(original.size.width*ratio)),height:Math.max(1,Math.round(original.size.height*ratio))},desiredPixelFormat:image.PixelMapFormat.RGBA_8888});
    const info=await pixel.getImageInfo(),stride=pixel.getBytesNumberPerRow(),buffer=new ArrayBuffer(stride*info.size.height);await pixel.readPixelsToBuffer(buffer);
    const rgba=new Uint8Array(info.size.width*info.size.height*4),input=new Uint8Array(buffer);
    for(let y=0;y<info.size.height;y++)rgba.set(input.subarray(y*stride,y*stride+info.size.width*4),y*info.size.width*4);
    if(info.alphaType===image.AlphaType.PREMUL)for(let i=0;i<rgba.length;i+=4){const alpha=rgba[i+3]/255;if(alpha>0)for(let c=0;c<3;c++)rgba[i+c]=Math.min(255,Math.round(rgba[i+c]/alpha));}
    return {width:info.size.width,height:info.size.height,rgba:rgba};
  } finally {if(pixel!==null)await pixel.release();if(source!==null)await source.release();if(file!==null)fileIo.closeSync(file.fd);}
}
export async function imagePalette(src:string):Promise<string[]> {return (await imageSwatches(src)).map((p:WeightedColor)=>p.color);}
export async function imageColor(src: string): Promise<string> { return (await imagePalette(src))[0]; }
export function cardSource(card:FridgeCard):string {
  if(card.capability?.k==='album')return card.capability.albumCover??'';
  if(card.shape==='subject'&&card.subjectPhoto&&card.cutout.startsWith('file://'))return card.cutout;
  const images=card.elements.filter((el)=>el.kind==='image'&&el.src.startsWith('file://')).sort((a,b)=>b.w*b.h-a.w*a.h);
  return images[0]?.src??'';
}
interface BackgroundSignatureCard { id:string; src:string; paper:string; layers:string[]; }
interface BackgroundSignature { mode:string; aspect:number; cards:BackgroundSignatureCard[]; }
export function backgroundSignature(state:FridgeState):string {
  const signature:BackgroundSignature = {mode:state.background.mode,aspect:state.canvasAspect,cards:state.cards.filter(card=>!card.hidden).map((card:FridgeCard):BackgroundSignatureCard=>({id:card.id,src:cardSource(card),paper:materialColors(card.material,card.paper)[0],layers:[String(card.subjectVersion),String(card.subjectPhoto),card.shape,String(card.w/card.h),...card.elements.filter((el)=>el.kind==='image'||el.kind==='shape').map((el)=>[el.kind,el.src,el.color,String(el.opacity),String(el.w),String(el.h),String(el.x),String(el.y),String(el.rot),el.primitive,String(el.behindCapability)].join('|'))]}))};
  return 'fluid-v18-local-light-fluid|'  + JSON.stringify(signature);
}
export function hash(value:string):string {let n=2166136261;for(let i=0;i<value.length;i++){n^=value.charCodeAt(i);n=Math.imul(n,16777619);}return(n>>>0).toString(16);}
