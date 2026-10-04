import { TimeCapabilitySettings } from '../views/TimeCapabilitySettings';
import { SettingsSegmented } from '../views/SettingsSegmented';
import { SettingsCounter } from '../views/SettingsCounter';
import { settingsReveal, settingsDialogOpen, settingsDialogClose } from '../model/SettingsMotion';
import { CapabilityAppearance } from '../views/CapabilityAppearance';
import { CapabilityDetails } from '../views/CapabilityDetails';
import { WeekTimetable } from '../views/WeekTimetable';
import { CapabilityPicker } from '../views/CapabilityPicker';
import { capabilityDescriptor } from '../model/CapabilityCatalog';
import { capabilityPreset } from '../model/CanvasLayout';
import { BatteryObserver } from '../model/BatteryObserver';
import { needsDataRefresh, capabilityRequestKey } from '../model/CapabilityData';
import { readCapability } from '../model/CapabilityService';
import { CapabilitySettings } from '../views/CapabilitySettings';
import { primeRenderContours } from '../model/RenderContours';
import { storageSnapshot } from '../model/StorageSnapshot';
import { CanvasEntry } from '../model/CanvasLibrary';
import { BoardMotion } from '../model/BoardMotion';
import { combineCards, ungroupCards, groupMembers, groupDragBounds, cleanGroups } from '../model/CardGroups';
import { PhotoCrop } from '../views/PhotoCrop';
import { CanvasBackdrop } from '../views/CanvasBackdrop';
import { CanvasBackground, FridgeState, normalizeState, normalizeBackground } from '../model/CardSchema';
import { backgroundSignature, createSmartBackground, importBackgroundPhoto, cropBackgroundPhoto } from '../model/BackgroundWorker';
import { exportTemplate, inspectTemplate, materializeTemplateUri } from '../model/TemplateFiles';
import { TemplateSummary, importedCards, fitImportedCanvas } from '../model/TemplatePackage';
import { picker } from '@kit.CoreFileKit';
import { sharePixelMap, shareTemplateFile } from '../model/ImageShare';
import { taskpool } from '@kit.ArkTS';
import { common } from '@kit.AbilityKit';
import { AppDesign } from '../model/AppDesign';
import { arrivalOffset } from '../model/ArrivalGeometry';
import { motionFrameRate } from '../model/MotionPolicy';
import { HdsNavigation, HdsNavigationTitleMode, TextStyleMode, ScrollEffectType, BlurStrategy, hdsMaterial } from '@kit.UIDesignKit';
import { EditorViewport, editorViewport, editorPreviewPaneHeight } from '../model/EditorViewport';
import { SelectionHandles, selectionHandles } from '../model/SelectionHandles';
import { CardEditHistory } from '../model/CardEditHistory';
import { ColorSetting } from '../views/ColorSetting';
import { ColorSelector } from '../views/ColorSelector';
import { FridgeStore, FridgeCard, CanvasElement, ElementBox, ShapePoint, CapBlock, BOARD_W, BOARD_H, materialColors, shapeRadius, typeLabel } from '../model/FridgeModel';
import { CardCanvas } from '../views/CardCanvas';
import { cardViewSnapshot, cardRenderSnapshot } from '../model/CardViewSnapshot';
import { CardFace } from '../views/CardFace';
import { sceneRect, SceneRect, layerLabel } from '../model/SceneLayout';
import { extractSubject, repairSubject } from '../model/SubjectShape';
import { fetchWeather } from '../model/WeatherService';
import { weatherNeedsRefresh } from '../model/WeatherRefresh';
import { BoardCard } from '../views/BoardCard';
import { capabilityBox, capabilityPlacement, safeContentBox, clampCardGeometry, ensureCapabilitySize, subjectSurfaceFactor, cardHandlePoint } from '../model/CanvasLayout';
import { fileIo } from '@kit.CoreFileKit';
import { cropCardToSubject } from '../model/SubjectGeometry';
import { applyCalendarAction } from '../model/CapabilityActions';
import { CapabilityView } from '../views/CapBlockView';
import { capabilityMinimum } from '../model/CapabilityMetrics';
import { photoAccessHelper } from '@kit.MediaLibraryKit';

const THEMES: string[] = ['white', 'cream', 'kraft', 'mint', 'blue', 'pink', 'dark'];
const EDITOR_NAV_INSET: number = 56;
const EDITOR_SAFE_GAP: number = 4;
const SHAPES: string[] = ['rect', 'round', 'pill', 'blob'];

@Entry
@Component
struct Index {
  private batteryObserver:BatteryObserver=new BatteryObserver();
  private refreshingCapabilities:boolean=false;
  private widgetRouteTimer:number=-1;
  private photoCropDialog: CustomDialogController | null = null;
  @State canvasPickerOpen: boolean = false;
  @State canvasChanging: boolean = false;
  @State canvasEntries: CanvasEntry[] = [];
  @State canvasName: string = '我的画布';
  @State renameValue: string = '';
  @StorageLink('routeCanvasId') @Watch('canvasRouteChanged') routeCanvasId: string = '';
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
  @State scatter: number = 0;
  @State showBackgroundOptions: boolean = false;
  @State showLayerOptions: boolean = false;
  private capabilityDialog: CustomDialogController | null = null;
  private resizeStart: ElementBox = new ElementBox();
  private rotateStart: number = 0;
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
  @StorageLink('appDark') appDark: boolean = false;
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
  private appWentBackground(): void { if(!this.appBackgrounded && this.ready) {this.tick=Date.now();this.refreshCapabilities();this.refreshDueWeather();} if (this.appBackgrounded && this.ready) { if (this.previewTimer >= 0 || this.gestureGroup.length > 0) this.flushPreview(); this.persist(true); } }

  @State repairingSubjects: boolean = false;
  @State weatherBusy: boolean = false;
  @State tick: number = Date.now();

  aboutToAppear(): void {
    this.alive = true;
    this.context = this.getUIContext().getHostContext() ?? null;
    this.initialize();
    this.clockTimer = setInterval(() => { this.tick = Date.now(); this.refreshDueWeather(); this.refreshCapabilities(); }, 60000);
    this.batteryObserver.start(()=>this.refreshCapabilities());
  }
  private initialize(): void {
    if (this.context === null) return;
    this.store.init(this.context).then(async () => {
      if (this.routeCanvasId) await this.store.openCanvas(this.routeCanvasId);
      this.refreshCanvasList();
      // Resolve FormKit geometry before revealing the scene; a late aspect update jumps after arrival.
      await this.store.refreshCanvasSpecs().catch(() => {});
      if (!this.alive) return;
      for (const card of this.store.state.cards) {
        if (!ensureCapabilitySize(card)) this.error = '部分卡片内部空间不足，请放大、更换形状或移除能力';
        this.clamp(card);
      }
      this.canvasDimension = this.widgetDimension || '4*4';
      this.canvasAspect = this.widgetAspect > 0 ? this.widgetAspect : (this.store.canvasSpecs[this.canvasDimension] ?? (this.canvasDimension === '6*4' ? 2 / 3 : (this.canvasDimension === '2*4' ? 2 : 1)));
      const routedLaunch = this.routedId.length > 0 || this.viewRouteId.length > 0;
      this.canvasBackground = this.store.state.background; this.layoutBoard(); this.ready = true; this.render(); this.scheduleBackground(); this.routeChanged(); this.viewRouteChanged();
      if (!routedLaunch) this.startArrival();
      this.maintenanceTimer = setTimeout(() => { if (this.alive) { this.editorMounted = true; this.persist(); this.repairStoredSubjects(); this.refreshDueWeather(); this.refreshCapabilities(); } }, 750);

    }).catch((e: Error) => { this.error = e.message; });
  }
  private refreshCanvasList(): void {
    this.canvasEntries = this.store.catalog.canvases.map((c: CanvasEntry): CanvasEntry => ({id:c.id,name:c.name}));
    this.canvasName = this.store.activeName; this.renameValue = this.canvasName;
  }
  private canvasRouteChanged(): void { if(this.ready && this.routeCanvasId) this.scheduleWidgetRoute(); }
  private async chooseCanvas(id: string): Promise<void> {
    if (this.heroActive || this.activeBoardId || this.sharing || this.busy || this.canvasChanging) return;
    if (this.editing) { this.getUIContext().getPromptAction().showToast({message:'请先完成当前卡片编辑'}); return; }
    this.canvasChanging=true;
    try {await this.loadCanvas(id);}catch(e){this.templateError('画布切换未完成',e as Error);}finally{this.canvasChanging=false;}
  }
  private async loadCanvas(id:string):Promise<void> {
    try {
      this.backgroundGeneration++; if(this.backgroundTimer >= 0) clearTimeout(this.backgroundTimer); this.backgroundBusy = false;
      await this.store.save(false); if (!await this.store.openCanvas(id)) return;
      this.selectedId = ''; this.activeBoardId = ''; this.groupSelection = []; this.groupSelecting = false;
      this.canvasBackground = this.store.state.background; this.refreshCanvasList();
      await primeRenderContours(this.store.state.cards,storageSnapshot(this.store.state));
      this.render(); this.persist(true); this.scheduleBackground(); this.canvasPickerOpen = false;
      this.refreshCapabilities(); this.refreshDueWeather();
    } catch (e) { this.templateError('画布切换未完成',e as Error); }
  }
  private async newCanvas(duplicate: boolean): Promise<void> {
    if(this.canvasChanging)return;this.canvasChanging=true;
    try {
      await this.store.save(false);this.backgroundGeneration++;
      const source = duplicate ? this.store.state : undefined;
      const id = this.store.createCanvas(duplicate ? this.canvasName+' 副本' : '画布 '+(this.canvasEntries.length+1),source);
      await this.loadCanvas(id);
    } catch(e) {this.templateError('画布未创建',e as Error);}finally{this.canvasChanging=false;}
  }
  private deleteCanvas(): void {
    if(this.canvasEntries.length <= 1 || this.canvasChanging) return;
    const id = this.store.state.canvasId;
    this.getUIContext().showAlertDialog({title:'删除这张画布？',message:'卡片和背景会一起删除。绑定它的桌面组件将显示剩余画布。',primaryButton:{value:'取消',action:()=>{}},secondaryButton:{value:'删除',fontColor:'#C43A35',action:()=>{
      if(this.canvasChanging)return;this.canvasChanging=true;
      this.store.deleteCanvas(id).then(()=>this.loadCanvas(this.store.catalog.activeId)).catch((e:Error)=>this.templateError('未能删除',e)).finally(()=>{this.canvasChanging=false;});
    }}});
  }
  @Builder
  canvasPicker() {
    Column({space:16}) {
      Text('我的画布').fontSize(20).fontWeight(FontWeight.Medium).fontColor(this.appText()).width('100%')
      Scroll() {
        Column({space:8}) {
          ForEach(this.canvasEntries,(c:CanvasEntry)=>{
            Button({type:ButtonType.ROUNDED_RECTANGLE, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL}) {
              Row({space:12}) { Text(c.name).fontColor(this.appText()).fontSize(16).layoutWeight(1).maxLines(1).textOverflow({overflow:TextOverflow.Ellipsis}); Text(c.id===this.store.state.canvasId?'当前':'切换').fontSize(12).fontColor(this.appMuted()) }.width('100%')
            }.width('100%').height(56).padding(16).backgroundColor(this.appSurface()).onClick(()=>this.chooseCanvas(c.id))
          },(c:CanvasEntry)=>c.id)
        }.width('100%')
      }.width('100%').layoutWeight(1).scrollBar(BarState.Off).align(Alignment.Top)
      Row({space:12}) {
        TextInput({text:this.renameValue,placeholder:'画布名称'}).height(44).layoutWeight(1).fontColor(this.appText()).backgroundColor(this.appControl()).borderRadius(14).onChange((v:string)=>this.renameValue=v)
        Button('重命名',{type:ButtonType.Capsule, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL}).height(44).fontColor(this.appText()).backgroundColor(this.appControl()).onClick(()=>{this.store.renameCanvas(this.renameValue);this.refreshCanvasList();this.persist(false);})
      }.width('100%')
      Row({space:12}) {
        Button('新画布',{type:ButtonType.Capsule, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL}).height(44).layoutWeight(1).fontColor(this.appText()).backgroundColor(this.appControl()).onClick(()=>this.newCanvas(false))
        Button('复制画布',{type:ButtonType.Capsule, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL}).height(44).layoutWeight(1).fontColor(this.appText()).backgroundColor(this.appControl()).onClick(()=>this.newCanvas(true))
        Button('删除',{type:ButtonType.Capsule, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.ERROR}).height(44).fontColor('#C43A35').backgroundColor(this.appControl()).enabled(this.canvasEntries.length>1).onClick(()=>this.deleteCanvas())
      }.width('100%')
      Text('桌面组件各自绑定添加时的画布，切换不会替换它们。').fontSize(12).fontColor(this.appMuted()).width('100%')
    }.width('100%').height('100%').padding(20).backgroundColor(this.appSurface()).enabled(!this.canvasChanging)
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
          if (!ensureCapabilitySize(card)) this.error = '部分卡片内部空间不足，请放大、更换形状或移除能力';
          this.clamp(card); this.render(); this.persist();
        } catch (_) { if (this.alive) this.error = '部分旧主体照片未能更新，请重新选择本地照片'; }
      }
    } finally { this.repairingSubjects = false; }
  }
  aboutToDisappear(): void { this.capabilityDialog?.close(); this.batteryObserver.stop(); if(this.widgetRouteTimer>=0)clearTimeout(this.widgetRouteTimer); if (this.previewTimer >= 0 || this.gestureGroup.length > 0) this.flushPreview(); this.alive = false; this.backgroundGeneration += 1; if (this.backgroundTimer >= 0) clearTimeout(this.backgroundTimer); if (this.maintenanceTimer >= 0) clearTimeout(this.maintenanceTimer); if (this.transitionTimer >= 0) clearTimeout(this.transitionTimer); this.activeBoardId = ''; this.persist(true); if (this.clockTimer >= 0) clearInterval(this.clockTimer); }
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
  private compactEditorLayers(): boolean { return this.editorLandscape() && this.editorBodyHeight()<320; }
  private previewPaneHeight(): number { return editorPreviewPaneHeight(this.editorBodyHeight(),this.editorLandscape()); }
  private editingAngle(): number { return this.preview.rot; }
  private previewViewport(): EditorViewport {
    return editorViewport(this.preview.w, this.preview.h, this.editingAngle(), this.editorViewportWidth(),
      this.screenHeight, this.safeTop, this.safeBottom, this.editorLandscape(), this.previewPaneHeight());
  }
  private editorScale(): number { return this.previewViewport().scale; }
  private editorRect(): SceneRect {
    const rect = new SceneRect(), scale = this.editorScale();
    rect.w = this.preview.w * scale; rect.h = this.preview.h * scale;
    rect.x = this.previewViewport().left; rect.y = this.safeTop + EDITOR_SAFE_GAP + EDITOR_NAV_INSET + this.previewViewport().top; rect.rot = this.editingAngle(); return rect;
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
    if(this.routeCanvasId&&this.routeCanvasId!==this.store.state.canvasId){this.scheduleWidgetRoute();return;}
    if (this.store.findCard(this.routedId) !== null) { this.openEditor(this.routedId); }
    AppStorage.setOrCreate('editCardId', '');
  }
  private viewRouteChanged(): void { if(this.ready&&this.viewRouteId) this.scheduleWidgetRoute(); }
  private scheduleWidgetRoute():void {
    if(this.widgetRouteTimer>=0)clearTimeout(this.widgetRouteTimer);
    this.widgetRouteTimer=setTimeout(()=>{this.widgetRouteTimer=-1;this.reloadWidgetRoute();},0);
  }
  private async reloadWidgetRoute():Promise<void> {
    if(!this.context || !this.alive)return;
    const canvas=this.routeCanvasId,id=this.viewRouteId;
    try {
      this.backgroundGeneration++;
      await this.store.init(this.context);if(canvas)await this.store.openCanvas(canvas);
      await primeRenderContours(this.store.state.cards,storageSnapshot(this.store.state));
      if(!this.alive)return;
      this.refreshCanvasList();this.canvasBackground=this.store.state.background;
      this.editing=false;this.heroActive=false;this.viewing=false;this.selectedId='';this.activeBoardId='';this.boardOpacity=1;this.render();this.layoutBoard();
      AppStorage.setOrCreate('viewCardId','');
      if(this.routeCanvasId===canvas)AppStorage.setOrCreate('routeCanvasId','');
      if(id&&this.store.findCard(id)){this.select(id);this.viewing=true;}
      this.routeChanged();this.scheduleBackground();this.refreshCapabilities();
      // Persist only the selection metadata. Replaying stale UI state could undo a widget-side action.
      this.store.save(false).catch(()=>{});
    }catch(_){this.error='画布读取失败，请重试';}
  }
  private calendarAction(operation: string): void {
    const card = this.current(); if (card !== null && applyCalendarAction(card, operation)) { this.render(); this.persist(); }
  }
  private current(): FridgeCard | null { return this.store.findCard(this.selectedId); }
  private currentElement(): CanvasElement | null { return this.current()?.elements.find((e: CanvasElement) => e.id === this.layerId) ?? null; }
  private currentBox(): ElementBox | null { const card=this.current();return this.layerId==='capability'?(card?.capability?card.capBox:null):this.currentElement(); }
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
        this.getUIContext().getPromptAction().showToast({ message: card.capability?.k==='timetable' && card.capability.timetableMode==='day' ? '这张卡片放不下完整概览，请换更宽的底板或使用下一课' : '卡片内部空间不足，请放大、更换形状或移除能力' });
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
      if(k==='timetable'){const d=new Date();d.setDate(d.getDate()-((d.getDay()+6)%7));cap.semester=d.getFullYear()+'-'+('0'+(d.getMonth()+1)).slice(-2)+'-'+('0'+d.getDate()).slice(-2);cap.courses=[];}
      if (k === 'worldclock') cap.zone = 'Asia/Shanghai';
      if (k === 'weather') { cap.city = ''; cap.temp = '--°'; cap.desc = '未更新'; }
      card.capability = cap; card.capBox = capabilityPreset(card,'center'); this.layerId = 'capability';
    }
    this.syncFields(); this.change(); this.scroller.scrollTo({ xOffset: 0, yOffset: 0 }); this.refreshCapabilities();
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
    else { this.boardMotion.offset = { x: 0, y: 0 }; this.boardMotion.ids = []; this.movingGroupIds = []; }
    this.activeBoardId = active ? id : '';
    if (this.saveTimer >= 0) clearTimeout(this.saveTimer); this.saveTimer = -1;
    if (!active) { this.scheduleBackground(); this.persist(true); }
  }
  private commitGeometry(updated: FridgeCard): void {
    const card = this.store.findCard(updated.id); if (card === null) return;
    const dx = updated.x - card.x, dy = updated.y - card.y;
    if (updated.w === card.w && updated.h === card.h && updated.rot === card.rot) { for (const peer of groupMembers(this.store.state.cards, card)) if (peer.id !== card.id) { peer.x += dx; peer.y += dy; } }
    this.boardMotion.offset = { x: 0, y: 0 };
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
  onPageShow(): void { this.tick=Date.now();if (this.ready) {this.refreshDueWeather();this.refreshCapabilities();} }
  private updateExtraCapability(id:string,next:CapBlock):void {
    const card=this.store.findCard(id);if(!card||card.capability?.k!==next.k)return;
    card.capability=next;this.syncFields();this.change();
  }
  private async refreshCapabilities():Promise<void> {
    if(!this.ready||!this.alive||this.appBackgrounded||this.activeBoardId||this.refreshingCapabilities||!this.context)return;
    this.refreshingCapabilities=true;const canvasId=this.store.state.canvasId;
    try {
      for(const card of this.store.state.cards.slice()) {
        const cap=card.capability;if(!needsDataRefresh(cap)||!cap)continue;
        const key=capabilityRequestKey(cap),next=await readCapability(cap,this.context);
        if(!this.alive||this.store.state.canvasId!==canvasId||this.store.findCard(card.id)!==card||card.capability!==cap||capabilityRequestKey(cap)!==key)continue;
        if(cap.k==='battery'&&cap.percent===next.percent&&cap.charging===next.charging&&cap.chargeState===next.chargeState&&cap.refreshState===next.refreshState)continue;
        if(JSON.stringify(next)===JSON.stringify(cap))continue;card.capability=next;
        this.render();this.persist(true);
      }
    }finally{this.refreshingCapabilities=false;}
  }
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
          if (this.error.length > 0) { Button('重试', { type: ButtonType.ROUNDED_RECTANGLE, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL }).height(AppDesign.controlHeight).onClick(() => this.initialize()) }
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
              onMove: (x: number, y: number) => { if (this.movingGroupIds.length > 0) { this.boardMotion.offset = { x: x, y: y }; } },
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
        CanvasBackdrop({ sceneBackground: this.canvasBackground, liveFluid: true }).width('100%').height('100%')
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
          Button({type:ButtonType.Capsule, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL}) {
            Row({space:6}) {
              Text(this.canvasName).fontSize(12).fontColor(this.appText()).maxLines(1).textOverflow({overflow:TextOverflow.Ellipsis}).layoutWeight(1)
              SymbolGlyph($r('sys.symbol.chevron_down')).fontSize(14).fontColor([this.appText()]).hitTestBehavior(HitTestMode.None)
            }.width('100%')
          }.padding({left:12,right:12}).accessibilityText('切换画布 '+this.canvasName).height(44).width(Math.min(130,Math.max(64,this.panelWidth-220))).fontSize(12).fontColor(this.appText()).backgroundColor(this.appControl()).margin({right:8}).onClick(()=>{this.refreshCanvasList();this.canvasPickerOpen=true;}).bindSheet(this.canvasPickerOpen,this.canvasPicker,{height:SheetSize.LARGE,showClose:true,backgroundColor:this.appBackground(),onDisappear:()=>{this.canvasPickerOpen=false;}})
          Button(this.groupSelecting ? '取消' : '多选', { type: ButtonType.Capsule, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL }).margin({ right: 8 }).height(44).fontSize(13).backgroundColor(this.appControl()).fontColor(this.appText()).onClick(() => { this.groupSelecting = !this.groupSelecting; this.groupSelection = []; })
          Button({ type: ButtonType.Circle, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL }) {SymbolGlyph($r('sys.symbol.plus')).fontSize(22).fontColor([Color.White]).hitTestBehavior(HitTestMode.None)}.width(44).height(AppDesign.controlHeight).fontSize(24).backgroundColor('#262626').fontColor(Color.White).accessibilityText('添加卡片').onClick(() => this.addCard())
        }.width('100%')
        Stack({ alignContent: Alignment.Bottom }) {
        Scroll() {
          Column({ space: 8 }) {
            ForEach(this.orderedCards().map((item: FridgeCard) => item.id), (id: string, index: number) => {
              Row({ space: 12 }) {
                if (this.groupSelecting) {
                  Checkbox().select(this.groupSelection.includes(id)).shape(CheckBoxShape.CIRCLE).width(24).height(24).margin(10)
                    .responseRegion({x:-10,y:-10,width:44,height:44}).selectedColor(AppDesign.selected(this.appDark))
                    .unselectedColor(this.appMuted()).mark({strokeColor:AppDesign.onSelected(this.appDark)})
                    .accessibilityText('选择 '+layerLabel(this.cardMap[id]))
                    .onChange((checked:boolean)=>{if(this.groupSelecting && checked!==this.groupSelection.includes(id))this.selectLayerCard(id);})
                }
                Button({type:ButtonType.ROUNDED_RECTANGLE,buttonStyle:ButtonStyleMode.NORMAL}) {
                  Row({space:12}) {
                    Stack() {
                      CardFace({card:this.cardMap[id],scaleFactor:Math.min(44/this.cardMap[id].w,44/this.cardMap[id].h),tick:this.tick})
                        .width(this.cardMap[id].w*Math.min(44/this.cardMap[id].w,44/this.cardMap[id].h)).height(this.cardMap[id].h*Math.min(44/this.cardMap[id].w,44/this.cardMap[id].h))
                    }.width(52).height(52).hitTestBehavior(HitTestMode.None)
                    Column({space:4}) {
                      Text(layerLabel(this.cardMap[id])).fontSize(14).maxLines(1).textOverflow({overflow:TextOverflow.Ellipsis}).fontColor(this.appText()).width('100%')
                      Text((this.cardMap[id].groupId.length>0?'组合 · ':'')+(index===0?'最上层 · ':'')+(this.cardMap[id].capability!==null?typeLabel(this.cardMap[id].capability?.k??''):'自定义')).fontSize(11).fontColor(this.appMuted()).width('100%')
                    }.layoutWeight(1).hitTestBehavior(HitTestMode.None)
                  }.width('100%')
                }.layoutWeight(1).height(60).padding(0).backgroundColor(Color.Transparent)
                  .accessibilityText('选择卡片 '+layerLabel(this.cardMap[id])).onClick(()=>this.selectLayerCard(id))
                Button('编辑',{type:ButtonType.Capsule,buttonStyle:ButtonStyleMode.NORMAL}).height(AppDesign.controlHeight).fontSize(13).backgroundColor(this.appControl()).fontColor(this.appText()).enabled(!this.groupSelecting).onClick(()=>this.openEditor(id))
              }.width('100%').padding(8).borderRadius(12).backgroundColor(this.appSurface()).border({width:!this.groupSelecting&&this.selectedId===id?1.5:0,color:this.appMuted()})
            }, (id: string) => id)
          }.width('100%').padding({ bottom: this.homeActionHeight() + 8 })
        }.width('100%').height('100%').align(Alignment.Top).scrollBar(BarState.Off)
        if (this.homeActionHeight() > 0) {
        Column({ space: 12 }) {
        if (this.groupSelecting) { Button('组合选中卡片（' + this.groupSelection.length + '）', { type: ButtonType.Capsule, buttonStyle:ButtonStyleMode.EMPHASIZED, role:ButtonRole.NORMAL }).backgroundColor(AppDesign.selected(this.appDark)).fontColor(AppDesign.onSelected(this.appDark)).height(44).width('100%').enabled(this.groupSelection.length > 1).shadow({radius:8,color:'#18000000',offsetY:3}).onClick(() => this.confirmGroup()) }
        if (!this.groupSelecting && (this.store.findCard(this.selectedId)?.groupId ?? '').length > 0) { Button('取消组合', { type: ButtonType.Capsule, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL }).height(44).fontSize(13).backgroundColor(this.appControl()).fontColor(this.appText()).shadow({radius:8,color:'#18000000',offsetY:3}).onClick(() => this.releaseGroup()) }
        if (!this.groupSelecting && this.selectedId.length > 0) {
          Row({ space: 12 }) {
            Button('上移一层', { type: ButtonType.Capsule, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL }).height(AppDesign.controlHeight).fontSize(12).backgroundColor(this.appControl()).fontColor(this.appText()).shadow({radius:8,color:'#18000000',offsetY:3}).onClick(() => this.moveCardLayer(this.selectedId, true))
            Button('下移一层', { type: ButtonType.Capsule, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL }).height(AppDesign.controlHeight).fontSize(12).backgroundColor(this.appControl()).fontColor(this.appText()).shadow({radius:8,color:'#18000000',offsetY:3}).onClick(() => this.moveCardLayer(this.selectedId, false))
            Blank()
            Button('删除', { type: ButtonType.Capsule, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.ERROR }).height(AppDesign.controlHeight).fontSize(12).backgroundColor(this.appControl()).fontColor('#C43A35').shadow({radius:8,color:'#18000000',offsetY:3}).onClick(() => this.deleteCard(this.selectedId))
          }.width('100%')
        }
        }.width('100%').padding(8)
        }
        }.width('100%').layoutWeight(1)
      }.width(this.panelWidth).height(this.panelHeight - 84).padding(12).backgroundColor(this.appSurface()).borderRadius(AppDesign.sectionRadius)
        .position({ x: this.panelLeft, y: this.panelTop })
  }
  private homeActionHeight():number {return this.groupSelecting?60:this.selectedId.length===0?0:(this.store.findCard(this.selectedId)?.groupId??'').length>0?108:56;}
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
    this.backgroundTimer = setTimeout(() => { this.backgroundTimer = -1; this.refreshBackground(); }, 1200);
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
  private backgroundColorKey(): string { return 'canvas:' + this.store.state.canvasId; }
  private setBackgroundColor(color: string, key: string): void {
    if (!this.alive || key !== this.backgroundColorKey() || this.canvasBackground.mode !== 'solid') return;
    const bg = new CanvasBackground(); bg.color = color || '#FFFFFF'; bg.photo = this.canvasBackground.photo; this.applyBackground(bg);
  }
  private chooseBackgroundColor(): void {
    const key = this.backgroundColorKey();
    this.colorDialog = new CustomDialogController({ builder: ColorSelector({ initialColor: this.canvasBackground.color,
      onPick: (color: string) => this.setBackgroundColor(color, key) }), customStyle: true,
      openAnimation: settingsDialogOpen(), closeAnimation: settingsDialogClose(), alignment: DialogAlignment.Center, autoCancel: true }); this.colorDialog.open();
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
      onApply: (zoom: number, x: number, y: number) => { this.commitBackgroundCrop(src, zoom, x, y); } }), customStyle: true, openAnimation: settingsDialogOpen(), closeAnimation: settingsDialogClose(), autoCancel: false });
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
      Button({ type: ButtonType.ROUNDED_RECTANGLE, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL }) {
        Row({ space: 12 }) {
          CanvasBackdrop({ sceneBackground: this.canvasBackground }).width(40).height(40).borderRadius(10).clip(true).border({ width: .5, color: AppDesign.border(this.appDark) })
          Column({ space: 3 }) { Text('画布背景').fontSize(14).fontColor(this.appText()); Text(this.backgroundBusy ? '正在取色' : this.backgroundLabel()).fontSize(11).fontColor(this.appMuted()) }.alignItems(HorizontalAlign.Start)
          Blank()
        }.width('100%')
      }.height(56).layoutWeight(1).backgroundColor(Color.Transparent).padding(8).onClick(() => { this.backgroundOpen = true; })
        .bindSheet(this.backgroundOpen, this.backgroundEditor, { height: SheetSize.LARGE, showClose: true, backgroundColor: this.appBackground(), onDisappear: () => { this.backgroundOpen = false; } })
      Button(this.sharing ? '生成中' : '作品', { type: ButtonType.Capsule, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL }).id('shareCanvas').height(44).fontSize(13).padding({ left: 12, right: 12 })
        .backgroundColor(this.appControl()).fontColor(this.appText()).enabled(!this.sharing && !this.backgroundBusy).onClick(() => this.shareMenu(false))
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
          SettingsSegmented({labels:['纯色','智能取色','智能多色','照片'],selectedIndex:this.canvasBackground.mode==='preset'?2:Math.max(0,['solid','smart','blend','photo'].indexOf(this.canvasBackground.mode)),appDark:this.appDark,
            onSelect:(index:number)=>{if(!this.backgroundBusy)this.chooseBackgroundMode(['solid','smart','blend','photo'][index]);}}).enabled(!this.backgroundBusy)
          ForEach([this.canvasBackground.mode],(_mode:string)=>{
          Column({space:16}) {
          if (this.canvasBackground.mode === 'solid') {
            ColorSetting({label:'背景颜色',color:this.canvasBackground.color,canReset:false,sourceKey:this.backgroundColorKey(),appDark:this.appDark,
              onPick:(color:string,key:string)=>this.setBackgroundColor(color,key),onFallback:()=>this.chooseBackgroundColor()})
            Flex({ wrap: FlexWrap.Wrap }) {
              ForEach(['#FFFFFF','#F1EEE6','#E9E5DF','#E2E8E2','#E3E9EF','#292B2B'], (color: string) => {
                Button({ type: ButtonType.Circle, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL }).width(44).height(44).backgroundColor(color).margin({ right: 8, bottom: 8 })
                  .border({ width: this.canvasBackground.color === color ? 2 : .5, color: this.appMuted() }).accessibilityText('背景色 '+color)
                  .onClick(() => { const bg = new CanvasBackground(); bg.color = color; bg.photo = this.canvasBackground.photo; this.applyBackground(bg); })
              }, (color: string) => color)
            }.width('100%')
          }
          if (this.canvasBackground.mode === 'smart' || this.canvasBackground.mode === 'blend') {
            Text(this.backgroundBusy ? '正在从本地卡片提取颜色' : this.canvasBackground.mode === 'smart' ? '根据全部可见卡片取色，降低饱和度以衬托作品。' : '移动时保持当前配色；换图或改色后更新，也可手动重新取色。').fontSize(13).fontColor(this.appMuted()).width('100%')
            Button('重新取色', { type: ButtonType.Capsule, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL }).height(44).fontColor(this.appText()).backgroundColor(this.appControl()).enabled(!this.backgroundBusy).onClick(() => this.refreshBackground(true))
          }
          if (this.canvasBackground.mode === 'photo') {
            if (this.canvasBackground.photo.length > 0) { Button('调整照片', { type: ButtonType.Capsule, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL }).height(44).fontColor(this.appText()).backgroundColor(this.appControl()).enabled(!this.backgroundBusy).onClick(() => this.openBackgroundCrop(this.canvasBackground.photo)) }
            Button('选择本地照片', { type: ButtonType.ROUNDED_RECTANGLE, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL }).height(44).width('100%').fontColor(this.appText()).backgroundColor(this.appControl()).enabled(!this.backgroundBusy).onClick(() => this.pickBackgroundPhoto())
            Text('按桌面画布比例拖动、双指缩放后确认；原照片不修改。').fontSize(12).fontColor(this.appMuted()).width('100%')
          }
          }.width('100%').transition(settingsReveal())
          },(mode:string)=>mode)
        }.width('100%').padding(16).borderRadius(20).backgroundColor(this.appSurface()).border({ width: 1, color: AppDesign.border(this.appDark) })
        Column({ space: 16 }) {
          Text('柔色预设').fontSize(16).fontColor(this.appText()).width('100%')
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(['雾沙','庭院','海盐'], (name: string, index: number) => {
              Button(name, { type: ButtonType.Capsule, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL }).height(44).fontColor(this.appText()).backgroundColor(this.appControl()).margin({ right: 8 }).enabled(!this.backgroundBusy).onClick(() => this.setBackgroundPreset(index))
            }, (name: string) => name)
          }.width('100%')
        }.width('100%').padding(16).borderRadius(20).backgroundColor(this.appSurface()).border({ width: 1, color: AppDesign.border(this.appDark) })
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
  private templateError(prefix:string,error:Error):void {
    if(/cancel/i.test(error.message??''))return;
    console.warn('Template operation failed: '+error.name+' '+error.message);
    this.getUIContext().getPromptAction().showToast({message:prefix+'：'+(error.message??'请重试'),duration:3500});
  }
  private async shareMenu(single: boolean): Promise<void> {
    if(this.sharing || this.context === null)return;
    try { const result=await this.getUIContext().getPromptAction().showActionMenu({title:single?'卡片作品':'画布作品',buttons:[
      {text:single?'分享可编辑卡片':'分享可编辑画布',color:this.appText()}, {text:'导出成品图片',color:this.appText()}, {text:'导入作品包',color:this.appText()}]});
      if(result.index===1){await this.shareArtwork(single);return;}if(result.index===2){await this.pickTemplate();return;}
      const id=single?this.selectedId:'';if(single&&this.store.findCard(id)===null)return;this.sharing=true;
      const path=await taskpool.execute(new taskpool.Task(exportTemplate,JSON.stringify(this.store.state),id,this.context.filesDir,this.context.cacheDir)) as string;
      await shareTemplateFile(this.context as common.UIAbilityContext,path,single?'shareCard':'shareCanvas');
    }catch(e){this.templateError('分享未完成',e as Error);}finally{this.sharing=false;}
  }
  private async pickTemplate():Promise<void>{
    if(this.context===null)return;const options=new picker.DocumentSelectOptions();options.maxSelectNumber=1;options.fileSuffixFilters=['桌面作品|.fridge'];
    try{const uris=await new picker.DocumentViewPicker(this.context).select(options);if(uris.length>0)await this.reviewTemplate(uris[0]);}catch(e){this.templateError('导入未完成',e as Error);}
  }
  private async reviewTemplate(uri:string):Promise<void>{
    try{const summary=JSON.parse(await taskpool.execute(new taskpool.Task(inspectTemplate,uri)) as string) as TemplateSummary;
      this.getUIContext().showAlertDialog({title:summary.kind==='card'?'导入卡片':'导入画布',message:summary.count+' 张卡片，'+summary.images+' 个图片资源。'+(summary.kind==='canvas'?'保存为独立画布，保留现有作品。':'添加到当前画布。'),primaryButton:{value:'取消',action:()=>{}},secondaryButton:{value:summary.kind==='canvas'?'保存新画布':'添加到画布',action:()=>{this.importTemplate(uri,summary.kind);}}});
    }catch(e){this.templateError('无法导入',e as Error);}
  }
  private async importTemplate(uri:string,kind:string):Promise<void>{
    if(this.context===null)return;
    try{this.busy=true;const state=normalizeState(JSON.parse(await taskpool.execute(new taskpool.Task(materializeTemplateUri,uri,this.context.filesDir)) as string) as FridgeState);
      const cards=importedCards(state,()=>this.store.newId());
      if(kind==='canvas') {
        await this.store.save(false); this.backgroundGeneration++; fitImportedCanvas(cards,state.canvasAspect,this.canvasAspect); state.cards=cards; state.canvasAspect=this.canvasAspect;
        const id=this.store.createCanvas('导入的画布',state); this.busy=false; await this.chooseCanvas(id); return;
      }
      if(kind==='card'&&cards.length===1){cards[0].x=Math.max(0,(BOARD_W-cards[0].w)/2);cards[0].y=Math.max(0,(BOARD_H-cards[0].h)/2);}
      for(const c of cards.slice().sort((a:FridgeCard,b:FridgeCard)=>a.z-b.z)){this.clamp(c);this.store.addCard(c);}this.render();this.persist(true);this.scheduleBackground();
      if(cards.length>0)this.select(cards[0].id);
    }catch(e){this.templateError('导入未完成',e as Error);}finally{this.busy=false;}
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
          Text(this.preview.capability?.title || capabilityDescriptor(this.preview.capability?.k??'none').detail).fontSize(20).fontColor(this.appText()).fontWeight(FontWeight.Medium)
          if(this.preview.capability!==null) {
            Text(capabilityDescriptor(this.preview.capability!.k).source).fontSize(12).fontColor(this.appMuted()).width('100%')
          }
          if(this.preview.capability!==null && ['parcel','agenda'].includes(this.preview.capability!.k)) {
            CapabilityDetails({cap:this.preview.capability!,appDark:this.appDark,tick:this.tick,onUpdate:(next:CapBlock)=>this.updateExtraCapability(this.preview.id,next)})
          } else if(this.preview.capability?.k==='timetable') {
            WeekTimetable({cap:this.preview.capability!,appDark:this.appDark,editable:false,heightLimit:Math.max(200,this.screenHeight-220)})
          } else {
            CardFace({card:this.preview,scaleFactor:this.editorScale(),tick:this.tick})
              .rotate({angle:this.preview.rot,centerX:0,centerY:'100%'}).width(this.preview.w*this.editorScale()).height(this.preview.h*this.editorScale()).margin({top:24,bottom:24})
          }
          if (this.preview.capability?.k === 'calendar') {
            Row({ space: 12 }) {
              Button('上月', { type: ButtonType.Capsule, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL }).height(AppDesign.controlHeight).fontSize(14).backgroundColor(this.appControl()).fontColor(this.appText()).onClick(() => this.calendarAction('previousMonth'))
              Button('本月', { type: ButtonType.Capsule, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL }).height(AppDesign.controlHeight).fontSize(14).backgroundColor(this.appControl()).fontColor(this.appText()).onClick(() => this.calendarAction('currentMonth'))
              Button('下月', { type: ButtonType.Capsule, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL }).height(AppDesign.controlHeight).fontSize(14).backgroundColor(this.appControl()).fontColor(this.appText()).onClick(() => this.calendarAction('nextMonth'))
            }
          }
          if (this.preview.capability?.k === 'weather') {
            Text(this.preview.capability!.updatedAt ? '更新于 ' + new Date(this.preview.capability!.updatedAt!).toLocaleString() : '尚无更新记录')
              .fontSize(12).fontColor(this.appMuted())
            Button(this.weatherBusy ? '更新中' : '刷新天气', { type: ButtonType.ROUNDED_RECTANGLE, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL }).height(44).backgroundColor(this.appControl()).fontColor(this.appText()).enabled(!this.weatherBusy).onClick(() => this.refreshWeather())
          }
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
            scrollEffectStyle: { backgroundStyle: { backgroundColor: Color.Transparent, maskExtraHeight: 0, blurRadius: 16 } },
            systemMaterialEffect: { materialType: hdsMaterial.MaterialType.IMMERSIVE, materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE },
            originalStyle: { backgroundStyle: { backgroundColor: Color.Transparent, maskExtraHeight: 0, blurRadius: 16 } }
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
        }.width('100%').height('100%').padding({ top: EDITOR_NAV_INSET }).backgroundColor(Color.Transparent)
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
            scrollEffectStyle: { backgroundStyle: { backgroundColor: Color.Transparent, maskExtraHeight: 0, blurRadius: 16 } },
            systemMaterialEffect: { materialType: hdsMaterial.MaterialType.IMMERSIVE, materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE },
            originalStyle: { backgroundStyle: { backgroundColor: Color.Transparent, maskExtraHeight: 0, blurRadius: 16 } }
          }
        })
        .bindToScrollable([this.scroller]).hideBackButton(false).hideToolBar(true).mode(NavigationMode.Stack).width('100%').height('100%').backgroundColor(Color.Transparent)
    }.width('100%').height('100%').padding({ top: this.safeTop + EDITOR_SAFE_GAP }).opacity(this.editorOpacity)
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
    this.layerId = this.settingsTab === 0 ? (this.preview.elements.find((el: CanvasElement) => el.behindCapability)?.id ?? '') : (this.preview.capability!==null?'capability':''); this.showLayerOptions = false; this.syncFields();
    this.scroller.scrollTo({ xOffset: 0, yOffset: 0 });
  }
  @Builder
  editorControls() {
    SettingsSegmented({labels:['背景创作','上层内容'],selectedIndex:this.settingsTab,appDark:this.appDark,onSelect:(index:number)=>{this.editorTabs=[index];}})
      .width(this.editorControlsWidth()).margin({top:4,bottom:12})
  }
  @Builder
  editorLayers() {
    Column({ space: 8 }) { this.layersPanel() }
      .width(this.editorLandscape() ? this.editorViewportWidth() - 32 : this.screenWidth - this.editorViewportWidth() - 24)
      .height(this.editorLandscape() ? Math.min(148, this.editorBodyHeight() - this.previewPaneHeight() - 16) : this.previewPaneHeight() - 12).padding(12).backgroundColor(this.appSurface()).borderRadius(AppDesign.sectionRadius)
      .clip(true)
      .margin({ left: this.editorLandscape() ? 16 : 0, right: 16, bottom: 12 })
  }
  @Builder
  editorInspector() {
      Scroll(this.scroller) {
        Column() {
        ForEach([this.settingsTab+':'+this.layerId+':'+(this.preview.capability?.k??'none')],(_key:string)=>{
        Column({ space: 12 }) {
          if (this.layerId.length > 0 && this.layerId !== 'capability') {
            this.elementFields()
          }
          if (this.settingsTab === 0 && this.layerId.length === 0) {
            Column({ space: 16 }) {
              Text('底板').fontSize(16).fontWeight(FontWeight.Medium).fontColor(this.appText()).width('100%')
            this.colorRow('底色', 'paper')
            Row({ space: 8 }) {
              Button(this.showBackgroundOptions ? '收起底板设置' : '底板形状与边缘', { type: ButtonType.ROUNDED_RECTANGLE, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL }).layoutWeight(1).height(AppDesign.controlHeight).fontSize(14).fontColor(this.appText()).backgroundColor(this.appControl())
                .onClick(() => { this.getUIContext().animateTo({ duration: 180, curve: Curve.EaseOut, expectedFrameRateRange: this.frameRate }, () => { this.showBackgroundOptions = !this.showBackgroundOptions; }); })
            }.width('100%')
            if (this.showBackgroundOptions) {Column(){this.appearancePanel()}.width('100%').transition(settingsReveal())}
            }.width('100%').padding(16).backgroundColor(this.appSurface()).borderRadius(AppDesign.sectionRadius).clip(true)
          } else if (this.settingsTab === 1 && (this.layerId === 'capability' || this.layerId.length === 0)) {
            Column({space:16}) { this.capabilityPanel() }.width('100%').padding(16).backgroundColor(this.appSurface()).borderRadius(AppDesign.sectionRadius)
            if(this.preview.capability!==null && ['countdown','anniversary','weather','battery','agenda','parcel','fetch','timetable','worldclock'].includes(this.preview.capability!.k)) {
              Column() { this.capabilityDataPanel() }.width('100%').padding(16).backgroundColor(this.appSurface()).borderRadius(AppDesign.sectionRadius)
            }
            if(this.preview.capability!==null) {
              CapabilityAppearance({card:this.preview,appDark:this.appDark,onArrange:(anchor:string)=>this.arrangeCapability(anchor),onColor:()=>this.chooseColor('ink'),onColorPick:(color:string,key:string)=>this.setCardColor('ink',color,key),onStyle:(style:string)=>{
                const card=this.current();if(card?.capability){card.capability.readingStyle=style;this.change();}
              }})
            }
          }

          if (this.settingsTab === 1 && this.preview.capability !== null && capabilityBox(this.preview).w === 0) { Text('内容空间不足，请调整文字大小或位置').fontSize(12).fontColor('#846339').width('100%') }
          Row({ space: 12 }) {
            Button(this.sharing ? '生成中' : '分享作品', { type: ButtonType.Capsule, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL }).id('shareCard').height(44).layoutWeight(1).fontSize(14).fontColor(this.appText()).backgroundColor(this.appSurface()).enabled(!this.sharing && !this.heroActive).onClick(() => this.shareMenu(true))
            Button('复制卡片', { type: ButtonType.Capsule, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL }).height(44).layoutWeight(1).fontSize(14).fontColor(this.appText()).backgroundColor(this.appSurface()).onClick(() => this.duplicate())
          }.width('100%').margin({ top: 4 })
        }.width('100%').padding({ left: 16, right: 16, top: 4, bottom: this.safeBottom + 16 }).transition(settingsReveal())
        },(key:string)=>key)
        }.width('100%')
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
      
      if (this.layerId.length > 0 && (this.layerId!=='capability'||this.preview.capability!==null) && this.layerDrag.length === 0) {
        Button({ type: ButtonType.Circle, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL }) {SymbolGlyph($r('sys.symbol.arrow_up_left_and_arrow_down_right')).fontSize(20).fontColor([this.appText()]).hitTestBehavior(HitTestMode.None)}.width(44).height(AppDesign.controlHeight).fontSize(18).backgroundColor(this.appSurface()).fontColor(this.appText()).shadow({ radius: 6, color: '#18000000', offsetY: 2 })
          .border({ width: 1, color: '#B8B8B8' }).position({ x: this.editorHandle(true).x - 22, y: this.editorHandle(true).y - 22 })
          .accessibilityText('缩放选中元素')
          .gesture(PanGesture({ distance: 2 }).onActionStart((e: GestureEvent) => this.startTransform(this.layerId, e)).onActionUpdate((e: GestureEvent) => this.resizeElement(e))
            .onActionEnd((e: GestureEvent) => { this.resizeElement(e); this.flushPreview(); }).onActionCancel(() => this.cancelTransform()))
        if (this.layerId !== 'capability') {
          Button({ type: ButtonType.Circle, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL }) {SymbolGlyph($r('sys.symbol.arrow_clockwise')).fontSize(20).fontColor([this.appText()]).hitTestBehavior(HitTestMode.None)}.width(44).height(AppDesign.controlHeight).fontSize(18).backgroundColor(this.appSurface()).fontColor(this.appText()).shadow({ radius: 6, color: '#18000000', offsetY: 2 })
            .border({ width: 1, color: '#B8B8B8' }).position({ x: this.editorHandle(false).x - 22, y: this.editorHandle(false).y - 22 })
            .accessibilityText('旋转选中元素')
            .gesture(PanGesture({ distance: 2 }).onActionStart((e: GestureEvent) => this.startTransform(this.layerId, e)).onActionUpdate((e: GestureEvent) => this.rotateElement(e))
              .onActionEnd((e: GestureEvent) => { this.rotateElement(e); this.flushPreview(); }).onActionCancel(() => this.cancelTransform()))
        }
      }

    }.width('100%').height(this.editorCanvasHeight())

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
  private layerTitle(id:string):string {
    if(id==='capability')return typeLabel(this.preview.capability?.k??'');
    if(id.length===0)return this.settingsTab===0?'背景底板':'添加能力';
    return this.layerElement(id)?.kind==='image'?'图片':this.layerElement(id)?.kind==='shape'?'形状':'文字';
  }
  @Builder
  layerThumbnail(id:string) {
    Stack() {
      if(id.length===0 && this.settingsTab===0) {
        if(this.preview.shape==='subject' && this.preview.subjectPhoto && this.preview.cutout) {
          Image(this.preview.cutout).width(32).height(32).objectFit(ImageFit.Contain).draggable(false)
        } else {Column().width(26).height(26).borderRadius(6).backgroundColor(materialColors(this.preview.material,this.preview.paper,this.preview.ink)[0]).border({width:.5,color:AppDesign.border(this.appDark)})}
      } else if(this.layerElement(id)?.kind==='image') {
        Image(this.layerElement(id)?.src??'').width(32).height(32).objectFit(ImageFit.Contain).draggable(false)
      } else if(this.layerElement(id)?.kind==='shape') {
        Column().width(24).height(this.layerElement(id)?.primitive==='line'?3:24).borderRadius(this.layerElement(id)?.primitive==='circle'?12:4).backgroundColor(this.layerElement(id)?.color||this.appText())
      } else if(id==='capability' && ['clock','worldclock','date','lunar','calendar'].includes(this.preview.capability?.k??'')) {SymbolGlyph($r('sys.symbol.clock')).fontSize(20).fontColor([this.appText()])}
      else if(id.length===0) {SymbolGlyph($r('sys.symbol.plus')).fontSize(18).fontColor([this.appText()])}
      else {Text(id==='capability'?typeLabel(this.preview.capability?.k??'').slice(0,2):'A').fontSize(id==='capability'?12:18).fontWeight(FontWeight.Medium).fontColor(this.appText())}
    }.width(36).height(36).hitTestBehavior(HitTestMode.None)
  }
  @Builder
  layerEntry(id:string) {
    Button({type:ButtonType.ROUNDED_RECTANGLE, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL}) {
      if(this.editorLandscape() && !this.compactEditorLayers()) {
        Column({space:4}) {this.layerThumbnail(id);Text(this.layerTitle(id)).fontSize(12).fontColor(this.appText()).maxLines(1).textOverflow({overflow:TextOverflow.Ellipsis})}.width('100%').padding(8)
      } else {
        Row({space:8}) {
          this.layerThumbnail(id)
          Text(this.layerTitle(id)).fontSize(13).fontColor(this.appText()).maxLines(1).textOverflow({overflow:TextOverflow.Ellipsis}).layoutWeight(1)
          if(this.layerId===id) {SymbolGlyph($r('sys.symbol.checkmark')).fontSize(14).fontColor([this.appText()]).hitTestBehavior(HitTestMode.None)}
        }.width('100%').padding({left:8,right:12})
      }
    }.width(this.editorLandscape()?(this.compactEditorLayers()?132:96):'100%').height(this.editorLandscape()&&!this.compactEditorLayers()?76:52)
      .backgroundColor(this.layerId===id?this.appControl():Color.Transparent)
      .accessibilityText('选择图层 '+this.layerTitle(id)).onClick(()=>this.chooseLayer(id))
  }
  @Builder
  layerEntries() {
    ForEach(this.preview.elements.filter((el: CanvasElement) => el.behindCapability === (this.settingsTab === 0)).slice().reverse(), (el: CanvasElement) => {
      this.layerEntry(el.id)
    }, (el: CanvasElement) => el.id)
    if (this.settingsTab === 1 && this.preview.capability !== null) { this.layerEntry('capability') }
    if(this.settingsTab===0) {this.layerEntry('')}
    else if(this.preview.capability===null) {this.layerEntry('')}
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
          SettingsCounter({value:this.elementPreview.fs,onChange:(value:number)=>{const el=this.currentElement();if(el!==null&&el.fs!==value){el.fs=value;this.change();}}})
          SettingsSegmented({labels:['左对齐','居中','右对齐'],selectedIndex:Math.max(0,['left','center','right'].indexOf(this.elementPreview.align)),appDark:this.appDark,
            onSelect:(index:number)=>{const el=this.currentElement();if(el!==null){el.align=['left','center','right'][index];this.change();}}})
          Row() { Text('加粗').fontSize(14).fontColor(this.appText()); Blank()
            Toggle({ type: ToggleType.Switch, isOn: this.elementPreview.bold }).margin({ left: 8 }).selectedColor('#303030').accessibilityText('加粗文字')
              .onChange((v: boolean) => { const el = this.currentElement(); if (el !== null) { el.bold = v; this.change(); } })
          }.width('100%').height(AppDesign.controlHeight)
        } else if (this.elementPreview.kind === 'image') {
          Button(this.busy ? '正在读取' : '选择图片或 GIF', { type: ButtonType.ROUNDED_RECTANGLE, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL }).height(AppDesign.controlHeight).fontSize(14).backgroundColor(this.appControl()).fontColor(this.appText()).enabled(!this.busy).onClick(() => this.pickImage())
          if (this.elementPreview.animated) { Text('App 内循环播放；桌面组件展示时播放一次。').fontSize(12).fontColor(this.appMuted()).width('100%') }
        } else {
          SettingsSegmented({labels:['矩形','圆形','线条'],selectedIndex:Math.max(0,['rect','circle','line'].indexOf(this.elementPreview.primitive)),appDark:this.appDark,
            onSelect:(index:number)=>{const el=this.currentElement();if(el!==null){el.primitive=['rect','circle','line'][index];this.change();}}})
        }
        if (this.elementPreview.kind !== 'image') { this.colorRow('元素颜色', 'element') }
      }.width('100%').padding(16).backgroundColor(this.appSurface()).borderRadius(AppDesign.sectionRadius).clip(true)
    }
    if (this.layerId.length > 0) {
      Column({ space: 12 }) {
        Text('位置与显示').fontSize(16).fontWeight(FontWeight.Medium).fontColor(this.appText()).width('100%')
        if (this.layerId !== 'capability') {
          if (this.settingsTab === 0) {
            Button('铺满底板', { type: ButtonType.ROUNDED_RECTANGLE, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL }).width('100%').height(AppDesign.controlHeight).fontSize(13).backgroundColor(this.appControl()).fontColor(this.appText())
              .onClick(() => { const el = this.currentElement(); if (el !== null) { el.x = 0; el.y = 0; el.w = 1; el.h = 1; el.rot = 0; this.change(); } })
          }
        }
        Text('在预览中直接调整大小与位置').fontSize(12).fontColor(this.appMuted()).width('100%')
        Flex({ wrap: FlexWrap.Wrap }) {
          Button('水平居中', { type: ButtonType.Capsule, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL }).height(44).margin({ right: 8, bottom: 8 }).fontSize(12).backgroundColor(this.appControl()).fontColor(this.appText()).onClick(() => { const box = this.currentBox(); if (box !== null) { box.x = (1 - box.w) / 2; this.change(); } })
          Button('垂直居中', { type: ButtonType.Capsule, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL }).height(44).margin({ right: 8, bottom: 8 }).fontSize(12).backgroundColor(this.appControl()).fontColor(this.appText()).onClick(() => { const box = this.currentBox(); if (box !== null) { box.y = (1 - box.h) / 2; this.change(); } })
          if (this.layerId !== 'capability') { Button('重置角度', { type: ButtonType.Capsule, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL }).height(44).margin({ right: 8, bottom: 8 }).fontSize(12).backgroundColor(this.appControl()).fontColor(this.appText()).onClick(() => { const box = this.currentBox(); if (box !== null) { box.rot = 0; this.change(); } }) }
        }
        Column({ space: 8 }) {
          Text('透明度').fontSize(13).fontColor(this.appText())
          SettingsSegmented({labels:['实色','柔和','轻透'],selectedIndex:this.boxPreview.opacity>.85?0:this.boxPreview.opacity>.55?1:2,appDark:this.appDark,
            onSelect:(index:number)=>{const box=this.currentBox();if(box!==null){box.opacity=[1,.7,.4][index];this.change();}}})
        }.width('100%').alignItems(HorizontalAlign.Start)
        Button(this.showLayerOptions ? '收起图层操作' : '图层操作', { type: ButtonType.ROUNDED_RECTANGLE, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL }).height(AppDesign.controlHeight).width('100%').fontSize(13).fontColor(this.appText()).backgroundColor(this.appControl())
          .onClick(() => { this.getUIContext().animateTo({ duration: 180, curve: Curve.EaseOut, expectedFrameRateRange: this.frameRate }, () => { this.showLayerOptions = !this.showLayerOptions; }); })
        if (this.showLayerOptions) {
        Column({space:12}) {
        if (this.layerId !== 'capability') {
          Row({ space: 8 }) {
            Button('复制元素', { type: ButtonType.Capsule, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL }).height(AppDesign.controlHeight).fontSize(12).backgroundColor(this.appControl()).fontColor(this.appText()).onClick(() => this.duplicateElement())
            Button('上移一层', { type: ButtonType.Capsule, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL }).height(AppDesign.controlHeight).fontSize(12).backgroundColor(this.appControl()).fontColor(this.appText()).onClick(() => this.moveElementOrder(true))
            Button('下移一层', { type: ButtonType.Capsule, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL }).height(AppDesign.controlHeight).fontSize(12).backgroundColor(this.appControl()).fontColor(this.appText()).onClick(() => this.moveElementOrder(false))
        }.width('100%')

        }
        Flex({ wrap: FlexWrap.Wrap }) {
          if (this.layerId.length > 0 && this.layerId !== 'capability') {
          Button(this.settingsTab === 0 ? '移到内容层' : '移到最上层', { type: ButtonType.ROUNDED_RECTANGLE, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL }).margin({ right: 8, bottom: 8 }).height(AppDesign.controlHeight).fontSize(13).fontColor(this.appText()).backgroundColor(this.appControl())
            .onClick(() => { const card = this.current(), el = this.currentElement(); if (card !== null && el !== null) { el.behindCapability = false; this.settingsTab = 1; this.editorTabs = [1]; card.elements = card.elements.filter((e: CanvasElement) => e.id !== el.id).concat([el]); this.change(); } })
          Button(this.settingsTab === 1 ? '移到背景层' : '移到最下层', { type: ButtonType.ROUNDED_RECTANGLE, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL }).margin({ right: 8, bottom: 8 }).height(AppDesign.controlHeight).fontSize(13).fontColor(this.appText()).backgroundColor(this.appControl())
            .onClick(() => { const card = this.current(), el = this.currentElement(); if (card !== null && el !== null) {
              el.behindCapability = true; this.settingsTab = 0; this.editorTabs = [0]; card.elements = [el].concat(card.elements.filter((e: CanvasElement) => e.id !== el.id)); this.change();
            } })
          }
          Button('移除此元素', { type: ButtonType.ROUNDED_RECTANGLE, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.ERROR }).height(AppDesign.controlHeight).fontSize(13).fontColor('#C43A35').backgroundColor(Color.Transparent).onClick(() => this.removeElement())
        }
        }.width('100%').transition(settingsReveal())
        }
      }.width('100%').padding(16).backgroundColor(this.appSurface()).borderRadius(AppDesign.sectionRadius).clip(true)
    }
  }
  private chooseCapability(): void {
    const id=this.preview.id;
    this.capabilityDialog=new CustomDialogController({builder:CapabilityPicker({selected:this.preview.capability?.k??'none',appDark:this.appDark,onChoose:(key:string)=>{
      if(this.editing && this.preview.id===id)this.setCapability(key);
    }}),customStyle:true,openAnimation:settingsDialogOpen(),closeAnimation:settingsDialogClose(),autoCancel:true});this.capabilityDialog.open();
  }
  @Builder
  capabilityPanel() {
    Row({space:12}) {
      Column({space:4}) {
        Text(capabilityDescriptor(this.preview.capability?.k??'none').name).fontSize(16).fontWeight(FontWeight.Medium).fontColor(this.appText()).width('100%')
        Text(capabilityDescriptor(this.preview.capability?.k??'none').summary).fontSize(12).fontColor(this.appMuted()).width('100%')
      }.layoutWeight(1)
      Button('选择能力',{type:ButtonType.Capsule, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL}).height(44).fontSize(13).backgroundColor(this.appControl()).fontColor(this.appText()).onClick(()=>this.chooseCapability())
    }.width('100%')
  }
  @Builder
  capabilityDataPanel() {
    Column({space:12}) {
      Text('内容与来源').fontSize(16).fontWeight(FontWeight.Medium).fontColor(this.appText()).width('100%')
      Text(capabilityDescriptor(this.preview.capability?.k??'none').source).fontSize(12).fontColor(this.appMuted()).width('100%')
      if (this.preview.capability?.k === 'countdown' || this.preview.capability?.k === 'anniversary') {
        TextInput({ text: this.titleValue, placeholder: '名称' }).height(AppDesign.controlHeight).borderRadius(AppDesign.controlRadius).fontSize(16).fontColor(this.appText()).placeholderColor(this.appMuted()).backgroundColor(this.appControl())
          .onChange((v: string) => { this.titleValue = v; const cap = this.current()?.capability; if (cap !== null && cap !== undefined) { cap.title = v; this.change(); } })
        Button('日期  ' + (this.preview.capability?.date ?? ''), { type: ButtonType.ROUNDED_RECTANGLE, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL }).height(AppDesign.controlHeight).fontColor(this.appText()).backgroundColor(this.appControl()).onClick(() => this.pickDate())
      }
      if (this.preview.capability?.k === 'worldclock') {
        TimeCapabilitySettings({cap:this.preview.capability!,appDark:this.appDark,onUpdate:(next:CapBlock)=>this.updateExtraCapability(this.preview.id,next)})
      }
      if (this.preview.capability?.k === 'weather') {
        TextInput({ text: this.cityValue, placeholder: '城市' }).height(AppDesign.controlHeight).borderRadius(AppDesign.controlRadius).fontSize(16).fontColor(this.appText()).placeholderColor(this.appMuted()).backgroundColor(this.appControl())
          .onChange((v: string) => { this.cityValue = v; const cap = this.current()?.capability; if (cap !== null && cap !== undefined) { if (cap.city !== v.trim()) { cap.city = v.trim(); cap.temp = '--°'; cap.desc = '未更新'; cap.updatedAt = 0; cap.attemptedAt = 0; cap.refreshState = ''; this.change(); } } })
          .onSubmit(() => this.refreshWeather())
        Button(this.weatherBusy ? '更新中' : '更新天气', { type: ButtonType.ROUNDED_RECTANGLE, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL }).height(AppDesign.controlHeight).backgroundColor(this.appControl()).fontColor(this.appText()).enabled(!this.weatherBusy).onClick(() => this.refreshWeather())
        Text(this.preview.capability?.refreshState === 'failed' ? '暂时无法获取天气，稍后自动重试' : '天气自动更新；打开 App 时会补刷过期数据').fontSize(12).fontColor(this.appMuted()).width('100%')
      }
      if(this.preview.capability!==null && ['battery','agenda','parcel','fetch','timetable'].includes(this.preview.capability!.k)) {
        CapabilitySettings({cap:this.preview.capability!,cardId:this.preview.id,appDark:this.appDark,onUpdate:(id:string,next:CapBlock)=>this.updateExtraCapability(id,next)})
      }
    }.width('100%')
  }
  private arrangeCapability(anchor:string):void {
    const card=this.current();if(card===null || card.capability===null)return;
    card.capBox=capabilityPreset(card,anchor);this.change();
  }
  private cardColorKey(target: string): string { return this.preview.id + ':' + target + ':' + (target === 'element' ? this.layerId : ''); }
  private setCardColor(target: string, color: string, key: string): void {
    if (!this.alive || !this.editing || key !== this.cardColorKey(target)) return;
    const card = this.current(); if (card === null) return;
    if (target === 'element') { const element = this.currentElement(); if (element === null) return; element.color = color; }
    if (target === 'paper') card.paper = color; if (target === 'ink') card.ink = color;
    this.syncFields(); this.change();
  }
  private chooseColor(target: string): void {
    const card = this.current(); if (card === null) return;
    const element = this.currentElement(), key = this.cardColorKey(target);
    const initial = target === 'element' ? (element?.color || materialColors(card.material, card.paper, card.ink)[1]) :
      target === 'ink' && card.shape === 'subject' && card.subjectPhoto && !card.ink ? card.subjectInk : materialColors(card.material, card.paper, card.ink)[target === 'paper' ? 0 : 1];
    this.colorDialog = new CustomDialogController({ builder: ColorSelector({ initialColor: initial,
      onPick: (color: string) => this.setCardColor(target, color, key) }), customStyle: true,
      openAnimation: settingsDialogOpen(), closeAnimation: settingsDialogClose(), alignment: DialogAlignment.Center, autoCancel: true });
    this.colorDialog.open();
  }
  @Builder
  colorRow(label: string, target: string) {
    ColorSetting({ label: label, color: (target === 'element' ? this.elementColor : target === 'paper' ? this.paperValue : this.inkValue) || materialColors(this.preview.material, this.preview.paper, this.preview.ink)[target === 'paper' ? 0 : 1],
      automatic: (target === 'element' ? this.elementColor : target === 'paper' ? this.paperValue : this.inkValue).length === 0, sourceKey: this.cardColorKey(target), appDark: this.appDark,
      onPick: (color: string, key: string) => this.setCardColor(target, color, key), onFallback: () => this.chooseColor(target) })
  }
  @Builder
  appearancePanel() {
    Column({ space: 12 }) {
      Text('底板配色').fontSize(14).fontWeight(FontWeight.Medium).fontColor(this.appText()).width('100%')
      Select(['白','米色','牛皮纸','绿','蓝','粉','黑'].map((value:string):SelectOption=>({value:value})))
        .selected(Math.max(0,THEMES.indexOf(this.preview.material))).value(['白','米色','牛皮纸','绿','蓝','粉','黑'][Math.max(0,THEMES.indexOf(this.preview.material))])
        .font({size:14}).fontColor(this.appText()).optionFontColor(this.appText()).optionBgColor(this.appSurface())
        .selectedOptionFontColor(AppDesign.onSelected(this.appDark)).selectedOptionBgColor(AppDesign.selected(this.appDark))
        .backgroundColor(this.appControl()).borderRadius(12).controlSize(ControlSize.NORMAL).width('100%').height(44)
        .onSelect((index:number)=>{const card=this.current();if(card!==null&&THEMES[index]){card.material=THEMES[index];card.paper='';this.paperValue='';this.change();}})
      Text('形状').fontSize(14).fontWeight(FontWeight.Medium).fontColor(this.appText()).width('100%').margin({ top: 8 })
      Select((this.preview.cutout.length>0?['方形','椭圆','胶囊','自由边角','照片主体']:['方形','椭圆','胶囊','自由边角']).map((value:string):SelectOption=>({value:value})))
        .selected(this.preview.shape==='subject'?4:Math.max(0,SHAPES.indexOf(this.preview.shape)))
        .value(this.preview.shape==='subject'?'照片主体':['方形','椭圆','胶囊','自由边角'][Math.max(0,SHAPES.indexOf(this.preview.shape))])
        .font({size:14}).fontColor(this.appText()).optionFontColor(this.appText()).optionBgColor(this.appSurface())
        .selectedOptionFontColor(AppDesign.onSelected(this.appDark)).selectedOptionBgColor(AppDesign.selected(this.appDark))
        .backgroundColor(this.appControl()).borderRadius(12).controlSize(ControlSize.NORMAL).width('100%').height(44)
        .onSelect((index:number)=>{const card=this.current();if(card!==null){if(index===4&&card.cutout.length>0){card.shape='subject';card.h=card.w/card.subjectAspect;}else if(SHAPES[index])card.shape=SHAPES[index];else return;this.change();}})
      Button(this.busy ? '正在处理照片' : '用照片主体作为形状', { type: ButtonType.ROUNDED_RECTANGLE, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL }).height(AppDesign.controlHeight).width('100%').fontSize(14)
        .fontColor(this.appText()).backgroundColor(this.appControl()).enabled(!this.busy).onClick(() => this.pickImage(true))
      if (this.preview.cutout.length > 0 && this.preview.shape !== 'subject') {
        Button('恢复主体形状', { type: ButtonType.ROUNDED_RECTANGLE, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL }).height(AppDesign.controlHeight).fontColor(this.appText()).backgroundColor(this.appControl())
          .onClick(() => { const card = this.current(); if (card !== null) { card.shape = 'subject'; card.h = card.w / card.subjectAspect; this.change(); } })
      }
      if (this.preview.cutout.length > 0) {
        Text('主体外观').fontSize(14).fontColor(this.appText()).width('100%')
        SettingsSegmented({labels:['只用形状','主体照片作底图'],selectedIndex:this.preview.subjectPhoto?1:0,appDark:this.appDark,
          onSelect:(index:number)=>{const card=this.current();if(card!==null){card.subjectPhoto=index===1;this.change();}}})
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
