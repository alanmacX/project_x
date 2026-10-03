import { CanvasBackdrop } from '../../views/CanvasBackdrop';
import { cardRenderSnapshot } from '../../model/CardViewSnapshot';
import { FridgeCard, CanvasBackground, normalizeBackground, BOARD_W } from '../../model/CardSchema';
import { scenePercent } from '../../model/SceneLayout';
import { capabilityPlacement } from '../../model/CanvasLayout';
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
    const hit = widgetHit(this.cardIds.map((id: string) => this.cardMap[id]), x, y, this.widthValue(), this.heightValue());
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
  actionButton(card: FridgeCard, symbol: string, operation: string, right: boolean) {
    Button(symbol, { type: ButtonType.Normal }).width(24 * this.widthValue() / BOARD_W).height(24 * this.widthValue() / BOARD_W)
      .padding(0).fontSize(14 * this.widthValue() / BOARD_W).fontColor(card.material === 'dark' ? '#F4F3EF' : '#303030').backgroundColor(Color.Transparent)
      .position({ x: ((capabilityPlacement(card).x + (right ? capabilityPlacement(card).w : 0)) * 100) + '%', y: (capabilityPlacement(card).y * 100) + '%' })
      .translate({ x: right ? -24 * this.widthValue() / BOARD_W : 0 })
      .enabled(operation !== 'refreshWeather' || card.capability?.refreshState !== 'refreshing')
      .accessibilityText(operation === 'previousMonth' ? '上个月' : (operation === 'nextMonth' ? '下个月' : '刷新天气'))
      .onClick((event: ClickEvent) => {
        const box = capabilityPlacement(card), scale = this.widthValue() / BOARD_W;
        const point = widgetCanvasPoint(card, box.x * card.w * scale + (right ? box.w * card.w * scale - 24 * scale : 0) + event.x,
          box.y * card.h * scale + event.y, this.widthValue(), this.heightValue());
        this.dispatch(point.x, point.y);
      })
  }
  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      CanvasBackdrop({ sceneBackground: this.canvasBackground }).width('100%').height('100%')
      ForEach(this.cardIds, (id: string) => {
        Stack({ alignContent: Alignment.TopStart }) {
        CardFace({ card: this.cardMap[id], scaleFactor: this.widthValue() / BOARD_W, tick: this.rev, widget: true })
          .width('100%').height('100%').hitTestBehavior(HitTestMode.None)
        if (this.cardMap[id].capability?.k === 'calendar') {
          this.actionButton(this.cardMap[id], '‹', 'previousMonth', false)
          this.actionButton(this.cardMap[id], '›', 'nextMonth', true)
        }
        if (this.cardMap[id].capability?.k === 'weather' && (this.cardMap[id].capability?.city ?? '').length > 0) { this.actionButton(this.cardMap[id], '↻', 'refreshWeather', true) }
        }
          .width(scenePercent(this.cardMap[id], this.widthValue() / this.heightValue()).w + '%').height(scenePercent(this.cardMap[id], this.widthValue() / this.heightValue()).h + '%')
          .position({ x: scenePercent(this.cardMap[id], this.widthValue() / this.heightValue()).x + '%', y: scenePercent(this.cardMap[id], this.widthValue() / this.heightValue()).y + '%' })
          .rotate({ angle: this.cardMap[id].rot, centerX: 0, centerY: '100%' }).animation({ duration: 180, curve: Curve.EaseOut }).zIndex(this.cardMap[id].z)
          .hitTestBehavior(HitTestMode.Transparent)
      }, (id: string) => id)
      Button('打开', { type: ButtonType.Normal }).width(48).height(32).padding(0).fontSize(12).borderRadius(10)
        .backgroundColor('#EEFFFFFF').fontColor('#303030').position({ x: '100%', y: '100%' }).translate({ x: -56, y: -40 }).zIndex(100000)
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
