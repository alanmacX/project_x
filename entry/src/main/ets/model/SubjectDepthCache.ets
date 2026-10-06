import { depthHash, depthArgb, DepthInput } from './SubjectDepthGeometry';
import { drawing } from '@kit.ArkGraphics2D';
import { image } from '@kit.ImageKit';
import { fileIo } from '@kit.CoreFileKit';
import { taskpool } from '@kit.ArkTS';
import { FridgeCard, materialColors } from './CardSchema';
import { cardRenderSnapshot } from './CardViewSnapshot';
import { cardOutline } from './RenderContours';
import { contourPath } from './ContourPath';
import { subjectSurfaceFactor } from './CanvasLayout';
import { cardEdgeColor } from './CardDepth';

const ready = new Map<string,string>();
function key(card: FridgeCard, scale: number): string {
  return [card.cutout,card.subjectVersion,card.w,card.h,scale,card.subjectPhoto,card.material,card.paper,true].join(':');
}
export function subjectDepthImage(card: FridgeCard, scale: number): string { return card.shape==='subject' && card.subjectBorder ? ready.get(key(card,scale)) ?? '' : ''; }
@Concurrent
export async function bakeSubjectDepth(json:string, cacheDir:string, density:number, retainedJson:string='[]'):Promise<string> {
  const inputs=JSON.parse(json) as DepthInput[],result:Record<string,string>={};
  for(const input of inputs) {
    const target=cacheDir+'/depth_v2_'+depthHash(JSON.stringify(input)+':'+density)+'.png';
    if(await fileIo.access(target)){result[input.key]='file://'+target;continue;}
    let pixel:image.PixelMap|null=null,packer:image.ImagePacker|null=null,file:fileIo.File|null=null;
    try {
      const width=Math.ceil((input.w+48)*density),height=Math.ceil((input.h+48)*density);
      pixel=await image.createPixelMap(new ArrayBuffer(width*height*4),{size:{width,height},pixelFormat:image.PixelMapFormat.RGBA_8888,alphaType:image.AlphaType.PREMUL,editable:true});
      const canvas=new drawing.Canvas(pixel),path=new drawing.Path();
      if(!path.buildFromSvgString(input.path))continue;
      const brush=new drawing.Brush(),pen=new drawing.Pen();brush.setAntiAlias(true);pen.setAntiAlias(true);pen.setJoinStyle(drawing.JoinStyle.ROUND_JOIN);
      const band=(color:string,line:number,opacity:number,y:number):void=>{
        canvas.save();canvas.translate(24*density,(24+y)*density);
        brush.setColor(depthArgb(color,opacity));canvas.attachBrush(brush);
        if(line>0){pen.setColor(depthArgb(color,opacity));pen.setStrokeWidth(line*density);canvas.attachPen(pen);}
        canvas.drawPath(path);canvas.detachBrush();canvas.detachPen();canvas.restore();
      };
      const border=6*input.scale,side=2*input.scale;
      const shadow=(radius:number,color:string,y:number):void=>{
        band(color,border+radius*2,.15,y);band(color,border+radius,.25,y);band(color,border,.6,y);
      };
      shadow(5.5*input.scale,'#30000000',side+4*input.scale);
      shadow(1.4*input.scale,'#48000000',side+1.2*input.scale);
      band(input.edge,border,1,side);band(input.surface,border,1,0);
      packer=image.createImagePacker();file=await fileIo.open(target+'.pending',fileIo.OpenMode.CREATE|fileIo.OpenMode.READ_WRITE|fileIo.OpenMode.TRUNC);
      await packer.packToFile(pixel,file.fd,{format:'image/png',quality:100});
      fileIo.closeSync(file.fd);file=null;await fileIo.rename(target+'.pending',target);result[input.key]='file://'+target;
    } catch(_) {try{await fileIo.unlink(target+'.pending');}catch(_){} }
    finally {if(file!==null)fileIo.closeSync(file.fd);if(pixel!==null)await pixel.release();if(packer!==null)await packer.release();}
  }
  // Disposable derived images cannot grow without bound after repeated resizes.
  try {
    const names=(await fileIo.listFile(cacheDir)).filter((name:string)=>/^depth_v[0-9]+_[0-9a-f]+\.png$/.test(name));
    const protectedFiles=new Set(Object.values(result).concat(JSON.parse(retainedJson) as string[]).map((uri:string)=>uri.slice(7)));
    let count=names.length;
    for(const name of names) {if(count<=128)break;const path=cacheDir+'/'+name;if(!protectedFiles.has(path)){await fileIo.unlink(path);count--;}}
  } catch(_) {}
  return JSON.stringify(result);
}
export async function prepareSubjectDepth(cards:FridgeCard[],scale:number,cacheDir:string,density:number):Promise<void> {
  const inputs:DepthInput[]=[];
  for(const source of cards) {
    if(source.shape!=='subject'||!source.cutout||ready.has(key(source,scale)))continue;
    const card=cardRenderSnapshot(source,true),input=new DepthInput();input.key=key(card,scale);
    input.w=card.w*scale;input.h=card.h*scale;input.scale=scale;
    input.path=contourPath(cardOutline(card),input.w*density,input.h*density,subjectSurfaceFactor(card));
    input.surface=card.subjectPhoto?'#FFFFFF':materialColors(card.material,card.paper,card.ink)[0];input.edge=cardEdgeColor(input.surface,card.subjectPhoto);
    inputs.push(input);
  }
  if(!inputs.length)return;
  try {
    const json=await taskpool.execute(new taskpool.Task(bakeSubjectDepth,JSON.stringify(inputs),cacheDir,density,JSON.stringify(Array.from(ready.values())))) as string;
    const entries=JSON.parse(json) as Record<string,string>;for(const k of Object.keys(entries))ready.set(k,entries[k]);
  } catch(_) {} // Fall back to the existing vector surface if a disposable cache fails.
}
