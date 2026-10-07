import { isReadingComposition } from '../model/ReadingComposition';
import { edgeAttachment, EdgeAttachment } from '../model/EdgeAttachment';
import { hookReserve } from '../model/MicaGeometry';
import { EditorLayerMotion } from '../model/EditorLayerMotion';
import { AlbumCapability } from './AlbumCapability';
import { readingSurface, paperReadingInk } from '../model/CapabilityPresentation';
import { capabilityInset } from '../model/CanvasLayout';
import { AnimatedPhoto } from './AnimatedPhoto';
import { FridgeCard, CanvasElement, ElementBox, materialColors, cardCornerRadius } from '../model/CardSchema';
import { capabilityObstructed, capabilityBox, capabilityPlacement, fitContentBox, safeContentBox, subjectSurfaceFactor } from '../model/CanvasLayout';
import { CapabilityView } from './CapBlockView';

@Component
export struct ElementView {
  @Prop element: CanvasElement = new CanvasElement();
  @Prop ink: string = '#262824';
  @Prop scaleFactor: number = 1;
  @Prop widget: boolean = false;
  build() {
    if (this.element.kind === 'text') {
      Text(this.element.text).fontSize(this.element.fs * this.scaleFactor)
        .minFontSize(Math.min(8, this.element.fs) * this.scaleFactor).maxFontSize(this.element.fs * this.scaleFactor)
        .heightAdaptivePolicy(TextHeightAdaptivePolicy.LAYOUT_CONSTRAINT_FIRST)
        .fontWeight(this.element.bold ? FontWeight.Medium : FontWeight.Normal)
        .fontColor(this.element.color || this.ink)
        .textAlign(this.element.align === 'center' ? TextAlign.Center : (this.element.align === 'right' ? TextAlign.End : TextAlign.Start))
        .width('100%').height('100%').textOverflow({ overflow: TextOverflow.Ellipsis })
    } else if (this.element.kind === 'image') {
      if (this.element.src.length > 0) {
        AnimatedPhoto({ src: this.element.src, animated: this.element.animated, widget: this.widget }).width('100%').height('100%')
      }
    } else {
      Column().width('100%').height(this.element.primitive === 'line' ? 3 : '100%')
        .backgroundColor(this.element.color || this.ink).borderRadius(this.element.primitive === 'circle' ? '50%' : 4)
    }
  }
}

@Component
struct CanvasElementLayer {
  @ObjectLink motion:EditorLayerMotion;
  @Prop element:CanvasElement=new CanvasElement();
  @Prop ink:string='#262824';
  @Prop scaleFactor:number=1;
  @Prop widget:boolean=false;
  private box():ElementBox {return this.motion.id===this.element.id?this.motion.box:this.element;}
  build() {
    Column() {ElementView({element:this.element,ink:this.ink,scaleFactor:this.scaleFactor,widget:this.widget})}
      .width(this.box().w*100+'%').height(this.box().h*100+'%')
      .position({x:this.box().x*100+'%',y:this.box().y*100+'%'})
      .rotate({angle:this.box().rot}).opacity(this.box().opacity).renderGroup(!this.element.animated)
  }
}

@Component
struct CapabilityContentLayer {
  @ObjectLink motion: EditorLayerMotion;
  @Prop card: FridgeCard = new FridgeCard();
  @Prop scaleFactor: number = 1;
  @Prop tick: number = 0;
  private box(): ElementBox { return this.motion.id==='capability'?this.motion.box:capabilityPlacement(this.card); }
  private contactKey:string='';
  private contactValue:EdgeAttachment=new EdgeAttachment();
  private contact():EdgeAttachment {
    const b=this.box(),edge=this.card.capability?.readingEdge||'left';
    if(this.card.capability?.readingBlend!=='sticker')return new EdgeAttachment();
    const key=[b.y,b.w,b.h,this.card.w,this.card.h,this.card.cutout,this.card.subjectVersion,this.card.renderContourKey,this.card.shape,edge,this.card.capability?.readingOutside].join(':');
    if(key!==this.contactKey){this.contactKey=key;this.contactValue=edgeAttachment(this.card,b,edge,this.card.capability?.readingOutside===true);}return this.contactValue;
  }

  private capSurfaceBox(): ElementBox {
    const box = this.card.capability?.readingBlend==='sticker'?this.contact().box:this.box(), f = subjectSurfaceFactor(this.card), inset = (1 - f) / 2;
    const surface = new ElementBox(); surface.x = (box.x - inset) / f; surface.y = (box.y - inset) / f;
    surface.w = box.w / f; surface.h = box.h / f; return surface;
  }
  private capabilityInk():string { return this.card.shape==='subject'&&this.card.subjectPhoto&&this.card.ink.length===0?this.card.subjectInk:materialColors(this.card.material,this.card.paper,this.card.ink)[1]; }
  private hasReadingSurface():boolean { return readingSurface(this.card.capability,this.card.shape==='subject'&&this.card.subjectPhoto,capabilityObstructed(this.card)); }
  private paperLabel():boolean {return this.hasReadingSurface()&&['paper','bare','badge','sticker','space','tag','dock'].includes(this.card.capability?.readingBlend??'');}
  build() {
    Stack() {
      Column() { CapabilityView({cap:this.card.capability!,ink:this.paperLabel()?paperReadingInk(this.capabilityInk()):this.capabilityInk(),readingHaloEnabled:(this.hasReadingSurface()&&!this.paperLabel())||this.card.capability?.readingBlend==='bare',contentBackingEnabled:this.hasReadingSurface(),backingEdge:this.card.capability?.readingEdge??'left',backingProfile:this.contact().profile,backingLeft:(this.card.capability?.readingEdge!=='right')!==(this.card.capability?.readingOutside===true),backingGutter:this.contact().gutter,backingTint:this.card.capability?.readingTint||materialColors(this.card.material,this.card.paper,this.card.ink)[0],scaleFactor:this.scaleFactor,
        contentWidth:this.card.w*(this.card.capability?.readingBlend==='sticker'?this.contact().box.w:this.box().w)-2*capabilityInset(this.card)-this.contact().gutter,contentHeight:this.card.h*this.box().h-2*capabilityInset(this.card)-hookReserve(this.card.capability?.readingBlend??''),tick:this.tick}) }
        .padding(0).width('100%').height('100%')
    }.width((this.capSurfaceBox().w*100)+'%').height((this.capSurfaceBox().h*100)+'%')
      .position({x:(this.capSurfaceBox().x*100)+'%',y:(this.capSurfaceBox().y*100)+'%'})

      .rotate({angle:this.card.capability?.readingBlend==='sticker'?0:this.box().rot}).opacity(this.box().opacity)
  }
}

/** Render-only component: positions are relative to each card's own little canvas. */
@Component
export struct CardCanvas {
  @Prop card: FridgeCard = new FridgeCard();
  @Prop scaleFactor: number = 1;
  @Prop widget: boolean = false;
  @Prop hideContent: boolean = false;
  @Prop tick: number = 0;
  @State layerMotion: EditorLayerMotion = new EditorLayerMotion();
  @Prop movingLayerId: string = '';
  @Prop moveX: number = 0;
  @Prop moveY: number = 0;
  private freeCapability():boolean {return this.card.capFree || isReadingComposition(this.card.capability?.readingBlend??'') || this.layerMotion.id==='capability';}
  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Stack({ alignContent: Alignment.TopStart }) {
      if(this.card.capability?.k==='album') {
        AlbumCapability({tick:this.tick,widget:this.widget,cap:this.card.capability!,cardWidth:this.card.w,cardHeight:this.card.h,scaleFactor:this.scaleFactor})
      } else {
      Column().width('100%').height('100%').backgroundColor(materialColors(this.card.material, this.card.paper, this.card.ink)[0])
      if (this.card.shape === 'subject' && this.card.subjectPhoto && this.card.cutout.length > 0) {
        Image(this.card.cutout).width('100%').height('100%').objectFit(ImageFit.Fill).draggable(false)
      }
      this.canvasElements(true)
      if (!this.freeCapability() && !this.hideContent && this.card.capability !== null && !capabilityObstructed(this.card)) { CapabilityContentLayer({motion:this.layerMotion,card:this.card,scaleFactor:this.scaleFactor,tick:this.tick}) }
      if (!this.hideContent) { this.canvasElements(false) }
      if (!this.freeCapability() && !this.hideContent && this.card.capability !== null && capabilityObstructed(this.card)) { CapabilityContentLayer({motion:this.layerMotion,card:this.card,scaleFactor:this.scaleFactor,tick:this.tick}) }
      if (this.card.shape === 'subject' && this.card.cutout.length > 0) {
        Image(this.card.cutout).width('100%').height('100%').objectFit(ImageFit.Fill).draggable(false)
          .blendMode(BlendMode.DST_IN, BlendApplyType.OFFSCREEN)
      }
      }
    }.width('100%').height('100%').borderRadius(cardCornerRadius(this.card,this.scaleFactor)).clip(true)
      .blendMode(BlendMode.SRC_OVER, this.card.shape === 'subject' ? BlendApplyType.OFFSCREEN : BlendApplyType.FAST)
      if(this.freeCapability() && !this.hideContent && this.card.capability!==null && this.card.capability.k!=='album') {
        CapabilityContentLayer({motion:this.layerMotion,card:this.card,scaleFactor:this.scaleFactor,tick:this.tick})
      }
    }.width('100%').height('100%')
  }
  private elementFor(id: string): CanvasElement { return this.card.elements.find((el: CanvasElement) => el.id === id) ?? new CanvasElement(); }
  @Builder
  canvasElements(behind: boolean) {
    ForEach(this.card.elements.filter((el: CanvasElement) => el.behindCapability === behind).map((el: CanvasElement) => el.id), (id: string) => {
        CanvasElementLayer({motion:this.layerMotion,element:this.elementFor(id),ink:materialColors(this.card.material,this.card.paper,this.card.ink)[1],scaleFactor:this.scaleFactor,widget:this.widget})
      }, (id: string) => id)
  }

}
