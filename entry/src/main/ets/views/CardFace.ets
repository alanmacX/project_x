import { subjectDepthImage } from '../model/SubjectDepthCache';
import { EditorLayerMotion } from '../model/EditorLayerMotion';
import { contourPath } from '../model/ContourPath';
import { cardOutline } from '../model/RenderContours';
import { FridgeCard, materialColors, shapeRadius } from '../model/CardSchema';
import { CardCanvas } from './CardCanvas';
import { subjectSurfaceFactor } from '../model/CanvasLayout';
import { cardDepthScale, cardEdgeColor } from '../model/CardDepth';
/** The same surface, optional frame and depth are used in app, editor, hero and widget. */
@Component
export struct CardFace {
  @Prop card: FridgeCard = new FridgeCard();
  @Prop scaleFactor: number = 1;
  @Prop tick: number = 0;
  @Prop lifted: boolean = false;
  @Prop widget: boolean = false;
  @Prop hideContent: boolean = false;
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
    if(this.card.shape==='subject' && this.commands().length>0) {
      // Explicit alpha contour bands avoid host-dependent blur compositing in
      // FormKit. Both hosts draw the same cached paths, without a blur filter.
      if (radius > 0) {
        Path().commands(this.commands()).fill(shadowColor).stroke(shadowColor)
          .strokeWidth((this.card.subjectBorder?6*this.scaleFactor:0)+radius*2)
          .strokeLineJoin(LineJoinStyle.Round).antiAlias(true).opacity(.15)
          .width('100%').height('100%').translate({y:offset+shadowY}).hitTestBehavior(HitTestMode.None)
        Path().commands(this.commands()).fill(shadowColor).stroke(shadowColor)
          .strokeWidth((this.card.subjectBorder?6*this.scaleFactor:0)+radius)
          .strokeLineJoin(LineJoinStyle.Round).antiAlias(true).opacity(.25)
          .width('100%').height('100%').translate({y:offset+shadowY}).hitTestBehavior(HitTestMode.None)
        Path().commands(this.commands()).fill(shadowColor).stroke(shadowColor)
          .strokeWidth(this.card.subjectBorder?6*this.scaleFactor:0)
          .strokeLineJoin(LineJoinStyle.Round).antiAlias(true).opacity(.6)
          .width('100%').height('100%').translate({y:offset+shadowY}).hitTestBehavior(HitTestMode.None)
      } else {
        Path().commands(this.commands()).fill(color).stroke(color)
          .strokeWidth(this.card.subjectBorder?6*this.scaleFactor:0).strokeLineJoin(LineJoinStyle.Round).antiAlias(true)
          .width('100%').height('100%').translate({y:offset}).hitTestBehavior(HitTestMode.None)
      }
    } else {
      Column().width('100%').height('100%').backgroundColor(color).borderRadius(shapeRadius(this.card.shape,this.scaleFactor))
        .translate({y:offset}).shadow({radius:vp2px(radius),color:shadowColor,offsetY:vp2px(shadowY)}).hitTestBehavior(HitTestMode.None)
    }
  }
  build() {
    Stack() {
      // Soft cast shadow + tight contact shadow + a solid, slightly warm sidewall.
      // The cached face owns these layers; pan/rotation only transform its texture.
      if(!this.widget && !this.lifted && subjectDepthImage(this.card,this.scaleFactor).length>0) {
        Image(subjectDepthImage(this.card,this.scaleFactor)).width(this.card.w*this.scaleFactor+48).height(this.card.h*this.scaleFactor+48)
          .position({x:-24,y:-24}).objectFit(ImageFit.Fill).draggable(false).hitTestBehavior(HitTestMode.None)
      } else {
      Stack() {
      this.backing(this.edge(),2*this.depthScale(),(this.lifted?9:5.5)*this.depthScale(),this.lifted?'#38000000':'#30000000',(this.lifted?7:4)*this.depthScale())
      this.backing(this.edge(),2*this.depthScale(),1.4*this.depthScale(),'#48000000',1.2*this.depthScale())
      this.backing(this.edge(),2*this.depthScale(),0,'#00000000',0)
      this.backing(this.card.shape==='subject'&&this.card.subjectPhoto?'#FFFFFF':this.paper(),0,0,'#00000000',0)
      }.width('100%').height('100%')
      }
      CardCanvas({ layerMotion:this.layerMotion, card: this.card, scaleFactor: this.scaleFactor, tick: this.tick, widget: this.widget, hideContent: this.hideContent,
        movingLayerId: this.movingLayerId, moveX: this.moveX, moveY: this.moveY })
        .width((subjectSurfaceFactor(this.card) * 100) + '%').height((subjectSurfaceFactor(this.card) * 100) + '%')
        .borderRadius(shapeRadius(this.card.shape,this.scaleFactor)).border({ width: this.card.frame && this.card.shape !== 'subject' ? 3 * this.scaleFactor : 0, color: '#FFFFFF' })
      if(this.card.shape!=='subject') {
        Column().width('100%').height('100%').borderRadius(shapeRadius(this.card.shape,this.scaleFactor))
          .border({width:.6,color:{top:'#88FFFFFF',left:'#48FFFFFF',right:'#14000000',bottom:'#20000000'}})
          .hitTestBehavior(HitTestMode.None)
      }
    // BoardCard caches the face together with its shadow fringe. A cache at
    // the face's own bounds truncates the native shadow at rounded corners.
    }.width('100%').height('100%')
  }
}
