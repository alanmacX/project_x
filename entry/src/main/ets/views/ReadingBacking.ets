import { readingSurfaceColor } from '../model/CapabilityPresentation';
import { isReadingComposition, compositionPadding } from '../model/ReadingComposition';
import { hookCenter, hookReserve, micaPath } from '../model/MicaGeometry';
import { PaperBacking } from './PaperBacking';
/** Imperative paint only: size changes never write observed layout state. */
@Component
export struct ReadingBacking {
 @Prop @Watch('paint') blend:string='paper';
 @Prop ink:string='#262824';
 @Prop tint:string='#E8D6B0';
 @Prop @Watch('paint') edge:string='';
 @Prop @Watch('paint') hook:number=.2;
 @Prop radius:number=8;
 @Prop @Watch('paint') scaleFactor:number=1;
 private context:CanvasRenderingContext2D=new CanvasRenderingContext2D(new RenderingContextSettings(true));
 private ready:boolean=false;
 private paintWidth:number=0;
 private paintHeight:number=0;
 private paint():void {
  if(!this.ready||this.paintWidth<=0||this.paintHeight<=0)return;
  const c=this.context,w=this.paintWidth,h=this.paintHeight,s=this.scaleFactor;
  c.clearRect(0,0,w,h);c.save();
  if(this.blend==='bare') {
   const p=compositionPadding(this.blend)*s;
   // A horizontal loaded-brush pass: translucent overlap, tapered bristle tips and parallel fibres.
   // Successive loaded-brush passes feather the fringe; no single hard cut-out edge.
   for(let pass=0;pass<8;pass++) {
    const inset=p*.35*pass/7;c.save();c.translate(inset,inset);
    c.fillStyle='rgba(247,249,252,0.095)';
    c.fill(new Path2D(micaPath('bare',vp2px(w-2*inset),vp2px(h-2*inset),vp2px(s))));c.restore();
   }
   c.lineCap='butt';
   for(let i=0;i<28;i++) {
    const y=(i+.2+(i%3)*.25)*h/28,tip=(.2+(i*7%9)*.32)*s;
    c.strokeStyle=i%3===0?'rgba(255,255,255,0.12)':'rgba(234,240,247,0.06)';c.lineWidth=(.25+(i%4)*.13)*s;
    c.beginPath();c.moveTo(tip,y);c.bezierCurveTo(w*.28,y-.7*s,w*.68,y+.7*s,w-tip,y+.25*s);c.stroke();
   }
  } else {
   const path=new Path2D(micaPath(this.blend,vp2px(w),vp2px(h),vp2px(s),this.edge));
   c.fillStyle='rgba(247,249,252,0.74)';c.fill(path);
   c.strokeStyle='rgba(255,255,255,0.34)';c.lineWidth=.6*s;c.stroke(path);
  }
  if(hookReserve(this.blend)>0) {
   const x=hookCenter(this.hook,w,s),y=10*s,r=3.3*s;
   c.globalCompositeOperation='destination-out';c.beginPath();c.arc(x,y,r,0,Math.PI*2);c.fill();
   c.globalCompositeOperation='source-over';c.strokeStyle='rgba(79,85,92,0.22)';c.lineWidth=.8*s;c.beginPath();c.arc(x,y,r+.4*s,0,Math.PI*2);c.stroke();
  }
  c.restore();
 }
 private texture():Resource {
  const color=readingSurfaceColor(this.ink),scrim=this.blend==='scrim';
  if(color==='#252824')return scrim?$r('app.media.reading_scrim_dark'):$r('app.media.reading_feather_dark');
  if(color==='#FFFFFF')return scrim?$r('app.media.reading_scrim_white'):$r('app.media.reading_feather_white');
  if(color==='#000000')return scrim?$r('app.media.reading_scrim_black'):$r('app.media.reading_feather_black');
  return scrim?$r('app.media.reading_scrim_warm'):$r('app.media.reading_feather_warm');
 }
 build() {
  Stack() {
   if(isReadingComposition(this.blend)) {
    Canvas(this.context).width('100%').height('100%')
     .onReady(()=>{this.ready=true;this.paintWidth=this.context.width;this.paintHeight=this.context.height;this.paint();})
     .onAreaChange((_:Area,a:Area)=>{const w=Number(a.width),h=Number(a.height);if(w!==this.paintWidth||h!==this.paintHeight){this.paintWidth=w;this.paintHeight=h;this.paint();}})
   } else if(this.blend==='paper'){PaperBacking({radius:this.radius,scaleFactor:this.scaleFactor})}
   else if(this.blend!=='halo'){Image(this.texture()).width('100%').height('100%').objectFit(ImageFit.Fill).draggable(false)}
  }.width('100%').height('100%').hitTestBehavior(HitTestMode.None)
 }
}
