import { EditorLayerMotion } from '../model/EditorLayerMotion';
import { AlbumCapability } from './AlbumCapability';
import { readingSurface, readingSurfaceColor, READING_PAPER_FILL, paperReadingInk, paperReadingRadius } from '../model/CapabilityPresentation';
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
  private capSurfaceBox(): ElementBox {
    const box = this.box(), f = subjectSurfaceFactor(this.card), inset = (1 - f) / 2;
    const surface = new ElementBox(); surface.x = (box.x - inset) / f; surface.y = (box.y - inset) / f;
    surface.w = box.w / f; surface.h = box.h / f; return surface;
  }
  private capabilityInk():string { return this.card.shape==='subject'&&this.card.subjectPhoto&&this.card.ink.length===0?this.card.subjectInk:materialColors(this.card.material,this.card.paper,this.card.ink)[1]; }
  private hasReadingSurface():boolean { return readingSurface(this.card.capability,this.card.shape==='subject'&&this.card.subjectPhoto,capabilityObstructed(this.card)); }
  private paperLabel():boolean {return this.hasReadingSurface()&&this.card.capability?.readingBlend==='paper';}
  private paperRadius():number {const box=this.box();return paperReadingRadius(this.card.w*box.w,this.card.h*box.h)*this.scaleFactor;}
  private readingTexture():Resource {
    const color=readingSurfaceColor(this.capabilityInk()),scrim=this.card.capability?.readingBlend==='scrim';
    if(color==='#252824')return scrim?$r('app.media.reading_scrim_dark'):$r('app.media.reading_feather_dark');
    if(color==='#FFFFFF')return scrim?$r('app.media.reading_scrim_white'):$r('app.media.reading_feather_white');
    if(color==='#000000')return scrim?$r('app.media.reading_scrim_black'):$r('app.media.reading_feather_black');
    return scrim?$r('app.media.reading_scrim_warm'):$r('app.media.reading_feather_warm');
  }
  build() {
    Stack() {
      if(this.paperLabel()) {
        Column().width('100%').height('100%').backgroundColor(READING_PAPER_FILL).borderRadius(this.paperRadius())
          .border({width:{bottom:.6*this.scaleFactor},color:'#35A79A82'})
          .shadow({radius:3*this.scaleFactor,color:'#16000000',offsetY:1.2*this.scaleFactor}).hitTestBehavior(HitTestMode.None)
        Column().width('100%').height('100%').backgroundImage($r('app.media.reading_paper_fibres'),ImageRepeat.XY)
          .backgroundImageSize({width:160*this.scaleFactor,height:160*this.scaleFactor}).borderRadius(this.paperRadius()).clip(true)
          .opacity(.55).hitTestBehavior(HitTestMode.None)
      } else if(this.hasReadingSurface() && this.card.capability?.readingBlend!=='halo') {
        // One precomputed alpha field: native gradient bounds differ across Form hosts.
        Image(this.readingTexture()).width('100%').height('100%').objectFit(ImageFit.Fill).draggable(false)
          .scale({x:1.45,y:1.45})
          .hitTestBehavior(HitTestMode.None)
      }
      Column() { CapabilityView({cap:this.card.capability!,ink:this.paperLabel()?paperReadingInk(this.capabilityInk()):this.capabilityInk(),readingHaloEnabled:this.hasReadingSurface()&&!this.paperLabel(),scaleFactor:this.scaleFactor,
        contentWidth:this.card.w*this.box().w-2*capabilityInset(this.card),contentHeight:this.card.h*this.box().h-2*capabilityInset(this.card),tick:this.tick}) }
        .padding(capabilityInset(this.card)*this.scaleFactor).width('100%').height('100%')
    }.width((this.capSurfaceBox().w*100)+'%').height((this.capSurfaceBox().h*100)+'%')
      .position({x:(this.capSurfaceBox().x*100)+'%',y:(this.capSurfaceBox().y*100)+'%'})

      .opacity(this.box().opacity)
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
  private freeCapability():boolean {return this.card.capFree || this.layerMotion.id==='capability';}
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
