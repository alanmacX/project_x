import { image } from '@kit.ImageKit';
import { fileIo } from '@kit.CoreFileKit';
import { BackgroundAnchor, CanvasBackground, FridgeState, FridgeCard, materialColors, BOARD_W, BOARD_H } from './CardSchema';
import { representativeColor, smartTone, blendPixels, combineColors, WeightedColor } from './BackgroundPalette';

import { imageColor, cardSource, backgroundSignature, hash } from './BackgroundInputs';
export { backgroundSignature } from './BackgroundInputs';
@Concurrent
export async function createSmartBackground(json:string,filesDir:string):Promise<string> {
  const state=JSON.parse(json) as FridgeState,bg=new CanvasBackground();bg.mode=state.background.mode;
  const colors:WeightedColor[]=[],anchors:BackgroundAnchor[]=[],cache=new Map<string,string>();
  for(const card of state.cards){
    const samples:WeightedColor[]=[],paper=materialColors(card.material,card.paper)[0];
    const cutout=card.shape==='subject'&&card.subjectPhoto?card.cutout:'';
    if(cutout.startsWith('file://')){try{const color=cache.get(cutout)??await imageColor(cutout);cache.set(cutout,color);samples.push({color:color,weight:1});}catch(_){}}
    let filled=0;
    for(const el of card.elements.filter((el)=>el.kind==='image'||el.kind==='shape').sort((a,b)=>b.w*b.h-a.w*a.h).slice(0,4)){
      const weight=Math.max(0,Math.min(1,el.w*el.h*el.opacity));filled+=weight;
      if(el.kind==='image'&&el.src.startsWith('file://')){try{const color=cache.get(el.src)??await imageColor(el.src);cache.set(el.src,color);samples.push({color:color,weight:weight});}catch(_){}}
      if(el.kind==='shape'&&el.color.length>0)samples.push({color:el.color,weight:weight});
    }
    if(samples.length===0||paper.toUpperCase()!=='#FFFFFF'&&cutout.length===0)samples.push({color:paper,weight:Math.max(.1,1-filled)});
    const color=combineColors(samples);
    const a=card.rot*Math.PI/180,w=card.w/BOARD_W,shapeH=card.h/BOARD_W,h=shapeH*state.canvasAspect;
    const x=card.x/BOARD_W+w*Math.cos(a)/2+shapeH*Math.sin(a)/2,y=card.y/BOARD_H+h+w*state.canvasAspect*Math.sin(a)/2-h*Math.cos(a)/2;
    const boundsW=Math.abs(w*Math.cos(a))+Math.abs(shapeH*Math.sin(a)),boundsH=Math.abs(w*state.canvasAspect*Math.sin(a))+Math.abs(h*Math.cos(a));
    const visible=Math.max(0,Math.min(1,x+boundsW/2)-Math.max(0,x-boundsW/2))*Math.max(0,Math.min(1,y+boundsH/2)-Math.max(0,y-boundsH/2));
    if(visible<=0)continue;const weight=Math.sqrt(visible);
    colors.push({color:color,weight:weight});anchors.push({x:Math.max(0,Math.min(1,x)),y:Math.max(0,Math.min(1,y)),color:color,weight:weight});
  }
  bg.color=smartTone(colors);bg.signature=backgroundSignature(state);bg.palette=Array.from(new Set(colors.map((c:WeightedColor)=>c.color))).slice(0,6);
  // Keep the twelve most visible influences; bitmap generation stays off the UI thread.
  bg.anchors=anchors.sort((a:BackgroundAnchor,b:BackgroundAnchor)=>b.weight-a.weight).slice(0,12);
  if(bg.mode==='smart')return JSON.stringify(bg);
  const width=640,height=Math.max(256,Math.min(1024,Math.round(width/state.canvasAspect))),path=filesDir+'/canvas_blend_'+hash(bg.signature)+'.png';
  try{if(await fileIo.access(path)){bg.src='file://'+path;return JSON.stringify(bg);}}catch(_){}
  const rgba=blendPixels(bg.anchors,bg.color,width,height);let pixel:image.PixelMap|null=null,packer:image.ImagePacker|null=null,file:fileIo.File|null=null;
  try{
    pixel=await image.createPixelMap(rgba.buffer as ArrayBuffer,{size:{width:width,height:height},srcPixelFormat:image.PixelMapFormat.RGBA_8888,pixelFormat:image.PixelMapFormat.RGBA_8888,alphaType:image.AlphaType.OPAQUE});
    packer=image.createImagePacker();file=await fileIo.open(path,fileIo.OpenMode.CREATE|fileIo.OpenMode.READ_WRITE);await packer.packToFile(pixel,file.fd,{format:'image/png',quality:100});bg.src='file://'+path;return JSON.stringify(bg);
  }finally{if(file!==null)fileIo.closeSync(file.fd);if(packer!==null)await packer.release();if(pixel!==null)await pixel.release();}
}

@Concurrent
export async function importBackgroundPhoto(uri:string,filesDir:string):Promise<string> {
  let input:fileIo.File|null=null,output:fileIo.File|null=null,source:image.ImageSource|null=null,pixel:image.PixelMap|null=null,packer:image.ImagePacker|null=null;
  const path=filesDir+'/canvas_photo_'+Date.now()+'.jpg';
  try {
    input=await fileIo.open(uri.startsWith('file:///')?uri.slice(7):uri,fileIo.OpenMode.READ_ONLY);source=image.createImageSource(input.fd);
    const info=await source.getImageInfo(),ratio=Math.min(1,1536/Math.max(info.size.width,info.size.height));
    pixel=await source.createPixelMap({desiredSize:{width:Math.max(1,Math.round(info.size.width*ratio)),height:Math.max(1,Math.round(info.size.height*ratio))}});
    packer=image.createImagePacker();output=await fileIo.open(path,fileIo.OpenMode.CREATE|fileIo.OpenMode.READ_WRITE);await packer.packToFile(pixel,output.fd,{format:'image/jpeg',quality:92});return 'file://'+path;
  } catch(e) {try{await fileIo.unlink(path);}catch(_){}throw e as Error;}
  finally {if(input!==null)fileIo.closeSync(input.fd);if(output!==null)fileIo.closeSync(output.fd);if(pixel!==null)await pixel.release();if(source!==null)await source.release();if(packer!==null)await packer.release();}
}
