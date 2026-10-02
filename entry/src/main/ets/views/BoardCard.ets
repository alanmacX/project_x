import { dragBounds, DragBounds } from '../model/DragGeometry';
import { cardOutline } from '../model/RenderContours';
import { motionFrameRate } from '../model/MotionPolicy';
import { FridgeCard, ShapePoint, shapeRadius } from '../model/CardSchema';
import { resizeFactor, clampCardGeometry, minimumCardSize, cardHandlePoint } from '../model/CanvasLayout';
import { CardFace } from './CardFace';
import { cardContainsPoint } from '../model/CardHitTest';

/** A stable card node owns its gestures; committing geometry never recreates its canvas. */
@Component
export struct BoardCard {
  @Prop card: FridgeCard = new FridgeCard();
  @Prop @Watch('syncHandles') selected: boolean = false;
  @Prop heroHidden: boolean = false;
  @Prop localCoordinates: boolean = false;
  @Prop cacheSurface: boolean = false;
  private frameRate: ExpectedFrameRateRange = motionFrameRate();
  @Prop @Watch('syncHandles') editingSurface: boolean = false;
  @Prop hideContent: boolean = false;
  @Prop movingLayerId: string = '';
  @Prop moveX: number = 0;
  @Prop moveY: number = 0;
  @Prop displayAngle: number = 0;
  @Prop scatterX: number = 0;
  @Prop scatterY: number = 0;
  @Prop scatterAngle: number = 0;
  @Prop scaleFactor: number = 1;
  @Prop yScaleFactor: number = 1;
  @Prop boardLeft: number = 0;
  @Prop boardTop: number = 100;
  @Prop tick: number = 0;
  onSelect: (id: string) => void = () => {};
  onDelete: (id: string) => void = () => {};
  onEdit: (id: string) => void = () => {};
  getMoveBounds: (card: FridgeCard) => DragBounds = (card: FridgeCard) => dragBounds(card);
  onMove: (x: number, y: number) => void = () => {};
  onInteraction: (active: boolean) => void = () => {};
  onCommit: (card: FridgeCard) => void = () => {};
  @State @Watch('syncHandles') moving: boolean = false;
  @State @Watch('syncHandles') resizing: boolean = false;
  @State dx: number = 0;
  @State dy: number = 0;
  @State tilt: number = 0;
  @State liftScale: number = 1;
  @State controlsOpacity: number = 0;
  @State controlsScale: number = .8;
  @State resizeControlScale: number = .8;
  private handlesTimer: number = -1;
  private alive: boolean = false;
  aboutToAppear(): void { this.alive = true; this.syncHandles(); }
  aboutToDisappear(): void { this.alive = false; if (this.handlesTimer >= 0) clearTimeout(this.handlesTimer); }
  private syncHandles(): void {
    if (this.handlesTimer >= 0) clearTimeout(this.handlesTimer);
    // Let the current render settle before beginning the small controls transaction.
    this.handlesTimer = setTimeout(() => {
      this.handlesTimer = -1; if (!this.alive) return;
      const opacity = this.shown() ? 1 : 0, scale = this.shown() ? 1 : .8, resizeScale = this.resizing ? 1.12 : scale;
      if (this.controlsOpacity === opacity && this.controlsScale === scale && this.resizeControlScale === resizeScale) return;
      this.getUIContext().animateTo({ duration: 180, curve: Curve.EaseOut, expectedFrameRateRange: this.frameRate }, () => {
        this.controlsOpacity = opacity; this.controlsScale = scale; this.resizeControlScale = resizeScale;
      });
    }, 0);
  }
  @State liveW: number = 180;
  @State liveH: number = 180;
  @State liveY: number = 32;
  private moveBounds: DragBounds = new DragBounds();
  private touchHit: HitTestMode = HitTestMode.Default;
  private originX: number = 0;
  private originY: number = 0;
  private originW: number = 0;
  private originH: number = 0;
  private lastDX: number = 0;
  private fingerStartX: number = 0;
  private fingerStartY: number = 0;
  private fingerDX: number = 0;
  private fingerDY: number = 0;
  private hasScreenFinger: boolean = false;
  private beginFinger(e: GestureEvent): void {
    const point = e.fingerList[0]; this.hasScreenFinger = point !== undefined;
    const angle = this.card.rot * Math.PI / 180;
    // Pan recognition begins after its threshold. Recover the original touch,
    // whose offset is already expressed in the rotated component's coordinates.
    this.fingerStartX = (point?.displayX ?? 0) - (e.offsetX * Math.cos(angle) - e.offsetY * Math.sin(angle));
    this.fingerStartY = (point?.displayY ?? 0) - (e.offsetX * Math.sin(angle) + e.offsetY * Math.cos(angle));
    this.fingerDX = 0; this.fingerDY = 0;
  }
  private screenOffset(e: GestureEvent): ShapePoint {
    const point = e.fingerList[0];
    if (this.hasScreenFinger && point !== undefined) {
      this.fingerDX = point.displayX - this.fingerStartX; this.fingerDY = point.displayY - this.fingerStartY;
    }
    return { x: this.hasScreenFinger ? this.fingerDX : e.offsetX, y: this.hasScreenFinger ? this.fingerDY : e.offsetY };
  }
  private minimumFactor: number = 1;
  private maximumFactor: number = 1;
  private resizeVectorW: number = 1;
  private resizeVectorH: number = 1;
  @State atMinimum: boolean = false;
  private copyCard(): FridgeCard {
    const copy = new FridgeCard();
    copy.id = this.card.id;
    copy.x = this.card.x;
    copy.y = this.card.y;
    copy.w = this.card.w;
    copy.h = this.card.h;
    copy.rot = this.card.rot;
    copy.z = this.card.z;
    copy.shape = this.card.shape;
    copy.frame = this.card.frame;
    copy.material = this.card.material;
    copy.paper = this.card.paper;
    copy.ink = this.card.ink;
    copy.capability = this.card.capability;
    copy.capBox = this.card.capBox;
    copy.elements = this.card.elements;
    copy.subjectPhoto = this.card.subjectPhoto;
    copy.subjectBorder = this.card.subjectBorder;
    copy.subjectAspect = this.card.subjectAspect;
    copy.subjectInk = this.card.subjectInk;
    copy.subjectVersion = this.card.subjectVersion;
    copy.cutout = this.card.cutout;
    copy.outline = this.card.outline;
    copy.renderContourKey = this.card.renderContourKey;
    copy.inDoor = this.card.inDoor;
    return copy;
  }
  private handleKey: string = '';
  private handleOutline: Object | null = null;
  private handles: ShapePoint[] = [];
  private handle(right: boolean, bottom: boolean): ShapePoint {
    const key = this.card.shape + ':' + this.card.w + ':' + this.card.h + ':' + this.card.subjectBorder;
    const contour = cardOutline(this.card);
    if (this.handleKey !== key || this.handleOutline !== contour) {
      this.handles = [cardHandlePoint(this.card, false, false), cardHandlePoint(this.card, true, false), cardHandlePoint(this.card, true, true)];
      this.handleKey = key; this.handleOutline = contour;
    }
    return this.handles[bottom ? 2 : (right ? 1 : 0)];
  }
  private w(): number { return (this.resizing ? this.liveW : this.card.w) * this.scaleFactor; }
  private h(): number { return (this.resizing ? this.liveH : this.card.h) * this.scaleFactor; }
  private shown(): boolean { return this.selected && !this.moving && !this.editingSurface; }
  private animateLift(active: boolean): void {
    this.getUIContext().animateTo({ duration: 160, curve: Curve.Friction, expectedFrameRateRange: this.frameRate }, () => {
      this.liftScale = active ? 1.025 : 1; if (!active) this.tilt = 0;
    });
  }
  private startMove(): void {
    this.animateLift(true); this.originX = this.card.x; this.originY = this.card.y; this.dx = 0; this.dy = 0; this.lastDX = 0; this.moveBounds = this.getMoveBounds(this.card); this.moving = true; this.onInteraction(true);
  }
  private move(e: GestureEvent): void {
    const offset = this.screenOffset(e);
    const x = Math.max(this.moveBounds.minX, Math.min(this.moveBounds.maxX, this.originX + offset.x / this.scaleFactor));
    const y = Math.max(this.moveBounds.minY, Math.min(this.moveBounds.maxY, this.originY + offset.y / this.yScaleFactor));
    this.dx = (x - this.originX) * this.scaleFactor; this.dy = (y - this.originY) * this.yScaleFactor;
    this.onMove(this.dx, this.dy);
    this.tilt = this.tilt * .65 + Math.max(-3, Math.min(3, (offset.x - this.lastDX) * .12)) * .35; this.lastDX = offset.x;
  }
  private cancelMove(): void { this.animateLift(false); this.dx = 0; this.dy = 0; this.moving = false; this.tilt = 0; this.onInteraction(false); }
  private finishMove(): void {
    if (!this.moving) return;
    this.animateLift(false); const next = this.copyCard();
    next.x = this.originX + this.dx / this.scaleFactor; next.y = this.originY + this.dy / this.yScaleFactor;
    // Synchronous handoff: update the prop and clear the offset in the same frame.
    clampCardGeometry(next); this.onCommit(next); this.dx = 0; this.dy = 0; this.moving = false; this.tilt = 0; this.onInteraction(false);
  }
  private startResize(): void {
    this.originW = this.card.w; this.originH = this.card.h; this.originY = this.card.y;
    const min = minimumCardSize(this.card), handle = this.handle(true, false);
    this.minimumFactor = Math.max(min.w / this.originW, min.h / this.originH);
    this.maximumFactor = Math.max(this.minimumFactor, Math.min(320 / this.originW, 420 / this.originH));
    this.resizeVectorW = this.originW * handle.x; this.resizeVectorH = this.originH * (1 - handle.y);
    this.liveW = this.card.w; this.liveH = this.card.h; this.liveY = this.card.y; this.resizing = true; this.atMinimum = false; this.onInteraction(true);
  }
  private resize(e: GestureEvent): void {
    const offset = this.screenOffset(e);
    const requested = resizeFactor(this.resizeVectorW, this.resizeVectorH, offset.x / this.scaleFactor, offset.y / this.scaleFactor, this.card.rot);
    this.atMinimum = requested < this.minimumFactor;
    const factor = Math.max(this.minimumFactor, Math.min(this.maximumFactor, requested));
    this.liveW = this.originW * factor; this.liveH = this.originH * factor; this.liveY = this.originY + (this.originH - this.liveH) * this.scaleFactor / this.yScaleFactor;
  }
  private cancelResize(): void { this.resizing = false; this.atMinimum = false; this.onInteraction(false); }
  private finishResize(): void {
    if (!this.resizing) return;
    const next = this.copyCard();
    next.w = this.liveW; next.h = this.liveH; next.y = this.liveY;
    clampCardGeometry(next); this.onCommit(next); this.resizing = false; this.onInteraction(false);
    if (this.atMinimum) this.getUIContext().getPromptAction().showToast({ message: this.card.capability === null ? '已到最小尺寸' : '已到最小可读尺寸；移除能力后可继续缩小' });
    this.atMinimum = false;
  }
  private faceCard(): FridgeCard {
    if (!this.resizing) return this.card;
    const card = this.copyCard(); card.w = this.liveW; card.h = this.liveH; return card;
  }
  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Stack() {
        // Shadow fringe stays in the texture; rotation and translation stay outside it.
        Stack({ alignContent: Alignment.TopStart }) {
          CardFace({ card: this.faceCard(), scaleFactor: this.scaleFactor, tick: this.tick, lifted: this.moving, hideContent: this.hideContent, movingLayerId: this.movingLayerId, moveX: this.moveX, moveY: this.moveY })
            .width(this.w()).height(this.h()).position({ x: 24, y: 24 }).hitTestBehavior(HitTestMode.BLOCK_DESCENDANTS)
        }.width(this.w() + 48).height(this.h() + 48).position({ x: -24, y: -24 })
          .renderGroup(this.cacheSurface || this.moving || (!this.editingSurface && this.card.elements.every(el => !el.animated))).hitTestBehavior(HitTestMode.None)
      }.scale({ x: this.liftScale, y: this.liftScale })
        .rotate({ angle: this.tilt })
        .width(this.w()).height(this.h()).position({ x: 24, y: 24 })
        .onTouchIntercept((e: TouchEvent): HitTestMode => {
          // Ownership is decided on DOWN; do not scan every contour on every MOVE.
          if (e.type === TouchType.Down) {
            const point = e.touches[0] ?? e.changedTouches[0];
            this.touchHit = point !== undefined && cardContainsPoint(this.faceCard(), point.x, point.y, this.scaleFactor) ? HitTestMode.Default : HitTestMode.BLOCK_DESCENDANTS;
          }
          return this.touchHit;
        })
        .gesture(GestureGroup(GestureMode.Parallel,
          PanGesture({ distance: 4 }).onActionStart((e: GestureEvent) => { this.beginFinger(e); this.startMove(); this.move(e); }).onActionUpdate((e: GestureEvent) => this.move(e))
            .onActionEnd((e: GestureEvent) => { this.move(e); this.finishMove(); }).onActionCancel(() => this.cancelMove()),
          TapGesture().onAction(() => { if (!this.moving) this.onSelect(this.card.id); })))
      Button('×', { type: ButtonType.Circle }).width(44).height(44).fontSize(24).fontColor('#D3423C').backgroundColor(Color.White)
        .shadow({ radius: 8, color: '#20000000', offsetY: 2 })
        .opacity(this.controlsOpacity).scale({ x: this.controlsScale, y: this.controlsScale })
        .position({ x: 2 + this.handle(false, false).x * this.w(), y: 2 + this.handle(false, false).y * this.h() }).hitTestBehavior(this.shown() ? HitTestMode.Default : HitTestMode.BLOCK_DESCENDANTS)
        .accessibilityLevel(this.shown() ? 'yes' : 'no-hide-descendants').accessibilityText('删除卡片').onClick(() => this.onDelete(this.card.id))
      Button('↗', { type: ButtonType.Circle }).width(44).height(44).fontSize(22).fontColor('#303030').backgroundColor(Color.White)
        .shadow({ radius: 8, color: '#20000000', offsetY: 2 })
        .opacity(this.controlsOpacity).scale({ x: this.resizeControlScale, y: this.resizeControlScale })
        .position({ x: 2 + this.handle(true, false).x * this.w(), y: 2 + this.handle(true, false).y * this.h() }).hitTestBehavior(this.shown() ? HitTestMode.Default : HitTestMode.BLOCK_DESCENDANTS)
        .accessibilityLevel(this.shown() ? 'yes' : 'no-hide-descendants').accessibilityText('调整卡片大小').onClick(() => this.getUIContext().getPromptAction().showToast({ message: '向外拖动放大，向内拖动缩小' }))
        .gesture(PanGesture({ distance: 2 }).onActionStart((e: GestureEvent) => { this.beginFinger(e); this.startResize(); this.resize(e); }).onActionUpdate((e: GestureEvent) => this.resize(e))
          .onActionEnd((e: GestureEvent) => { this.resize(e); this.finishResize(); }).onActionCancel(() => this.cancelResize()))
      if (this.resizing && this.atMinimum) {
        Text('最小可读尺寸').fontSize(12).fontColor('#FFFFFF').padding(8).backgroundColor('#303030').borderRadius(8)
          .position({ x: 24, y: this.h() + 26 }).hitTestBehavior(HitTestMode.None)
      }
      Button('编辑', { type: ButtonType.Circle }).width(44).height(44).fontSize(11).fontColor('#303030').backgroundColor(Color.White)
        .shadow({ radius: 8, color: '#20000000', offsetY: 2 })
        .opacity(this.controlsOpacity).scale({ x: this.controlsScale, y: this.controlsScale })
        .position({ x: 2 + this.handle(true, true).x * this.w(), y: 2 + this.handle(true, true).y * this.h() }).hitTestBehavior(this.shown() ? HitTestMode.Default : HitTestMode.BLOCK_DESCENDANTS)
        .accessibilityLevel(this.shown() ? 'yes' : 'no-hide-descendants').accessibilityText('编辑卡片内容').onClick(() => this.onEdit(this.card.id))
    }.width(this.w() + 48).height(this.h() + 48).opacity(this.heroHidden ? 0 : 1).hitTestBehavior(this.heroHidden ? HitTestMode.BLOCK_DESCENDANTS : HitTestMode.Transparent)
      .translate({ x: this.scatterX + this.dx, y: this.scatterY + this.dy })
      .rotate({ angle: this.editingSurface ? this.displayAngle : this.card.rot + this.scatterAngle, centerX: 24, centerY: this.h() + 24 })
      .position({ x: (this.localCoordinates ? 0 : this.boardLeft + this.card.x * this.scaleFactor - 24),
        y: (this.localCoordinates ? (this.resizing ? this.liveY - this.card.y : 0) * this.yScaleFactor : this.boardTop + (this.resizing ? this.liveY : this.card.y) * this.yScaleFactor - 24) })
      .zIndex(this.moving ? 100002 : (this.resizing ? 100001 : this.card.z))
  }
}
