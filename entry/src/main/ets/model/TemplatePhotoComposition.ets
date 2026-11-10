import { FridgeCard, CanvasElement, ElementBox } from './CardSchema';
import { CardTemplate } from './CardTemplate';
import { templatePhotoBox, templateSubjectBox } from './TemplatePhotoGeometry';
export const PHOTO_CLOCK_POSITIONS:string[]=['top-left','top','top-right','bottom-left','bottom','bottom-right'];
export class PhotoClockLayout {x:number=0;y:number=0;w:number=0;h:number=0;size:number=0;stacked:boolean=false;}
export function photoClockLayout(width:number,height:number,position:string='top'):PhotoClockLayout{
 const out=new PhotoClockLayout(),side=position.endsWith('-left')||position.endsWith('-right');out.stacked=side;
 out.size=side?Math.min(70,width*.24,height*.27):Math.min(82,width*.274,height*.32);
 out.w=side?width*.42:width*.94;out.h=out.size*(side?2.24:1.2);out.x=side?(position.endsWith('-right')?width-out.w-width*.04:width*.04):(width-out.w)/2;
 const inset=Math.min(18,height*.065);out.y=position.startsWith('bottom')?height-out.h-inset:inset;return out;
}
export function photoControlRegion(card:FridgeCard):ElementBox{
 const box=new ElementBox(),wide=card.w/card.h>=1.5;box.x=0;box.y=0;box.w=300;box.h=300*card.h/card.w;
 if(card.template?.id==='portrait'){
  if(card.template.photoFraming!=='cover'){box.y=box.h<180?44:74;box.h=Math.max(1,box.h-box.y);}
 }else{box.x=wide?148:138;box.y=wide?16:58;box.w=wide?134:140;box.h=wide?118:169;}
 return box;
}
export function portraitPhotoFrame(card:FridgeCard,photo:CanvasElement):ElementBox{
 const region=photoControlRegion(card),t=card.template!,subject=photo.depthEnabled&&!!photo.depthForeground&&t.photoMode!=='photo';
 const box=templatePhotoBox(photo,t,region.w,region.h,t.photoFraming==='cover'&&!subject,subject);box.x+=region.x;box.y+=region.y;return box;
}
/** Conservative per-digit safety: small edge overlaps retain depth, large overlaps put time in front.
 * This geometry-only guard runs in every renderer, including old saved canvases and widgets. */
export function photoClockDepthAllowed(card:FridgeCard):boolean {
 const photo=card.elements.find(e=>e.kind==='image'&&!!e.src),t=card.template;
 if(!photo||!t||!t.depth||!photo.depthEnabled||!photo.depthForeground)return false;
 const frame=portraitPhotoFrame(card,photo),front=t.photoMode!=='photo'?frame:templateSubjectBox(photo,frame);
 const clock=photoClockLayout(300,300*card.h/card.w,t.clockPosition??'top');
 const rows=clock.stacked?2:1,columns=clock.stacked?2:5;
 for(let row=0;row<rows;row++)for(let col=0;col<columns;col++){
  const x=clock.x+col*clock.w/columns,y=clock.y+row*clock.size*1.04,w=clock.w/columns,h=clock.size;
  const overlapW=Math.max(0,Math.min(x+w,front.x+front.w)-Math.max(x,front.x));
  const overlapH=Math.max(0,Math.min(y+h,front.y+front.h)-Math.max(y,front.y));
  if(overlapW*overlapH/(w*h)>.18)return false;
 }
 return true;
}
export class PhotoCompositionViewport {unit:number=1;offsetX:number=0;offsetY:number=0;}
/** Match the renderer's centered scene, including letterboxing on a filled canvas. */
export function photoCompositionViewport(card:FridgeCard,scale:number):PhotoCompositionViewport {
 const out=new PhotoCompositionViewport(),height=card.template?.id==='portrait'?300*card.h/card.w:card.w/card.h>=1.5?150:300;
 out.unit=Math.min(card.w/300,card.h/height)*scale;
 out.offsetX=(card.w*scale-300*out.unit)/2;out.offsetY=(card.h*scale-height*out.unit)/2;return out;
}
export class PhotoGesturePoint {id:number=0;x:number=0;y:number=0;}
export class PhotoCameraPose {zoom:number=1;offsetX:number=0;offsetY:number=0;}
/** Pointer coordinates and camera dimensions use the same local scene units. */
export class PhotoCameraGesture {
 private ids:string='';private centerX:number=0;private centerY:number=0;private distance:number=1;private initial:PhotoCameraPose=new PhotoCameraPose();
 reset():void{this.ids='';}
 update(points:PhotoGesturePoint[],config:CardTemplate,region:ElementBox):PhotoCameraPose{
  const result=new PhotoCameraPose();result.zoom=config.zoom;result.offsetX=config.offsetX;result.offsetY=config.offsetY;
  if(!points.length){this.reset();return result;}
  const selected=points.slice(0,2).sort((a,b)=>a.id-b.id),ids=selected.map(p=>p.id).join(':'),cx=selected.reduce((n,p)=>n+p.x,0)/selected.length,cy=selected.reduce((n,p)=>n+p.y,0)/selected.length;
  const distance=selected.length>1?Math.max(1,Math.hypot(selected[1].x-selected[0].x,selected[1].y-selected[0].y)):1;
  if(ids!==this.ids){this.ids=ids;this.centerX=cx;this.centerY=cy;this.distance=distance;this.initial=result;return result;}
  result.zoom=Math.max(.25,Math.min(4,this.initial.zoom*distance/this.distance));const ratio=result.zoom/this.initial.zoom;
  const originX=region.x+region.w/2+this.initial.offsetX*region.w,originY=region.y+region.h/2+this.initial.offsetY*region.h;
  result.offsetX=Math.max(-1,Math.min(1,(cx+(originX-this.centerX)*ratio-region.x-region.w/2)/region.w));
  result.offsetY=Math.max(-1,Math.min(1,(cy+(originY-this.centerY)*ratio-region.y-region.h/2)/region.h));return result;
 }
}
export class PhotoSamples {width:number=0;height:number=0;rgba:number[]=[];}
export class PhotoClockRecommendation {position:string='top';ink:string='';}
function sample(image:PhotoSamples,u:number,v:number):number[]{if(!image.width||u<0||v<0||u>=1||v>=1)return [0,0,0,0];const i=(Math.floor(v*image.height)*image.width+Math.floor(u*image.width))*4;return image.rgba.slice(i,i+4);}
function luma(rgb:number[]):number{return (rgb[0]*.2126+rgb[1]*.7152+rgb[2]*.0722)/255;}
/** Scores real alpha coverage (especially the upper subject) and visual texture in each time region. */
export function recommendPhotoClock(card:FridgeCard,subject:PhotoSamples,original:PhotoSamples,background:string):PhotoClockRecommendation{
 const result=new PhotoClockRecommendation(),photo=card.elements.find(e=>e.kind==='image'&&!!e.src);if(!photo)return result;
 const frame=portraitPhotoFrame(card,photo),subjectMode=photo.depthEnabled&&!!photo.depthForeground&&card.template?.photoMode!=='photo',front=subjectMode?frame:templateSubjectBox(photo,frame),height=300*card.h/card.w;
 const bg=[parseInt(background.slice(1,3),16),parseInt(background.slice(3,5),16),parseInt(background.slice(5,7),16)];let best=Infinity;
 PHOTO_CLOCK_POSITIONS.forEach((position,index)=>{
  const box=photoClockLayout(300,height,position);let occupied=0,bright=0,squared=0,n=0;
  for(let row=0;row<12;row++)for(let col=0;col<16;col++){
   const x=box.x+(col+.5)/16*box.w,y=box.y+(row+.5)/12*box.h,uvY=(y-front.y)/front.h,mask=sample(subject,(x-front.x)/front.w,uvY),alpha=(mask[3]??0)/255;
   occupied+=alpha*(uvY<.42?1.7:1);const raw=subjectMode?[...bg,255]:sample(original,(x-frame.x)/frame.w,(y-frame.y)/frame.h),a=(raw[3]??0)/255;
   const value=luma(raw)*a+luma(bg)*(1-a);bright+=value;squared+=value*value;n++;
  }
  const mean=bright/n,variance=Math.max(0,squared/n-mean*mean),score=occupied/n*5+Math.sqrt(variance)*1.3+index*.006;
  if(score<best){best=score;result.position=position;result.ink=mean>.56?'#202222':'#FFFFFF';}
 });return result;
}
