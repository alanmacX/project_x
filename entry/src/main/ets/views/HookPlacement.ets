import { hookPoint, hookPosition } from '../model/ReadingComposition';
import { AppDesign } from '../model/AppDesign';
/** Continuous upper-half placement; one native gesture surface, no slider or modal. */
@Component
export struct HookPlacement {
 @Prop @Watch('sync') hookLocation:number=.2;
 @State live:number=.2;
 private dragging:boolean=false;
 aboutToAppear():void {this.sync();}
 private sync():void {if(!this.dragging)this.live=this.hookLocation;}
 @Prop appDark:boolean=false;
 private viewportWidth:number=280;
 onChoose:(position:number)=>void=()=>{};
 private start:number=.2;
 build() {
  Column({space:6}) {
   Text('挂钩位置 · 在上半圈拖动打孔').fontSize(12).fontColor(AppDesign.muted(this.appDark)).width('100%')
   Stack({alignContent:Alignment.TopStart}) {
    Image($r('app.media.mica_hook_arc')).width('100%').height(120).objectFit(ImageFit.Fill).draggable(false)
    Image($r('app.media.mica_hook')).sourceSize({width:64,height:80}).width(24).height(32).objectFit(ImageFit.Contain).draggable(false)
      .position({x:(hookPoint(this.live)[0]*100)+'%',y:(hookPoint(this.live)[1]*100)+'%'}).translate({x:-12,y:-16})
   }.width('100%').height(120).borderRadius(16).backgroundColor(AppDesign.control(this.appDark))
     .onAreaChange((_:Area,a:Area)=>this.viewportWidth=Number(a.width))
     .gesture(PanGesture({distance:1}).onActionStart(()=>{this.dragging=true;this.start=this.live;}).onActionUpdate((e:GestureEvent)=>{const p=hookPoint(this.start);this.live=hookPosition(p[0]+e.offsetX/this.viewportWidth,p[1]+e.offsetY/120);}).onActionEnd(()=>{this.dragging=false;this.onChoose(this.live);}).onActionCancel(()=>{this.dragging=false;this.sync();}))
     .onTouch((e:TouchEvent)=>{if(e.type===TouchType.Down&&e.touches.length){this.live=hookPosition(e.touches[0].x/this.viewportWidth,e.touches[0].y/120);}}).onClick(()=>this.onChoose(this.live))
  }.width('100%')
 }
}
