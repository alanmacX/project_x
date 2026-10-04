import { WidgetActionRect, widgetActionRects } from '../../model/WidgetActions';
import { CanvasBackdrop } from '../../views/CanvasBackdrop';
import { cardRenderSnapshot } from '../../model/CardViewSnapshot';
import { FridgeCard, CanvasBackground, normalizeBackground, BOARD_W, materialColors } from '../../model/CardSchema';
import { scenePercent } from '../../model/SceneLayout';
import { widgetHit, widgetCanvasPoint } from '../../model/WidgetHitTest';
import { CardFace } from '../../views/CardFace';

@Entry
@Component
struct FridgeWidgetCard {
  @LocalStorageProp('background') @Watch('syncBackground') backgroundJson: string = '{}';
  @State canvasBackground: CanvasBackground = new CanvasBackground();
  private syncBackground(): void { try { this.canvasBackground = normalizeBackground(JSON.parse(this.backgroundJson) as CanvasBackground); } catch (_) { this.canvasBackground = new CanvasBackground(); } }
  @LocalStorageProp('cards') @Watch('syncCards') cardsJson: string = '';
  @State cardIds: string[] = [];
  @State cardMap: Record<string, FridgeCard> = {};
  @LocalStorageProp('faceCards') @Watch('syncLegacyCards') faceCardsJson: string = '[]';
  @LocalStorageProp('doorCards') @Watch('syncLegacyCards') doorCardsJson: string = '[]';
  @LocalStorageProp('rev') rev: number = 0;
  @LocalStorageProp('canvasId') canvasId: string = 'canvas_main';
  @LocalStorageProp('dim') dim: string = '4*4';
  @LocalStorageProp('canvasWidth') canvasWidth: number = 344;
  @LocalStorageProp('canvasHeight') canvasHeight: number = 344;
  @State measuredWidth: number = 0;
  @State measuredHeight: number = 0;
  private widthValue(): number { return this.measuredWidth > 0 ? this.measuredWidth : this.canvasWidth; }
  private heightValue(): number { return this.measuredHeight > 0 ? this.measuredHeight : this.canvasHeight; }
  private dispatch(x: number, y: number): void {
    const hit = widgetHit(this.cardIds.map((id: string) => this.cardMap[id]), x, y, this.widthValue(), this.heightValue(),this.rev||Date.now());
    if (hit.id.length === 0 || hit.operation === 'disabled') return;
    if (hit.operation.length > 0) this.action(hit.id, hit.operation); else this.open(hit.id);
  }
  private parse(json: string): FridgeCard[] {
    try { return JSON.parse(json) as FridgeCard[]; } catch (_) { return []; }
  }
  aboutToAppear(): void { this.syncBackground(); this.syncCards(); }
  private syncLegacyCards(): void { if (this.cardsJson.length === 0) this.syncCards(); }
  private syncCards(): void {
    const cards = (this.cardsJson.length > 0 ? this.parse(this.cardsJson) : this.parse(this.faceCardsJson).concat(this.parse(this.doorCardsJson)))
      .sort((a: FridgeCard, b: FridgeCard) => a.z - b.z);
    const map: Record<string, FridgeCard> = {};
    cards.forEach((card: FridgeCard) => { map[card.id] = cardRenderSnapshot(card); });
    this.cardMap = map; this.cardIds = cards.map((card: FridgeCard) => card.id);
  }
  private open(id: string = ''): void {
    postCardAction(this, { action: 'router', abilityName: 'EntryAbility',
      params: { canvasId: this.canvasId, viewCardId: id, canvasDimension: this.dim, canvasAspect: String(this.widthValue() / this.heightValue()) } });
  }
  private action(id: string, operation: string): void {
    postCardAction(this, { action: 'message', params: { cardId: id, operation: operation } });
  }
  @Builder
  actionButton(card:FridgeCard,action:WidgetActionRect) {
    Button(action.symbol,{type:ButtonType.Circle}).width(44).height(44).padding(0).fontSize(20).fontColor(card.shape==='subject'&&card.subjectPhoto&&card.ink.length===0?card.subjectInk:materialColors(card.material,card.paper,card.ink)[1]).backgroundColor(Color.Transparent)
      .position({x:action.x*this.widthValue()/BOARD_W,y:action.y*this.widthValue()/BOARD_W})
      .accessibilityText(action.operation==='previousMonth'?'上个月':'下个月')
      .onClick((event:ClickEvent)=>{
        const scale=this.widthValue()/BOARD_W,point=widgetCanvasPoint(card,action.x*scale+event.x,action.y*scale+event.y,this.widthValue(),this.heightValue());this.dispatch(point.x,point.y);
      })
  }
  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      CanvasBackdrop({ sceneBackground: this.canvasBackground }).width('100%').height('100%')
      ForEach(this.cardIds, (id: string) => {
        Stack({ alignContent: Alignment.TopStart }) {
        CardFace({ card: this.cardMap[id], scaleFactor: this.widthValue() / BOARD_W, tick: this.rev, widget: true })
          .width('100%').height('100%').hitTestBehavior(HitTestMode.None)
        ForEach(widgetActionRects(this.cardMap[id],this.widthValue()/BOARD_W,this.rev||Date.now()),(action:WidgetActionRect)=>{
          this.actionButton(this.cardMap[id],action)
        },(action:WidgetActionRect)=>action.operation)
        }
          .width(scenePercent(this.cardMap[id], this.widthValue() / this.heightValue()).w + '%').height(scenePercent(this.cardMap[id], this.widthValue() / this.heightValue()).h + '%')
          .position({ x: scenePercent(this.cardMap[id], this.widthValue() / this.heightValue()).x + '%', y: scenePercent(this.cardMap[id], this.widthValue() / this.heightValue()).y + '%' })
          .rotate({ angle: this.cardMap[id].rot, centerX: 0, centerY: '100%' }).animation({ duration: 180, curve: Curve.EaseOut }).zIndex(this.cardMap[id].z)
          .hitTestBehavior(HitTestMode.Transparent)
      }, (id: string) => id)
      Button('打开', { type: ButtonType.Capsule }).width(56).height(44).padding(0).fontSize(12).borderRadius(10)
        .backgroundColor('#EEFFFFFF').fontColor('#303030').position({ x: '100%', y: '100%' }).translate({ x: -64, y: -52 }).zIndex(100000)
        .accessibilityText('打开卡片画布').onClick(() => this.open())
    }.width('100%').height('100%').backgroundColor(Color.White).borderRadius(24).clip(true)
      .onSizeChange((_: SizeOptions, size: SizeOptions) => {
        const width = Number(size.width), height = Number(size.height);
        if (width > 0 && height > 0 && (Math.abs(width - this.measuredWidth) > .1 || Math.abs(height - this.measuredHeight) > .1)) {
          this.measuredWidth = width; this.measuredHeight = height;
        }
      })
      .onClick((event: ClickEvent) => this.dispatch(event.x, event.y))
  }
}
