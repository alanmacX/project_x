import { photoFrame } from './PhotoCropGeometry';
import { image } from '@kit.ImageKit';
import { fileIo } from '@kit.CoreFileKit';
import { BackgroundAnchor, CanvasBackground, FridgeState, FridgeCard, materialColors, BOARD_W, BOARD_H } from './CardSchema';
import { representativeColor, smartTone, blendPixels, combineColors, WeightedColor, colorLab } from './BackgroundPalette';

import { imageSwatches, imageColor, cardSource, backgroundSignature, hash } from './BackgroundInputs';
export { backgroundSignature } from './BackgroundInputs';
@Concurrent
export async function createSmartBackground(json:string,filesDir:string):Promise<string> {
  const state=JSON.parse(json) as FridgeState,bg=new CanvasBackground();bg.mode=state.background.mode;
  const colors:WeightedColor[]=[],anchors:BackgroundAnchor[]=[],cache=new Map<string,WeightedColor[]>();
  for(const card of state.cards){
    const samples:WeightedColor[]=[],paper=materialColors(card.material,card.paper)[0];
    const cutout=card.shape==='subject'&&card.subjectPhoto?card.cutout:'';
    if(cutout.startsWith('file://')){try{const palette=cache.get(cutout)??await imageSwatches(cutout);cache.set(cutout,palette);palette.forEach((p:WeightedColor)=>samples.push(p));}catch(_){}}
    if(card.capability?.k==='album'&&card.capability.albumCover?.startsWith('file://')) {try{const palette=await imageSwatches(card.capability.albumCover);palette.forEach((p:WeightedColor)=>samples.push(p));}catch(_){}}
    let filled=0;
    for(const el of card.elements.filter((el)=>el.kind==='image'||el.kind==='shape').sort((a,b)=>b.w*b.h-a.w*a.h).slice(0,4)){
      const weight=Math.max(0,Math.min(1,el.w*el.h*el.opacity));filled+=weight;
      if(el.kind==='image'&&el.src.startsWith('file://')){try{const palette=cache.get(el.src)??await imageSwatches(el.src);cache.set(el.src,palette);palette.forEach((p:WeightedColor)=>samples.push({color:p.color,weight:weight*p.weight}));}catch(_){}}
      if(el.kind==='shape'&&el.color.length>0)samples.push({color:el.color,weight:weight});
    }
    if(samples.length===0||paper.toUpperCase()!=='#FFFFFF'&&cutout.length===0)samples.push({color:paper,weight:Math.max(.1,1-filled)});
    const color=combineColors(samples);
    const a=card.rot*Math.PI/180,w=card.w/BOARD_W,shapeH=card.h/BOARD_W,h=shapeH*state.canvasAspect;
    const x=card.x/BOARD_W+w*Math.cos(a)/2+shapeH*Math.sin(a)/2,y=card.y/BOARD_H+h+w*state.canvasAspect*Math.sin(a)/2-h*Math.cos(a)/2;
    const boundsW=Math.abs(w*Math.cos(a))+Math.abs(shapeH*Math.sin(a)),boundsH=Math.abs(w*state.canvasAspect*Math.sin(a))+Math.abs(h*Math.cos(a));
    const visible=Math.max(0,Math.min(1,x+boundsW/2)-Math.max(0,x-boundsW/2))*Math.max(0,Math.min(1,y+boundsH/2)-Math.max(0,y-boundsH/2));
    if(visible<=0)continue;const weight=visible;
    colors.push({color:color,weight:weight});
    const influences=samples.slice().sort((a:WeightedColor,b:WeightedColor)=>b.weight-a.weight).slice(0,3),total=influences.reduce((sum:number,p:WeightedColor)=>sum+p.weight,0);
    influences.forEach((p:WeightedColor,i:number)=>anchors.push({x:Math.max(0,Math.min(1,x+(i===1?-.2:i===2?.2:0))),y:Math.max(0,Math.min(1,y+(i===1?.16:i===2?-.16:0))),color:p.color,weight:weight*p.weight/Math.max(total,.001)}));
  }
  bg.color=smartTone(colors);bg.signature=backgroundSignature(state);bg.palette=Array.from(new Set(colors.map((c:WeightedColor)=>c.color))).slice(0,6);
  // Keep at most six spatial influences; bitmap generation stays off the UI thread.
  // Repeated yellow cards must not create twelve opaque copies of one colour.
  // Merge only nearby clouds of the same tone. Distant artwork keeps its own light fold.
  const fields:BackgroundAnchor[]=[];
  for(const candidate of anchors.sort((a:BackgroundAnchor,b:BackgroundAnchor)=>b.weight-a.weight)){
    const lab=colorLab(candidate.color);
    const existing=fields.find((p:BackgroundAnchor)=>{const other=colorLab(p.color);return Math.hypot(lab.l-other.l,lab.a-other.a,lab.b-other.b)<12&&Math.hypot(candidate.x-p.x,candidate.y-p.y)<.2;});
    if(existing!==undefined){const total=existing.weight+candidate.weight;existing.x=(existing.x*existing.weight+candidate.x*candidate.weight)/total;existing.y=(existing.y*existing.weight+candidate.y*candidate.weight)/total;existing.weight=total;}
    else fields.push({x:candidate.x,y:candidate.y,color:candidate.color,weight:candidate.weight});
  }
  bg.anchors=fields.sort((a:BackgroundAnchor,b:BackgroundAnchor)=>b.weight-a.weight).slice(0,6);
  if(bg.mode==='smart')return JSON.stringify(bg);
  const width=320,height=Math.max(160,Math.min(512,Math.round(width/state.canvasAspect))),path=filesDir+'/canvas_blend_'+hash(bg.signature+'|'+JSON.stringify(bg.anchors))+'.png';
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

/** Commit the same cover transform shown inside the widget-shaped crop frame. */
@Concurrent
export async function cropBackgroundPhoto(src: string, filesDir: string, aspect: number, zoom: number, x: number, y: number): Promise<string> {
  let file: fileIo.File | null = null, output: fileIo.File | null = null, source: image.ImageSource | null = null, pixel: image.PixelMap | null = null, packer: image.ImagePacker | null = null;
  const path = filesDir + '/canvas_crop_' + Date.now() + '.jpg';
  try {
    file = await fileIo.open(src.slice(7), fileIo.OpenMode.READ_ONLY); source = image.createImageSource(file.fd);
    pixel = await source.createPixelMap({ editable: true }); const info = await pixel.getImageInfo();
    const f = photoFrame(info.size.width, info.size.height, 280, 280 / aspect, zoom, x, y), scale = f.width / info.size.width;
    const left = Math.max(0, Math.round(-f.left / scale)), top = Math.max(0, Math.round(-f.top / scale));
    const width = Math.min(info.size.width - left, Math.max(1, Math.round(280 / scale))), height = Math.min(info.size.height - top, Math.max(1, Math.round(280 / aspect / scale)));
    await pixel.crop({ x: left, y: top, size: { width: width, height: height } });
    packer = image.createImagePacker(); output = await fileIo.open(path, fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE);
    await packer.packToFile(pixel, output.fd, { format: 'image/jpeg', quality: 94 }); return 'file://' + path;
  } catch (e) { try { await fileIo.unlink(path); } catch (_) {} throw e as Error; }
  finally { if (file !== null) fileIo.closeSync(file.fd); if (output !== null) fileIo.closeSync(output.fd); if (pixel !== null) await pixel.release(); if (source !== null) await source.release(); if (packer !== null) await packer.release(); }
}
