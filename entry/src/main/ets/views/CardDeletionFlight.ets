import { image } from '@kit.ImageKit';
import { FrameCallback } from '@kit.ArkUI';
import { motionFrameRate } from '../model/MotionPolicy';
import { PaperFoldController } from './PaperFoldNode';
class DeletionFirstFrame extends FrameCallback {
  private run:()=>void;
  constructor(run:()=>void){super();this.run=run;}
  onFrame():void {this.run();}
}
@Component
export struct CardDeletionFlight {
  bitmap:image.PixelMap|undefined=undefined;
  faceWidth:number=200;faceHeight:number=200;
  originX:number=0;originY:number=0;angle:number=0;
  viewportWidth:number=360;viewportHeight:number=720;
  onDone:()=>void=()=>{};
  @State turn:number=0;@State tx:number=0;@State ty:number=0;@State flightScale:number=1;
  private alive:boolean=true;
  private controller:PaperFoldController=new PaperFoldController();
  aboutToAppear():void {
    this.controller.configure(this.bitmap,this.faceWidth,this.faceHeight,this.getUIContext().vp2px(1));
    this.getUIContext().postFrameCallback(new DeletionFirstFrame(()=>this.start()));
  }
  aboutToDisappear():void {this.alive=false;this.controller.stop();}
  private start():void {
    if(!this.alive)return;
    this.getUIContext().animateTo({duration:80,curve:Curve.EaseOut,expectedFrameRateRange:motionFrameRate(),onFinish:()=>{
      if(this.alive)this.controller.fold(this.getUIContext(),()=>this.toss());
    }},()=>{this.ty=-12;this.turn=-5;});
  }
  private toss():void {
    if(!this.alive)return;
    this.getUIContext().keyframeAnimateTo({expectedFrameRateRange:motionFrameRate(),onFinish:()=>{if(this.alive)this.onDone();}},[
      {duration:70,curve:Curve.EaseOut,event:()=>{this.tx=-22;this.ty=-22;this.turn=-18;}},
      {duration:110,curve:Curve.EaseOut,event:()=>{this.tx=Math.min(140,this.viewportWidth*.22);this.ty=-Math.min(110,this.viewportHeight*.14);this.turn=75;}},
      {duration:160,curve:Curve.EaseIn,event:()=>{this.tx=this.viewportWidth-this.originX+this.faceWidth;this.ty=this.viewportHeight-this.originY+this.faceHeight;this.turn=255;this.flightScale=.82;}}
    ]);
  }
  build() {
    Stack({alignContent:Alignment.TopStart}) {
      Stack() {
        NodeContainer(this.controller).width(this.faceWidth).height(this.faceHeight)
          .scale({x:this.flightScale,y:this.flightScale}).rotate({angle:this.turn})
      }.width(this.faceWidth).height(this.faceHeight)
        .rotate({angle:this.angle,centerX:24,centerY:this.faceHeight-24})
        .translate({x:this.tx,y:this.ty}).position({x:this.originX,y:this.originY})
    }.width(this.viewportWidth).height(this.viewportHeight).clip(true).hitTestBehavior(HitTestMode.None).accessibilityLevel('no-hide-descendants')
  }
}
