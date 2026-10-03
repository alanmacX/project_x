import { BoardMotion } from '../model/BoardMotion';
import { combineCards, ungroupCards, groupMembers, groupDragBounds, cleanGroups } from '../model/CardGroups';
import { PhotoCrop } from '../views/PhotoCrop';
import { CanvasBackdrop } from '../views/CanvasBackdrop';
import { CanvasBackground, FridgeState, normalizeBackground } from '../model/CardSchema';
import { backgroundSignature, createSmartBackground, importBackgroundPhoto, cropBackgroundPhoto } from '../model/BackgroundWorker';
import { sharePixelMap } from '../model/ImageShare';
import { taskpool } from '@kit.ArkTS';
import { common } from '@kit.AbilityKit';
import { AppDesign } from '../model/AppDesign';
import { arrivalOffset } from '../model/ArrivalGeometry';
import { motionFrameRate } from '../model/MotionPolicy';
import { HdsNavigation, HdsNavigationTitleMode, TextStyleMode, ScrollEffectType, BlurStrategy, hdsMaterial } from '@kit.UIDesignKit';
import { SegmentButton, SegmentButtonOptions } from '@kit.ArkUI';
import { EditorViewport, editorViewport } from '../model/EditorViewport';
import { SelectionHandles, selectionHandles } from '../model/SelectionHandles';
import { CardEditHistory } from '../model/CardEditHistory';
import { ColorSelector } from '../views/ColorSelector';
import { FridgeStore, FridgeCard, CanvasElement, ElementBox, ShapePoint, CapBlock, BOARD_W, BOARD_H, CAPABILITIES, materialColors, shapeRadius, typeLabel } from '../model/FridgeModel';
import { CardCanvas } from '../views/CardCanvas';
import { cardViewSnapshot, cardRenderSnapshot } from '../model/CardViewSnapshot';
import { CardFace } from '../views/CardFace';
import { sceneRect, SceneRect, layerLabel } from '../model/SceneLayout';
import { extractSubject, repairSubject } from '../model/SubjectShape';
import { fetchWeather } from '../model/WeatherService';
import { weatherNeedsRefresh } from '../model/WeatherRefresh';
import { BoardCard } from '../views/BoardCard';
import { capabilityBox, capabilityPlacement, safeContentBox, clampCardGeometry, ensureCapabilitySize, minimumCardSize, subjectSurfaceFactor, cardHandlePoint } from '../model/CanvasLayout';
import { fileIo } from '@kit.CoreFileKit';
import { cropCardToSubject } from '../model/SubjectGeometry';
import { applyCalendarAction } from '../model/CapabilityActions';
import { CapabilityView } from '../views/CapBlockView';
import { capabilityMinimum, compactCapability } from '../model/CapabilityMetrics';
import { photoAccessHelper } from '@kit.MediaLibraryKit';

const THEMES: string[] = ['white', 'cream', 'kraft', 'mint', 'blue', 'pink', 'dark'];
const SHAPES: string[] = ['rect', 'round', 'pill', 'blob'];

@Entry
@Component
struct Index {
  private photoCropDialog: CustomDialogController | null = null;
  @State groupSelecting: boolean = false;
  @State groupSelection: string[] = [];
  @State boardMotion: BoardMotion = new BoardMotion();
  private movingGroupIds: string[] = [];
  private store: FridgeStore = new FridgeStore();
  private context: Context | null = null;
  private frameRate: ExpectedFrameRateRange = motionFrameRate();
  private maintenanceTimer: number = -1;
  @State arriving: boolean = false;
  @State arrival: number = 0;
  private saveTimer: number = -1;
  private previewTimer: number = -1;
  private alive: boolean = true;
  private clockTimer: number = -1;
  private layerStartX: number = 0;
  private layerStartY: number = 0;
  private scroller: Scroller = new Scroller();
  private detailScroller: Scroller = new Scroller();
  private history: CardEditHistory = new CardEditHistory();
  private gestureGroup: string = '';
  @State undoAvailable: boolean = false;
  @State redoAvailable: boolean = false;
  @StorageLink('safeTop') safeTop: number = 36;
  @StorageLink('safeBottom') safeBottom: number = 24;
  @StorageLink('editCardId') @Watch('routeChanged') routedId: string = '';
  @StorageLink('viewCardId') @Watch('viewRouteChanged') viewRouteId: string = '';
  @State viewing: boolean = false;
  @State ready: boolean = false;
  @State error: string = '';
  @State cards: FridgeCard[] = [];
  @State cardIds: string[] = [];
  @State cardMap: Record<string, FridgeCard> = {};
  @State revision: number = 0;
  @State selectedId: string = '';
  @State activeBoardId: string = '';
  @State editing: boolean = false;
  @State settingsTab: number = 0;
  @State @Watch('editorTabChanged') editorTabs: number[] = [0];
  @State editorTabOptions: SegmentButtonOptions = SegmentButtonOptions.capsule({
    buttons: [{ text: '背景创作' }, { text: '上层内容' }], multiply: false
  });
  @State scatter: number = 0;
  @State showBackgroundOptions: boolean = false;
  @State showLayerOptions: boolean = false;
  private resizeStart: ElementBox = new ElementBox();
  private rotateStart: number = 0;
  private outerResizeW: number = 0;
  private outerResizeH: number = 0;
  private outerResizeY: number = 0;
  private rotationStartAngle: number = 0;
  @State private cardRotating: boolean = false;
  private rotationViewport: EditorViewport = new EditorViewport();
  private rotationVector: ShapePoint = { x: 0, y: -40 };
  @State showEditorContent: boolean = false;
  private fingerStartX: number = 0;
  private fingerStartY: number = 0;
  private fingerLastX: number = 0;
  private fingerLastY: number = 0;
  private hasGlobalFinger: boolean = false;
  @State panelLeft: number = 20;
  @State panelTop: number = 450;
  @State panelWidth: number = 350;
  @State panelHeight: number = 250;
  private colorDialog: CustomDialogController | null = null;
  @State editorMounted: boolean = false;
  @State editorReady: boolean = false;
  @State preview: FridgeCard = new FridgeCard();
  @State boardScale: number = 1;
  @State boardLeft: number = 0;
  @State boardTop: number = 60;
  @State boardHeight: number = 470;
  @State screenWidth: number = 390;
  @State screenHeight: number = 844;
  @State canvasAspect: number = 1;
  @State canvasDimension: string = '4*4';
  @State heroActive: boolean = false;
  @State creatingTransition: boolean = false;
  @State transitionClipX: number = 0;
  @State transitionClipY: number = 0;
  @State transitionClipW: number = 390;
  @State transitionClipH: number = 844;
  @State transitionClipRadius: number = 0;
  @StorageLink('appDark') @Watch('appearanceChanged') appDark: boolean = false;
  @State heroRect: SceneRect = new SceneRect();
  @State heroBase: SceneRect = new SceneRect();
  @State heroScale: number = 1;
  @State heroX: number = 0;
  @State heroY: number = 0;
  @State heroAngle: number = 0;
  @State editorOpacity: number = 0;
  @State boardOpacity: number = 1;
  private transitionTimer: number = -1;
  @StorageLink('widgetDimension') widgetDimension: string = '';
  @StorageLink('widgetAspect') @Watch('widgetFrameChanged') widgetAspect: number = 0;
  @State layerId: string = '';
  @State layerDrag: string = '';
  @State layerDX: number = 0;
  @State layerDY: number = 0;
  @State boxPreview: ElementBox = new ElementBox();
  @State elementPreview: CanvasElement = new CanvasElement();
  @State textValue: string = '';
  @State titleValue: string = '';
  @State cityValue: string = '';
  @State paperValue: string = '';
  @State inkValue: string = '';
  @State elementColor: string = '';
  @State busy: boolean = false;
  @State canvasBackground: CanvasBackground = new CanvasBackground();
  @State backgroundOpen: boolean = false;
  @State backgroundBusy: boolean = false;
  @State sharing: boolean = false;
  private backgroundGeneration: number = 0;
  private backgroundTimer: number = -1;
  @StorageLink('appBackgrounded') @Watch('appWentBackground') appBackgrounded: boolean = false;
  private appWentBackground(): void { if (this.appBackgrounded && this.ready) { if (this.previewTimer >= 0 || this.gestureGroup.length > 0) this.flushPreview(); this.persist(true); } }

  @State repairingSubjects: boolean = false;
  @State weatherBusy: boolean = false;
  @State tick: number = Date.now();

  aboutToAppear(): void {
    this.alive = true; this.appearanceChanged();
    this.context = this.getUIContext().getHostContext() ?? null;
    this.initialize();
    this.clockTimer = setInterval(() => { this.tick = Date.now(); this.refreshDueWeather(); }, 60000);
  }
  private initialize(): void {
    if (this.context === null) return;
    this.store.init(this.context).then(async () => {
      // Resolve FormKit geometry before revealing the scene; a late aspect update jumps after arrival.
      await this.store.refreshCanvasSpecs().catch(() => {});
      if (!this.alive) return;
      for (const card of this.store.state.cards) {
        if (!ensureCapabilitySize(card)) this.error = '部分主体内部空间不足，请移除能力或更换形状';
        this.clamp(card);
      }
      this.canvasDimension = this.widgetDimension || '4*4';
      this.canvasAspect = this.widgetAspect > 0 ? this.widgetAspect : (this.store.canvasSpecs[this.canvasDimension] ?? (this.canvasDimension === '6*4' ? 2 / 3 : (this.canvasDimension === '2*4' ? 2 : 1)));
      const routedLaunch = this.routedId.length > 0 || this.viewRouteId.length > 0;
      this.canvasBackground = this.store.state.background; this.layoutBoard(); this.ready = true; this.render(); this.scheduleBackground(); this.routeChanged(); this.viewRouteChanged();
      if (!routedLaunch) this.startArrival();
      this.maintenanceTimer = setTimeout(() => { if (this.alive) { this.editorMounted = true; this.persist(); this.repairStoredSubjects(); this.refreshDueWeather(); } }, 750);

    }).catch((e: Error) => { this.error = e.message; });
  }
  private arrivalOffsets: Record<string, ShapePoint> = {};
  private startArrival(): void {
    if (this.editing || this.viewing || this.cardIds.length === 0) return;
    this.arrivalOffsets = {};
    this.cards.forEach((card: FridgeCard) => { this.arrivalOffsets[card.id] = arrivalOffset(card, BOARD_W * this.boardScale, this.boardHeight); });
    this.arriving = true; this.arrival = 1; this.boardOpacity = 0;
    this.transitionTimer = setTimeout(() => {
      if (!this.alive) return;
      this.getUIContext().animateTo({ duration: 520, curve: Curve.Friction, expectedFrameRateRange: this.frameRate,
        onFinish: () => { if (this.alive) this.arriving = false; } }, () => { this.arrival = 0; this.boardOpacity = 1; });
    }, 32);
  }
  private arrivalX(id: string): number { return this.arrival * (this.arrivalOffsets[id]?.x ?? 0); }
  private arrivalY(id: string): number { return this.arrival * (this.arrivalOffsets[id]?.y ?? 0); }
  private async repairStoredSubjects(): Promise<void> {
    if (this.context === null || this.repairingSubjects) return;
    const pending = this.store.state.cards.filter((card: FridgeCard) => card.cutout.startsWith('file://') && card.subjectVersion < 4);
    if (pending.length === 0) return;
    this.repairingSubjects = true;
    try {
      for (const card of pending) {
        if (!this.alive) break;
        if (this.store.findCard(card.id) !== card) continue;
        const src = card.cutout;
        try {
          const result = await repairSubject(src, this.context.filesDir);
          if (!this.alive || this.store.findCard(card.id) !== card || card.cutout !== src || card.subjectVersion >= 4) {
            try { await fileIo.unlink(result.src.slice(7)); } catch (_) {} continue;
          }
          if (card.shape === 'subject') { cropCardToSubject(card, result.crop); card.h = card.w / result.aspect; }
          card.subjectAspect = result.aspect; card.cutout = result.src; card.outline = result.outline; card.subjectVersion = 4; card.subjectInk = result.ink;
          if (!ensureCapabilitySize(card)) this.error = '部分主体内部空间不足，请移除能力或更换形状';
          this.clamp(card); this.render(); this.persist();
        } catch (_) { if (this.alive) this.error = '部分旧主体照片未能更新，请重新选择本地照片'; }
      }
    } finally { this.repairingSubjects = false; }
  }
  aboutToDisappear(): void { if (this.previewTimer >= 0 || this.gestureGroup.length > 0) this.flushPreview(); this.alive = false; this.backgroundGeneration += 1; if (this.backgroundTimer >= 0) clearTimeout(this.backgroundTimer); if (this.maintenanceTimer >= 0) clearTimeout(this.maintenanceTimer); if (this.transitionTimer >= 0) clearTimeout(this.transitionTimer); this.activeBoardId = ''; this.persist(true); if (this.clockTimer >= 0) clearInterval(this.clockTimer); }
  onBackPress(): boolean {
    if (this.heroActive) return true;
    if (this.viewing) { this.viewing = false; this.selectedId = ''; return true; }
    if (this.editing) { this.closeEditor(); return true; }
    if (this.selectedId.length > 0) { this.selectedId = ''; return true; }
    return false;
  }
  private widgetFrameChanged(): void {
    if (this.widgetAspect > 0) { this.canvasDimension = this.widgetDimension || this.canvasDimension; this.canvasAspect = this.widgetAspect; this.layoutBoard(); }
  }
  private layoutBoard(): void {
    const landscape = this.screenWidth > this.screenHeight;
    const available = Math.max(180, this.screenHeight - this.safeTop - this.safeBottom - 40);
    const side = Math.min(320, Math.max(240, this.screenWidth * .3));
    const width = Math.min(landscape ? this.screenWidth - side - 60 : this.screenWidth - 40,
      (landscape ? available : Math.max(100, available - 294)) * this.canvasAspect);
    this.boardScale = width / BOARD_W; this.boardHeight = width / this.canvasAspect;
    this.boardLeft = landscape ? 20 : (this.screenWidth - width) / 2; this.boardTop = this.safeTop + 20;
    this.panelLeft = landscape ? this.boardLeft + width + 20 : 20;
    this.panelTop = landscape ? this.boardTop : this.boardTop + this.boardHeight + 16;
    this.panelWidth = this.screenWidth - this.panelLeft - 20;
    this.panelHeight = Math.max(120, this.screenHeight - this.panelTop - this.safeBottom - 20);
  }
  private scatterOffset(id: string, horizontal: boolean): number {
    const card = this.cardMap[id]; if (card === undefined || id === this.selectedId) return 0;
    const selected = this.cardMap[this.selectedId];
    const cx = (card.x + card.w / 2) * this.boardScale, cy = card.y * this.boardHeight / BOARD_H + card.h * this.boardScale / 2;
    const sx = selected === undefined ? BOARD_W * this.boardScale / 2 : (selected.x + selected.w / 2) * this.boardScale;
    const sy = selected === undefined ? this.boardHeight / 2 : selected.y * this.boardHeight / BOARD_H + selected.h * this.boardScale / 2;
    let dx = cx - sx, dy = cy - sy;
    if (Math.abs(dx) + Math.abs(dy) < 1) { dx = card.z % 2 === 0 ? 1 : -1; dy = .5; }
    const length = Math.sqrt(dx * dx + dy * dy);
    return (horizontal ? dx : dy) / length * Math.max(BOARD_W * this.boardScale, this.boardHeight) * 1.2 * this.scatter;
  }

  private editorLandscape(): boolean { return this.screenWidth > this.screenHeight; }
  private editorViewportWidth(): number { return this.editorLandscape() ? this.screenWidth * .48 : this.screenWidth * .57; }
  private editorBodyHeight(): number { return Math.max(120, this.screenHeight - this.safeTop - this.safeBottom - 76); }
  private previewPaneHeight(): number { return this.editorLandscape() ? Math.min(300, Math.max(64, this.editorBodyHeight() - 164), this.editorBodyHeight() * .58) : Math.min(280, this.editorBodyHeight() * .36); }
  private editingAngle(): number { return this.preview.rot; }
  private previewViewport(): EditorViewport {
    if (this.cardRotating) return this.rotationViewport;
    return editorViewport(this.preview.w, this.preview.h, this.editingAngle(), this.editorViewportWidth(),
      this.screenHeight, this.safeTop, this.safeBottom, this.editorLandscape(), this.previewPaneHeight());
  }
  private editorScale(): number { return this.previewViewport().scale; }
  private editorRect(): SceneRect {
    const rect = new SceneRect(), scale = this.editorScale();
    rect.w = this.preview.w * scale; rect.h = this.preview.h * scale;
    rect.x = this.previewViewport().left; rect.y = this.safeTop + 76 + this.previewViewport().top; rect.rot = this.editingAngle(); return rect;
  }
  private boardRect(): SceneRect {
    const rect = sceneRect(this.preview, this.boardScale * BOARD_W, this.boardHeight);
    rect.x += this.boardLeft; rect.y += this.boardTop; return rect;
  }
  private openEditor(id: string, created: boolean = false): void {
    if (this.heroActive || this.arriving) return;
    this.select(id, true); this.scatter = 0; this.showEditorContent = false; this.showBackgroundOptions = false; this.showLayerOptions = false; this.settingsTab = 0; this.editorTabs = [0];
    this.heroRect = this.boardRect();
    if (created) {
      const rect = new SceneRect(); rect.w = 28; rect.h = 28 * this.preview.h / this.preview.w;
      rect.x = this.panelLeft + this.panelWidth - 38; rect.y = this.panelTop + 22 - rect.h / 2; this.heroRect = rect;
    }
    this.layerId = this.preview.elements.find((el: CanvasElement) => el.behindCapability)?.id ?? ''; this.syncFields();
    this.creatingTransition = created; this.heroBase = this.editorRect(); this.setHeroPose(this.heroRect); this.setTransitionClip(true);
    this.editorMounted = true; this.editorReady = true; this.scroller.scrollTo({ xOffset: 0, yOffset: 0 }); this.editorOpacity = 0; this.boardOpacity = 1; this.heroActive = true; this.editing = true;
    this.transitionTimer = setTimeout(() => {
      if (!this.alive) return;
      this.getUIContext().animateTo({ duration: 380, curve: Curve.Friction, expectedFrameRateRange: this.frameRate, onFinish: () => { if (this.alive) { this.heroActive = false; this.creatingTransition = false; } } }, () => {
        this.setHeroPose(this.editorRect()); this.setTransitionClip(false); this.scatter = 1; this.boardOpacity = 0; this.editorOpacity = 1;
      });
    }, 16);
  }
  private setTransitionClip(board: boolean): void {
    this.transitionClipX = board ? this.boardLeft : 0; this.transitionClipY = board ? this.boardTop : 0;
    this.transitionClipW = board ? BOARD_W * this.boardScale : this.screenWidth;
    this.transitionClipH = board ? this.boardHeight : this.screenHeight;
    this.transitionClipRadius = board ? 24 : 0;
  }
  private surfaceScale(): number { return this.heroActive ? this.heroScale * this.heroBase.w / (this.preview.w * this.boardScale) : this.editorScale() / this.boardScale; }
  private surfaceX(): number { return this.heroActive ? this.heroX : this.editorRect().x; }
  private surfaceY(): number { return this.heroActive ? this.heroY : this.editorRect().y; }
  private surfaceAngle(): number { return this.heroActive ? this.heroAngle : this.editingAngle(); }
  private transitionCardRect(id: string): SceneRect {
    const rect = sceneRect(this.cardMap[id], BOARD_W * this.boardScale, this.boardHeight);
    rect.x += this.boardLeft + this.scatterOffset(id, true); rect.y += this.boardTop + this.scatterOffset(id, false);
    return rect;
  }
  private appearanceChanged(): void {
    this.editorTabOptions = SegmentButtonOptions.capsule({
      buttons: [{ text: '背景创作' }, { text: '上层内容' }], multiply: false,
      fontColor: this.appText(), selectedFontColor: this.appText(),
      backgroundColor: Color.Transparent, selectedBackgroundColor: Color.Transparent
    });
  }
  private appBackground(): string { return AppDesign.background(this.appDark); }
  private appSurface(): string { return AppDesign.surface(this.appDark); }
  private appPanel(): string { return this.appBackground(); }
  private appControl(): string { return this.appBackground(); }
  private appText(): string { return AppDesign.text(this.appDark); }
  private appMuted(): string { return AppDesign.muted(this.appDark); }
  private setHeroPose(rect: SceneRect): void {
    this.heroScale = rect.w / this.heroBase.w; this.heroX = rect.x; this.heroY = rect.y; this.heroAngle = rect.rot;
  }
  private closeEditor(): void {
    if (this.heroActive || !this.editing) return;
    if (this.previewTimer >= 0 || this.gestureGroup.length > 0) this.flushPreview();
    this.creatingTransition = false;
    this.heroBase = this.editorRect(); this.setHeroPose(this.heroBase); this.setTransitionClip(false); this.heroActive = true;
    // Publish the edited card to the board once, before it fades back in.
    this.renderBoard(); this.persist(true); this.scheduleBackground();
    this.getUIContext().animateTo({ duration: 340, curve: Curve.Friction, expectedFrameRateRange: this.frameRate, onFinish: () => {
      if (this.alive) { this.editing = false; this.editorReady = false; this.heroActive = false; this.selectedId = ''; this.persist(); }
    } }, () => { this.setHeroPose(this.boardRect()); this.setTransitionClip(true); this.editorOpacity = 0; this.boardOpacity = 1; this.scatter = 0; });
  }
  private orderedCards(): FridgeCard[] { return this.cards.slice().sort((a: FridgeCard, b: FridgeCard) => b.z - a.z); }
  private moveCardLayer(id: string, upward: boolean): void {
    const sorted = this.store.state.cards.slice().sort((a: FridgeCard, b: FridgeCard) => a.z - b.z);
    const index = sorted.findIndex((card: FridgeCard) => card.id === id), other = index + (upward ? 1 : -1);
    if (index < 0 || other < 0 || other >= sorted.length) return;
    const card = sorted[index]; sorted[index] = sorted[other]; sorted[other] = card;
    sorted.forEach((item: FridgeCard, i: number) => { item.z = i + 1; }); this.store.state.maxZ = sorted.length;
    this.render(); this.persist();
  }
  private routeChanged(): void {
    if (!this.ready || this.routedId.length === 0) return;
    if (this.store.findCard(this.routedId) !== null) { this.openEditor(this.routedId); }
    AppStorage.setOrCreate('editCardId', '');
  }
  private viewRouteChanged(): void {
    if (!this.ready || this.viewRouteId.length === 0 || this.context === null) return;
    const id = this.viewRouteId; AppStorage.setOrCreate('viewCardId', '');
    this.store.init(this.context).then(async () => {
      // Resolve FormKit geometry before revealing the scene; a late aspect update jumps after arrival.
      await this.store.refreshCanvasSpecs().catch(() => {});
      if (!this.alive) return;
      if (!this.alive || this.store.findCard(id) === null) return;
      this.editing = false; this.heroActive = false; this.boardOpacity = 1;
      this.render(); this.select(id); this.viewing = true;
    }).catch(() => { this.error = '卡片读取失败，请重试'; });
  }
  private calendarAction(operation: string): void {
    const card = this.current(); if (card !== null && applyCalendarAction(card, operation)) { this.render(); this.persist(); }
  }
  private current(): FridgeCard | null { return this.store.findCard(this.selectedId); }
  private currentElement(): CanvasElement | null { return this.current()?.elements.find((e: CanvasElement) => e.id === this.layerId) ?? null; }
  private currentBox(): ElementBox | null { return this.layerId === 'capability' ? this.current()?.capBox ?? null : this.currentElement(); }
  private renderBoard(): void {
    const next = this.store.state.cards.map((card: FridgeCard) => cardRenderSnapshot(card));
    if (next.length === this.cards.length && next.every((card: FridgeCard, index: number) => card === this.cards[index])) return;
    this.cards = next;
    const map: Record<string, FridgeCard> = {};
    this.cards.forEach((item: FridgeCard) => { map[item.id] = item; });
    this.cardMap = map; this.cardIds = this.cards.map((item: FridgeCard) => item.id);
  }
  private render(): void {
    if (!this.editing) this.renderBoard();
    const card = this.current(); if (card !== null) this.preview = cardRenderSnapshot(card);
    this.revision += 1; this.syncPreviewFields();
  }
  private continuousChange(mode: SliderChangeMode): void {
    if (this.gestureGroup.length === 0) {
      if (this.saveTimer >= 0) clearTimeout(this.saveTimer); this.saveTimer = -1;
      this.gestureGroup = 'continuous_' + Date.now();
    }
    if (mode === SliderChangeMode.End || mode === SliderChangeMode.Click) { this.flushPreview(); return; }
    if (this.previewTimer >= 0) return;
    this.previewTimer = setTimeout(() => { this.previewTimer = -1; if (this.alive) this.render(); }, 16);
  }
  private flushPreview(): void {
    if (this.previewTimer >= 0) clearTimeout(this.previewTimer); this.previewTimer = -1; this.change(); this.gestureGroup = '';
  }
  private select(id: string, refresh: boolean = false): void {
    if (!refresh && !this.editing && !this.viewing && this.selectedId === id) return;
    const selected = this.store.findCard(id);
    if (selected !== null && this.selectedId !== id) { this.history.reset(selected); this.undoAvailable = false; this.redoAvailable = false; }
    this.selectedId = id; this.layerId = ''; this.syncFields();
    const card = this.current(); if (card !== null) this.preview = cardRenderSnapshot(card);
  }
  private syncPreviewFields(): void {
    this.boxPreview = JSON.parse(JSON.stringify(this.currentBox() ?? new ElementBox())) as ElementBox;
    this.elementPreview = JSON.parse(JSON.stringify(this.currentElement() ?? new CanvasElement())) as CanvasElement;
  }
  private syncFields(): void {
    this.syncPreviewFields();
    const card = this.current(), element = this.currentElement();
    this.textValue = element?.text ?? ''; this.elementColor = element?.color ?? '';
    this.titleValue = card?.capability?.title ?? ''; this.cityValue = card?.capability?.city ?? '';
    this.paperValue = card?.paper ?? ''; this.inkValue = card?.ink ?? '';
  }
  private change(group: string = this.gestureGroup): void {
    const card = this.current();
    if (card !== null) {
      if (!ensureCapabilitySize(card)) {
        const index = this.store.state.cards.findIndex((item: FridgeCard) => item.id === card.id);
        if (this.preview.id === card.id && index >= 0) this.store.state.cards[index] = cardViewSnapshot(this.preview);
        this.getUIContext().getPromptAction().showToast({ message: '这个主体的内部空间不足以显示紧凑能力，请更换形状或移除能力' });
        this.syncFields(); this.render(); return;
      }
      if (card.capability !== null) card.capBox = capabilityPlacement(card);
      this.clamp(card);
      if (this.editing) { this.history.record(card, group); this.undoAvailable = this.history.canUndo(); this.redoAvailable = this.history.canRedo(); }
    }
    this.render();
    if (this.saveTimer >= 0) clearTimeout(this.saveTimer);
    this.scheduleBackground(); this.saveTimer = setTimeout(() => this.persist(true), 120);
  }
  private restoreHistory(redo: boolean): void {
    if (this.layerDrag.length > 0 || this.gestureGroup.length > 0 || this.heroActive || this.busy) return;
    if (this.previewTimer >= 0) this.flushPreview();
    const restored = redo ? this.history.redo() : this.history.undo(); if (restored === null) return;
    const index = this.store.state.cards.findIndex((card: FridgeCard) => card.id === restored.id);
    if (index < 0) return;
    this.store.state.cards[index] = restored;
    if (this.layerId !== 'capability' && !restored.elements.some((el: CanvasElement) => el.id === this.layerId)) this.layerId = '';
    if (this.layerId === 'capability' && restored.capability === null) this.layerId = '';
    this.gestureGroup = ''; this.syncFields(); this.render();
    this.undoAvailable = this.history.canUndo(); this.redoAvailable = this.history.canRedo(); this.persist(true);
  }
  private duplicateElement(): void {
    const card = this.current(), element = this.currentElement(); if (card === null || element === null) return;
    const copy = JSON.parse(JSON.stringify(element)) as CanvasElement; copy.id = this.store.newId();
    copy.x = Math.min(1 - copy.w, copy.x + .04); copy.y = Math.min(1 - copy.h, copy.y + .04);
    card.elements.push(copy); this.layerId = copy.id; this.change(); this.syncFields();
  }
  private moveElementOrder(up: boolean): void {
    const card = this.current(), element = this.currentElement(); if (card === null || element === null) return;
    const peers = card.elements.filter((el: CanvasElement) => el.behindCapability === element.behindCapability);
    const at = peers.findIndex((el: CanvasElement) => el.id === element.id), next = at + (up ? 1 : -1);
    if (next < 0 || next >= peers.length) return;
    const a = card.elements.indexOf(element), b = card.elements.indexOf(peers[next]);
    card.elements[a] = peers[next]; card.elements[b] = element; this.change();
  }
  private persist(syncWidgets: boolean = true): void {
    if (!this.ready || this.activeBoardId.length > 0) return;
    if (this.saveTimer >= 0) clearTimeout(this.saveTimer); this.saveTimer = -1;
    this.store.state.canvasAspect = this.canvasAspect; this.store.state.canvasDimension = this.canvasDimension;
    this.store.save(syncWidgets).catch((e: Error) => { this.error = e.message === '桌面组件同步未完成' ? '桌面同步暂未完成，点此重试' : '保存失败，点此重试'; });
  }
  private clamp(card: FridgeCard): void {
    clampCardGeometry(card);
  }
  private addCard(): void {
    const card = new FridgeCard(); card.id = this.store.newId();
    const offset = (this.cards.length % 6) * 20; card.x += offset; card.y += offset;
    this.clamp(card); this.store.addCard(card); this.select(card.id); this.change(); this.openEditor(card.id, true);
  }
  private setCapability(k: string): void {
    const card = this.current(); if (card === null) return;
    if (card.capability?.k === k) { this.layerId = 'capability'; this.syncFields(); this.scroller.scrollTo({ xOffset: 0, yOffset: 0 }); return; }
    if (k === 'none') { card.capability = null; this.layerId = ''; }
    else {
      const cap: CapBlock = { k: k };
      if (k === 'countdown' || k === 'anniversary') {
        const date = new Date(); cap.date = date.getFullYear() + '-' + ('0' + (date.getMonth() + 1)).slice(-2) + '-' + ('0' + date.getDate()).slice(-2);
        cap.title = '';
      }
      if (k === 'weather') { cap.city = ''; cap.temp = '--°'; cap.desc = '未更新'; }
      card.capability = cap; card.capBox = safeContentBox(card); this.layerId = 'capability';
    }
    this.syncFields(); this.change(); this.scroller.scrollTo({ xOffset: 0, yOffset: 0 });
  }
  private addElement(kind: string): void {
    const card = this.current(); if (card === null) return;
    const el = new CanvasElement(); el.id = this.store.newId(); el.kind = kind;
    el.y = 0.12 + (card.elements.length % 5) * 0.12; el.h = kind === 'text' ? 0.25 : 0.35;
    el.w = kind === 'shape' ? 0.3 : 0.7; el.color = kind === 'shape' ? '#D6DCE3' : '';
    el.text = kind === 'text' ? '文字' : ''; el.behindCapability = this.settingsTab === 0;
    const importGroup = kind === 'image' ? 'image_' + el.id + '_' + Date.now() : '';
    card.elements.push(el); this.layerId = el.id; this.syncFields(); this.change(importGroup);
    if (kind === 'image') this.pickImage(false, importGroup).then(() => {
      if (el.src.length === 0 && this.store.findCard(card.id) === card && card.elements.includes(el)) {
        card.elements = card.elements.filter((item: CanvasElement) => item.id !== el.id);
        if (this.layerId === el.id) this.layerId = ''; this.change(importGroup);
      }
    });
  }
  private removeElement(): void {
    const card = this.current(); if (card === null) return;
    if (this.layerId === 'capability') card.capability = null;
    else card.elements = card.elements.filter((e: CanvasElement) => e.id !== this.layerId);
    this.layerId = ''; this.syncFields(); this.change();
  }
  private duplicate(): void {
    const card = this.current(); if (card === null) return;
    const copy = JSON.parse(JSON.stringify(card)) as FridgeCard; copy.id = this.store.newId(); copy.groupId = ''; copy.x += 16; copy.y += 16;
    copy.elements.forEach((e: CanvasElement) => { e.id = this.store.newId(); });
    this.clamp(copy); this.store.addCard(copy); this.select(copy.id); this.change();
  }
  private deleteCard(id: string): void {
    this.getUIContext().showAlertDialog({ title: '删除卡片？', message: '卡片中的内容也会删除。',
      primaryButton: { value: '取消', action: () => {} },
      secondaryButton: { value: '删除', fontColor: '#C43A35', action: () => {
        this.store.removeCard(id); cleanGroups(this.store.state.cards); this.selectedId = ''; this.editing = false; this.change();
      } }
    });
  }
  private boardInteraction(id: string, active: boolean): void {
    if (active) { const card = this.store.findCard(id); this.movingGroupIds = card === null ? [] : groupMembers(this.store.state.cards, card).filter((c: FridgeCard) => c.id !== id).map((c: FridgeCard) => c.id); this.boardMotion.ids = this.movingGroupIds.length > 0 ? [id, ...this.movingGroupIds] : []; }
    else { this.boardMotion.x = 0; this.boardMotion.y = 0; this.boardMotion.ids = []; this.movingGroupIds = []; }
    this.activeBoardId = active ? id : '';
    if (this.saveTimer >= 0) clearTimeout(this.saveTimer); this.saveTimer = -1;
    if (!active) { this.scheduleBackground(); this.persist(true); }
  }
  private commitGeometry(updated: FridgeCard): void {
    const card = this.store.findCard(updated.id); if (card === null) return;
    const dx = updated.x - card.x, dy = updated.y - card.y;
    if (updated.w === card.w && updated.h === card.h) { for (const peer of groupMembers(this.store.state.cards, card)) if (peer.id !== card.id) { peer.x += dx; peer.y += dy; } }
    this.boardMotion.x = 0; this.boardMotion.y = 0;
    card.x = updated.x; card.y = updated.y; card.w = updated.w; card.h = updated.h; card.rot = updated.rot;
    this.clamp(card); groupMembers(this.store.state.cards, card).sort((a: FridgeCard, b: FridgeCard) => a.z - b.z).forEach((member: FridgeCard) => this.store.bringToFront(member));
    // Geometry handoff only updates the visible board; hydrate inspector on entry.
    if (this.editing || this.viewing) this.render(); else this.renderBoard();
    if (this.saveTimer >= 0) clearTimeout(this.saveTimer);
    this.scheduleBackground(); this.persist(true);
  }
  private async pickImage(subject: boolean = false, group: string = ''): Promise<void> {
    if (this.context === null || this.busy) return;
    const id = this.selectedId, elementId = this.layerId;
    this.busy = true;
    let input: fileIo.File | null = null, output: fileIo.File | null = null;
    let path = '';
    try {
      const options = new photoAccessHelper.PhotoSelectOptions(); options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE; options.maxSelectNumber = 1;
      const result = await new photoAccessHelper.PhotoViewPicker().select(options); if (result.photoUris.length === 0) return;
      const card = this.store.findCard(id); if (card === null) return;
      if (subject) {
        const shapeResult = await extractSubject(result.photoUris[0], this.context.filesDir);
        if (this.store.findCard(id) !== card) { await fileIo.unlink(shapeResult.src.slice(7)); return; }
        card.cutout = shapeResult.src; card.outline = shapeResult.outline; card.shape = 'subject'; card.subjectBorder = true; card.subjectVersion = 4; card.subjectInk = shapeResult.ink; card.subjectAspect = shapeResult.aspect;
        card.h = card.w / shapeResult.aspect;
        const fit = Math.min(1, 320 / card.w, 420 / card.h); card.w *= fit; card.h *= fit;
        card.capBox = safeContentBox(card); this.change(group);
      } else {
        const element = card.elements.find((e: CanvasElement) => e.id === elementId); if (element === undefined) return;
        input = await fileIo.open(result.photoUris[0], fileIo.OpenMode.READ_ONLY);
        path = this.context.filesDir + '/image_' + Date.now() + '.img';
        output = await fileIo.open(path, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE); await fileIo.copyFile(input.fd, output.fd);
        const header = new ArrayBuffer(6); fileIo.readSync(output.fd, header, { offset: 0, length: 6 });
        const bytes = new Uint8Array(header); const gif = bytes[0] === 71 && bytes[1] === 73 && bytes[2] === 70 && bytes[3] === 56 && (bytes[4] === 55 || bytes[4] === 57) && bytes[5] === 97;
        if (this.store.findCard(id) !== card || !card.elements.includes(element)) { await fileIo.unlink(path); return; }
        element.src = 'file://' + path; element.animated = gif; this.change(group);
      }
    } catch (e) {
      if (path.length > 0) { try { await fileIo.unlink(path); } catch (_) {} }
      this.getUIContext().getPromptAction().showToast({ message: subject ? '主体抠图失败：' + (e as Error).message : '照片读取失败，请重试' });
    } finally {
      if (input !== null) { try { fileIo.closeSync(input.fd); } catch (_) {} }
      if (output !== null) { try { fileIo.closeSync(output.fd); } catch (_) {} }
      this.busy = false;
    }
  }
  private pickDate(): void {
    const cap = this.current()?.capability; if (cap === null || cap === undefined) return;
    const card = this.current();
    this.getUIContext().showDatePickerDialog({ start: new Date('1900-01-01'), end: new Date('2100-12-31'), selected: new Date((cap.date ?? '2026-09-30') + 'T00:00:00'),
      onDateAccept: (d: Date) => {
        if (card?.capability !== cap) return;
        cap.date = d.getFullYear() + '-' + ('0' + (d.getMonth() + 1)).slice(-2) + '-' + ('0' + d.getDate()).slice(-2); this.change();
      }
    });
  }
  private autoWeatherBusy: boolean = false;
  onPageHide(): void { if (this.previewTimer >= 0 || this.gestureGroup.length > 0) this.flushPreview(); this.persist(true); }
  onPageShow(): void { if (this.ready) this.refreshDueWeather(); }
  private async refreshDueWeather(): Promise<void> {
    if (!this.ready || !this.alive || this.autoWeatherBusy || this.weatherBusy) return;
    this.autoWeatherBusy = true;
    try {
      const cards = this.store.state.cards.filter((card: FridgeCard) => weatherNeedsRefresh(card.capability));
      for (const card of cards) {
        if (!this.alive) break;
        const cap = card.capability!, city = cap.city!.trim(), attempted = Date.now();
        cap.attemptedAt = attempted; cap.refreshState = 'refreshing';
        const result = await fetchWeather(city);
        if (!this.alive || this.store.findCard(card.id)?.capability !== cap || cap.city?.trim() !== city || cap.attemptedAt !== attempted) continue;
        cap.refreshState = result === null ? 'failed' : 'done';
        if (result !== null) { cap.temp = result.temp; cap.desc = result.desc; cap.updatedAt = Date.now(); }
        this.render(); this.persist();
      }
    } finally { this.autoWeatherBusy = false; }
  }
  private async refreshWeather(): Promise<void> {
    const card = this.current(), cap = card?.capability; if (cap?.k !== 'weather' || this.weatherBusy) return;
    const city = this.cityValue.trim(); if (city.length === 0) { this.getUIContext().getPromptAction().showToast({ message: '请输入城市' }); return; }
    this.weatherBusy = true; cap.attemptedAt = Date.now();
    try {
      const result = await fetchWeather(city);
      if (card?.capability !== cap || cap.city !== city) return;
      if (result === null) { cap.refreshState = 'failed'; this.change(); this.getUIContext().getPromptAction().showToast({ message: '天气更新失败，请重试' }); return; }
      cap.temp = result.temp; cap.desc = result.desc; cap.updatedAt = Date.now(); cap.refreshState = 'done'; this.change();
    } finally { this.weatherBusy = false; }
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column().width('100%').height('100%').backgroundColor(this.appBackground())
      if (!this.ready) {
        Column({ space: 12 }) {
          if (this.error.length > 0) { Text(this.error).fontSize(14).fontColor(this.appMuted()) }
          if (this.error.length > 0) { Button('重试', { type: ButtonType.ROUNDED_RECTANGLE }).onClick(() => this.initialize()) }
        }.width('100%').height('100%').justifyContent(FlexAlign.Center)
      } else {
        this.board()
        if (this.editing && this.editorReady) {
          // Backdrop and chrome are separate from the persistent card surface.
          Stack({ alignContent: Alignment.TopStart }) {
            Column().width('100%').height('100%').backgroundColor(this.appBackground())
            Column().width(this.editorViewportWidth()).height(this.editorCanvasHeight()).backgroundColor(this.appPanel())
              .position({ x: 0, y: this.safeTop + 76 })
          }.width('100%').height('100%').opacity(this.editorOpacity).hitTestBehavior(HitTestMode.None)
        }
        this.editingScene()
        if (this.editorMounted) { this.editor() }
        if (this.viewing) { this.detail() }
      }
    }.width('100%').height('100%').backgroundColor(this.appBackground())
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
      .onAreaChange((_: Area, area: Area) => {
        const width = Number(area.width), height = Number(area.height);
        if (width > 0 && height > 0) { this.screenWidth = width; this.screenHeight = height; this.layoutBoard(); }
      })
  }
  private sceneCard(id: string): FridgeCard { return this.editing && id === this.selectedId ? this.preview : this.cardMap[id]; }
  private sceneScale(id: string): number { return this.editing && id === this.selectedId ? this.surfaceScale() : 1; }
  private sceneX(id: string): number { return this.editing && id === this.selectedId ? this.surfaceX() : this.transitionCardRect(id).x; }
  private sceneY(id: string): number { return this.editing && id === this.selectedId ? this.surfaceY() : this.transitionCardRect(id).y; }
  private sceneClipX(): number { return this.creatingTransition ? 0 : this.editing ? (this.heroActive ? this.transitionClipX : 0) : this.boardLeft; }
  private sceneClipY(): number { return this.creatingTransition ? 0 : this.editing ? (this.heroActive ? this.transitionClipY : 0) : this.boardTop; }
  private creationClip(id: string): boolean { return this.creatingTransition && id !== this.selectedId; }
  private creationClipX(id: string): number { return this.creationClip(id) ? this.transitionClipX : 0; }
  private creationClipY(id: string): number { return this.creationClip(id) ? this.transitionClipY : 0; }
  @Builder
  editingScene() {
    // Stable IDs keep the actual board surfaces (including decoded photos) alive.
    // Cache each unrotated face; transforms remain outside its padded texture.
    Stack({ alignContent: Alignment.TopStart }) {
      Stack({ alignContent: Alignment.TopStart }) {
        ForEach(this.cardIds, (id: string) => {
          Stack({ alignContent: Alignment.TopStart }) {
            Stack({ alignContent: Alignment.TopStart }) {
            BoardCard({ controlViewportWidth: BOARD_W * this.boardScale, controlViewportHeight: this.boardHeight, motion: this.boardMotion, card: this.sceneCard(id), localCoordinates: true, cacheSurface: this.heroActive || this.arriving, scatterAngle: 0, editingSurface: this.editing,
              displayAngle: id === this.selectedId ? this.surfaceAngle() : this.cardMap[id].rot + this.scatter * (this.cardMap[id].z % 2 === 0 ? 9 : -9),
              selected: this.selectedId === id && !this.editing && !this.groupSelecting, scaleFactor: this.boardScale, yScaleFactor: this.boardHeight / BOARD_H,
              hideContent: this.editing && id === this.selectedId && this.settingsTab === 0,
              movingLayerId: id === this.selectedId ? this.layerDrag : '',
              moveX: id === this.selectedId && this.editing ? this.layerDX * this.boardScale / this.editorScale() : 0, moveY: id === this.selectedId && this.editing ? this.layerDY * this.boardScale / this.editorScale() : 0, tick: this.tick,
              getMoveBounds: (card: FridgeCard) => groupDragBounds(this.store.state.cards, card),
              onMove: (x: number, y: number) => { if (this.movingGroupIds.length > 0) { this.boardMotion.x = x; this.boardMotion.y = y; } },
              onSelect: (id: string) => this.selectLayerCard(id), onDelete: (id: string) => this.deleteCard(id),
              onEdit: (id: string) => this.openEditor(id), onInteraction: (active: boolean) => this.boardInteraction(id, active), onCommit: (updated: FridgeCard) => this.commitGeometry(updated) })
          }.width(this.sceneCard(id).w * this.boardScale + 48).height(this.sceneCard(id).h * this.boardScale + 48)
            .scale({ x: this.sceneScale(id), y: this.sceneScale(id), centerX: 24, centerY: 24 })
            .position({ x: this.sceneX(id) - 24 - this.creationClipX(id), y: this.sceneY(id) - 24 - this.creationClipY(id) })
            .translate({ x: this.arrivalX(id), y: this.arrivalY(id) })
            .hitTestBehavior(this.editing || this.arriving ? HitTestMode.None : HitTestMode.Transparent)
          }.width(this.creationClip(id) ? this.transitionClipW : this.screenWidth)
            .height(this.creationClip(id) ? this.transitionClipH : this.screenHeight)
            .position({ x: this.creationClipX(id), y: this.creationClipY(id) })
            .borderRadius(this.creationClip(id) ? this.transitionClipRadius : 0).clip(this.creationClip(id))
            .opacity(this.editing && id === this.selectedId ? 1 : this.boardOpacity).zIndex(this.activeBoardId === id ? 100002 : this.cardMap[id].z)
            .hitTestBehavior(this.editing || this.arriving ? HitTestMode.None : HitTestMode.Transparent)
        }, (id: string) => id)
      }.width(this.screenWidth).height(this.screenHeight)
        .position({ x: -this.sceneClipX(), y: -this.sceneClipY() }).hitTestBehavior(HitTestMode.Transparent)
    }.width(this.creatingTransition ? this.screenWidth : this.editing ? (this.heroActive ? this.transitionClipW : this.screenWidth) : BOARD_W * this.boardScale)
      .height(this.creatingTransition ? this.screenHeight : this.editing ? (this.heroActive ? this.transitionClipH : this.screenHeight) : this.boardHeight)
      .position({ x: this.sceneClipX(), y: this.sceneClipY() })
      .borderRadius(this.creatingTransition ? 0 : this.editing ? (this.heroActive ? this.transitionClipRadius : 0) : 24).clip(true)
      .hitTestBehavior(this.editing || this.arriving ? HitTestMode.None : HitTestMode.Transparent)
  }
  @Builder
  board() {
    Stack({ alignContent: Alignment.TopStart }) {
      Stack({ alignContent: Alignment.TopStart }) {
        CanvasBackdrop({ sceneBackground: this.canvasBackground }).width('100%').height('100%')
        Column().width('100%').height('100%').onClick(() => { this.selectedId = ''; })
        if (this.cards.length === 0) {
          Text('放一张自己的卡片').fontSize(16).fontColor('#989898').width('100%').height('100%').textAlign(TextAlign.Center).hitTestBehavior(HitTestMode.None)
        }
      }.width(BOARD_W * this.boardScale).height(this.boardHeight).borderRadius(24).clip(true).backgroundColor(Color.White)
        .border({ width: .5, color: '#E9E9E9' })
        .position({ x: this.boardLeft, y: this.boardTop })
      this.homeLayers()
      this.homeBackground()
    }.width('100%').height('100%').opacity(this.boardOpacity).accessibilityLevel(this.editing || this.viewing ? 'no-hide-descendants' : 'auto').hitTestBehavior(this.editing || this.viewing ? HitTestMode.BLOCK_DESCENDANTS : HitTestMode.Default)
  }
  private selectLayerCard(id: string): void {
    if (!this.groupSelecting) { this.select(id); return; }
    this.groupSelection = this.groupSelection.includes(id) ? this.groupSelection.filter((value: string) => value !== id) : this.groupSelection.concat([id]);
  }
  private confirmGroup(): void {
    if (this.groupSelection.length < 2) return;
    combineCards(this.store.state.cards, this.groupSelection, this.store.newId()); this.groupSelecting = false; this.groupSelection = []; this.renderBoard(); this.persist(true);
  }
  private releaseGroup(): void {
    const card = this.store.findCard(this.selectedId); if (card === null) return; ungroupCards(this.store.state.cards, card.groupId); this.renderBoard(); this.persist(true);
  }
  @Builder
  homeLayers() {
      Column({ space: 12 }) {
        Row() {
          Text('图层').fontSize(17).fontWeight(FontWeight.Medium).fontColor(this.appText()); Blank()
          Button(this.groupSelecting ? '取消' : '多选', { type: ButtonType.Capsule }).margin({ right: 8 }).height(44).fontSize(13).backgroundColor(this.appControl()).fontColor(this.appText()).border({ width: .5, color: AppDesign.border(this.appDark) }).onClick(() => { this.groupSelecting = !this.groupSelecting; this.groupSelection = []; })
          Button('+', { type: ButtonType.Circle }).width(44).height(AppDesign.controlHeight).fontSize(24).backgroundColor('#262626').fontColor(Color.White).accessibilityText('添加卡片').onClick(() => this.addCard())
        }.width('100%')
        Scroll() {
          Column({ space: 8 }) {
            ForEach(this.orderedCards().map((item: FridgeCard) => item.id), (id: string, index: number) => {
              Row({ space: 12 }) {
                Stack() {
                  CardFace({ card: this.cardMap[id], scaleFactor: Math.min(44 / this.cardMap[id].w, 44 / this.cardMap[id].h), tick: this.tick })
                    .width(this.cardMap[id].w * Math.min(44 / this.cardMap[id].w, 44 / this.cardMap[id].h)).height(this.cardMap[id].h * Math.min(44 / this.cardMap[id].w, 44 / this.cardMap[id].h))
                }.width(52).height(52).hitTestBehavior(HitTestMode.None)
                Column({ space: 4 }) {
                  Text(layerLabel(this.cardMap[id])).fontSize(14).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }).fontColor(this.appText()).width('100%')
                  Text((this.cardMap[id].groupId.length > 0 ? '组合 · ' : '') + (index === 0 ? '最上层 · ' : '') + (this.cardMap[id].capability !== null ? typeLabel(this.cardMap[id].capability?.k ?? '') : '自定义')).fontSize(11).fontColor(this.appMuted()).width('100%')
                }.layoutWeight(1).hitTestBehavior(HitTestMode.None)
                Button('编辑', { type: ButtonType.ROUNDED_RECTANGLE }).height(AppDesign.controlHeight).fontSize(13).backgroundColor(Color.Transparent).fontColor(this.appText()).enabled(!this.groupSelecting).onClick(() => this.openEditor(id))
              }.width('100%').padding(8).borderRadius(12).backgroundColor(this.appSurface()).border({ width: (this.groupSelecting ? this.groupSelection.includes(id) : this.selectedId === id) ? 1.5 : 0, color: this.appMuted() })
                .accessibilityText('选择卡片 ' + layerLabel(this.cardMap[id])).onClick(() => this.selectLayerCard(id))
            }, (id: string) => id)
          }.width('100%')
        }.width('100%').layoutWeight(1).align(Alignment.Top).scrollBar(BarState.Off)
        if (this.groupSelecting) { Button('组合选中卡片（' + this.groupSelection.length + '）', { type: ButtonType.Capsule }).height(44).width('100%').enabled(this.groupSelection.length > 1).onClick(() => this.confirmGroup()) }
        if (!this.groupSelecting && (this.store.findCard(this.selectedId)?.groupId ?? '').length > 0) { Button('取消组合', { type: ButtonType.Capsule }).height(44).fontSize(13).backgroundColor(this.appControl()).fontColor(this.appText()).border({ width: .5, color: AppDesign.border(this.appDark) }).onClick(() => this.releaseGroup()) }
        if (!this.groupSelecting && this.selectedId.length > 0) {
          Row({ space: 12 }) {
            Button('上移一层', { type: ButtonType.Capsule }).fontSize(12).backgroundColor(this.appControl()).fontColor(this.appText()).border({ width: .5, color: AppDesign.border(this.appDark) }).onClick(() => this.moveCardLayer(this.selectedId, true))
            Button('下移一层', { type: ButtonType.Capsule }).fontSize(12).backgroundColor(this.appControl()).fontColor(this.appText()).border({ width: .5, color: AppDesign.border(this.appDark) }).onClick(() => this.moveCardLayer(this.selectedId, false))
            Blank()
            Button('删除', { type: ButtonType.Capsule }).fontSize(12).backgroundColor(Color.Transparent).fontColor('#C43A35').onClick(() => this.deleteCard(this.selectedId))
          }.width('100%')
        }
      }.width(this.panelWidth).height(this.panelHeight - 84).padding(12).backgroundColor(this.appSurface()).borderRadius(AppDesign.sectionRadius).border({ width: 1, color: AppDesign.border(this.appDark) })
        .position({ x: this.panelLeft, y: this.panelTop })
  }
  private backgroundLabel(): string {
    return this.canvasBackground.mode === 'smart' ? '智能取色' : this.canvasBackground.mode === 'blend' ? '智能多色' : this.canvasBackground.mode === 'photo' ? '本地照片' : this.canvasBackground.mode === 'preset' ? '柔色预设' : '纯色';
  }
  private applyBackground(bg: CanvasBackground): void {
    this.backgroundGeneration += 1; this.backgroundBusy = false; this.canvasBackground = bg; this.store.state.background = bg;
    this.persist(true);
  }
  private scheduleBackground(): void {
    if (!['smart','blend'].includes(this.canvasBackground.mode) || !this.ready) return;
    if (this.backgroundTimer >= 0) clearTimeout(this.backgroundTimer);
    this.backgroundTimer = setTimeout(() => { this.backgroundTimer = -1; this.refreshBackground(); }, 450);
  }
  private async refreshBackground(force: boolean = false): Promise<void> {
    if (this.context === null || !['smart','blend'].includes(this.canvasBackground.mode)) return;
    this.store.state.background = this.canvasBackground; this.store.state.canvasAspect = this.canvasAspect;
    const signature = backgroundSignature(this.store.state);
    if (!force && signature === this.canvasBackground.signature) return;
    const generation = ++this.backgroundGeneration; this.backgroundBusy = true;
    const state = new FridgeState(); state.background = this.canvasBackground; state.canvasAspect = this.canvasAspect;
    state.cards = this.store.state.cards.map((card: FridgeCard) => cardRenderSnapshot(card));
    try {
      const json = await taskpool.execute(new taskpool.Task(createSmartBackground, JSON.stringify(state), this.context.filesDir)) as string;
      if (!this.alive || generation !== this.backgroundGeneration) return;
      const next = normalizeBackground(JSON.parse(json) as CanvasBackground); this.applyBackground(next);
    } catch (_) { if (this.alive && generation === this.backgroundGeneration) this.getUIContext().getPromptAction().showToast({ message: '取色未完成，保留原背景，请重试' }); }
    finally { if (generation === this.backgroundGeneration) this.backgroundBusy = false; }
  }
  private chooseBackgroundMode(mode: string): void {
    if (mode === 'photo') { if (this.canvasBackground.photo.length > 0) { this.openBackgroundCrop(this.canvasBackground.photo); } else this.pickBackgroundPhoto(); return; }
    const bg = new CanvasBackground(); bg.mode = mode; bg.color = this.canvasBackground.color; bg.photo = this.canvasBackground.photo;
    this.applyBackground(bg); if (mode === 'smart' || mode === 'blend') this.refreshBackground(true);
  }
  private chooseBackgroundColor(): void {
    this.colorDialog = new CustomDialogController({ builder: ColorSelector({ initialColor: this.canvasBackground.color, onPick: (color: string) => {
      const bg = new CanvasBackground(); bg.color = color || '#FFFFFF'; bg.photo = this.canvasBackground.photo; this.applyBackground(bg);
    } }), customStyle: true, alignment: DialogAlignment.Center, autoCancel: true }); this.colorDialog.open();
  }
  private async pickBackgroundPhoto(): Promise<void> {
    if (this.context === null || this.backgroundBusy) return;
    this.backgroundBusy = true;
    try {
      const options = new photoAccessHelper.PhotoSelectOptions(); options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE; options.maxSelectNumber = 1;
      const result = await new photoAccessHelper.PhotoViewPicker().select(options); if (result.photoUris.length === 0) return;
      const src = await taskpool.execute(new taskpool.Task(importBackgroundPhoto, result.photoUris[0], this.context.filesDir)) as string;
      if (!this.alive) return;
      this.openBackgroundCrop(src);
    } catch (_) { if (this.alive) this.getUIContext().getPromptAction().showToast({ message: '照片未导入，请重试' }); }
    finally { this.backgroundBusy = false; }
  }
  private openBackgroundCrop(src: string): void {
    this.photoCropDialog = new CustomDialogController({ builder: PhotoCrop({ source: src, aspect: this.canvasAspect, appDark: this.appDark,
      onApply: (zoom: number, x: number, y: number) => { this.commitBackgroundCrop(src, zoom, x, y); } }), customStyle: true, autoCancel: false });
    this.photoCropDialog.open();
  }
  private async commitBackgroundCrop(src: string, zoom: number, x: number, y: number): Promise<void> {
    if (this.context === null) return; this.backgroundBusy = true; const generation = ++this.backgroundGeneration;
    try {
      const result = await taskpool.execute(new taskpool.Task(cropBackgroundPhoto, src, this.context.filesDir, this.canvasAspect, zoom, x, y)) as string;
      if (!this.alive || generation !== this.backgroundGeneration) return;
      const bg = new CanvasBackground(); bg.mode = 'photo'; bg.src = result; bg.photo = src; this.applyBackground(bg);
    } catch (_) { if (this.alive) this.getUIContext().getPromptAction().showToast({ message: '照片调整失败，请重试' }); }
    finally { if (generation === this.backgroundGeneration) this.backgroundBusy = false; }
  }
  private setBackgroundPreset(index: number): void {
    const palettes: string[][] = [['#C5B6A3','#83949A','#D5B6A9'],['#9EAF96','#B6B0C5','#D9C9A5'],['#859EB5','#B8C7C2','#C5B7AD']];
    const bg = new CanvasBackground(); bg.mode = 'blend'; bg.color = palettes[index][0];
    // Presets are generated locally by the same blend renderer; no remote photos.
    const state = new FridgeState(); state.canvasAspect = this.canvasAspect; state.background = bg;
    state.cards = palettes[index].map((color: string, i: number) => { const card = new FridgeCard(); card.id = 'preset'+i; card.paper = color; card.x = i === 1 ? 170 : 20; card.y = i === 2 ? 270 : 20; return card; });
    if (this.context === null) return;
    const generation = ++this.backgroundGeneration; this.backgroundBusy = true;
    taskpool.execute(new taskpool.Task(createSmartBackground, JSON.stringify(state), this.context.filesDir)).then((json: Object) => {
      if (!this.alive || generation !== this.backgroundGeneration) return;
      const next = normalizeBackground(JSON.parse(json as string) as CanvasBackground); next.mode = 'preset'; next.photo = this.canvasBackground.photo; this.applyBackground(next);
    }).catch(() => this.getUIContext().getPromptAction().showToast({ message: '预设生成失败' })).finally(() => { if (generation === this.backgroundGeneration) this.backgroundBusy = false; });
  }
  @Builder
  homeBackground() {
    Row({ space: 8 }) {
      Button({ type: ButtonType.ROUNDED_RECTANGLE }) {
        Row({ space: 12 }) {
          CanvasBackdrop({ sceneBackground: this.canvasBackground }).width(40).height(40).borderRadius(10).clip(true).border({ width: .5, color: AppDesign.border(this.appDark) })
          Column({ space: 3 }) { Text('画布背景').fontSize(14).fontColor(this.appText()); Text(this.backgroundBusy ? '正在取色' : this.backgroundLabel()).fontSize(11).fontColor(this.appMuted()) }.alignItems(HorizontalAlign.Start)
          Blank()
        }.width('100%')
      }.height(56).layoutWeight(1).backgroundColor(Color.Transparent).padding(8).onClick(() => { this.backgroundOpen = true; })
        .bindSheet(this.backgroundOpen, this.backgroundEditor, { height: SheetSize.LARGE, showClose: true, backgroundColor: this.appBackground(), onDisappear: () => { this.backgroundOpen = false; } })
      Button(this.sharing ? '生成中' : '系统分享', { type: ButtonType.Capsule }).id('shareCanvas').height(44).fontSize(13).padding({ left: 12, right: 12 })
        .backgroundColor(this.appControl()).fontColor(this.appText()).border({ width: .5, color: AppDesign.border(this.appDark) }).enabled(!this.sharing && !this.backgroundBusy).onClick(() => this.shareArtwork(false))
    }.width(this.panelWidth).height(72).padding(8).borderRadius(AppDesign.sectionRadius).border({ width: 1, color: AppDesign.border(this.appDark) }).backgroundColor(this.appSurface())
      .position({ x: this.panelLeft, y: this.panelTop + this.panelHeight - 72 })
  }
  @Builder
  backgroundEditor() {
    Scroll() {
      Column({ space: 20 }) {
        Text('画布背景').fontSize(22).fontWeight(FontWeight.Medium).fontColor(this.appText()).width('100%')
        Stack({ alignContent: Alignment.TopStart }) {
          CanvasBackdrop({ sceneBackground: this.canvasBackground }).width('100%').height('100%')
          ForEach(this.cards, (card: FridgeCard) => {
            CardFace({ card: card, scaleFactor: 240 / BOARD_W, tick: this.tick })
              .width(card.w * 240 / BOARD_W).height(card.h * 240 / BOARD_W)
              .position({ x: card.x * 240 / BOARD_W, y: card.y * (240 / this.canvasAspect) / BOARD_H })
              .rotate({ angle: card.rot, centerX: 0, centerY: '100%' }).zIndex(card.z)
          }, (card: FridgeCard) => card.id)
        }.width(240).height(240 / this.canvasAspect).borderRadius(20).clip(true)
        Column({ space: 16 }) {
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(['solid','smart','blend','photo'], (mode: string, index: number) => {
              Button(['纯色','智能取色','智能多色','照片'][index], { type: ButtonType.Capsule }).height(44).fontSize(14).margin({ right: 8, bottom: 8 })
                .backgroundColor(Color.Transparent).fontColor(this.appText()).border({ width: this.canvasBackground.mode === mode ? 1.5 : .5, color: AppDesign.border(this.appDark) })
                .enabled(!this.backgroundBusy).onClick(() => this.chooseBackgroundMode(mode))
            }, (mode: string) => mode)
          }.width('100%')
          if (this.canvasBackground.mode === 'solid') {
            Button('自定义颜色', { type: ButtonType.ROUNDED_RECTANGLE }).height(44).width('100%').fontColor(this.appText()).backgroundColor(this.appControl()).borderRadius(12).border({ width: .5, color: AppDesign.border(this.appDark) }).onClick(() => this.chooseBackgroundColor())
            Flex({ wrap: FlexWrap.Wrap }) {
              ForEach(['#FFFFFF','#F1EEE6','#E9E5DF','#E2E8E2','#E3E9EF','#292B2B'], (color: string) => {
                Button({ type: ButtonType.Circle }).width(44).height(44).backgroundColor(color).margin({ right: 8, bottom: 8 })
                  .border({ width: this.canvasBackground.color === color ? 2 : .5, color: this.appMuted() }).accessibilityText('背景色 '+color)
                  .onClick(() => { const bg = new CanvasBackground(); bg.color = color; bg.photo = this.canvasBackground.photo; this.applyBackground(bg); })
              }, (color: string) => color)
            }.width('100%')
          }
          if (this.canvasBackground.mode === 'smart' || this.canvasBackground.mode === 'blend') {
            Text(this.backgroundBusy ? '正在从本地卡片提取颜色' : this.canvasBackground.mode === 'smart' ? '根据全部可见卡片取色，降低饱和度以衬托作品。' : '根据卡片颜色与位置柔和融合，移动结束后自动更新。').fontSize(13).fontColor(this.appMuted()).width('100%')
            Button('重新取色', { type: ButtonType.Capsule }).height(44).fontColor(this.appText()).backgroundColor(this.appControl()).border({ width: .5, color: AppDesign.border(this.appDark) }).enabled(!this.backgroundBusy).onClick(() => this.refreshBackground(true))
          }
          if (this.canvasBackground.mode === 'photo') {
            if (this.canvasBackground.photo.length > 0) { Button('调整照片', { type: ButtonType.Capsule }).height(44).fontColor(this.appText()).backgroundColor(this.appControl()).border({ width: .5, color: AppDesign.border(this.appDark) }).enabled(!this.backgroundBusy).onClick(() => this.openBackgroundCrop(this.canvasBackground.photo)) }
            Button('选择本地照片', { type: ButtonType.ROUNDED_RECTANGLE }).height(44).width('100%').fontColor(this.appText()).backgroundColor(this.appControl()).borderRadius(12).border({ width: .5, color: AppDesign.border(this.appDark) }).enabled(!this.backgroundBusy).onClick(() => this.pickBackgroundPhoto())
            Text('按桌面画布比例拖动、双指缩放后确认；原照片不修改。').fontSize(12).fontColor(this.appMuted()).width('100%')
          }
        }.width('100%').padding(16).borderRadius(20).border({ width: 1, color: AppDesign.border(this.appDark) })
        Column({ space: 16 }) {
          Text('柔色预设').fontSize(16).fontColor(this.appText()).width('100%')
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(['雾沙','庭院','海盐'], (name: string, index: number) => {
              Button(name, { type: ButtonType.Capsule }).height(44).fontColor(this.appText()).backgroundColor(Color.Transparent).margin({ right: 8 }).border({ width: .5, color: AppDesign.border(this.appDark) }).enabled(!this.backgroundBusy).onClick(() => this.setBackgroundPreset(index))
            }, (name: string) => name)
          }.width('100%')
        }.width('100%').padding(16).borderRadius(20).border({ width: 1, color: AppDesign.border(this.appDark) })
      }.width('100%').constraintSize({ maxWidth: 640 }).padding({ top: 24, left: 20, right: 20, bottom: this.safeBottom + 24 })
    }.width('100%').height('100%').align(Alignment.Top).scrollBar(BarState.Off)
  }
  private shareCards: FridgeCard[] = [];
  private shareSingle: boolean = false;
  private shareOpaque: boolean = false;
  private shareWidth: number = 344;
  private shareHeight: number = 344;
  private shareX: number = 0;
  private shareY: number = 0;
  private shareTick: number = 0;
  private shareBackground: CanvasBackground = new CanvasBackground();
  @Builder
  shareScene() {
    Stack({ alignContent: Alignment.TopStart }) {
      if (!this.shareSingle) { CanvasBackdrop({ sceneBackground: this.shareBackground }).width('100%').height('100%') }
      ForEach(this.shareCards, (card: FridgeCard) => {
        CardFace({ card: card, scaleFactor: 1, tick: this.shareTick, widget: true })
          .width(card.w).height(card.h)
          .position({ x: this.shareSingle ? this.shareX : card.x, y: this.shareSingle ? this.shareY : card.y * this.shareHeight / BOARD_H })
          .rotate({ angle: card.rot, centerX: 0, centerY: '100%' }).zIndex(card.z)
      }, (card: FridgeCard) => card.id)
    }.width(this.shareWidth).height(this.shareHeight).backgroundColor(this.shareOpaque ? Color.White : Color.Transparent).clip(true)
  }
  private async shareArtwork(single: boolean): Promise<void> {
    if (this.context === null || this.sharing || this.heroActive || this.arriving) return;
    try {
      const result = await this.getUIContext().getPromptAction().showActionMenu({ title: single ? '分享卡片图片' : '分享画布图片', buttons: [
        { text: single ? '透明 PNG' : 'PNG', color: this.appText() }, { text: '实色底 JPG', color: this.appText() }
      ] });
      this.sharing = true; this.shareSingle = single; this.shareOpaque = result.index === 1; this.shareTick = Date.now(); this.shareBackground = normalizeBackground(JSON.parse(JSON.stringify(this.canvasBackground)) as CanvasBackground);
      const card = this.current(); if (single && card === null) return;
      this.shareCards = (single ? [card!] : this.store.state.cards).map((item: FridgeCard) => cardRenderSnapshot(item)).sort((a: FridgeCard,b: FridgeCard) => a.z-b.z);
      if (single) {
        const a = card!.rot * Math.PI / 180, c = Math.cos(a), s = Math.sin(a), w = card!.w, h = card!.h;
        const xs = [0,h*s,w*c+h*s,w*c], ys = [h,h-h*c,h+w*s-h*c,h+w*s];
        this.shareX = 24-Math.min(...xs); this.shareY = 24-Math.min(...ys);
        this.shareWidth = Math.max(...xs)-Math.min(...xs)+48; this.shareHeight = Math.max(...ys)-Math.min(...ys)+48;
      } else { this.shareWidth = BOARD_W; this.shareHeight = BOARD_W/this.canvasAspect; }
      const scale = Math.min(3, 1280/this.getUIContext().vp2px(Math.max(this.shareWidth,this.shareHeight)));
      const pixel = await this.getUIContext().getComponentSnapshot().createFromBuilder(() => { this.shareScene(); }, 350, true, { scale: scale, waitUntilRenderFinished: true });
      try { await sharePixelMap(this.context as common.UIAbilityContext, pixel, this.shareOpaque, single ? 'shareCard' : 'shareCanvas'); }
      finally { await pixel.release(); }
    } catch (e) {
      // Action-menu cancellation has no message; actual export errors are actionable.
      
      if (this.sharing) this.getUIContext().getPromptAction().showToast({ message: '图片导出或分享未完成，请重试' });
    } finally { this.sharing = false; }
  }
  @Builder
  detail() {
    Column({ space: 20 }) {
      HdsNavigation() {
      Scroll(this.detailScroller) {
        Column({ space: 20 }) {
          Text(this.preview.capability?.title || typeLabel(this.preview.capability?.k ?? '')).fontSize(20).fontColor(this.appText()).fontWeight(FontWeight.Medium)
          if (this.preview.capability !== null) {
            CapabilityView({ cap: this.preview.capability!, ink: this.appText(), contentWidth: 280, contentHeight: 280, tick: this.tick })
              .width(280).height(280)
          }
          if (this.preview.capability?.k === 'calendar') {
            Row({ space: 12 }) {
              Button('上月', { type: ButtonType.Capsule }).fontSize(14).backgroundColor(this.appControl()).fontColor(this.appText()).border({ width: .5, color: AppDesign.border(this.appDark) }).onClick(() => this.calendarAction('previousMonth'))
              Button('本月', { type: ButtonType.Capsule }).fontSize(14).backgroundColor(this.appControl()).fontColor(this.appText()).border({ width: .5, color: AppDesign.border(this.appDark) }).onClick(() => this.calendarAction('currentMonth'))
              Button('下月', { type: ButtonType.Capsule }).fontSize(14).backgroundColor(this.appControl()).fontColor(this.appText()).border({ width: .5, color: AppDesign.border(this.appDark) }).onClick(() => this.calendarAction('nextMonth'))
            }
          }
          if (this.preview.capability?.k === 'weather') {
            Text(this.preview.capability!.updatedAt ? '更新于 ' + new Date(this.preview.capability!.updatedAt!).toLocaleString() : '尚无更新记录')
              .fontSize(12).fontColor(this.appMuted())
            Button(this.weatherBusy ? '更新中' : '刷新天气', { type: ButtonType.ROUNDED_RECTANGLE }).backgroundColor(Color.Transparent).fontColor(this.appText()).border({ width: .5, color: this.appMuted() }).enabled(!this.weatherBusy).onClick(() => this.refreshWeather())
          }
          CardFace({ card: this.preview, scaleFactor: this.editorScale(), tick: this.tick })
            .rotate({ angle: this.preview.rot, centerX: 0, centerY: '100%' }).width(this.preview.w * this.editorScale()).height(this.preview.h * this.editorScale())
        }.width('100%').padding({ bottom: 24 })
      }.width('100%').height('100%').align(Alignment.Top).padding({ top: 76, left: 24, right: 24, bottom: this.safeBottom + 8 })
      }.titleMode(HdsNavigationTitleMode.MINI)
        .titleBar({
          content: {
            backIcon: { label: '关闭', type: TextStyleMode.NORMAL, action: () => { this.viewing = false; this.selectedId = ''; } },
            menu: { maxCount: 1, value: [
              { content: { label: '编辑卡片', type: TextStyleMode.NORMAL, action: () => { const id = this.selectedId; this.viewing = false; this.openEditor(id); } } }
            ] }
          },
          style: {
            blurStrategy: BlurStrategy.ADAPTIVE, thermoCtrl: true,
            scrollEffectOpts: { enableScrollEffect: true, scrollEffectType: ScrollEffectType.IMMERSIVE_GRADIENT_BLUR },
            scrollEffectStyle: { contentStyle: { menuStyle: { textColor: this.appText(), iconColor: this.appText() }, backIconStyle: { textColor: this.appText(), iconColor: this.appText() } }, backgroundStyle: { backgroundColor: Color.Transparent, maskExtraHeight: 0, blurRadius: 16 } },
            systemMaterialEffect: { materialType: hdsMaterial.MaterialType.IMMERSIVE, materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE },
            originalStyle: { contentStyle: { menuStyle: { textColor: this.appText(), iconColor: this.appText() }, backIconStyle: { textColor: this.appText(), iconColor: this.appText() } }, backgroundStyle: { backgroundColor: Color.Transparent, maskExtraHeight: 0, blurRadius: 16 } }
          }
        })
        .bindToScrollable([this.detailScroller]).hideBackButton(false).hideToolBar(true).mode(NavigationMode.Stack).width('100%').height('100%').backgroundColor(Color.Transparent)
    }.width('100%').height('100%').padding({ top: this.safeTop + 4 })
      .backgroundColor(this.appSurface()).zIndex(160000)
  }
  @Builder
  editor() {
    Column() {
      HdsNavigation() {
        Column() {
          if (this.editorLandscape()) {
            Row() {
              Column({ space: 12 }) {
                this.canvasEditor()
                this.editorLayers()
              }.width(this.editorViewportWidth()).height('100%')
              Column() { this.editorControls(); this.editorInspector() }.layoutWeight(1).height('100%')
            }.width('100%').layoutWeight(1)
          } else {
            Row({ space: 8 }) {
              Column() { this.canvasEditor() }.width(this.editorViewportWidth()).height(this.previewPaneHeight())
              Column() { this.editorLayers() }.layoutWeight(1).height(this.previewPaneHeight())
            }.width('100%').height(this.previewPaneHeight())
            this.editorControls(); this.editorInspector()
          }
        }.width('100%').height('100%').padding({ top: 56 }).backgroundColor(Color.Transparent)
      }.titleMode(HdsNavigationTitleMode.MINI)
        .titleBar({
          content: {
            backIcon: { label: '撤销', type: TextStyleMode.NORMAL, isEnabled: this.undoAvailable && !this.heroActive, action: () => this.restoreHistory(false) },
            menu: { maxCount: 3, value: [
              { content: { label: '添加', type: TextStyleMode.NORMAL, isEnabled: !this.heroActive, action: () => this.showAddMenu() } },
              { content: { label: '重做', type: TextStyleMode.NORMAL, isEnabled: this.redoAvailable && !this.heroActive, action: () => this.restoreHistory(true) } },
              { content: { label: '完成', type: TextStyleMode.NORMAL, isEnabled: !this.heroActive, action: () => this.closeEditor() } }
            ] }
          },
          style: {
            blurStrategy: BlurStrategy.ADAPTIVE, thermoCtrl: true,
            scrollEffectOpts: { enableScrollEffect: true, scrollEffectType: ScrollEffectType.IMMERSIVE_GRADIENT_BLUR },
            scrollEffectStyle: { contentStyle: { menuStyle: { textColor: this.appText(), iconColor: this.appText() }, backIconStyle: { textColor: this.appText(), iconColor: this.appText() } }, backgroundStyle: { backgroundColor: Color.Transparent, maskExtraHeight: 0, blurRadius: 16 } },
            systemMaterialEffect: { materialType: hdsMaterial.MaterialType.IMMERSIVE, materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE },
            originalStyle: { contentStyle: { menuStyle: { textColor: this.appText(), iconColor: this.appText() }, backIconStyle: { textColor: this.appText(), iconColor: this.appText() } }, backgroundStyle: { backgroundColor: Color.Transparent, maskExtraHeight: 0, blurRadius: 16 } }
          }
        })
        .bindToScrollable([this.scroller]).hideBackButton(false).hideToolBar(true).mode(NavigationMode.Stack).width('100%').height('100%').backgroundColor(Color.Transparent)
    }.width('100%').height('100%').padding({ top: this.safeTop + 4 }).opacity(this.editorOpacity)
      .hitTestBehavior(!this.editing || this.heroActive ? HitTestMode.None : HitTestMode.Default)
      .visibility(this.editing ? Visibility.Visible : Visibility.Hidden)
      .accessibilityLevel(this.editing ? 'yes' : 'no-hide-descendants')
  }
  private showAddMenu(): void {
    this.getUIContext().getPromptAction().showActionMenu({ title: '添加到当前图层', buttons: [
      { text: '文字', color: this.appText() }, { text: '本地图片 / GIF', color: this.appText() }, { text: '形状', color: this.appText() }
    ] }).then((result) => { if (this.alive && this.editing) this.addElement(['text', 'image', 'shape'][result.index]); }).catch(() => {});
  }
  private editorControlsWidth(): number {
    return (this.editorLandscape() ? this.screenWidth - this.editorViewportWidth() : this.screenWidth) - 32;
  }
  private editorTabChanged(): void {
    this.settingsTab = this.editorTabs[0] ?? 0;
    this.layerId = this.settingsTab === 0 ? (this.preview.elements.find((el: CanvasElement) => el.behindCapability)?.id ?? '') : 'capability'; this.showLayerOptions = false; this.syncFields();
    this.scroller.scrollTo({ xOffset: 0, yOffset: 0 });
  }
  @Builder
  editorControls() {
    Row({ space: 20 }) {
      Button('背景创作', { type: ButtonType.Capsule }).height(AppDesign.controlHeight).fontSize(15).backgroundColor(Color.Transparent).fontColor(this.appText())
        .fontWeight(this.settingsTab === 0 ? FontWeight.Medium : FontWeight.Normal)
        .border({ width: this.settingsTab === 0 ? 1.5 : .5, color: AppDesign.border(this.appDark) })
        .onClick(() => { this.editorTabs = [0]; })
      Button('上层内容', { type: ButtonType.Capsule }).height(AppDesign.controlHeight).fontSize(15).backgroundColor(Color.Transparent).fontColor(this.appText())
        .fontWeight(this.settingsTab === 1 ? FontWeight.Medium : FontWeight.Normal)
        .border({ width: this.settingsTab === 1 ? 1.5 : .5, color: AppDesign.border(this.appDark) })
        .onClick(() => { this.editorTabs = [1]; })
      Blank()
    }.width(this.editorControlsWidth()).margin({ top: 4, bottom: 8 })
  }
  @Builder
  editorLayers() {
    Column({ space: 8 }) { this.layersPanel() }
      .width(this.editorLandscape() ? this.editorViewportWidth() - 32 : this.screenWidth - this.editorViewportWidth() - 24)
      .height(this.editorLandscape() ? Math.min(148, this.editorBodyHeight() - this.previewPaneHeight() - 16) : this.previewPaneHeight() - 12).padding(12).backgroundColor(this.appSurface()).borderRadius(AppDesign.sectionRadius)
      .border({ width: 1, color: AppDesign.border(this.appDark) }).clip(true)
      .margin({ left: this.editorLandscape() ? 16 : 0, right: 16, bottom: 12 })
  }
  @Builder
  editorInspector() {
      Scroll(this.scroller) {
        Column({ space: 12 }) {
          if (this.layerId.length > 0) {
            this.elementFields()
          }
          if (this.settingsTab === 0 && this.layerId.length === 0) {
            Column({ space: 16 }) {
              Text('底板').fontSize(16).fontWeight(FontWeight.Medium).fontColor(this.appText()).width('100%')
            Row({ space: 8 }) {
              Button('底色', { type: ButtonType.ROUNDED_RECTANGLE }).layoutWeight(1).height(AppDesign.controlHeight).fontSize(14).fontColor(this.appText()).backgroundColor(this.appControl()).borderRadius(12).border({ width: .5, color: AppDesign.border(this.appDark) }).onClick(() => this.chooseColor('paper'))
              Button(this.showBackgroundOptions ? '收起底板设置' : '底板形状与边缘', { type: ButtonType.ROUNDED_RECTANGLE }).layoutWeight(2).height(AppDesign.controlHeight).fontSize(14).fontColor(this.appText()).backgroundColor(this.appControl()).borderRadius(12).border({ width: .5, color: AppDesign.border(this.appDark) })
                .onClick(() => { this.getUIContext().animateTo({ duration: 180, curve: Curve.EaseOut, expectedFrameRateRange: this.frameRate }, () => { this.showBackgroundOptions = !this.showBackgroundOptions; }); })
            }.width('100%')
            if (this.showBackgroundOptions) { this.appearancePanel() }
            }.width('100%').padding(16).backgroundColor(this.appSurface()).borderRadius(AppDesign.sectionRadius).border({ width: 1, color: AppDesign.border(this.appDark) }).clip(true)
          } else if (this.settingsTab === 1) {
            Column({ space: 16 }) { this.capabilityPanel() }.width('100%').padding(16).backgroundColor(this.appSurface()).borderRadius(AppDesign.sectionRadius).border({ width: 1, color: AppDesign.border(this.appDark) }).clip(true)
            Column() { this.colorRow('内容默认颜色', 'ink', this.inkValue) }.width('100%').padding(16).backgroundColor(this.appSurface()).borderRadius(AppDesign.sectionRadius).border({ width: 1, color: AppDesign.border(this.appDark) }).clip(true)
          }
          if (this.settingsTab === 1 && this.preview.capability !== null && capabilityBox(this.preview).w === 0) { Text('内容空间不足，请调整文字大小或位置').fontSize(12).fontColor('#846339').width('100%') }
          Button(this.sharing ? '生成中' : '系统分享', { type: ButtonType.Capsule }).id('shareCard').height(44).width('100%').fontSize(14).fontColor(this.appText()).backgroundColor(Color.Transparent).border({ width: .5, color: AppDesign.border(this.appDark) }).enabled(!this.sharing && !this.heroActive).onClick(() => this.shareArtwork(true))
          Button('复制卡片', { type: ButtonType.ROUNDED_RECTANGLE }).height(AppDesign.controlHeight).borderRadius(AppDesign.controlRadius).fontSize(14).width('100%').fontColor(this.appText()).backgroundColor(this.appControl()).border({ width: .5, color: AppDesign.border(this.appDark) }).onClick(() => this.duplicate())
        }.width('100%').padding({ left: 16, right: 16, top: 4, bottom: this.safeBottom + 16 })
      }.width('100%').layoutWeight(1).scrollable(ScrollDirection.Vertical).align(Alignment.Top).scrollBar(BarState.Off).backgroundColor(this.appPanel()).renderGroup(this.heroActive)
        .onAppear(() => this.scroller.scrollTo({ xOffset: 0, yOffset: 0 }))
  }
  private editorCanvasHeight(): number { return this.previewViewport().height; }
  private selectionGeometry(): SelectionHandles {
    return selectionHandles(this.touchBox(this.layerId), this.preview.w * this.editorScale(), this.preview.h * this.editorScale(),
      this.editingAngle(), this.editorViewportWidth(), this.editorCanvasHeight(), this.previewViewport().left, this.previewViewport().top);
  }
  private editorHandle(resize: boolean): ShapePoint { const handles = this.selectionGeometry(); return resize ? handles.resize : handles.rotate; }
  @Builder
  canvasEditor() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column().width('100%').height('100%').backgroundColor(Color.Transparent).onClick(() => { this.layerId = ''; this.syncFields(); })
      Stack({ alignContent: Alignment.TopStart }) {
        ForEach(this.preview.elements.filter((el: CanvasElement) => el.behindCapability && this.settingsTab === 0), (el: CanvasElement) => { this.layerTouch(el.id) }, (el: CanvasElement) => el.id)
        if (this.settingsTab === 1 && this.preview.capability !== null) { this.layerTouch('capability') }
        ForEach(this.preview.elements.filter((el: CanvasElement) => !el.behindCapability && this.settingsTab === 1), (el: CanvasElement) => { this.layerTouch(el.id) }, (el: CanvasElement) => el.id)
      }.width(this.preview.w * this.editorScale()).height(this.preview.h * this.editorScale())
        .rotate({ angle: this.editingAngle(), centerX: 0, centerY: '100%' })
        .position({ x: this.previewViewport().left, y: this.previewViewport().top })
      
      if (this.layerId.length > 0 && this.layerDrag.length === 0) {
        Button('↘', { type: ButtonType.Circle }).width(44).height(AppDesign.controlHeight).fontSize(18).backgroundColor(Color.Transparent).backgroundBlurStyle(BlurStyle.Regular).fontColor(this.appText())
          .border({ width: 1, color: '#B8B8B8' }).position({ x: this.editorHandle(true).x - 22, y: this.editorHandle(true).y - 22 })
          .accessibilityText('缩放选中元素')
          .gesture(PanGesture({ distance: 2 }).onActionStart((e: GestureEvent) => this.startTransform(this.layerId, e)).onActionUpdate((e: GestureEvent) => this.resizeElement(e))
            .onActionEnd((e: GestureEvent) => { this.resizeElement(e); this.flushPreview(); }).onActionCancel(() => this.cancelTransform()))
        if (this.layerId !== 'capability') {
          Button('↻', { type: ButtonType.Circle }).width(44).height(AppDesign.controlHeight).fontSize(18).backgroundColor(Color.Transparent).backgroundBlurStyle(BlurStyle.Regular).fontColor(this.appText())
            .border({ width: 1, color: '#B8B8B8' }).position({ x: this.editorHandle(false).x - 22, y: this.editorHandle(false).y - 22 })
            .accessibilityText('旋转选中元素')
            .gesture(PanGesture({ distance: 2 }).onActionStart((e: GestureEvent) => this.startTransform(this.layerId, e)).onActionUpdate((e: GestureEvent) => this.rotateElement(e))
              .onActionEnd((e: GestureEvent) => { this.rotateElement(e); this.flushPreview(); }).onActionCancel(() => this.cancelTransform()))
        }
      }
      if (this.layerId.length === 0) { this.wholeCardControls() }
    }.width('100%').height(this.editorCanvasHeight())

  }
  private wholeCardHandle(right: boolean, bottom: boolean): ShapePoint {
    const v = this.previewViewport(), w = this.preview.w * this.editorScale(), h = this.preview.h * this.editorScale(), a = this.editingAngle() * Math.PI / 180;
    const unrotated: ShapePoint[] = [{x:0,y:-h},{x:w,y:-h},{x:w,y:0},{x:0,y:0}];
    const corners: ShapePoint[] = unrotated.map((p:ShapePoint):ShapePoint=>({x:v.left+p.x*Math.cos(a)-p.y*Math.sin(a),y:v.top+h+p.x*Math.sin(a)+p.y*Math.cos(a)}));
    const xs=corners.map((p:ShapePoint)=>p.x),ys=corners.map((p:ShapePoint)=>p.y),left=Math.min(...xs),top=Math.min(...ys),rightEdge=Math.max(...xs),bottomEdge=Math.max(...ys);
    const cx=(left+rightEdge)/2,cy=(top+bottomEdge)/2,rx=Math.max(28,(rightEdge-left)/2+12),ry=Math.max(28,(bottomEdge-top)/2+12);
    return {x:Math.max(22,Math.min(this.editorViewportWidth()-22,cx+(right?rx:-rx))),y:Math.max(22,Math.min(this.editorCanvasHeight()-22,cy+(bottom?ry:-ry)))};
  }
  @Builder
  wholeCardControls() {
    Button('×', { type: ButtonType.Circle }).width(44).height(44).fontSize(24).fontColor('#D3423C').backgroundColor(this.appSurface())
      .position({ x: this.wholeCardHandle(false, false).x - 22, y: this.wholeCardHandle(false, false).y - 22 }).accessibilityText('删除整张卡片').onClick(() => this.deleteCard(this.selectedId))
    Button('↗', { type: ButtonType.Circle }).width(44).height(44).fontSize(22).fontColor(this.appText()).backgroundColor(this.appSurface())
      .position({ x: this.wholeCardHandle(true, false).x - 22, y: this.wholeCardHandle(true, false).y - 22 }).accessibilityText('缩放整张卡片')
      .gesture(PanGesture({ distance: 2 }).onActionStart(() => { const c = this.current(); if (c !== null) { this.outerResizeW = c.w; this.outerResizeH = c.h; this.outerResizeY = c.y; } })
        .onActionUpdate((e: GestureEvent) => this.resizeOuterCard(e)).onActionEnd(() => this.flushPreview()).onActionCancel(() => { const c = this.current(); if (c !== null) { c.w = this.outerResizeW; c.h = this.outerResizeH; c.y = this.outerResizeY; } this.flushPreview(); }))
    Button('编辑', { type: ButtonType.Circle }).width(44).height(44).fontSize(11).fontColor(this.appText()).backgroundColor(this.appSurface())
      .position({ x: this.wholeCardHandle(true, true).x - 22, y: this.wholeCardHandle(true, true).y - 22 }).accessibilityText('编辑上层内容').onClick(() => { this.settingsTab = 1; this.chooseLayer('capability'); })
    Button('↻', { type: ButtonType.Circle }).width(44).height(44).fontSize(22).fontColor(this.appText()).backgroundColor(this.appSurface())
      .position({ x: this.wholeCardHandle(false, true).x - 22, y: this.wholeCardHandle(false, true).y - 22 }).accessibilityText('旋转整张卡片')
      .onClick(() => { const c = this.current(); if (c !== null) { c.rot = 0; this.change(); } })
      .gesture(PanGesture({ distance: 2 }).onActionStart((e: GestureEvent) => { this.beginFinger(e, 0); const c = this.current(); if (c !== null) { this.rotateStart = c.rot; this.rotationViewport = this.previewViewport(); this.cardRotating = true; } })
        .onActionUpdate((e: GestureEvent) => this.rotateOuterCard(e)).onActionEnd((e: GestureEvent) => { this.rotateOuterCard(e); this.finishCardRotation(false); }).onActionCancel(() => this.finishCardRotation(true)))
  }
  private resizeOuterCard(e: GestureEvent): void {
    const c = this.current(); if (c === null || this.outerResizeW <= 0) return;
    const a = c.rot * Math.PI / 180, dx = (e.offsetX * Math.cos(a) + e.offsetY * Math.sin(a)) / this.editorScale(), dy = (-e.offsetX * Math.sin(a) + e.offsetY * Math.cos(a)) / this.editorScale();
    const min = minimumCardSize(c), f = Math.max(min.w / this.outerResizeW, min.h / this.outerResizeH, Math.min(320 / this.outerResizeW, 420 / this.outerResizeH, 1 + (dx * this.outerResizeW - dy * this.outerResizeH) / (this.outerResizeW ** 2 + this.outerResizeH ** 2)));
    c.w = this.outerResizeW * f; c.h = this.outerResizeH * f; c.y = this.outerResizeY + this.outerResizeH - c.h; this.continuousChange(SliderChangeMode.Moving);
  }
  private rotateOuterCard(e: GestureEvent): void {
    const card = this.current(); if (card === null || !this.cardRotating) return;
    const offset = this.fingerOffset(e); const raw = this.rotateStart + offset.x * .65 - offset.y * .35;
    const value = ((raw + 180) % 360 + 360) % 360 - 180;
    card.rot = Math.abs(value - Math.round(value / 15) * 15) < 2 ? Math.round(value / 15) * 15 : value;
    this.continuousChange(SliderChangeMode.Moving);
  }
  private finishCardRotation(cancelled: boolean): void {
    if (!this.cardRotating) return;
    const card = this.current(); if (cancelled && card !== null) card.rot = this.rotateStart;
    this.cardRotating = false; this.flushPreview();
  }
  private elementTouchBox(element: CanvasElement): ElementBox {
    const f = subjectSurfaceFactor(this.preview), inset = (1 - f) / 2;
    const box = new ElementBox(); box.x = inset + element.x * f; box.y = inset + element.y * f;
    box.w = element.w * f; box.h = element.h * f; box.rot = element.rot; return box;
  }
  private finishLayerDrag(cancelled: boolean = false): void {
    if (cancelled) { const box = this.currentBox(); if (box !== null) { box.x = this.layerStartX; box.y = this.layerStartY; } }
    this.layerDrag = ''; this.layerDX = 0; this.layerDY = 0; this.syncFields(); this.change(); this.gestureGroup = '';
  }
  private beginFinger(e: GestureEvent, degrees: number): void {
    if (this.saveTimer >= 0) clearTimeout(this.saveTimer); this.saveTimer = -1;
    this.gestureGroup = 'gesture_' + Date.now();
    const point = e.fingerList[0]; this.hasGlobalFinger = point !== undefined;
    const angle = degrees * Math.PI / 180;
    this.fingerStartX = (point?.displayX ?? 0) - (e.offsetX * Math.cos(angle) - e.offsetY * Math.sin(angle));
    this.fingerStartY = (point?.displayY ?? 0) - (e.offsetX * Math.sin(angle) + e.offsetY * Math.cos(angle));
    this.fingerLastX = 0; this.fingerLastY = 0;
  }
  private fingerOffset(e: GestureEvent): ShapePoint {
    const point = e.fingerList[0];
    if (this.hasGlobalFinger && point !== undefined) {
      this.fingerLastX = point.displayX - this.fingerStartX; this.fingerLastY = point.displayY - this.fingerStartY;
    }
    return { x: this.hasGlobalFinger ? this.fingerLastX : e.offsetX, y: this.hasGlobalFinger ? this.fingerLastY : e.offsetY };
  }
  private startTransform(id: string, e: GestureEvent): void {
    this.layerId = id; this.beginFinger(e, 0);
    const card = this.current();
    if (id === 'capability' && card !== null) card.capBox = JSON.parse(JSON.stringify(capabilityPlacement(card))) as ElementBox;
    const box = this.currentBox(); if (box === null) return;
    this.resizeStart = JSON.parse(JSON.stringify(box)) as ElementBox;
    this.rotateStart = box.rot;
    const geometry = this.selectionGeometry();
    this.rotationVector = { x: geometry.rotate.x - geometry.pivot.x, y: geometry.rotate.y - geometry.pivot.y };
  }
  private resizeElement(e: GestureEvent): void {
    const box = this.currentBox(); if (box === null) return;
    const f = this.layerId === 'capability' ? 1 : subjectSurfaceFactor(this.preview);
    const w = this.preview.w * this.editorScale() * f, h = this.preview.h * this.editorScale() * f;
    const angle = (this.editingAngle() + this.resizeStart.rot) * Math.PI / 180;
    const offset = this.fingerOffset(e);
    const dx = offset.x * Math.cos(angle) + offset.y * Math.sin(angle);
    const dy = -offset.x * Math.sin(angle) + offset.y * Math.cos(angle);
    let nextW = this.resizeStart.w + dx / w, nextH = this.resizeStart.h + dy / h;
    if (this.currentElement()?.kind === 'image') {
      const factor = Math.max(.05, (nextW / this.resizeStart.w + nextH / this.resizeStart.h) / 2);
      nextW = this.resizeStart.w * factor; nextH = this.resizeStart.h * factor;
    }
    const min = capabilityMinimum(this.preview.capability, true);
    const minW = this.layerId === 'capability' ? min.w / this.preview.w : .04;
    const minH = this.layerId === 'capability' ? min.h / this.preview.h : .04;
    if (this.currentElement()?.kind === 'image') {
      const minFactor = Math.max(.04 / this.resizeStart.w, .04 / this.resizeStart.h);
      const factor = Math.max(minFactor, Math.min(nextW / this.resizeStart.w, (1 - this.resizeStart.x) / this.resizeStart.w, (1 - this.resizeStart.y) / this.resizeStart.h));
      box.w = this.resizeStart.w * factor; box.h = this.resizeStart.h * factor;
    } else {
      box.w = Math.max(minW, Math.min(1 - box.x, nextW)); box.h = Math.max(minH, Math.min(1 - box.y, nextH));
    }
    // Keep the opposite corner still when resizing a rotated element.
    const local = this.resizeStart.rot * Math.PI / 180, c = Math.cos(local), sn = Math.sin(local);
    const dw = (this.resizeStart.w - box.w) * w, dh = (this.resizeStart.h - box.h) * h;
    box.x = Math.max(0, Math.min(1 - box.w, this.resizeStart.x + (dw * (1 - c) + dh * sn) / (2 * w)));
    box.y = Math.max(0, Math.min(1 - box.h, this.resizeStart.y + (dh * (1 - c) - dw * sn) / (2 * h)));
    this.continuousChange(SliderChangeMode.Moving);
  }
  private rotateElement(e: GestureEvent): void {
    const live = this.currentBox(); if (live === null) return;
    const offset = this.fingerOffset(e);
    let delta = Math.atan2(this.rotationVector.y + offset.y, this.rotationVector.x + offset.x) - Math.atan2(this.rotationVector.y, this.rotationVector.x);
    if (delta > Math.PI) delta -= 2 * Math.PI; if (delta < -Math.PI) delta += 2 * Math.PI;
    const value = this.rotateStart + delta * 180 / Math.PI;
    live.rot = Math.abs(value - Math.round(value / 15) * 15) < 3 ? Math.round(value / 15) * 15 : value;
    this.continuousChange(SliderChangeMode.Moving);
  }
  private moveElement(e: GestureEvent): void {
    const live = this.currentBox(); if (live === null) return;
    const f = this.layerId === 'capability' ? 1 : subjectSurfaceFactor(this.preview);
    const width = this.preview.w * this.editorScale() * f, height = this.preview.h * this.editorScale() * f;
    const angle = this.editingAngle() * Math.PI / 180;
    const offset = this.fingerOffset(e);
    const dx = offset.x * Math.cos(angle) + offset.y * Math.sin(angle), dy = -offset.x * Math.sin(angle) + offset.y * Math.cos(angle);
    live.x = Math.max(0, Math.min(1 - live.w, this.layerStartX + dx / width));
    live.y = Math.max(0, Math.min(1 - live.h, this.layerStartY + dy / height));
    const centerX = (1 - live.w) / 2, centerY = (1 - live.h) / 2;
    if (Math.abs(live.x - centerX) * width < 5) live.x = centerX;
    if (Math.abs(live.y - centerY) * height < 5) live.y = centerY;
    this.layerDX = (live.x - this.layerStartX) * width; this.layerDY = (live.y - this.layerStartY) * height;
  }
  private cancelTransform(): void {
    const box = this.currentBox(); if (box !== null) { box.x = this.resizeStart.x; box.y = this.resizeStart.y; box.w = this.resizeStart.w; box.h = this.resizeStart.h; box.rot = this.resizeStart.rot; }
    this.flushPreview();
  }
  private touchBox(id: string): ElementBox {
    if (id === 'capability') return capabilityPlacement(this.preview);
    return this.elementTouchBox(this.preview.elements.find((el: CanvasElement) => el.id === id) ?? new CanvasElement());
  }
  @Builder
  layerTouch(id: string) {
    Stack() {
      Column().width('100%').height('100%').hitTestBehavior(HitTestMode.None)
    }.width((this.touchBox(id).w * 100) + '%').height((this.touchBox(id).h * 100) + '%')
      .position({ x: (this.touchBox(id).x * 100) + '%', y: (this.touchBox(id).y * 100) + '%' })
      .border({ width: this.layerId === id ? 1 : 0, color: '#7A7A7A' })
      .translate({ x: this.layerDrag === id ? this.layerDX : 0, y: this.layerDrag === id ? this.layerDY : 0 })
      .rotate({ angle: this.touchBox(id).rot }).zIndex(this.layerId === id ? 10000 : 0)
      .onClick(() => { this.layerId = id; this.syncFields(); })
      .gesture(PanGesture({ distance: 3 }).onActionStart((e: GestureEvent) => {
        this.layerId = id; this.beginFinger(e, this.editingAngle() + (this.currentBox()?.rot ?? 0)); this.layerDrag = id; const card = this.current();
        if (id === 'capability' && card !== null) card.capBox = JSON.parse(JSON.stringify(capabilityPlacement(card))) as ElementBox;
        const live = this.currentBox(); this.layerStartX = live?.x ?? 0; this.layerStartY = live?.y ?? 0; this.syncFields();
      }).onActionUpdate((e: GestureEvent) => this.moveElement(e)).onActionEnd((e: GestureEvent) => { this.moveElement(e); this.finishLayerDrag(); }).onActionCancel(() => this.finishLayerDrag(true)))
  }
  private chooseLayer(id: string): void {
    this.layerId = id; this.showLayerOptions = false; this.showBackgroundOptions = id.length === 0;
    this.syncFields(); this.scroller.scrollTo({ xOffset: 0, yOffset: 0 });
  }
  private layerElement(id: string): CanvasElement | null { return this.preview.elements.find((el: CanvasElement) => el.id === id) ?? null; }
  @Builder
  layerEntry(id: string, label: string) {
    Button({ type: ButtonType.ROUNDED_RECTANGLE }) {
      Column({ space: 6 }) {
        Stack() {
          if (id.length === 0) {
            if (this.preview.shape === 'subject' && this.preview.subjectPhoto && this.preview.cutout.length > 0) {
              Image(this.preview.cutout).width(AppDesign.controlHeight).height(AppDesign.controlHeight).objectFit(ImageFit.Contain).draggable(false)
            } else {
              Column().width(32).height(32).borderRadius(8).backgroundColor(materialColors(this.preview.material, this.preview.paper, this.preview.ink)[0]).border({ width: .5, color: '#999999' })
            }
          } else if (this.layerElement(id)?.kind === 'image') {
            Image(this.layerElement(id)?.src ?? '').width(AppDesign.controlHeight).height(AppDesign.controlHeight).objectFit(ImageFit.Contain).draggable(false)
          } else if (this.layerElement(id)?.kind === 'shape') {
            Column().width(28).height(this.layerElement(id)?.primitive === 'line' ? 3 : 28).borderRadius(this.layerElement(id)?.primitive === 'circle' ? 14 : 4).backgroundColor(this.layerElement(id)?.color || this.appText())
          } else {
            Text(id === 'capability' ? 'Aa' : 'A').fontSize(15).fontColor(this.appText()).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
          }
        }.width(44).height(AppDesign.controlHeight).hitTestBehavior(HitTestMode.None)
        Text(label).fontSize(12).fontColor(this.appText()).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
      }.padding(8).width('100%')
    }.width(this.editorLandscape() ? 96 : '100%').height(82).backgroundColor(Color.Transparent)
      .border({ width: this.layerId === id ? 1.5 : .5, color: AppDesign.border(this.appDark) }).borderRadius(12).clip(true)
      .accessibilityText('选择图层 ' + label).onClick(() => this.chooseLayer(id))
  }
  @Builder
  layerEntries() {
    ForEach(this.preview.elements.filter((el: CanvasElement) => el.behindCapability === (this.settingsTab === 0)).slice().reverse(), (el: CanvasElement) => {
      this.layerEntry(el.id, el.kind === 'text' ? '文字' : (el.kind === 'image' ? '图片' : '形状'))
    }, (el: CanvasElement) => el.id)
    if (this.settingsTab === 1 && this.preview.capability !== null) { this.layerEntry('capability', typeLabel(this.preview.capability!.k)) }
    this.layerEntry('', this.settingsTab === 0 ? '背景底板' : '能力设置')
  }
  @Builder
  layersPanel() {
    Text('图层').fontSize(14).fontWeight(FontWeight.Medium).fontColor(this.appText()).width('100%')
    if (this.editorLandscape()) {
      Scroll() { Row({ space: 8 }) { this.layerEntries() }.padding(2) }.width('100%').layoutWeight(1).scrollable(ScrollDirection.Horizontal).align(Alignment.TopStart).scrollBar(BarState.Off)
    } else {
      Scroll() { Column({ space: 8 }) { this.layerEntries() }.width('100%') }.width('100%').layoutWeight(1).scrollable(ScrollDirection.Vertical).align(Alignment.Top).scrollBar(BarState.Off)
    }
  }
  @Builder
  elementFields() {
    if (this.layerId.length > 0 && this.layerId !== 'capability') {
      Column({ space: 12 }) {
        Text('元素样式').fontSize(16).fontWeight(FontWeight.Medium).fontColor(this.appText()).width('100%')
        if (this.elementPreview.kind === 'text') {
          TextArea({ text: this.textValue, placeholder: '文字内容' }).height(96).fontSize(16).fontColor(this.appText()).placeholderColor(this.appMuted()).backgroundColor(this.appControl()).borderRadius(12).border({ width: .5, color: AppDesign.border(this.appDark) })
            .onChange((v: string) => { this.textValue = v; const el = this.currentElement(); if (el !== null) { el.text = v; this.change('typing_' + el.id); } })
          Row({ space: 12 }) {
            Text('字号').fontSize(14).fontColor(this.appText()); Blank()
            Button('−', { type: ButtonType.Circle }).width(AppDesign.controlHeight).height(AppDesign.controlHeight).fontColor(this.appText()).backgroundColor(this.appControl()).border({ width: .5, color: AppDesign.border(this.appDark) }).accessibilityText('减小字号')
              .onClick(() => { const el = this.currentElement(); if (el !== null) { el.fs = Math.max(10, el.fs - 2); this.change(); } })
            Text(String(this.elementPreview.fs)).fontColor(this.appText()).fontSize(14).width(32).textAlign(TextAlign.Center)
            Button('+', { type: ButtonType.Circle }).width(AppDesign.controlHeight).height(AppDesign.controlHeight).fontColor(this.appText()).backgroundColor(this.appControl()).border({ width: .5, color: AppDesign.border(this.appDark) }).accessibilityText('增大字号')
              .onClick(() => { const el = this.currentElement(); if (el !== null) { el.fs = Math.min(64, el.fs + 2); this.change(); } })
        }.width('100%')
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(['left', 'center', 'right'], (align: string, index: number) => {
              Button(['左对齐', '居中', '右对齐'][index], { type: ButtonType.Capsule }).margin({ right: 8, bottom: 8 }).height(AppDesign.controlHeight).borderRadius(AppDesign.controlRadius).fontSize(13).backgroundColor(Color.Transparent).fontColor(this.appText()).border({ width: this.elementPreview.align === align ? 1.5 : .5, color: AppDesign.border(this.appDark) }).borderRadius(12).clip(true)
                .onClick(() => { const el = this.currentElement(); if (el !== null) { el.align = align; this.change(); } })
            }, (v: string) => v)

          }
          Row() { Text('加粗').fontSize(14).fontColor(this.appText()); Blank()
            Toggle({ type: ToggleType.Switch, isOn: this.elementPreview.bold }).margin({ left: 8 }).selectedColor('#303030').accessibilityText('加粗文字')
              .onChange((v: boolean) => { const el = this.currentElement(); if (el !== null) { el.bold = v; this.change(); } })
          }.width('100%').height(AppDesign.controlHeight)
        } else if (this.elementPreview.kind === 'image') {
          Button(this.busy ? '正在读取' : '选择图片或 GIF', { type: ButtonType.ROUNDED_RECTANGLE }).height(AppDesign.controlHeight).borderRadius(AppDesign.controlRadius).fontSize(14).backgroundColor(this.appControl()).fontColor(this.appText()).border({ width: 1, color: AppDesign.border(this.appDark) }).enabled(!this.busy).onClick(() => this.pickImage())
          if (this.elementPreview.animated) { Text('App 内循环播放；桌面组件展示时播放一次。').fontSize(12).fontColor(this.appMuted()).width('100%') }
        } else {
          Row({ space: 8 }) {
            ForEach(['rect', 'circle', 'line'], (shape: string, index: number) => {
              Button(['矩形', '圆形', '线条'][index], { type: ButtonType.Capsule }).height(AppDesign.controlHeight).borderRadius(AppDesign.controlRadius).fontSize(13).backgroundColor(Color.Transparent).fontColor(this.appText()).border({ width: this.elementPreview.primitive === shape ? 1.5 : .5, color: AppDesign.border(this.appDark) }).borderRadius(12).clip(true)
                .onClick(() => { const el = this.currentElement(); if (el !== null) { el.primitive = shape; this.change(); } })
            }, (v: string) => v)
          }
        }
        if (this.elementPreview.kind !== 'image') { this.colorRow('元素颜色', 'element', this.elementColor) }
      }.width('100%').padding(16).backgroundColor(this.appSurface()).borderRadius(AppDesign.sectionRadius).border({ width: 1, color: AppDesign.border(this.appDark) }).clip(true)
    }
    if (this.layerId.length > 0) {
      Column({ space: 12 }) {
        Text('位置与显示').fontSize(16).fontWeight(FontWeight.Medium).fontColor(this.appText()).width('100%')
        if (this.layerId !== 'capability') {
          if (this.settingsTab === 0) {
            Button('铺满底板', { type: ButtonType.ROUNDED_RECTANGLE }).width('100%').height(AppDesign.controlHeight).fontSize(13).backgroundColor(this.appControl()).fontColor(this.appText()).border({ width: .5, color: AppDesign.border(this.appDark) })
              .onClick(() => { const el = this.currentElement(); if (el !== null) { el.x = 0; el.y = 0; el.w = 1; el.h = 1; el.rot = 0; this.change(); } })
          }
        }
        Text('在预览中直接调整大小与位置').fontSize(12).fontColor(this.appMuted()).width('100%')
        Row({ space: 8 }) {
          Button('水平居中').fontSize(12).backgroundColor(this.appControl()).fontColor(this.appText()).border({ width: .5, color: AppDesign.border(this.appDark) }).onClick(() => { const box = this.currentBox(); if (box !== null) { box.x = (1 - box.w) / 2; this.change(); } })
          Button('垂直居中').fontSize(12).backgroundColor(this.appControl()).fontColor(this.appText()).border({ width: .5, color: AppDesign.border(this.appDark) }).onClick(() => { const box = this.currentBox(); if (box !== null) { box.y = (1 - box.h) / 2; this.change(); } })
          if (this.layerId !== 'capability') { Button('重置角度').fontSize(12).backgroundColor(this.appControl()).fontColor(this.appText()).border({ width: .5, color: AppDesign.border(this.appDark) }).onClick(() => { const box = this.currentBox(); if (box !== null) { box.rot = 0; this.change(); } }) }
        }
        Row({ space: 8 }) {
          Text('透明度').fontSize(13).fontColor(this.appText())
          ForEach([1, .7, .4], (opacity: number, index: number) => {
            Button(['实色', '柔和', '轻透'][index], { type: ButtonType.ROUNDED_RECTANGLE }).height(AppDesign.controlHeight).layoutWeight(1).borderRadius(AppDesign.controlRadius).fontSize(12)
              .backgroundColor(Color.Transparent).fontColor(this.appText()).border({ width: Math.abs(this.boxPreview.opacity - opacity) < .01 ? 1.5 : .5, color: AppDesign.border(this.appDark) })
              .onClick(() => { const box = this.currentBox(); if (box !== null) { box.opacity = opacity; this.change(); } })
          }, (opacity: number) => String(opacity))
        }.width('100%')
        Button(this.showLayerOptions ? '收起图层操作' : '图层操作', { type: ButtonType.ROUNDED_RECTANGLE }).height(AppDesign.controlHeight).width('100%').fontSize(13).fontColor(this.appMuted()).backgroundColor(Color.Transparent)
          .onClick(() => { this.getUIContext().animateTo({ duration: 180, curve: Curve.EaseOut, expectedFrameRateRange: this.frameRate }, () => { this.showLayerOptions = !this.showLayerOptions; }); })
        if (this.showLayerOptions) {
        if (this.layerId !== 'capability') {
          Row({ space: 8 }) {
            Button('复制元素', { type: ButtonType.Capsule }).fontSize(12).backgroundColor(this.appControl()).fontColor(this.appText()).border({ width: .5, color: AppDesign.border(this.appDark) }).onClick(() => this.duplicateElement())
            Button('上移一层', { type: ButtonType.Capsule }).fontSize(12).backgroundColor(this.appControl()).fontColor(this.appText()).border({ width: .5, color: AppDesign.border(this.appDark) }).onClick(() => this.moveElementOrder(true))
            Button('下移一层', { type: ButtonType.Capsule }).fontSize(12).backgroundColor(this.appControl()).fontColor(this.appText()).border({ width: .5, color: AppDesign.border(this.appDark) }).onClick(() => this.moveElementOrder(false))
        }.width('100%')

        }
        Flex({ wrap: FlexWrap.Wrap }) {
          if (this.layerId.length > 0 && this.layerId !== 'capability') {
          Button(this.settingsTab === 0 ? '移到内容层' : '移到最上层', { type: ButtonType.ROUNDED_RECTANGLE }).margin({ right: 8, bottom: 8 }).height(AppDesign.controlHeight).borderRadius(AppDesign.controlRadius).fontSize(13).fontColor(this.appText()).backgroundColor(this.appControl())
            .onClick(() => { const card = this.current(), el = this.currentElement(); if (card !== null && el !== null) { el.behindCapability = false; this.settingsTab = 1; this.editorTabs = [1]; card.elements = card.elements.filter((e: CanvasElement) => e.id !== el.id).concat([el]); this.change(); } })
          Button(this.settingsTab === 1 ? '移到背景层' : '移到最下层', { type: ButtonType.ROUNDED_RECTANGLE }).margin({ right: 8, bottom: 8 }).height(AppDesign.controlHeight).borderRadius(AppDesign.controlRadius).fontSize(13).fontColor(this.appText()).backgroundColor(this.appControl())
            .onClick(() => { const card = this.current(), el = this.currentElement(); if (card !== null && el !== null) {
              el.behindCapability = true; this.settingsTab = 0; this.editorTabs = [0]; card.elements = [el].concat(card.elements.filter((e: CanvasElement) => e.id !== el.id)); this.change();
            } })
          }
          Button('移除此元素', { type: ButtonType.ROUNDED_RECTANGLE }).height(AppDesign.controlHeight).borderRadius(AppDesign.controlRadius).fontSize(13).fontColor('#C43A35').backgroundColor(Color.Transparent).onClick(() => this.removeElement())
        }
        }
      }.width('100%').padding(16).backgroundColor(this.appSurface()).borderRadius(AppDesign.sectionRadius).border({ width: 1, color: AppDesign.border(this.appDark) }).clip(true)
    }
  }
  @Builder
  capabilityPanel() {
    Column({ space: 12 }) {
      Text('能力').fontSize(16).fontWeight(FontWeight.Medium).fontColor(this.appText()).width('100%')
      Text('每张卡片可放一个能力，也可以只用自己的元素。').fontSize(12).fontColor(this.appMuted()).width('100%')
      if (this.preview.capability !== null) {
        Text('最小可读尺寸 ' + Math.ceil(minimumCardSize(this.preview).w) + ' × ' + Math.ceil(minimumCardSize(this.preview).h)).fontSize(12).fontColor(this.appMuted()).width('100%')
      }
      if (this.preview.capability !== null && capabilityBox(this.preview).w === 0) {
        Text('元素与能力重叠，可移动元素或调整前后层级。').fontSize(12).fontColor(this.appMuted()).width('100%')
      }
      if (this.preview.capability !== null) {
        Text(compactCapability(this.preview.capability!, this.preview.w * capabilityPlacement(this.preview).w, this.preview.h * capabilityPlacement(this.preview).h) ?
          (this.preview.capability!.k === 'calendar' ? '紧凑显示：本周；点按桌面卡片可看完整月历' : '紧凑显示：保留主要信息') : '完整显示：缩小时自动切换紧凑布局')
          .fontSize(12).fontColor(this.appMuted()).width('100%')
      }
      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(['none'].concat(CAPABILITIES), (k: string) => {
          Button(k === 'none' ? '无' : typeLabel(k), { type: ButtonType.Capsule }).height(AppDesign.controlHeight).borderRadius(AppDesign.controlRadius).fontSize(13).margin({ right: 8, bottom: 8 })
            .backgroundColor(Color.Transparent).fontColor(this.appText()).border({ width: (this.preview.capability?.k ?? 'none') === k ? 1.5 : .5, color: AppDesign.border(this.appDark) })
            .onClick(() => this.setCapability(k))
        }, (k: string) => k)
      }.width('100%')
      if (this.preview.capability?.k === 'countdown' || this.preview.capability?.k === 'anniversary') {
        TextInput({ text: this.titleValue, placeholder: '名称' }).height(AppDesign.controlHeight).borderRadius(AppDesign.controlRadius).fontSize(16).fontColor(this.appText()).placeholderColor(this.appMuted()).backgroundColor(this.appControl())
          .onChange((v: string) => { this.titleValue = v; const cap = this.current()?.capability; if (cap !== null && cap !== undefined) { cap.title = v; this.change(); } })
        Button('日期  ' + (this.preview.capability?.date ?? ''), { type: ButtonType.ROUNDED_RECTANGLE }).height(AppDesign.controlHeight).borderRadius(AppDesign.controlRadius).fontColor(this.appText()).backgroundColor(this.appControl()).border({ width: .5, color: AppDesign.border(this.appDark) }).onClick(() => this.pickDate())
      }
      if (this.preview.capability?.k === 'weather') {
        TextInput({ text: this.cityValue, placeholder: '城市' }).height(AppDesign.controlHeight).borderRadius(AppDesign.controlRadius).fontSize(16).fontColor(this.appText()).placeholderColor(this.appMuted()).backgroundColor(this.appControl())
          .onChange((v: string) => { this.cityValue = v; const cap = this.current()?.capability; if (cap !== null && cap !== undefined) { if (cap.city !== v.trim()) { cap.city = v.trim(); cap.temp = '--°'; cap.desc = '未更新'; cap.updatedAt = 0; cap.attemptedAt = 0; cap.refreshState = ''; this.change(); } } })
          .onSubmit(() => this.refreshWeather())
        Button(this.weatherBusy ? '更新中' : '更新天气', { type: ButtonType.ROUNDED_RECTANGLE }).height(AppDesign.controlHeight).borderRadius(AppDesign.controlRadius).backgroundColor(Color.Transparent).fontColor(this.appText()).border({ width: .5, color: this.appMuted() }).enabled(!this.weatherBusy).onClick(() => this.refreshWeather())
        Text(this.preview.capability?.refreshState === 'failed' ? '暂时无法获取天气，稍后自动重试' : '天气自动更新；打开 App 时会补刷过期数据').fontSize(12).fontColor(this.appMuted()).width('100%')
      }
    }.width('100%')
  }
  private chooseColor(target: string): void {
    const card = this.current(); if (card === null) return;
    const element = this.currentElement(), id = card.id;
    const initial = target === 'element' ? (element?.color || materialColors(card.material, card.paper, card.ink)[1]) : materialColors(card.material, card.paper, card.ink)[target === 'paper' ? 0 : 1];
    this.colorDialog = new CustomDialogController({ builder: ColorSelector({ initialColor: initial, onPick: (color: string) => {
      if (this.store.findCard(id) !== card) return;
      if (target === 'element' && element !== null && card.elements.includes(element)) element.color = color;
      if (target === 'paper') card.paper = color; if (target === 'ink') card.ink = color;
      this.syncFields(); this.change();
    } }), customStyle: true, alignment: DialogAlignment.Center, autoCancel: true });
    this.colorDialog.open();
  }
  @Builder
  colorRow(label: string, target: string, value: string) {
    Row({ space: 12 }) {
      Text(label).fontSize(14).fontColor(this.appText()); Blank()
      Text(value.length === 0 ? '自动' : '自定义').fontSize(12).fontColor(this.appMuted())
      Column().width(28).height(28).borderRadius(8).backgroundColor(value || materialColors(this.preview.material, this.preview.paper, this.preview.ink)[target === 'paper' ? 0 : 1])
        .border({ width: .5, color: '#BDBDBD' }).hitTestBehavior(HitTestMode.BLOCK_DESCENDANTS)
    }.width('100%').height(48).padding({ left: 12, right: 12 }).backgroundColor(this.appControl()).borderRadius(12)
      .accessibilityText('选择' + label).onClick(() => this.chooseColor(target))
  }
  @Builder
  appearancePanel() {
    Column({ space: 12 }) {
      Text('背景底板').fontSize(16).fontWeight(FontWeight.Medium).fontColor(this.appText()).width('100%')
      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(THEMES, (m: string, index: number) => {
          Button(['白', '米色', '牛皮纸', '绿', '蓝', '粉', '黑'][index], { type: ButtonType.Capsule }).height(AppDesign.controlHeight).borderRadius(AppDesign.controlRadius).fontSize(13)
            .backgroundColor(Color.Transparent).fontColor(this.appText())
            .border({ width: this.preview.material === m ? 1.5 : 0.5, color: '#BDBDBD' }).margin({ right: 8, bottom: 8 })
            .onClick(() => { const card = this.current(); if (card !== null) { card.material = m; card.paper = ''; this.paperValue = ''; this.change(); } })
        }, (m: string) => m)
      }.width('100%')
      this.colorRow('底色', 'paper', this.paperValue)
      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(SHAPES, (s: string, index: number) => {
          Button(['方形', '椭圆', '胶囊', '自由边角'][index], { type: ButtonType.Capsule }).height(AppDesign.controlHeight).borderRadius(AppDesign.controlRadius).fontSize(13).margin({ right: 8, bottom: 8 })
            .backgroundColor(Color.Transparent).fontColor(this.appText()).border({ width: this.preview.shape === s ? 1.5 : .5, color: AppDesign.border(this.appDark) })
            .onClick(() => { const card = this.current(); if (card !== null) { card.shape = s; this.change(); } })
        }, (s: string) => s)
      }.width('100%')
      Button(this.busy ? '正在处理照片' : '用照片主体作为形状', { type: ButtonType.ROUNDED_RECTANGLE }).height(AppDesign.controlHeight).borderRadius(AppDesign.controlRadius).width('100%').fontSize(14)
        .fontColor(this.appText()).backgroundColor(this.appControl()).border({ width: .5, color: AppDesign.border(this.appDark) }).enabled(!this.busy).onClick(() => this.pickImage(true))
      if (this.preview.cutout.length > 0 && this.preview.shape !== 'subject') {
        Button('恢复主体形状', { type: ButtonType.ROUNDED_RECTANGLE }).height(AppDesign.controlHeight).borderRadius(AppDesign.controlRadius).fontColor(this.appText()).backgroundColor(this.appControl()).border({ width: .5, color: AppDesign.border(this.appDark) })
          .onClick(() => { const card = this.current(); if (card !== null) { card.shape = 'subject'; card.h = card.w / card.subjectAspect; this.change(); } })
      }
      if (this.preview.cutout.length > 0) {
        Text('主体外观').fontSize(14).fontColor(this.appText()).width('100%')
        Row({ space: 8 }) {
          Button('只用形状', { type: ButtonType.Capsule }).height(AppDesign.controlHeight).fontSize(13).borderRadius(AppDesign.controlRadius).layoutWeight(1)
            .backgroundColor(Color.Transparent).fontColor(this.appText()).border({ width: !this.preview.subjectPhoto ? 1.5 : .5, color: AppDesign.border(this.appDark) })
            .onClick(() => { const card = this.current(); if (card !== null) { card.subjectPhoto = false; this.change(); } })
          Button('主体照片作底图', { type: ButtonType.Capsule }).height(AppDesign.controlHeight).fontSize(13).borderRadius(AppDesign.controlRadius).layoutWeight(1)
            .backgroundColor(Color.Transparent).fontColor(this.appText()).border({ width: this.preview.subjectPhoto ? 1.5 : .5, color: AppDesign.border(this.appDark) })
            .onClick(() => { const card = this.current(); if (card !== null) { card.subjectPhoto = true; this.change(); } })
        }.width('100%')
      }
      if (this.preview.shape === 'subject') {
        Text('抠图固定使用白边，保留柔化的主体轮廓。').fontSize(12).fontColor(this.appMuted()).width('100%')
      }
      if (this.preview.shape !== 'subject') {
      Row() {
        Text('白边').fontSize(14).fontColor(this.appText()); Blank()
        Toggle({ type: ToggleType.Switch, isOn: this.preview.frame }).selectedColor('#303030')
          .onChange((v: boolean) => { const card = this.current(); if (card !== null) { card.frame = v; this.change(); } })
      }.width('100%').height(AppDesign.controlHeight).borderRadius(AppDesign.controlRadius)
      }
    }.width('100%')
  }
}
