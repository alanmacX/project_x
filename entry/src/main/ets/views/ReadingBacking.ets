import { attachedPath } from '../model/EdgeAttachment';
import { readingSurfaceColor } from '../model/CapabilityPresentation';
import { isReadingComposition, compositionPadding } from '../model/ReadingComposition';
import { hookCenter, hookReserve, micaPath } from '../model/MicaGeometry';
import { micaStudyFill } from '../model/MicaMaterialStudy';
import { PaperBacking } from './PaperBacking';
/** Shared native material paths; translating a card never clears a bitmap surface. */
@Component
export struct ReadingBacking {
 @Prop blend:string='paper';
 @Prop study:number=0;
 @Prop ink:string='#262824';
 @Prop tint:string='#E8D6B0';
 @Prop edge:string='';
 @Prop profile:number[]=[];
 @Prop contactLeft:boolean=true;
 @Prop hook:number=.2;
 @Prop radius:number=8;
 @Prop surfaceWidth:number=0;
 @Prop surfaceHeight:number=0;
 @Prop scaleFactor:number=1;
 // Native paths participate in layout in both ArkUI and the restricted Form host.
 // No bitmap-clear or onReady/resize handoff is needed when the label changes size.
 @State private actualWidth:number=0;
 @State private actualHeight:number=0;
 private w():number {return this.actualWidth||this.surfaceWidth;}
 private h():number {return this.actualHeight||this.surfaceHeight;}
 private path(inset:number=0):string {
  const w=vp2px(Math.max(0,this.w()-2*inset)),h=vp2px(Math.max(0,this.h()-2*inset)),s=vp2px(this.scaleFactor);
  if(w<=0||h<=0)return '';
  let path=this.profile.length?attachedPath(w,h,this.profile,this.contactLeft,6*s):micaPath(this.blend,w,h,s,this.edge);
  if(hookReserve(this.blend)>0) {
   const x=vp2px(hookCenter(this.hook,this.w(),this.scaleFactor)-inset),y=10*s-vp2px(inset),r=3.3*s;
   // Counter-clockwise subpath punches a real transparent hole using nonzero winding.
   path+=` M ${x+r} ${y} A ${r} ${r} 0 1 0 ${x-r} ${y} A ${r} ${r} 0 1 0 ${x+r} ${y} Z`;
  }
  return path;
 }
 private fibre(index:number):string {
  const w=vp2px(this.w()),h=vp2px(this.h()),s=vp2px(this.scaleFactor),y=(index+.2+(index%3)*.25)*h/28,tip=(.2+(index*7%9)*.32)*s;
  return `M ${tip} ${y} C ${w*.28} ${y-.7*s} ${w*.68} ${y+.7*s} ${w-tip} ${y+.25*s}`;
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
    if(this.study>0) {
     Path().commands(this.path()).fill(micaStudyFill(this.tint,this.study)).stroke('#40FFFCF2').strokeWidth(.45*this.scaleFactor).antiAlias(true).width('100%').height('100%')
     ForEach([1,2],(pass:number)=>{
      Path().commands(this.path(compositionPadding(this.blend)*this.scaleFactor*.12*pass)).fill(pass===1?'#10FFFFFF':'#0CFFFFFF').stroke(Color.Transparent).antiAlias(true)
       .width('100%').height('100%').translate({x:compositionPadding(this.blend)*this.scaleFactor*.12*pass,y:compositionPadding(this.blend)*this.scaleFactor*.12*pass})
     },(pass:number)=>String(pass))
     if(this.blend==='bare') {
      ForEach([2,5,8,11,14,17,20,23],(index:number)=>{
       Path().commands(this.fibre(index)).fill(Color.Transparent).stroke('#15FFFFFF').strokeWidth(.3*this.scaleFactor).width('100%').height('100%')
      },(index:number)=>String(index))
     }
    } else if(this.blend==='bare') {
     ForEach([0,1,2,3,4,5,6,7],(pass:number)=>{
      Path().commands(this.path(compositionPadding(this.blend)*this.scaleFactor*.35*pass/7)).fill('#18F7F9FC').stroke(Color.Transparent).antiAlias(true)
       .width('100%').height('100%').translate({x:compositionPadding(this.blend)*this.scaleFactor*.35*pass/7,y:compositionPadding(this.blend)*this.scaleFactor*.35*pass/7})
     },(pass:number)=>String(pass))
     ForEach(Array.from({length:28},(_:number,i:number)=>i),(index:number)=>{
      Path().commands(this.fibre(index)).fill(Color.Transparent).stroke(index%3===0?'#1FFFFFFF':'#0FEAF0F7').strokeWidth((.25+(index%4)*.13)*this.scaleFactor).width('100%').height('100%')
     },(index:number)=>String(index))
    } else {
     Path().commands(this.path()).fill('#BDF7F9FC').stroke('#57FFFFFF').strokeWidth(.6*this.scaleFactor).antiAlias(true).width('100%').height('100%')
    }
   } else if(this.blend==='paper'){PaperBacking({radius:this.radius,scaleFactor:this.scaleFactor})}
   else if(this.blend!=='halo'){Image(this.texture()).width('100%').height('100%').objectFit(ImageFit.Fill).draggable(false)}
  }.width('100%').height('100%').onSizeChange((_:SizeOptions,size:SizeOptions)=>{const w=Number(size.width),h=Number(size.height);if(w>0&&h>0&&(Math.abs(w-this.actualWidth)>.01||Math.abs(h-this.actualHeight)>.01)){this.actualWidth=w;this.actualHeight=h;}}).hitTestBehavior(HitTestMode.None)
 }
}
