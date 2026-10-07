import { EditorLayerMotion } from '../model/EditorLayerMotion';
import { ElementBox, FridgeCard } from '../model/CardSchema';
import { edgeAttachment } from '../model/EdgeAttachment';
import { selectionHandles, SelectionHandles } from '../model/SelectionHandles';
import { immersiveChrome } from '../model/ChromeMaterial';
import { AppDesign } from '../model/AppDesign';
@Component
export struct EditorLayerTarget {
  @ObjectLink motion:EditorLayerMotion;
  @Prop targetId:string='';
  @Prop attachmentCard:FridgeCard|null=null;
  @Prop box:ElementBox=new ElementBox();
  @Prop factor:number=1;
  @Prop selected:boolean=false;
  onSelect:()=>void=()=>{};
  onStart:(e:GestureEvent)=>void=()=>{};
  onUpdate:(e:GestureEvent)=>void=()=>{};
  onEnd:(e:GestureEvent)=>void=()=>{};
  onCancel:()=>void=()=>{};
  private live():ElementBox {const b=this.motion.id===this.targetId?this.motion.box:this.box,c=this.attachmentCard;return c?.capability?.readingBlend==='sticker'?edgeAttachment(c,b,c.capability.readingEdge||'left',c.capability.readingOutside===true).box:b;}
  private inset():number {return (1-this.factor)/2;}
  build() {
    Stack().width(this.live().w*this.factor*100+'%').height(this.live().h*this.factor*100+'%')
      .position({x:(this.inset()+this.live().x*this.factor)*100+'%',y:(this.inset()+this.live().y*this.factor)*100+'%'})
      .rotate({angle:this.live().rot}).border({width:this.selected?1:0,color:'#7A7A7A'}).zIndex(this.selected?10000:0)
      .onClick(()=>this.onSelect()).gesture(PanGesture({distance:3}).onActionStart((e)=>this.onStart(e)).onActionUpdate((e)=>this.onUpdate(e)).onActionEnd((e)=>this.onEnd(e)).onActionCancel(()=>this.onCancel()))
  }
}
@Component
export struct EditorLayerHandles {
  @ObjectLink motion:EditorLayerMotion;
  @Prop targetId:string='';
  @Prop attachmentCard:FridgeCard|null=null;
  @Prop box:ElementBox=new ElementBox();
  @Prop contentW:number=1;
  @Prop contentH:number=1;
  @Prop angle:number=0;
  @Prop viewportWidth:number=1;
  @Prop viewportHeight:number=1;
  @Prop left:number=0;
  @Prop top:number=0;
  @Prop factor:number=1;
  @Prop appDark:boolean=false;
  onStart:(e:GestureEvent)=>void=()=>{};
  onResize:(e:GestureEvent)=>void=()=>{};
  onRotate:(e:GestureEvent)=>void=()=>{};
  onEnd:()=>void=()=>{};
  onCancel:()=>void=()=>{};
  private handles():SelectionHandles {
    const raw=this.motion.id===this.targetId?this.motion.box:this.box,c=this.attachmentCard;
    const b=c?.capability?.readingBlend==='sticker'?edgeAttachment(c,raw,c.capability.readingEdge||'left',c.capability.readingOutside===true).box:raw,inset=(1-this.factor)/2,box=new ElementBox();
    box.x=inset+b.x*this.factor;box.y=inset+b.y*this.factor;box.w=b.w*this.factor;box.h=b.h*this.factor;box.rot=b.rot;
    return selectionHandles(box,this.contentW,this.contentH,this.angle,this.viewportWidth,this.viewportHeight,this.left,this.top);
  }
  @Builder
  handle(resize:boolean) {
    Button({type:ButtonType.Circle,buttonStyle:ButtonStyleMode.NORMAL}) {
      SymbolGlyph(resize?$r('sys.symbol.arrow_up_left_and_arrow_down_right'):$r('sys.symbol.arrow_clockwise')).fontSize(20).fontColor([AppDesign.text(this.appDark)]).hitTestBehavior(HitTestMode.None)
    }.width(44).height(44).backgroundColor(AppDesign.surface(this.appDark)).attributeModifier(immersiveChrome(this.appDark))
      .position({x:(resize?this.handles().resize.x:this.handles().rotate.x)-22,y:(resize?this.handles().resize.y:this.handles().rotate.y)-22})
      .accessibilityText(resize?'缩放选中元素':'旋转选中元素')
      .gesture(PanGesture({distance:2}).onActionStart((e)=>this.onStart(e)).onActionUpdate((e)=>{if(resize)this.onResize(e);else this.onRotate(e);})
        .onActionEnd((e)=>{if(resize)this.onResize(e);else this.onRotate(e);this.onEnd();}).onActionCancel(()=>this.onCancel()))
  }
  build() {Stack({alignContent:Alignment.TopStart}) {this.handle(true);if(this.attachmentCard?.capability?.readingBlend!=='sticker'){this.handle(false)}}.width('100%').height('100%').hitTestBehavior(HitTestMode.Transparent)}
}
