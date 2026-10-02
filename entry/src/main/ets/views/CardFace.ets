import { contourPath } from '../model/ContourPath';
import { cardOutline } from '../model/RenderContours';
import { FridgeCard, materialColors, shapeRadius } from '../model/CardSchema';
import { CardCanvas } from './CardCanvas';
import { subjectSurfaceFactor } from '../model/CanvasLayout';
import { PathShape } from '@kit.ArkUI';
/** The same surface, optional frame and depth are used in app, editor, hero and widget. */
@Component
export struct CardFace {
  @Prop card: FridgeCard = new FridgeCard();
  @Prop scaleFactor: number = 1;
  @Prop tick: number = 0;
  @Prop lifted: boolean = false;
  @Prop widget: boolean = false;
  @Prop hideContent: boolean = false;
  @Prop movingLayerId: string = '';
  @Prop moveX: number = 0;
  @Prop moveY: number = 0;
  private pathKey: string = '';
  private outlineRef: Object | null = null;
  private pathCommands: string = '';
  private cachedPath: PathShape | undefined = undefined;
  private commands(): string {
    if (this.card.shape !== 'subject' || cardOutline(this.card).length === 0) return '';
    const key = this.card.w + ':' + this.card.h + ':' + this.scaleFactor + ':' + this.card.subjectBorder + ':' + this.card.cutout + ':' + this.card.subjectVersion;
    if (key === this.pathKey && (this.card.cutout.length > 0 || this.outlineRef === cardOutline(this.card))) return this.pathCommands;
    const factor = subjectSurfaceFactor(this.card), inset = (1 - factor) / 2;
    const width = vp2px(this.card.w * this.scaleFactor), height = vp2px(this.card.h * this.scaleFactor);
    this.pathKey = key; this.outlineRef = cardOutline(this.card); this.pathCommands = contourPath(cardOutline(this.card), width, height, factor);
    this.cachedPath = new PathShape({ commands: this.pathCommands }); return this.pathCommands;
  }
  private path(): PathShape | undefined { this.commands(); return this.card.shape === 'subject' ? this.cachedPath : undefined; }
  build() {
    Stack() {
      Column().width('100%').height('100%').backgroundColor(materialColors(this.card.material, this.card.paper, this.card.ink)[0])
        .borderRadius(shapeRadius(this.card.shape)).clipShape(this.path()).translate({ y: 1.5 * this.scaleFactor })
        .shadow({ radius: this.lifted ? 22 : 12, color: '#26000000', offsetY: this.lifted ? 12 : 5 })
      if (this.card.shape === 'subject' && this.card.subjectBorder) {
        Path().commands(this.commands()).fillOpacity(0).stroke('#FFFFFF').strokeWidth(6 * this.scaleFactor).strokeLineJoin(LineJoinStyle.Round).antiAlias(true)
          .width('100%').height('100%').hitTestBehavior(HitTestMode.None)
      }
      CardCanvas({ card: this.card, scaleFactor: this.scaleFactor, tick: this.tick, widget: this.widget, hideContent: this.hideContent,
        movingLayerId: this.movingLayerId, moveX: this.moveX, moveY: this.moveY })
        .width((subjectSurfaceFactor(this.card) * 100) + '%').height((subjectSurfaceFactor(this.card) * 100) + '%')
        .borderRadius(shapeRadius(this.card.shape)).border({ width: this.card.frame && this.card.shape !== 'subject' ? 3 * this.scaleFactor : 0, color: '#FFFFFF' })
    }.width('100%').height('100%')
  }
}
