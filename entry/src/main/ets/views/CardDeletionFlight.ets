import { image } from '@kit.ImageKit';
import { FrameCallback } from '@kit.ArkUI';
import { motionFrameRate } from '../model/MotionPolicy';

class DeletionFirstFrame extends FrameCallback {
  private run:()=>void;
  constructor(run:()=>void){super();this.run=run;}
  onFrame():void {this.run();}
}
/** One captured face and one static crease texture. Only compositor properties animate. */
@Component
export struct CardDeletionFlight {
  bitmap:image.PixelMap|undefined=undefined;
  faceWidth:number=200;faceHeight:number=200;
  originX:number=0;originY:number=0;angle:number=0;
  viewportWidth:number=360;viewportHeight:number=720;
  onDone:()=>void=()=>{};
  @State sx:number=1;@State sy:number=1;
  @State turn:number=0;@State lean:number=0;
  @State tx:number=0;@State ty:number=0;
  @State round:number=0;@State crease:number=0;
  private alive:boolean=true;
  private ink:CanvasRenderingContext2D=new CanvasRenderingContext2D(new RenderingContextSettings(true));
  aboutToAppear():void {this.getUIContext().postFrameCallback(new DeletionFirstFrame(()=>this.start()));}
  aboutToDisappear():void {this.alive=false;}
  private start():void {
    if(!this.alive)return;
    const ball=Math.min(38,Math.min(this.faceWidth,this.faceHeight)*.48);
    this.getUIContext().keyframeAnimateTo({expectedFrameRateRange:motionFrameRate(),onFinish:()=>{if(this.alive)this.onDone();}},[
      {duration:90,curve:Curve.EaseOut,event:()=>{this.sx=.96;this.sy=1.03;this.ty=-10;this.turn=-7;}},
      {duration:150,curve:Curve.EaseInOut,event:()=>{this.sx=.56;this.sy=.43;this.turn=19;this.lean=32;this.round=Math.max(this.faceWidth,this.faceHeight);this.crease=.72;}},
      {duration:120,curve:Curve.EaseOut,event:()=>{this.sx=ball/this.faceWidth;this.sy=ball/this.faceHeight;this.turn=-26;this.lean=0;this.tx=-18;this.ty=-30;this.crease=1;}},
      {duration:110,curve:Curve.EaseOut,event:()=>{this.tx=Math.min(140,this.viewportWidth*.22);this.ty=-Math.min(110,this.viewportHeight*.14);this.turn=95;}},
      {duration:190,curve:Curve.EaseIn,event:()=>{this.tx=this.viewportWidth-this.originX+this.faceWidth;this.ty=this.viewportHeight-this.originY+this.faceHeight;this.turn=310;this.sx=ball*.76/this.faceWidth;this.sy=ball*.76/this.faceHeight;}}
    ]);
  }
  private drawCreases():void {
    const c=this.ink,w=this.faceWidth,h=this.faceHeight;
    c.clearRect(0,0,w,h);
    // Light/dark facets are drawn once, with no blur, image decoding or physics.
    c.fillStyle='rgba(248,243,230,0.62)';c.fillRect(0,0,w,h);
    const points:number[][]=[[0,0,.46,.52,1,0],[1,0,.46,.52,1,.82],[1,1,.46,.52,.23,1],[0,1,.46,.52,0,.25]];
    points.forEach((p:number[],i:number)=>{c.beginPath();c.moveTo(p[0]*w,p[1]*h);c.lineTo(p[2]*w,p[3]*h);c.lineTo(p[4]*w,p[5]*h);c.closePath();c.fillStyle=i%2===0?'rgba(255,255,255,0.42)':'rgba(52,43,30,0.22)';c.fill();});
    c.lineWidth=Math.max(1,w*.008);c.strokeStyle='rgba(255,255,255,0.55)';
    c.beginPath();c.moveTo(w*.12,h*.2);c.lineTo(w*.46,h*.52);c.lineTo(w*.78,h*.9);c.moveTo(w*.46,h*.52);c.lineTo(w*.87,h*.24);c.stroke();
  }
  build() {
    Stack({alignContent:Alignment.TopStart}) {
      Stack() {
        Image(this.bitmap).width(this.faceWidth).height(this.faceHeight).objectFit(ImageFit.Fill).draggable(false)
        Canvas(this.ink).width(this.faceWidth).height(this.faceHeight).onReady(()=>this.drawCreases()).opacity(this.crease).renderGroup(true)
      }.width(this.faceWidth).height(this.faceHeight).borderRadius(this.round).clip(true)
        .scale({x:this.sx,y:this.sy}).rotate({x:1,y:0,angle:this.lean}).rotate({angle:this.turn})
        .rotate({angle:this.angle,centerX:24,centerY:this.faceHeight-24})
        .translate({x:this.tx,y:this.ty}).position({x:this.originX,y:this.originY})
    }.width(this.viewportWidth).height(this.viewportHeight).clip(true).hitTestBehavior(HitTestMode.None).accessibilityLevel('no-hide-descendants')
  }
}
