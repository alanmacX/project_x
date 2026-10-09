import { EditorLayerMotion } from '../model/EditorLayerMotion';
import { contourPath } from '../model/ContourPath';
import { cardOutline } from '../model/RenderContours';
import { FridgeCard, materialColors, cardCornerRadius } from '../model/CardSchema';
import { CardCanvas } from './CardCanvas';
import { subjectSurfaceFactor } from '../model/CanvasLayout';
import { cardDepthScale, cardEdgeColor, CARD_SIDE, CARD_CAST_RADIUS, CARD_CAST_Y, CARD_CAST_COLOR, CARD_CONTACT_RADIUS, CARD_CONTACT_Y, CARD_CONTACT_COLOR } from '../model/CardDepth';
/** The same surface, optional frame and depth are used in app, editor, hero and widget. */
@Component
export struct CardFace {
  @Prop card: FridgeCard = new FridgeCard();
  @Prop scaleFactor: number = 1;
  @Prop tick: number = 0;
  @Prop lifted: boolean = false;
  @Prop widget: boolean = false;
  @Prop hideContent: boolean = false;
  @Prop animateContent: boolean = false;
  @State layerMotion: EditorLayerMotion = new EditorLayerMotion();
  @Prop movingLayerId: string = '';
  @Prop moveX: number = 0;
  @Prop moveY: number = 0;
  private pathKey: string = '';
  private outlineRef: Object | null = null;
  private pathCommands: string = '';
  private commands(): string {
    if (this.card.shape !== 'subject' || cardOutline(this.card).length === 0) return '';
    const key = this.card.w + ':' + this.card.h + ':' + this.scaleFactor + ':' + this.card.subjectBorder + ':' + this.card.cutout + ':' + this.card.subjectVersion;
    if (key === this.pathKey && (this.card.cutout.length > 0 || this.outlineRef === cardOutline(this.card))) return this.pathCommands;
    const factor = subjectSurfaceFactor(this.card);
    const width = vp2px(this.card.w * this.scaleFactor), height = vp2px(this.card.h * this.scaleFactor);
    this.pathKey = key; this.outlineRef = cardOutline(this.card); this.pathCommands = contourPath(cardOutline(this.card), width, height, factor);
    return this.pathCommands;
  }
  private depthScale(): number { return cardDepthScale(this.scaleFactor); }
  private paper(): string { return materialColors(this.card.material,this.card.paper,this.card.ink)[0]; }
  private edge(): string { return cardEdgeColor(this.paper(),this.card.shape==='subject'&&this.card.subjectPhoto); }
  @Builder
  backing(color: string, offset: number, radius: number, shadowColor: string, shadowY: number) {
    Column().width('100%').height('100%').backgroundColor(color).borderRadius(cardCornerRadius(this.card,this.scaleFactor))
      .translate({y:offset}).shadow({radius:vp2px(radius),color:shadowColor,offsetY:vp2px(shadowY)}).hitTestBehavior(HitTestMode.None)
  }

  build() {
    Stack() {
      // Soft cast shadow + tight contact shadow + a solid, slightly warm sidewall.
      // The cached face owns these layers; pan/rotation only transform its texture.
      if(this.card.shape==='subject'&&(this.card.reliefSrc.length>0||this.commands().length>0)){
        if(this.card.reliefSrc){
          Image(this.card.reliefSrc).width((this.card.w+48)*this.scaleFactor).height((this.card.h+48)*this.scaleFactor)
            .position({x:-24*this.scaleFactor,y:-24*this.scaleFactor}).objectFit(ImageFit.Fill).draggable(false).hitTestBehavior(HitTestMode.None)
        }else{
          // Visible fallback while an off-thread cache is prepared: no shadow nodes.
          Path().commands(this.commands()).fill(this.card.subjectPhoto?'#FFFFFF':this.paper()).stroke(this.card.subjectPhoto?'#FFFFFF':this.paper())
            .strokeWidth(this.card.subjectBorder?6*this.scaleFactor:0).strokeLineJoin(LineJoinStyle.Round).antiAlias(true).width('100%').height('100%').hitTestBehavior(HitTestMode.None)
        }
      }else{
      Stack() {
        this.backing(this.edge(),CARD_SIDE*this.depthScale(),(this.lifted?13:CARD_CAST_RADIUS)*this.depthScale(),CARD_CAST_COLOR,(this.lifted?8:CARD_CAST_Y)*this.depthScale())
        this.backing(this.edge(),CARD_SIDE*this.depthScale(),CARD_CONTACT_RADIUS*this.depthScale(),CARD_CONTACT_COLOR,CARD_CONTACT_Y*this.depthScale())
        this.backing(this.edge(),CARD_SIDE*this.depthScale(),0,'#00000000',0)
        this.backing(this.card.shape==='subject'&&this.card.subjectPhoto?'#FFFFFF':this.paper(),0,0,'#00000000',0)
      }.width('100%').height('100%')
      }
      CardCanvas({ layerMotion:this.layerMotion, card: this.card, scaleFactor: this.scaleFactor, tick: this.tick, widget: this.widget, hideContent: this.hideContent, animateContent:this.animateContent,
        movingLayerId: this.movingLayerId, moveX: this.moveX, moveY: this.moveY })
        .width((subjectSurfaceFactor(this.card) * 100) + '%').height((subjectSurfaceFactor(this.card) * 100) + '%')
        .borderRadius(cardCornerRadius(this.card,this.scaleFactor)).border({ width: this.card.frame && this.card.shape !== 'subject' ? 3 * this.scaleFactor : 0, color: '#FFFFFF' })
      if(this.card.shape!=='subject') {
        Column().width('100%').height('100%').borderRadius(cardCornerRadius(this.card,this.scaleFactor))
          .border({width:.6,color:{top:'#88FFFFFF',left:'#48FFFFFF',right:'#14000000',bottom:'#20000000'}})
          .hitTestBehavior(HitTestMode.None)
      }
    // BoardCard caches the face together with its shadow fringe. A cache at
    // the face's own bounds truncates the native shadow at rounded corners.
    }.width('100%').height('100%')
  }
}
