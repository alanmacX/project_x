import { hookCenter } from '../model/MicaGeometry';
/** Two visible wire segments: rear above the paper; front emerges through its punched hole. */
@Component
export struct ReadingHook {
 @Prop @Watch('paint') hook:number=.2;
 @Prop @Watch('paint') scaleFactor:number=1;
 private context:CanvasRenderingContext2D=new CanvasRenderingContext2D(new RenderingContextSettings(true));
 private ready:boolean=false;
 private paintWidth:number=0;
 private paint():void {
  if(!this.ready||this.paintWidth<=0)return;
  const c=this.context,s=this.scaleFactor,x=hookCenter(this.hook,this.paintWidth,s);
  c.clearRect(0,0,this.paintWidth,36*s);c.save();c.lineCap='round';
  // Label starts at y=16. The hidden rear leg is occluded by its surface.
  c.beginPath();c.moveTo(x-3*s,16*s);c.lineTo(x-3*s,9*s);c.bezierCurveTo(x-3*s,1*s,x+6*s,1*s,x+6*s,9*s);c.lineTo(x+6*s,21*s);c.bezierCurveTo(x+6*s,27*s,x,29*s,x,26*s);
  c.strokeStyle='rgba(29,35,42,0.16)';c.lineWidth=3.4*s;c.stroke();
  c.strokeStyle='#90979E';c.lineWidth=2.6*s;c.stroke();
  c.strokeStyle='#E4E8EC';c.lineWidth=1.3*s;c.stroke();c.restore();
 }
 build() {
  Stack({alignContent:Alignment.TopStart}) {
   Canvas(this.context).width('100%').height(36*this.scaleFactor).translate({y:-16*this.scaleFactor})
    .onReady(()=>{this.ready=true;this.paintWidth=this.context.width;this.paint();})
    .onAreaChange((_:Area,a:Area)=>{if(Number(a.width)!==this.paintWidth){this.paintWidth=Number(a.width);this.paint();}})
  }.width('100%').height('100%').hitTestBehavior(HitTestMode.None)
 }
}
