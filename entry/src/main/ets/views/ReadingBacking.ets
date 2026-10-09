import { CLOUD_READING_OUTSET, cloudReadingPath } from '../model/CloudReadingGeometry';
import { PathShape } from '@kit.ArkUI';
import { attachedPath } from '../model/EdgeAttachment';
import { readingSurfaceColor } from '../model/CapabilityPresentation';
import { isReadingComposition, compositionPadding } from '../model/ReadingComposition';
import { hookCenter, hookReserve, micaPath } from '../model/MicaGeometry';
import { micaStudyFill, micaStudyPigment, tactileFill, tactilePigment, tactileTextureOpacity, tactileEdgeColor, tactileThickness } from '../model/MicaMaterialStudy';
import { PaperBacking } from './PaperBacking';
/** Shared native material paths; translating a card never clears a bitmap surface. */
@Component
export struct ReadingBacking {
 @Prop blend:string='paper';
 @Prop study:number=5;
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
 private cloudKey:string='';
 private cloudValue:string='';
 private cloudPath():string {
  const w=vp2px(this.w()),h=vp2px(this.h()),scale=vp2px(this.scaleFactor),key=[w,h,scale].join(':');
  if(key!==this.cloudKey){this.cloudKey=key;this.cloudValue=cloudReadingPath(w,h,scale);}
  return this.cloudValue;
 }
 private path(inset:number=0):string {
  const w=vp2px(Math.max(0,this.w()-2*inset)),h=vp2px(Math.max(0,this.h()-2*inset)),s=vp2px(this.scaleFactor);
  if(w<=0||h<=0)return '';
  let path=this.profile.length?attachedPath(w,h,this.profile,this.contactLeft,6*s):micaPath(this.blend,w,h,s,this.edge);
  if(this.study>0&&this.study<4&&(this.blend==='tag'||this.blend==='dock')) {
   const r=Math.min(18*s,w/4,h/4);
   path=`M ${r} 0 L ${w-r} 0 Q ${w} 0 ${w} ${r} L ${w} ${h-r} Q ${w} ${h} ${w-r} ${h} L ${r} ${h} Q 0 ${h} 0 ${h-r} L 0 ${r} Q 0 0 ${r} 0 Z`;
  }
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
 private tactileWidth():number {return this.w()+(this.blend==='cloud'?2*CLOUD_READING_OUTSET*this.scaleFactor:0);}
 private tactileHeight():number {return this.h()+(this.blend==='cloud'?2*CLOUD_READING_OUTSET*this.scaleFactor:0);}
 private tactilePath():string {return this.blend==='cloud'?this.cloudPath():this.path();}
 @Builder private tactileSurface() {
  Stack() {
   Path().commands(this.tactilePath()).fill(tactileEdgeColor(this.study)).stroke(Color.Transparent).antiAlias(true)
    .width('100%').height('100%').translate({y:tactileThickness(this.study)*this.scaleFactor})
   Stack() {
    Column().width('100%').height('100%').backgroundColor(tactileFill(this.tint,this.study))
    Column().width('100%').height('100%').radialGradient({center:['84%','90%'],radius:'96%',colors:[[tactilePigment(this.tint,this.study),0],['#00000000',1]]})
    Image($r('app.media.reading_surface_paper')).width('100%').height('100%').objectFit(ImageFit.Fill).opacity(tactileTextureOpacity(this.study)).draggable(false)
    Column().width('100%').height('100%').linearGradient({angle:180,colors:[['#58FFFFFC',0],['#00FFFFFC',.48],['#0DAD9168',1]]})
   }.width('100%').height('100%').clipShape(new PathShape().commands(this.tactilePath()))
   Path().commands(this.tactilePath()).fill(Color.Transparent).stroke('#A8FFFDF7').strokeWidth(.7*this.scaleFactor).antiAlias(true).width('100%').height('100%')
  }.width(this.tactileWidth()).height(this.tactileHeight())
   .position({x:this.blend==='cloud'?-CLOUD_READING_OUTSET*this.scaleFactor:0,y:this.blend==='cloud'?-CLOUD_READING_OUTSET*this.scaleFactor:0})
 }
 build() {
  Stack() {
   if(isReadingComposition(this.blend)) {
    if(this.study>=4) {
     this.tactileSurface()
    } else if(this.blend==='cloud') {
     // Two native shapes, no blur/bitmap clear. Expanded bounds preserve the text core.
     Path().commands(this.cloudPath()).fill('#249C8B6C').stroke(Color.Transparent).antiAlias(true)
      .width(this.w()+2*CLOUD_READING_OUTSET*this.scaleFactor).height(this.h()+2*CLOUD_READING_OUTSET*this.scaleFactor)
      .position({x:-CLOUD_READING_OUTSET*this.scaleFactor,y:-CLOUD_READING_OUTSET*this.scaleFactor+2*this.scaleFactor})
     Path().commands(this.cloudPath()).fill('#E6FAF4E3').stroke('#FFFDF6').strokeWidth(1.1*this.scaleFactor).antiAlias(true)
      .width(this.w()+2*CLOUD_READING_OUTSET*this.scaleFactor).height(this.h()+2*CLOUD_READING_OUTSET*this.scaleFactor)
      .position({x:-CLOUD_READING_OUTSET*this.scaleFactor,y:-CLOUD_READING_OUTSET*this.scaleFactor})
    } else if(this.study>0) {
     // Shape offset gives thickness without Path.shadow's rectangular layer bounds.
     Path().commands(this.path()).fill('#28B29D74').stroke(Color.Transparent).antiAlias(true)
      .width('100%').height('100%').translate({y:1.2*this.scaleFactor})
     Stack() {
      Column().width('100%').height('100%').backgroundColor(micaStudyFill(this.tint,this.study))
      Image($r('app.media.reading_mica_cloud')).width('100%').height('100%').objectFit(ImageFit.Fill).opacity(.55).draggable(false)
      // Broad, uneven colour pools rather than a uniformly coloured sheet.
      Column().width('100%').height('100%')
       .radialGradient({center:['86%','82%'],radius:'92%',colors:[[micaStudyPigment(this.tint,this.study),0],[micaStudyPigment(this.tint,this.study,.4),.46],['#00000000',1]]})
      Column().width('100%').height('100%')
       .radialGradient({center:['15%','22%'],radius:'80%',colors:[['#B8FFFFF8',0],['#50FFFFF8',.35],['#00FFFFF8',1]]})
      Column().width('100%').height('100%')
       .radialGradient({center:['58%','-10%'],radius:'74%',colors:[['#72FFFFFD',0],['#08FFFFFD',.7],['#00FFFFFD',1]]})
      Column().width('100%').height('100%')
       .linearGradient({angle:120,colors:[['#20FFFFFF',0],['#00FFFFFF',.35],['#16FFF3D8',.68],['#00FFFFFF',1]]})
     }.width('100%').height('100%').clipShape(new PathShape().commands(this.path()))
     // An outer cream lip and a finer inset highlight give a thin mica edge.
     Path().commands(this.path()).fill(Color.Transparent).stroke(this.blend==='bare'?'#42FFFCF1':'#C8FFFDF6')
      .strokeWidth((this.blend==='bare'?.6:1.5)*this.scaleFactor).antiAlias(true).width('100%').height('100%')
     Path().commands(this.path(.9*this.scaleFactor)).fill(Color.Transparent).stroke('#42FFFFFF').strokeWidth(.4*this.scaleFactor)
      .antiAlias(true).width('100%').height('100%').translate({x:.9*this.scaleFactor,y:.9*this.scaleFactor})
     if(this.blend==='bare') {
      ForEach([2,5,8,11,14,17,20,23],(index:number)=>{
       Path().commands(this.fibre(index)).fill(Color.Transparent).stroke('#18FFFFFF').strokeWidth(.45*this.scaleFactor).width('100%').height('100%')
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
