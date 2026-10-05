import { BoardMotion, GroupPose } from '../model/BoardMotion';
import { ShapePoint } from '../model/CardSchema';
import { GroupBox } from '../model/GroupGeometry';
import { immersiveChrome } from '../model/ChromeMaterial';
/** One selection and two native handles for the entire group; the empty box never intercepts cards. */
@Component
export struct GroupSelection {
  @ObjectLink motion:BoardMotion;
  @Prop box:GroupBox=new GroupBox();
  @Prop minimum:number=0.2;
  @Prop maximum:number=4;
  @Prop viewportW:number=1;
  @Prop viewportH:number=1;
  onBegin:()=>void=()=>{};
  onFinish:(scale:number,angle:number)=>void=()=>{};
  onCancel:()=>void=()=>{};
  private startX:number=0;private startY:number=0;private lastAngle:number=0;private turn:number=0;
  private vectorX:number=1;private vectorY:number=1;
  private handleHit: HitTestMode = HitTestMode.None;
  private intercept(e:TouchEvent):HitTestMode {
    if(e.type===TouchType.Down) {
      const p=e.touches[0]??e.changedTouches[0],resize=this.handle(true),rotate=this.handle(false);
      const inside=(h:ShapePoint):boolean=>p!==undefined&&p.x>=h.x&&p.x<=h.x+44&&p.y>=h.y&&p.y<=h.y+44;
      this.handleHit=inside(resize)||inside(rotate)?HitTestMode.Transparent:HitTestMode.None;
    }
    return this.handleHit;
  }
  private begin(e:GestureEvent,rotation:boolean):void {
    const p=e.fingerList[0];this.startX=(p?.displayX??0)-e.offsetX;this.startY=(p?.displayY??0)-e.offsetY;
    const handle=this.handle(!rotation);this.vectorX=handle.x+22-this.box.x-this.box.w/2;this.vectorY=handle.y+22-this.box.y-this.box.h/2;
    this.turn=0;this.lastAngle=Math.atan2(this.vectorY,this.vectorX)*180/Math.PI;
    this.onBegin();this.update(e,rotation);
  }
  private update(e:GestureEvent,rotation:boolean):void {
    const p=e.fingerList[0],dx=p?p.displayX-this.startX:e.offsetX,dy=p?p.displayY-this.startY:e.offsetY;
    const pose=new GroupPose();
    if(rotation){const a=Math.atan2(this.vectorY+dy,this.vectorX+dx)*180/Math.PI;this.turn+=((a-this.lastAngle+540)%360)-180;this.lastAngle=a;const snap=Math.round(this.turn/90)*90;pose.angle=Math.abs(this.turn-snap)<2?snap:this.turn;}
    else{const x=this.vectorX,y=this.vectorY;pose.scale=Math.max(this.minimum,Math.min(this.maximum,1+(dx*x+dy*y)/Math.max(1,x*x+y*y)));}
    this.motion.pose=pose;
  }
  private finish():void{this.onFinish(this.motion.pose.scale,this.motion.pose.angle);}
  private handle(right:boolean):ShapePoint {
    const a=this.motion.pose.angle*Math.PI/180,s=this.motion.pose.scale;
    const x=(right?1:-1)*this.box.w*s/2,y=-this.box.h*s/2;
    return {x:Math.max(22,Math.min(this.viewportW-22,this.box.x+this.box.w/2+x*Math.cos(a)-y*Math.sin(a)+this.motion.offset.x))-22,
      y:Math.max(22,Math.min(this.viewportH-22,this.box.y+this.box.h/2+x*Math.sin(a)+y*Math.cos(a)+this.motion.offset.y))-22};
  }
  build(){
    Stack({alignContent:Alignment.TopStart}){
      Column().width(this.box.w).height(this.box.h).border({width:1.5,color:'#A89B80',radius:12})
        .position({x:this.box.x,y:this.box.y}).scale({x:this.motion.pose.scale,y:this.motion.pose.scale})
        .rotate({angle:this.motion.pose.angle}).translate(this.motion.offset).hitTestBehavior(HitTestMode.None)
      Button({type:ButtonType.Circle,buttonStyle:ButtonStyleMode.NORMAL}){SymbolGlyph($r('sys.symbol.arrow_up_left_and_arrow_down_right')).fontSize(22).fontColor(['#303030']).hitTestBehavior(HitTestMode.None)}
        .width(44).height(44).backgroundColor('#F6F2E9').attributeModifier(immersiveChrome()).position(this.handle(true)).accessibilityText('调整整个组合大小')
        .gesture(PanGesture({distance:2}).onActionStart((e:GestureEvent)=>this.begin(e,false)).onActionUpdate((e:GestureEvent)=>this.update(e,false)).onActionEnd(()=>this.finish()).onActionCancel(()=>this.onCancel()))
      Button({type:ButtonType.Circle,buttonStyle:ButtonStyleMode.NORMAL}){SymbolGlyph($r('sys.symbol.arrow_clockwise')).fontSize(22).fontColor(['#303030']).hitTestBehavior(HitTestMode.None)}
        .width(44).height(44).backgroundColor('#F6F2E9').attributeModifier(immersiveChrome()).position(this.handle(false)).accessibilityText('旋转整个组合')
        .gesture(PanGesture({distance:2}).onActionStart((e:GestureEvent)=>this.begin(e,true)).onActionUpdate((e:GestureEvent)=>this.update(e,true)).onActionEnd(()=>this.finish()).onActionCancel(()=>this.onCancel()))
    }.width(this.viewportW).height(this.viewportH).borderRadius(24).clip(true)
      // Transparent alone still lets this full-size custom component enter the
      // hit-test chain. Only handles own touches; cards and empty space pass through.
      .responseRegion([{x:this.handle(true).x,y:this.handle(true).y,width:44,height:44},
        {x:this.handle(false).x,y:this.handle(false).y,width:44,height:44}])
      .onTouchIntercept((e:TouchEvent):HitTestMode=>this.intercept(e))
      .hitTestBehavior(HitTestMode.Transparent)
  }
}
