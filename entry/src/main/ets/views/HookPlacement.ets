import { AppDesign } from '../model/AppDesign';
import { ReadingBacking } from './ReadingBacking';
import { ReadingHook } from './ReadingHook';
@Component
export struct HookPlacement {
 @Prop @Watch('sync') hookLocation:number=.2;
 @State live:number=.2;
 @Prop appDark:boolean=false;
 private dragging:boolean=false;
 private viewportWidth:number=280;
 private start:number=.2;
 onChoose:(position:number)=>void=()=>{};
 aboutToAppear():void {this.sync();}
 private sync():void {if(!this.dragging)this.live=this.hookLocation;}
 private positionAt(x:number):number {return Math.max(0,Math.min(1,(x-14)/Math.max(1,this.viewportWidth-28)));}
 build() {
  Column({space:10}) {
   Text('挂钩位置').fontSize(14).fontColor(AppDesign.text(this.appDark)).width('100%')
   Stack({alignContent:Alignment.TopStart}) {
    ReadingBacking({blend:'tag',hook:this.live}).width('100%').height(64)
    ReadingHook({hook:this.live}).width('100%').height(64)
    Text('点按上沿或左右拖动挂钩').fontSize(12).fontColor('#535B63').position({x:14,y:30}).hitTestBehavior(HitTestMode.None)
   }.width('100%').height(64).margin({top:16})
    .onAreaChange((_:Area,a:Area)=>this.viewportWidth=Number(a.width))
    .gesture(PanGesture({direction:PanDirection.Horizontal,distance:2}).onActionStart(()=>{this.dragging=true;this.start=this.live;}).onActionUpdate((e:GestureEvent)=>{this.live=Math.max(0,Math.min(1,this.start+e.offsetX/Math.max(1,this.viewportWidth-28)));}).onActionEnd(()=>{this.dragging=false;this.onChoose(this.live);}).onActionCancel(()=>{this.dragging=false;this.sync();}))
    .onTouch((e:TouchEvent)=>{if(e.type===TouchType.Down&&e.touches.length){this.live=this.positionAt(e.touches[0].x);}}).onClick(()=>this.onChoose(this.live))
   Row({space:8}) {
    ForEach([0,.5,1],(p:number)=>{Button(p===0?'左侧':p===1?'右侧':'居中',{type:ButtonType.Capsule}).fontSize(12).fontColor(AppDesign.text(this.appDark)).backgroundColor(AppDesign.control(this.appDark)).layoutWeight(1).height(44).onClick(()=>{this.live=p;this.onChoose(p);})})
   }.width('100%')
  }.width('100%')
 }
}
