import { EditorLayerMotion } from '../model/EditorLayerMotion';
import { AlbumCapability } from './AlbumCapability';
import { readingSurface, readingVeilColor } from '../model/CapabilityPresentation';
import { capabilityInset } from '../model/CanvasLayout';
import { AnimatedPhoto } from './AnimatedPhoto';
import { FridgeCard, CanvasElement, ElementBox, materialColors, shapeRadius } from '../model/CardSchema';
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
  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      if(this.card.capability?.k==='album') {
        AlbumCapability({cap:this.card.capability!,cardWidth:this.card.w,cardHeight:this.card.h,scaleFactor:this.scaleFactor})
      } else {
      Column().width('100%').height('100%').backgroundColor(materialColors(this.card.material, this.card.paper, this.card.ink)[0])
      if (this.card.shape === 'subject' && this.card.subjectPhoto && this.card.cutout.length > 0) {
        Image(this.card.cutout).width('100%').height('100%').objectFit(ImageFit.Fill).draggable(false)
      }
      this.canvasElements(true)
      if (!this.hideContent && this.card.capability !== null && !capabilityObstructed(this.card)) { this.capabilityContent() }
      if (!this.hideContent) { this.canvasElements(false) }
      if (!this.hideContent && this.card.capability !== null && capabilityObstructed(this.card)) { this.capabilityContent() }
      if (this.card.shape === 'subject' && this.card.cutout.length > 0) {
        Image(this.card.cutout).width('100%').height('100%').objectFit(ImageFit.Fill).draggable(false)
          .blendMode(BlendMode.DST_IN, BlendApplyType.OFFSCREEN)
      }
      }
    }.width('100%').height('100%').borderRadius(shapeRadius(this.card.shape)).clip(true)
      .blendMode(BlendMode.SRC_OVER, this.card.shape === 'subject' ? BlendApplyType.OFFSCREEN : BlendApplyType.FAST)
  }
  private capSurfaceBox(): ElementBox {
    const box = capabilityPlacement(this.card), f = subjectSurfaceFactor(this.card), inset = (1 - f) / 2;
    const surface = new ElementBox(); surface.x = (box.x - inset) / f; surface.y = (box.y - inset) / f;
    surface.w = box.w / f; surface.h = box.h / f; return surface;
  }
  private capabilityInk():string { return this.card.shape==='subject'&&this.card.subjectPhoto&&this.card.ink.length===0?this.card.subjectInk:materialColors(this.card.material,this.card.paper,this.card.ink)[1]; }
  private hasReadingSurface():boolean { return readingSurface(this.card.capability,this.card.shape==='subject'&&this.card.subjectPhoto,capabilityObstructed(this.card)); }
  @Builder
  capabilityContent() {
    Stack() {
      if(this.hasReadingSurface() && this.card.capability?.readingBlend!=='halo') {
        // Feather the entire field to zero before its perimeter. No border,
        // backdrop blur or additional offscreen material pass per capability.
        Column().width('100%').height('100%')
          .radialGradient({center:['50%','50%'],radius:'50%',colors:[
            [readingVeilColor(this.capabilityInk(), this.card.capability?.readingBlend==='scrim'?.70:.42,this.card.capability?.readingBlend), 0],
            [readingVeilColor(this.capabilityInk(), this.card.capability?.readingBlend==='scrim'?.62:.30,this.card.capability?.readingBlend), .38],
            [readingVeilColor(this.capabilityInk(), this.card.capability?.readingBlend==='scrim'?.22:.12,this.card.capability?.readingBlend), .72],
            [readingVeilColor(this.capabilityInk(), 0), 1]]})
          .scale({x:1.45,y:1.45})
          .hitTestBehavior(HitTestMode.None)
      }
      Column() { CapabilityView({cap:this.card.capability!,ink:this.capabilityInk(),readingHaloEnabled:this.hasReadingSurface(),scaleFactor:this.scaleFactor,
        contentWidth:this.card.w*capabilityPlacement(this.card).w-2*capabilityInset(this.card),contentHeight:this.card.h*capabilityPlacement(this.card).h-2*capabilityInset(this.card),tick:this.tick}) }
        .padding(capabilityInset(this.card)*this.scaleFactor).width('100%').height('100%')
    }.width((this.capSurfaceBox().w*100)+'%').height((this.capSurfaceBox().h*100)+'%')
      .position({x:(this.capSurfaceBox().x*100)+'%',y:(this.capSurfaceBox().y*100)+'%'})
      .translate({x:this.movingLayerId==='capability'?this.moveX:0,y:this.movingLayerId==='capability'?this.moveY:0})
      .opacity(capabilityPlacement(this.card).opacity)
  }
  private elementFor(id: string): CanvasElement { return this.card.elements.find((el: CanvasElement) => el.id === id) ?? new CanvasElement(); }
  @Builder
  canvasElements(behind: boolean) {
    ForEach(this.card.elements.filter((el: CanvasElement) => el.behindCapability === behind).map((el: CanvasElement) => el.id), (id: string) => {
        CanvasElementLayer({motion:this.layerMotion,element:this.elementFor(id),ink:materialColors(this.card.material,this.card.paper,this.card.ink)[1],scaleFactor:this.scaleFactor,widget:this.widget})
      }, (id: string) => id)
  }

}
