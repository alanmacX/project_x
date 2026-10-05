import { image } from '@kit.ImageKit';
import { fileIo } from '@kit.CoreFileKit';
import { BackgroundAnchor, CanvasBackground, FridgeState, FridgeCard, materialColors, BOARD_W, BOARD_H } from './CardSchema';
import { representativeColor, representativePalette, representativeSwatches, smartTone, blendPixels, WeightedColor } from './BackgroundPalette';

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
  const signature:BackgroundSignature = {mode:state.background.mode,aspect:state.canvasAspect,cards:state.cards.map((card:FridgeCard):BackgroundSignatureCard=>({id:card.id,src:cardSource(card),paper:materialColors(card.material,card.paper)[0],layers:[String(card.subjectVersion),String(card.subjectPhoto),card.shape,...card.elements.filter((el)=>el.kind==='image'||el.kind==='shape').map((el)=>[el.kind,el.src,el.color,String(el.opacity),String(el.w),String(el.h)].join('|'))]}))};
  return 'fluid-v9|'  + JSON.stringify(signature);
}
export function hash(value:string):string {let n=2166136261;for(let i=0;i<value.length;i++){n^=value.charCodeAt(i);n=Math.imul(n,16777619);}return(n>>>0).toString(16);}
