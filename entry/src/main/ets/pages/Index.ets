import { canvasRotationEnabled } from '../model/CanvasRotation';
import { prepareReadingTints, ReadingTintRequest, ReadingTintResult } from '../model/ReadingMaterialWorker';
import { cardSource, hash } from '../model/BackgroundInputs';
import { capabilityRenderTick } from '../model/CapabilityClock';
import lazy { HookPlacement } from '../views/HookPlacement';
import lazy { EditorVisualChoices } from '../views/EditorVisualChoices';
import { editorWorkspace, EditorWorkspace } from '../model/EditorWorkspace';
import { editorReadingPlacement } from '../model/EditorVisualChoices';
import { sameTimetable, useSavedTimetable } from '../model/TimetableLibrary';
import { edgeAttachment } from '../model/EdgeAttachment';
import { capabilityAttachmentEdges } from '../model/CanvasLayout';
import { preferredReadingStyle, defaultReadingStyle } from '../model/ReadingStylePolicy';
import { CompositionOverflow, compositionOverflow, isReadingComposition, snapComposition, readingStyles } from '../model/ReadingComposition';
import { CenterGuides } from '../views/CenterGuides';
import lazy { ReadingComparison } from '../views/ReadingComparison';
import { CardDeletionFlight } from '../views/CardDeletionFlight';
import lazy { enhanceImageJob, supportsSuperResolution } from '../model/SuperResolution';
import { EnhancementPreview } from '../views/EnhancementPreview';
import { revealStartup } from '../model/StartupPresentation';
import { removeStagedTemplate } from '../model/IncomingTemplate';
import { workspaceLayout } from '../model/WorkspaceLayout';
import { cardContainsPoint } from '../model/CardHitTest';
import lazy { SceneSchedulePanel } from '../views/SceneSchedulePanel';
import { SceneRule, SavedSceneLayout, normalizeSceneRules } from '../model/SceneScheduleSchema';
import { ScheduledScene, SceneOccurrence, activeSceneRule, nextSceneBoundary, projectScheduledScene, resolveScheduledScene, captureSceneLayout, dismissScene, setNormalSceneLayout, refreshNormalSceneLayout } from '../model/SceneSchedule';
import { EditorLayerMotion } from '../model/EditorLayerMotion';
import lazy { EditorLayerTarget, EditorLayerHandles } from '../views/EditorLayerControls';
import { startupMark } from '../model/StartupTrace';
import { image } from '@kit.ImageKit';
import { assertCanvasCapacity, CANVAS_CARD_TARGET, CANVAS_CARD_LIMIT, canvasCapacityHint } from '../model/CanvasCapacity';
import { SymbolGlyphModifier, FrameCallback, LengthMetrics } from '@kit.ArkUI';
import { chromeMaterial, popupMaterial, immersiveChrome, prepareChromeMaterial } from '../model/ChromeMaterial';
import lazy { TimeCapabilitySettings } from '../views/TimeCapabilitySettings';
import lazy { SettingsSelect } from '../views/SettingsSelect';
import lazy { SettingsSegmented } from '../views/SettingsSegmented';
import lazy { SettingsCounter } from '../views/SettingsCounter';
import { canvasToolsMotion, canvasToolsTransition, settingsContentSwap, settingsReveal, settingsDialogOpen, settingsDialogClose } from '../model/SettingsMotion';
import lazy { CapabilityDetails } from '../views/CapabilityDetails';
import lazy { WeekTimetable } from '../views/WeekTimetable';
import lazy { CapabilityPicker } from '../views/CapabilityPicker';
import { capabilityDescriptor } from '../model/CapabilityCatalog';
import { capabilityPreset } from '../model/CanvasLayout';
import { BatteryObserver } from '../model/BatteryObserver';
import { needsDataRefresh, capabilityRequestKey } from '../model/CapabilityData';
import { readCapability } from '../model/CapabilityService';
import lazy { CapabilitySettings } from '../views/CapabilitySettings';
import { primeRenderContours } from '../model/RenderContours';
import { storageSnapshot } from '../model/StorageSnapshot';
import { CanvasEntry, withScenePolicy, sceneDocumentExists } from '../model/CanvasLibrary';
import lazy { GroupSelection } from '../views/GroupSelection';
import { GroupBox, groupBox, groupMinimumScale, transformGroup } from '../model/GroupGeometry';
import { BoardMotion, GroupPose } from '../model/BoardMotion';
import { layerSections, LayerSection, combineCards, ungroupCards, groupMembers, groupDragBounds, cleanGroups } from '../model/CardGroups';
import lazy { PhotoCrop } from '../views/PhotoCrop';
import lazy { prepareSceneRelief } from '../model/SceneRelief';
import { CanvasFrame } from '../views/CanvasFrame';
import { CanvasBackdrop } from '../views/CanvasBackdrop';
import { CanvasBackground, FridgeState, normalizeState, normalizeBackground } from '../model/CardSchema';
import { backgroundSignature, createSmartBackground, importBackgroundPhoto, cropBackgroundPhoto } from '../model/BackgroundWorker';
import lazy { exportTemplate, inspectTemplate, materializeTemplateUri } from '../model/TemplateFiles';
import lazy { TemplateSummary, importedCards, fitImportedCanvas, remapSceneSchedules } from '../model/TemplatePackage';
import { picker } from '@kit.CoreFileKit';
import lazy { sharePixelMap, shareTemplateFile } from '../model/ImageShare';
import { taskpool } from '@kit.ArkTS';
import { common } from '@kit.AbilityKit';
import { AppDesign } from '../model/AppDesign';
import { arrivalOffset } from '../model/ArrivalGeometry';
import { motionFrameRate } from '../model/MotionPolicy';
import { HdsNavigation, HdsNavigationTitleMode, IconStyleMode, TextStyleMode, ScrollEffectType, BlurStrategy, hdsMaterial } from '@kit.UIDesignKit';
import { EditorViewport, editorViewport } from '../model/EditorViewport';
import { SelectionHandles, selectionHandles } from '../model/SelectionHandles';
import { CardEditHistory } from '../model/CardEditHistory';
import lazy { ColorSetting } from '../views/ColorSetting';
import lazy { ColorSelector } from '../views/ColorSelector';
import { FridgeStore, FridgeCard, CanvasElement, ElementBox, ShapePoint, CapBlock, BOARD_W, BOARD_H, materialColors, shapeRadius, typeLabel } from '../model/FridgeModel';
import { CardCanvas } from '../views/CardCanvas';
import { cardStorageShell, cardViewSnapshot, cardRenderSnapshot } from '../model/CardViewSnapshot';
import { CardFace } from '../views/CardFace';
import { sceneRect, SceneRect, layerLabel } from '../model/SceneLayout';
import lazy { extractSubject, repairSubject } from '../model/SubjectShape';
import { BoardCard } from '../views/BoardCard';
import { constrainCapabilityDrag, cardCapabilityMinimum, capabilityBox, capabilityPlacement, safeContentBox, clampCardGeometry, ensureCapabilitySize, subjectSurfaceFactor, cardHandlePoint } from '../model/CanvasLayout';
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

/** Start a transition after the inspector's first measure, not on a guessed timer. */
class PreparedTransition extends FrameCallback {
  private start: () => void;
  private idle: boolean;
  constructor(start: () => void, idle: boolean = false) { super(); this.start = start; this.idle = idle; }
  // Idle callbacks can be indefinitely deferred on a busy/high-refresh display.
  // Queue transitions after the frame's synchronous measure/layout instead.
  onFrame(_time: number): void { if(!this.idle)setTimeout(()=>this.start(),0); }
  onIdle(_budget: number): void { if(this.idle)this.start(); }
}

@Entry
@Component
struct Index {
  @State navMenuOpen:boolean=false;
  @State navMenuItems:MenuElement[]=[];
  @State navMenuX:number=0;
  @State navMenuY:number=0;
  private navMenuResult:number=-1;
  private navMenuResolve:((index:number)=>void)|null=null;
  @State chromeSnapshot: image.PixelMap | undefined = undefined;
  private retiredChrome: image.PixelMap | undefined = undefined;
  private chromeSignature: string = '';
  @State heroHideContent: boolean = false;
  private batteryObserver:BatteryObserver=new BatteryObserver();
  private refreshingCapabilities:boolean=false;
  private widgetRouteTimer:number=-1;
  @State deletionId:string='';
  @State deletionBitmap:image.PixelMap|undefined=undefined;
  private deletionX:number=0;private deletionY:number=0;
  private deletionW:number=0;private deletionH:number=0;private deletionAngle:number=0;
  private deletionTimer:number=-1;
  private enhancementDialog: CustomDialogController | null = null;
  private enhancementOpen: boolean = false;
  @State readingComparisonOpen: boolean = false;
  @State enhancingSubject: boolean = false;
  @State enhancingBackground: boolean = false;
  private photoCropDialog: CustomDialogController | null = null;
  @State canvasPickerOpen: boolean = false;
  @State canvasCreating: boolean = false;
  @State canvasDuplicate: boolean = false;
  @State canvasDraftName: string = '';
  @State canvasChanging: boolean = false;
  @State canvasEntries: CanvasEntry[] = [];
  @State canvasName: string = '我的画布';
  @State renameValue: string = '';
  @State canvasRenameId: string = '';
  @StorageLink('routeCanvasId') @Watch('canvasRouteChanged') routeCanvasId: string = '';
  @State groupSelecting: boolean = false;
  @State groupSelection: string[] = [];
  @State boardMotion: BoardMotion = new BoardMotion();
  private movingGroupIds: string[] = [];
  private store: FridgeStore = new FridgeStore();
  @State @Watch('homeToolsChanged') scheduleOpen:boolean=false;
  @State timingHeaderActive:boolean=false;
  @State backgroundHeaderActive:boolean=false;
  @State sceneEditing:boolean=false;
  @State scenePanelTab:number=0;
  @State sceneEntries:CanvasEntry[]=[];
  @State copyTargetOpen:boolean=false;
  private sceneReturnId:string='';
  private sceneNavigationBusy:boolean=false;
  @State scheduleRules:SceneRule[]=[];
  @State savedLayouts:SavedSceneLayout[]=[];
  @State normalLayoutId:string='';
  @State scheduledName:string='';
  @State scheduledFocusId:string='';
  @State scheduleTransition:boolean=false;
  @State schedulePhase:number=0;
  private timedScene:ScheduledScene|null=null;
  private scheduleVisualGeneration:number=0;
  private scheduleOverride:SceneRule|null=null;
  private scheduleTimer:number=-1;
  private scheduleGeneration:number=0;
  private scheduling:boolean=false;
  private context: Context | null = null;
  private frameRate: ExpectedFrameRateRange = motionFrameRate();
  private maintenanceTimer: number = -1;
  @State arriving: boolean = false;
  @State arrival: number = 0;
  @State private layerMotion:EditorLayerMotion = new EditorLayerMotion();
  private saveTimer: number = -1;
  private previewTimer: number = -1;
  private alive: boolean = true;
  private clockTimer: number = -1;
  private layerStartX: number = 0;
  private layerStartY: number = 0;
  private layerFreeStart:boolean=false;
  private scroller: Scroller = new Scroller();
  private detailScroller: Scroller = new Scroller();
  private history: CardEditHistory = new CardEditHistory();
  private gestureGroup: string = '';
  @State undoAvailable: boolean = false;
  @State redoAvailable: boolean = false;
  @StorageLink('safeTop') @Watch('layoutBoard') safeTop: number = 36;
  @StorageLink('safeBottom') @Watch('layoutBoard') safeBottom: number = 24;
  @StorageLink('editCardId') @Watch('routeChanged') routedId: string = '';
  @StorageLink('viewCardId') @Watch('viewRouteChanged') viewRouteId: string = '';
  @StorageLink('incomingTemplateUri') @Watch('incomingTemplateChanged') incomingUri: string = '';
  @StorageLink('incomingTemplateError') @Watch('incomingTemplateChanged') incomingError: string = '';
  private incomingReview: boolean = false;
  private templateReviewOpen: boolean = false;
  private incomingTimer: number = -1;
  private incomingDeferred: string = '';
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
  @State scatter: number = 0;
  @State showBackgroundOptions: boolean = false;
  @State showLayerOptions: boolean = false;
  @State editorSection:number=0;
  @State editorSheetTab:number=0;
  @State editorExpanded:boolean=false;
  @State editorSheetHeightVp:number=0;
  @State editorSheetOpen:boolean=false;
  @State @Watch('homeToolsChanged') homeToolsOpen:boolean=false;
  @State homeToolsMoving:boolean=false;
  private homeToolsMotionGeneration:number=0;
  @State capabilityPickerOpen:boolean=false;
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
  private editorBackPending:boolean=false;
  @State creatingTransition: boolean = false;
  @State transitionClipX: number = 0;
  @State transitionClipY: number = 0;
  @State transitionClipW: number = 390;
  @State transitionClipH: number = 844;
  @State transitionClipRadius: number = 0;
  @StorageLink('appDark') @Watch('sceneThemeChanged') appDark: boolean = false;
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
  @State paperValue: string = '';
  @State inkValue: string = '';
  @State elementColor: string = '';
  @State busy: boolean = false;
  @State canvasBackground: CanvasBackground = new CanvasBackground();
  @State @Watch('homeToolsChanged') backgroundOpen: boolean = false;
  @State backgroundBusy: boolean = false;
  @State sharing: boolean = false;
  private backgroundGeneration: number = 0;
  private backgroundTimer: number = -1;
  private readingTintTimer:number=-1;
  private readingTintBusy:boolean=false;
  @StorageLink('appBackgrounded') @Watch('appWentBackground') appBackgrounded: boolean = false;
  private appWentBackground(): void {
    if(this.appBackgrounded) {
      this.cancelForegroundRefresh();this.finishCardDeletion();
      if(!this.ready)return;
      if(this.scheduleTransition){this.scheduleVisualGeneration++;this.scheduleTransition=false;this.schedulePhase=0;this.timedScene=null;this.scheduledName='';this.scheduledFocusId='';this.renderBoard();}
      this.flushPendingEdits();
    } else if(this.ready) {this.scheduleForegroundRefresh();this.incomingTemplateChanged();}
  }
  private flushPendingEdits():void {
    if(this.previewTimer>=0||this.gestureGroup.length>0)this.flushPreview();
    // Changes already publish at their commit. A pure window roundtrip has no
    // edits to serialize or deliver, and page-hide/background must not duplicate it.
    if(this.saveTimer>=0)this.persist(true);
  }
  @StorageLink('appWindowFocused') @Watch('windowFocusChanged') appWindowFocused:boolean=true;
  private windowFocusChanged():void {if(!this.appWindowFocused)this.cancelForegroundRefresh();else if(this.ready)this.scheduleForegroundRefresh();}
  private foregroundGeneration:number=0;
  private pageVisible:boolean=true;
  private cancelForegroundRefresh():void {
    this.foregroundGeneration++;
    if(this.foregroundRefreshTimer>=0)clearTimeout(this.foregroundRefreshTimer);
    this.foregroundRefreshTimer=-1;
  }

  @State repairingSubjects: boolean = false;
  @State tick: number = Math.floor(Date.now()/60000)*60000;
  private foregroundRefreshTimer: number = -1;

  aboutToAppear(): void {
    this.alive = true;
    this.context = this.getUIContext().getHostContext() ?? null;
    this.initialize();
    this.clockTimer = setInterval(() => { if(!this.alive||!this.ready||!this.pageVisible||!this.appWindowFocused||this.appBackgrounded||this.deletionId || this.readingComparisonOpen || this.gestureGroup || this.activeBoardId || this.heroActive || this.arriving)return;this.tick = Math.floor(Date.now()/60000)*60000;this.refreshCapabilities();this.updateScheduledScene(true); }, 60000);
    this.batteryObserver.start(()=>this.refreshCapabilities());
  }
  private initialize(): void {
    if (this.context === null) return;
    const materialReady=prepareChromeMaterial();
    this.store.init(this.context).then(async () => {
      await materialReady; startupMark('material-ready');
      if ((this.viewRouteId||this.routedId) && this.routeCanvasId && this.routeCanvasId!==this.store.state.canvasId) await this.store.openCanvas(this.routeCanvasId);
      this.refreshCanvasList();
      // Refresh host geometry for the next launch without changing the visible arrival aspect.
      // Cached host geometry is enough for first paint. System IPC must not hold the screen blank.
      this.store.refreshCanvasSpecs().catch(() => {});
      if (!this.alive) return;
      for (const card of this.store.state.cards) {
        if (!ensureCapabilitySize(card)) this.error = '部分卡片内部空间不足，请放大、更换形状或移除能力';
      }
      this.canvasDimension=this.store.state.canvasDimension;
      this.canvasAspect=this.store.state.canvasAspect; // Authored ratio is independent of launcher orientation.
      // The launcher already animates the form into this window. A second cold
      // scatter/prepare sequence underneath it fights quick gesture cancellation.
      const widgetLaunch=AppStorage.get<boolean>('launchFromWidget')===true;
      const routedLaunch = widgetLaunch || this.routedId.length > 0 || this.viewRouteId.length > 0;
      this.canvasBackground = this.store.state.background; this.layoutBoard();
      startupMark('geometry-ready');
      if(!this.alive)return;
      this.ready = true; this.render(); this.queueReadingTints();this.queueRelief(); startupMark('scene-ready');
      this.getUIContext().postFrameCallback(new PreparedTransition(()=>startupMark('scene-idle'),true));
      this.scheduleBackground(); this.routeChanged(); this.viewRouteChanged(); this.incomingTemplateChanged();
      if(!this.viewRouteId && this.routeCanvasId===this.store.state.canvasId)AppStorage.setOrCreate('routeCanvasId','');
      if(widgetLaunch && !this.editing && !this.viewing && this.cardIds.length>0)this.prepareWidgetScene();
      else if (!routedLaunch && this.cardIds.length > 0) this.startArrival();
      else this.getUIContext().postFrameCallback(new PreparedTransition(() => { revealStartup(); }));
      this.scheduleMaintenance();

    }).catch((e: Error) => { this.error = e.message; this.getUIContext().postFrameCallback(new PreparedTransition(() => { revealStartup(); })); });
  }
  private scheduleMaintenance(): void {
    this.maintenanceTimer = setTimeout(() => {
      this.maintenanceTimer = -1;
      if (!this.alive) return;
      if(!this.pageVisible||!this.appWindowFocused||this.appBackgrounded)return;
      if (this.arriving || this.heroActive || this.activeBoardId || this.gestureGroup || this.editing || this.busy) {
        this.scheduleMaintenance(); return;
      }
      // Opening an unchanged canvas is not an edit: do not reserialize it or
      // trigger a desktop delivery immediately after the entrance.
      this.syncSchedules(); this.updateScheduledScene(true);
      this.repairStoredSubjects(); this.refreshCapabilities();
    }, 1200);
  }
  private refreshCanvasList(): void {
    this.canvasEntries = this.store.catalog.canvases.map((c: CanvasEntry): CanvasEntry => ({id:c.id,name:c.name}));
    this.sceneEntries=this.store.catalog.scenes.slice();this.canvasName = this.store.activeName; this.renameValue = this.canvasName;
  }
  private canvasRouteChanged(): void { if(this.ready && this.routeCanvasId) this.scheduleWidgetRoute(); }
  private async foregroundSchedules(generation:number):Promise<void> {
    try{await this.store.reloadSceneAcknowledgements();}catch(_){}
    if(!this.alive||!this.pageVisible||!this.appWindowFocused||this.appBackgrounded||generation!==this.foregroundGeneration)return;this.syncSchedules();this.refreshCapabilities();this.updateScheduledScene();this.scheduleMaintenance();
  }
  private scheduleForegroundRefresh():void {
    this.cancelForegroundRefresh();
    if(!this.pageVisible||!this.appWindowFocused||this.appBackgrounded)return;
    const generation=this.foregroundGeneration;
    this.foregroundRefreshTimer=setTimeout(()=>{
      this.foregroundRefreshTimer=-1;if(!this.alive||!this.pageVisible||!this.appWindowFocused||this.appBackgrounded||generation!==this.foregroundGeneration)return;
      if(this.deletionId||this.arriving||this.heroActive||this.activeBoardId||this.layerDrag||this.gestureGroup){this.scheduleForegroundRefresh();return;}
      // Resume/PageShow arrive together. Reconcile once after the system's
      // window entrance, instead of invalidating the entire scene twice in it.
      const tick=Math.floor(Date.now()/60000)*60000;if(tick!==this.tick)this.tick=tick;this.foregroundSchedules(generation);
    },700);
  }
  private syncSchedules():void {
    this.normalLayoutId=this.store.state.sceneBaseLayoutId;
    if(this.scheduleRules.length>0||this.store.catalog.sceneRules.length>0)this.scheduleRules=this.store.catalog.sceneRules.slice();
    if(this.savedLayouts.length>0||this.store.state.sceneLayouts.length>0)this.savedLayouts=this.store.state.sceneLayouts.slice();
  }
  private armScheduleTimer():void {
    if(this.scheduleTimer>=0)clearTimeout(this.scheduleTimer);if(!this.alive||!this.ready||!this.pageVisible||!this.appWindowFocused||this.appBackgrounded||(!withScenePolicy(this.store.state,this.store.catalog,this.appDark).sceneRules.some(r=>r.enabled)&&!canvasRotationEnabled(this.store.catalog.rotation)))return;
    const wait=Math.min(60000,Math.max(100,nextSceneBoundary(withScenePolicy(this.store.state,this.store.catalog,this.appDark),Date.now())-Date.now()));
    this.scheduleTimer=setTimeout(()=>{this.scheduleTimer=-1;this.updateScheduledScene();},wait);
  }
  private async updateScheduledScene(force:boolean=false):Promise<void> {
    if(!this.alive||!this.ready||this.appBackgrounded||this.sceneEditing)return;
    if(!this.scheduleOverride && !this.timedScene && (!withScenePolicy(this.store.state,this.store.catalog,this.appDark).sceneRules.some(r=>r.enabled)&&!canvasRotationEnabled(this.store.catalog.rotation))) {
      if(this.scheduleTimer>=0)clearTimeout(this.scheduleTimer);this.scheduleTimer=-1;return;
    }
    if(this.deletionId||this.scheduling||this.scheduleTransition||this.arriving||this.editing||this.viewing||this.heroActive||this.activeBoardId||this.gestureGroup||this.backgroundOpen||this.templateReviewOpen||this.incomingReview||this.sharing||this.busy) {
      if(this.scheduleTimer>=0)clearTimeout(this.scheduleTimer);this.scheduleTimer=setTimeout(()=>this.updateScheduledScene(force),1000);return;
    }
    this.scheduling=true;const generation=this.scheduleGeneration,baseId=this.store.state.canvasId;
    try {
      let next:ScheduledScene;
      if(this.scheduleOverride) {
        const o=new SceneOccurrence();o.rule=this.scheduleOverride;o.token='preview';o.start=Date.now();o.end=Number.POSITIVE_INFINITY;
        const target=await this.store.canvasSnapshot(o.rule.targetId);if(target.cards.length!==1)throw new Error('请先添加中央卡片');next=projectScheduledScene(withScenePolicy(this.store.state,this.store.catalog,this.appDark),o,target);
      } else next=await resolveScheduledScene(withScenePolicy(this.store.state,this.store.catalog,this.appDark),Date.now(),async(id:string):Promise<FridgeState|null>=>{
        if(!sceneDocumentExists(this.store.catalog,id))return null;return this.store.canvasSnapshot(id);
      });
      if(!this.alive||!this.pageVisible||!this.appWindowFocused||this.appBackgrounded||generation!==this.scheduleGeneration||baseId!==this.store.state.canvasId||this.sceneEditing)return;
      if(!force&&next.key===(this.timedScene?.key??'base')&&next.normalState.canvasId===this.store.state.canvasId)return;
      await primeRenderContours(next.state.cards,storageSnapshot(next.state));
      if(!this.alive||!this.pageVisible||!this.appWindowFocused||this.appBackgrounded||generation!==this.scheduleGeneration||baseId!==this.store.state.canvasId||this.sceneEditing)return;
      this.applyScheduledScene(next);
    } catch(_) {if(this.scheduleOverride){this.scheduleOverride=null;this.getUIContext().getPromptAction().showToast({message:'请先完成中央卡片，再预览场景'});}}
    finally {this.scheduling=false;this.armScheduleTimer();}
  }
  private applyScheduledScene(next:ScheduledScene):void {
    const previous=this.timedScene?.key??'base',differentCanvas=(this.timedScene?.state.canvasId??this.store.state.canvasId)!==next.state.canvasId;
    if(previous!==next.key){this.backgroundGeneration++;if(this.backgroundTimer>=0)clearTimeout(this.backgroundTimer);this.backgroundTimer=-1;this.backgroundBusy=false;}
    const apply=():void=>{if(next.normalState.canvasId!==this.store.state.canvasId){this.store.adoptCanvas(next.normalState);this.canvasAspect=this.store.state.canvasAspect;this.canvasDimension=this.store.state.canvasDimension;this.layoutBoard();this.refreshCanvasList();this.persist(false);}this.timedScene=next.ruleId?next:null;this.scheduledFocusId=next.focusId;this.scheduledName=next.ruleId?next.name||'定时场景':'';if(previous!==next.key||differentCanvas){this.selectedId='';this.groupSelecting=false;this.groupSelection=[];}this.canvasBackground=next.state.background;this.renderBoard();if(previous!==next.key||differentCanvas)this.store.refreshWidgets().catch((e:Error)=>this.templateError('桌面刷新未完成',e));if(!next.ruleId&&previous!=='base')this.scheduleBackground();};
    if(previous===next.key&&!differentCanvas){apply();return;}
    const transitionGeneration=++this.scheduleVisualGeneration;this.scheduleTransition=true;
    if(differentCanvas||next.focusId.length>0||(this.timedScene?.focusId??'').length>0) {
      this.getUIContext().animateTo({duration:260,curve:Curve.EaseIn,expectedFrameRateRange:this.frameRate,onFinish:()=>{
        if(!this.alive||transitionGeneration!==this.scheduleVisualGeneration)return;apply();this.getUIContext().postFrameCallback(new PreparedTransition(()=>{
          if(!this.alive||transitionGeneration!==this.scheduleVisualGeneration)return;this.getUIContext().animateTo({duration:460,curve:Curve.Friction,expectedFrameRateRange:this.frameRate,onFinish:()=>{if(transitionGeneration===this.scheduleVisualGeneration)this.scheduleTransition=false;}},()=>this.schedulePhase=0);
        }));
      }},()=>this.schedulePhase=1);
    } else this.getUIContext().animateTo({duration:560,curve:Curve.Friction,expectedFrameRateRange:this.frameRate,onFinish:()=>{if(transitionGeneration===this.scheduleVisualGeneration)this.scheduleTransition=false;}},apply);
  }
  private scheduleOffset(id:string,horizontal:boolean):number {
    if(this.schedulePhase===0)return 0;const card=this.cardMap[id];if(!card)return 0;
    const rect=sceneRect(card,BOARD_W*this.boardScale,this.boardHeight),dx=rect.x+rect.w/2-BOARD_W*this.boardScale/2,dy=rect.y+rect.h/2-this.boardHeight/2;
    const horizontalExit=Math.abs(dx)/(BOARD_W*this.boardScale)>=Math.abs(dy)/this.boardHeight;
    return (horizontal===horizontalExit?(horizontal?(dx<0?-1:1):(dy<0?-1:1))*Math.max(BOARD_W*this.boardScale,this.boardHeight)*1.5:0)*this.schedulePhase;
  }
  private focusedFringeCard:FridgeCard|null=null;
  private focusedFringeScale:number=0;
  private focusedFringeValue:CompositionOverflow=new CompositionOverflow();
  private focusedFringe(card:FridgeCard):CompositionOverflow {
    if(this.focusedFringeCard!==card||this.focusedFringeScale!==this.boardScale){this.focusedFringeCard=card;this.focusedFringeScale=this.boardScale;this.focusedFringeValue=compositionOverflow(card,this.boardScale);}return this.focusedFringeValue;
  }
  private restoreScheduledScene():void {
    if(this.scheduleTransition)return;
    if(this.scheduleOverride)this.scheduleOverride=null;
    else if(this.timedScene)dismissScene(withScenePolicy(this.store.state,this.store.catalog,this.appDark),this.timedScene.ruleId,this.timedScene.occurrence,Date.now());
    this.syncSchedules();this.persist(true);this.updateScheduledScene(true);
  }
  private sceneThemeChanged():void {if(this.ready&&this.store.catalog.rotation.mode==='theme'){this.scheduleGeneration++;this.updateScheduledScene(true);}}
  private async openScenePanel(tab:number=0):Promise<void> {
    this.scenePanelTab=tab;
    this.homeToolsOpen=false;this.canvasPickerOpen=false;this.backgroundOpen=false;
    try{await this.store.upgradeTimedScenes();this.refreshCanvasList();this.syncSchedules();this.scheduleOpen=true;}catch(e){this.templateError('场景读取失败',e as Error);}
  }
  private async editTimedScene(id:string='',create:boolean=false,source:FridgeCard|null=null):Promise<void> {
    if(this.busy||this.canvasChanging||this.sceneNavigationBusy)return;this.sceneNavigationBusy=true;
    try{
    this.copyTargetOpen=false;this.canvasPickerOpen=false;this.scheduleOpen=false;this.scheduleGeneration++;this.scheduleOverride=null;this.timedScene=null;this.scheduledName='';this.scheduledFocusId='';
    this.sceneReturnId=this.store.catalog.activeId;await this.store.save(false);
    if(create){id=this.store.createTimedScene('定时场景 '+(this.store.catalog.scenes.length+1),source??undefined);const rule=new SceneRule();rule.id=this.store.newId();rule.kind='focus';rule.centralOnly=true;rule.untilDismissed=false;rule.targetId=id;rule.name=this.store.activeName;rule.start=(new Date().getHours()*60+new Date().getMinutes()+5)%1440;rule.enabled=true;rule.createdAt=Date.now();this.store.catalog.sceneRules.push(rule);await this.store.save(false);}
    else if(!await this.store.openCanvas(id))return;
    this.canvasAspect=this.store.state.canvasAspect;this.canvasDimension=this.store.state.canvasDimension;this.layoutBoard();this.sceneEditing=true;this.selectedId='';this.groupSelecting=false;this.groupSelection=[];this.canvasBackground=this.store.state.background;this.refreshCanvasList();this.syncSchedules();this.render();
    if(this.store.state.cards.length===0)this.addCard();
    }catch(e){this.templateError('场景编辑未完成',e as Error);}finally{this.sceneNavigationBusy=false;}
  }
  private async leaveTimedScene():Promise<void> {
    if(this.sceneNavigationBusy)return;this.sceneNavigationBusy=true;
    try{await this.store.save(true);await this.loadCanvas(this.sceneReturnId||this.store.catalog.activeId);this.sceneEditing=this.store.catalog.scenes.some(c=>c.id===this.store.state.canvasId);if(!this.sceneEditing){this.syncSchedules();this.scheduleOpen=true;this.armScheduleTimer();this.updateScheduledScene(true);}}catch(e){this.templateError('场景保存未完成',e as Error);}finally{this.sceneNavigationBusy=false;}
  }
  private async toggleSceneRule(id:string,value:boolean):Promise<void> {
    const rule=this.store.catalog.sceneRules.find(r=>r.id===id);if(!rule)return;rule.enabled=value;this.syncSchedules();
    try{if(value){const target=await this.store.canvasSnapshot(rule.targetId);if(rule.enabled!==value)return;if(target.cards.length!==1){rule.enabled=false;this.getUIContext().getPromptAction().showToast({message:'请先添加中央卡片'});}else{rule.createdAt=Date.now();rule.dismissed='';}}this.scheduleGeneration++;this.syncSchedules();this.armScheduleTimer();await this.store.save(true);this.updateScheduledScene(true);}catch(e){rule.enabled=false;this.syncSchedules();this.templateError('场景无法启用',e as Error);}
  }
  @Builder
  scheduleEditor() {
    SceneSchedulePanel({rules:this.scheduleRules,scenes:this.sceneEntries,canvases:this.canvasEntries,rotation:this.store.catalog.rotation,appDark:this.appDark,initialTab:this.scenePanelTab,
      onCreate:()=>this.editTimedScene('',true),onEditCard:id=>this.editTimedScene(id),
      onRotation:rotation=>{this.store.catalog.rotation=rotation;this.scheduleGeneration++;this.armScheduleTimer();this.store.save(true).then(()=>this.updateScheduledScene(true)).catch((e:Error)=>this.templateError('轮换设置未保存',e));},
      onSave:source=>{const rule=normalizeSceneRules([source])[0];if(!rule)return;rule.centralOnly=true;rule.kind='focus';rule.untilDismissed=false;rule.dismissed='';rule.createdAt=Date.now();const i=this.store.catalog.sceneRules.findIndex(r=>r.id===rule.id);if(i>=0)this.store.catalog.sceneRules[i]=rule;const entry=this.store.catalog.scenes.find(c=>c.id===rule.targetId);if(entry)entry.name=rule.name;this.scheduleGeneration++;this.syncSchedules();this.refreshCanvasList();this.armScheduleTimer();this.store.save(true).then(()=>this.updateScheduledScene(true)).catch((e:Error)=>this.templateError('定时设置未保存',e));},
      onToggle:(id,value)=>this.toggleSceneRule(id,value),
      onRemove:id=>{this.getUIContext().showAlertDialog({title:'删除定时场景？',message:'中央卡片和时间规则会一起删除。',primaryButton:{value:'取消',action:()=>{}},secondaryButton:{value:'删除',fontColor:'#C43A35',action:()=>{this.store.deleteTimedScene(id).then(()=>{this.scheduleGeneration++;this.refreshCanvasList();this.syncSchedules();this.armScheduleTimer();this.updateScheduledScene(true);}).catch((e:Error)=>this.templateError('场景未删除',e));}}});},
      onPreview:rule=>{this.scheduleOpen=false;this.scheduleOverride=rule;setTimeout(()=>{if(this.alive)this.updateScheduledScene(true);},240);}})

  }

  private async chooseCanvas(id: string): Promise<void> {
    if (this.heroActive || this.activeBoardId || this.sharing || this.busy || this.canvasChanging || this.scheduleTransition) return;
    if (this.editing) { this.getUIContext().getPromptAction().showToast({message:'请先完成当前卡片编辑'}); return; }
    this.canvasChanging=true;
    try {await this.loadCanvas(id,true);}catch(e){this.templateError('画布切换未完成',e as Error);}finally{this.canvasChanging=false;}
  }
  private async loadCanvas(id:string,manual:boolean=false):Promise<void> {
    try {
      this.backgroundGeneration++; if(this.backgroundTimer >= 0) clearTimeout(this.backgroundTimer); this.backgroundBusy = false;
      if(manual){if(!await this.store.selectCanvas(id))return;}else{await this.store.save(false);if(!await this.store.openCanvas(id))return;await this.store.save(false);}
      this.scheduleGeneration++;this.timedScene=null;this.scheduleOverride=null;this.scheduledName='';this.scheduledFocusId='';this.syncSchedules();
      this.selectedId = ''; this.activeBoardId = ''; this.groupSelection = []; this.groupSelecting = false;
      this.canvasAspect=this.store.state.canvasAspect;this.canvasDimension=this.store.state.canvasDimension;this.layoutBoard();
      this.canvasBackground = this.store.state.background; this.refreshCanvasList();
      await primeRenderContours(this.store.state.cards,storageSnapshot(this.store.state));
      this.render(); this.persist(true); this.scheduleBackground(); this.canvasPickerOpen = false;
      this.refreshCapabilities();this.updateScheduledScene(true);
    } catch (e) { this.templateError('画布切换未完成',e as Error); }
  }
  private async newCanvas(duplicate: boolean, name: string = ''): Promise<void> {
    if(this.canvasChanging || this.busy || this.sharing)return;this.canvasChanging=true;
    try {
      await this.store.save(false);this.backgroundGeneration++;
      const source = duplicate ? this.store.state : undefined;
      const id = this.store.createCanvas(name.trim() || (duplicate ? this.canvasName+' 副本' : '画布 '+(this.canvasEntries.length+1)),source);
      await this.loadCanvas(id,true);
    } catch(e) {this.templateError('画布未创建',e as Error);}finally{this.canvasChanging=false;}
  }
  private deleteCanvas(id: string): void {
    if(this.canvasEntries.length <= 1 || this.canvasChanging) return;
    const active=this.store.state.canvasId===id;
    this.getUIContext().showAlertDialog({title:'删除“'+this.canvasTitle(id)+'”？',message:'卡片和背景会一起删除。绑定它的桌面组件将显示剩余画布。',primaryButton:{value:'取消',action:()=>{}},secondaryButton:{value:'删除',fontColor:'#C43A35',action:()=>{
      if(this.canvasChanging)return;this.canvasChanging=true;
      this.store.deleteCanvas(id).then(async()=>{if(active){await this.loadCanvas(this.store.catalog.activeId);}else this.refreshCanvasList();}).catch((e:Error)=>this.templateError('未能删除',e)).finally(()=>{this.canvasChanging=false;});
    }}});
  }
  private canvasTitle(id: string): string { return this.canvasEntries.find((entry: CanvasEntry)=>entry.id===id)?.name ?? ''; }
  private canvasPopupWidth(): number { return Math.min(344, Math.max(240, this.screenWidth - 48)); }
  private prepareCanvas(duplicate: boolean): void {
    this.canvasDuplicate = duplicate; this.canvasDraftName = duplicate ? this.canvasName + ' 副本' : '画布 ' + (this.canvasEntries.length + 1); this.canvasCreating = true;
  }
  private renameCanvas(): void {
    if (this.canvasChanging || !this.renameValue.trim()) return;
    this.store.renameCanvas(this.renameValue.trim(),this.canvasRenameId); this.refreshCanvasList(); this.canvasRenameId=''; this.persist(false);
  }
  @Builder
  canvasPicker() {
    Scroll() {
    Column({space:12}) {
      Row({space:8}) {
        if (this.canvasCreating) {
          Button({type:ButtonType.Circle,buttonStyle:ButtonStyleMode.NORMAL}) {
            SymbolGlyph($r('sys.symbol.chevron_left')).fontSize(18).fontColor([this.appText()]).hitTestBehavior(HitTestMode.None)
          }.width(44).height(44).backgroundColor(Color.Transparent).accessibilityText('返回画布列表').onClick(()=>this.canvasCreating=false)
        }
        Text(this.canvasCreating?'新建画布':'画布').fontSize(18).fontWeight(FontWeight.Medium).fontColor(this.appText()).layoutWeight(1)
        Button({type:ButtonType.Circle,buttonStyle:ButtonStyleMode.NORMAL}) {
          SymbolGlyph($r('sys.symbol.xmark')).fontSize(18).fontColor([this.appText()]).hitTestBehavior(HitTestMode.None)
        }.width(44).height(44).backgroundColor(Color.Transparent).accessibilityText('关闭画布菜单').onClick(()=>this.canvasPickerOpen=false)
      }.width('100%')
      if (this.canvasCreating) {
        TextInput({text:this.canvasDraftName,placeholder:'画布名称'}).height(44).fontColor(this.appText()).placeholderColor(this.appMuted())
          .backgroundColor(AppDesign.popupChoice(this.appDark,false)).borderRadius(12).maxLength(30).onChange((value:string)=>this.canvasDraftName=value)
        Text(this.canvasDuplicate?'保留当前布局，创建一份独立副本':'从空白开始，添加你的卡片').fontSize(12).fontColor(this.appMuted()).width('100%')
        Button(this.canvasChanging?'创建中':'创建画布',{type:ButtonType.Capsule,buttonStyle:ButtonStyleMode.EMPHASIZED})
          .height(44).width('100%').backgroundColor(AppDesign.selected(this.appDark)).fontColor(AppDesign.onSelected(this.appDark)).enabled(!this.canvasChanging && this.canvasDraftName.trim().length>0)
          .onClick(()=>this.newCanvas(this.canvasDuplicate,this.canvasDraftName))
      } else {
        List({space:4}) {
          ForEach(this.canvasEntries.map((entry:CanvasEntry)=>entry.id),(id:string)=>{
            ListItem() {
              Row({space:8}) {
              if(this.canvasRenameId===id) {
                TextInput({text:this.renameValue,placeholder:'画布名称'}).layoutWeight(1).height(48).fontSize(14).fontColor(this.appText()).backgroundColor(AppDesign.popupChoice(this.appDark,true)).borderRadius(12).maxLength(30).onChange((value:string)=>this.renameValue=value).onSubmit(()=>this.renameCanvas())
                Button({type:ButtonType.Circle,buttonStyle:ButtonStyleMode.NORMAL}) {SymbolGlyph($r('sys.symbol.checkmark')).fontSize(18).fontColor([this.appText()]).hitTestBehavior(HitTestMode.None)}.width(44).height(44).backgroundColor(this.appControl()).accessibilityText('保存名称').enabled(this.renameValue.trim().length>0).onClick(()=>this.renameCanvas())
              } else {
              Button({type:ButtonType.ROUNDED_RECTANGLE,buttonStyle:ButtonStyleMode.NORMAL}) {
                Row({space:8}) {
                  Text(this.canvasTitle(id)).fontColor(this.appText()).fontSize(14).layoutWeight(1).maxLines(1).textOverflow({overflow:TextOverflow.Ellipsis})
                  if(id===this.store.state.canvasId) {SymbolGlyph($r('sys.symbol.checkmark')).fontSize(18).fontColor([this.appText()]).hitTestBehavior(HitTestMode.None)}
                }.width('100%')
              }.layoutWeight(1).height(48).padding({left:12,right:12}).backgroundColor(AppDesign.popupChoice(this.appDark,id===this.store.state.canvasId))
                .accessibilityText('切换到 '+this.canvasTitle(id)).onClick(()=>this.chooseCanvas(id))
                Button({type:ButtonType.Circle,buttonStyle:ButtonStyleMode.NORMAL}) {
                  SymbolGlyph($r('sys.symbol.square_and_pencil')).fontSize(18).fontColor([this.appText()]).hitTestBehavior(HitTestMode.None)
                }.width(44).height(44).backgroundColor(Color.Transparent).accessibilityText('改名 '+this.canvasTitle(id)).onClick(()=>{this.canvasRenameId=id;this.renameValue=this.canvasTitle(id);})
                Button({type:ButtonType.Circle,buttonStyle:ButtonStyleMode.NORMAL}) {
                  SymbolGlyph($r('sys.symbol.rectangle_and_arrowshape_turn_up_right')).fontSize(20).fontColor([this.appText()]).hitTestBehavior(HitTestMode.None)
                }.id('shareCanvas_'+id).width(44).height(44).backgroundColor(AppDesign.popupChoice(this.appDark,true)).enabled(!this.sharing)
                  .accessibilityText('分享 '+this.canvasTitle(id)).onClick(()=>this.shareCanvasFromPicker(id))
                Button({type:ButtonType.Circle,buttonStyle:ButtonStyleMode.NORMAL,role:ButtonRole.ERROR}) {
                  SymbolGlyph($r('sys.symbol.trash')).fontSize(18).fontColor(['#C43A35']).hitTestBehavior(HitTestMode.None)
                }.width(44).height(44).backgroundColor(Color.Transparent).enabled(this.canvasEntries.length>1).accessibilityText('删除 '+this.canvasTitle(id)).onClick(()=>this.deleteCanvas(id))
              }
              }.width('100%')
            }
          },(id:string)=>id)
        }.width('100%').height(Math.min(200,Math.max(48,this.canvasEntries.length*52))).scrollBar(BarState.Off)
        if(this.sceneEntries.length>0) {
          Text('定时场景').fontSize(13).fontWeight(FontWeight.Medium).fontColor(this.appMuted()).width('100%')
          ForEach(this.sceneEntries,(entry:CanvasEntry)=>{
            Button({type:ButtonType.ROUNDED_RECTANGLE,buttonStyle:ButtonStyleMode.NORMAL}) {
              Row({space:8}) {
                SymbolGlyph($r('sys.symbol.timer')).fontSize(18).fontColor([this.appText()]).hitTestBehavior(HitTestMode.None)
                Text(entry.name).fontSize(14).fontColor(this.appText()).layoutWeight(1).maxLines(1).textOverflow({overflow:TextOverflow.Ellipsis})
                SymbolGlyph($r('sys.symbol.chevron_right')).fontSize(14).fontColor([this.appMuted()]).hitTestBehavior(HitTestMode.None)
              }.width('100%')
            }.width('100%').height(48).padding({left:12,right:12}).backgroundColor(AppDesign.popupChoice(this.appDark,false)).accessibilityText('编辑定时场景 '+entry.name).onClick(()=>this.editTimedScene(entry.id))
          },(entry:CanvasEntry)=>entry.id)
        }
        Row({space:8}) {
          Button('新画布',{type:ButtonType.Capsule,buttonStyle:ButtonStyleMode.NORMAL}).height(44).layoutWeight(1).backgroundColor(AppDesign.popupChoice(this.appDark,false)).fontColor(this.appText()).onClick(()=>this.prepareCanvas(false))
          Button('复制画布',{type:ButtonType.Capsule,buttonStyle:ButtonStyleMode.NORMAL}).height(44).layoutWeight(1).backgroundColor(AppDesign.popupChoice(this.appDark,false)).fontColor(this.appText()).onClick(()=>this.prepareCanvas(true))
          if(!this.floatingHome()){Button('导入',{type:ButtonType.Capsule,buttonStyle:ButtonStyleMode.NORMAL}).height(44).layoutWeight(1).fontSize(13).fontColor(this.appText()).backgroundColor(AppDesign.popupChoice(this.appDark,false)).enabled(!this.sharing).onClick(()=>this.pickTemplate())}
        }.width('100%')

      }
    }.width('100%').padding(16).enabled(!this.canvasChanging)
    }.width(this.canvasPopupWidth()).constraintSize({maxHeight:Math.max(160,this.screenHeight-this.safeTop-this.safeBottom-32)})
      .scrollBar(BarState.Off).clip(true)
  }
  private arrivalOffsets: Record<string, ShapePoint> = {};
  @State private startupCardCount: number = -1;
  private startupFromWidget:boolean=false;
  private prepareWidgetScene():void {
    // Keep the native starting surface during preparation, with cards already
    // in their final positions. Spread first construction across frames.
    this.startupFromWidget=true;this.arriving=true;this.arrival=0;this.boardOpacity=.01;
    this.startupCardCount=0;this.prepareStartupCard();
  }
  private startArrival(): void {
    this.startupFromWidget=false;
    if (this.editing || this.viewing || this.cardIds.length === 0) return;
    this.arrivalOffsets = {};
    this.cards.forEach((card: FridgeCard) => { this.arrivalOffsets[card.id] = arrivalOffset(card, BOARD_W * this.boardScale, this.boardHeight); });
    // A zero-alpha/offscreen face is culled by the renderer: its texture would
    // otherwise be uploaded for the first time halfway through the entrance.
    this.arriving = true; this.arrival = 0; this.boardOpacity = .01;
    // Do not construct every photo, contour and capability in one launch frame.
    // Build one stable card per frame before exposing the arrival animation.
    this.startupCardCount=0; this.prepareStartupCard();
  }
  private prepareStartupCard():void {
    this.getUIContext().postFrameCallback(new PreparedTransition(()=>{
      if(!this.alive || !this.arriving)return;
      if(this.startupCardCount<this.cardIds.length) {
        this.startupCardCount++;this.prepareStartupCard();return;
      }
      this.startupCardCount=-1;
      if(this.startupFromWidget){
        this.boardOpacity=1;this.arriving=false;this.startupFromWidget=false;startupMark('widget-surfaces-ready');
        this.getUIContext().postFrameCallback(new PreparedTransition(()=>revealStartup()));return;
      }
      startupMark('surfaces-ready');this.arrival=1;this.boardOpacity=0;
      this.getUIContext().postFrameCallback(new PreparedTransition(async ()=>{
        await revealStartup();
        if(!this.alive||!this.arriving)return;
        startupMark('arrival-start');
        this.getUIContext().animateTo({duration:520,curve:Curve.Friction,expectedFrameRateRange:this.frameRate,
          onFinish:()=>{if(this.alive){this.arriving=false;startupMark('arrival-end');}}},()=>{this.arrival=0;this.boardOpacity=1;});
      }));
    }));
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
  aboutToDisappear(): void { this.reliefGeneration++;if(this.reliefTimer>=0)clearTimeout(this.reliefTimer); this.finishNavMenu(-1); this.finishCardDeletion(); this.enhancementDialog?.close();this.enhancementOpen=false; if(this.foregroundRefreshTimer>=0)clearTimeout(this.foregroundRefreshTimer); this.capabilityPickerOpen=false;this.scheduleGeneration++;if(this.scheduleTimer>=0)clearTimeout(this.scheduleTimer); this.batteryObserver.stop(); if(this.widgetRouteTimer>=0)clearTimeout(this.widgetRouteTimer); if (this.previewTimer >= 0 || this.gestureGroup.length > 0) this.flushPreview(); this.alive = false; if(this.readingTintTimer>=0)clearTimeout(this.readingTintTimer); if(this.incomingTimer>=0)clearTimeout(this.incomingTimer); this.chromeSnapshot?.release(); this.chromeSnapshot = undefined; this.retiredChrome?.release(); this.retiredChrome = undefined; this.backgroundGeneration += 1; if (this.backgroundTimer >= 0) clearTimeout(this.backgroundTimer); if (this.maintenanceTimer >= 0) clearTimeout(this.maintenanceTimer); if (this.transitionTimer >= 0) clearTimeout(this.transitionTimer); this.activeBoardId = ''; this.persist(true); if (this.clockTimer >= 0) clearInterval(this.clockTimer); }
  onBackPress(): boolean {
    if(this.navMenuOpen){this.finishNavMenu(-1);return true;}
    if(this.deletionId)return true;
    if(this.scheduleOpen){this.scheduleOpen=false;this.updateScheduledScene(true);return true;}
    if(this.canvasPickerOpen){this.canvasPickerOpen=false;this.canvasCreating=false;return true;}
    if(this.backgroundOpen){this.closeBackgroundEditor();return true;}
    if(this.homeToolsOpen){this.homeToolsOpen=false;return true;}
    if(this.editing&&this.editorExpanded){this.expandEditor(false);return true;}
    if(this.showBackgroundOptions){this.showBackgroundOptions=false;return true;}
    if(this.showLayerOptions){this.showLayerOptions=false;return true;}
    if(this.readingComparisonOpen){this.readingComparisonOpen=false;return true;}
    if(this.capabilityPickerOpen){this.capabilityPickerOpen=false;return true;}
    if (this.heroActive) {if(this.editing)this.editorBackPending=true;return true;}
    if (this.viewing) { this.viewing = false; this.selectedId = ''; this.incomingTemplateChanged(); return true; }
    if (this.editing) { this.closeEditor(); return true; }
    if(this.sceneEditing){this.leaveTimedScene();return true;}
    if (this.selectedId.length > 0) { this.selectedId = ''; return true; }
    return false;
  }
  private widgetFrameChanged(): void {
    if(this.ready){this.canvasAspect=this.store.state.canvasAspect;this.canvasDimension=this.store.state.canvasDimension;this.layoutBoard();}
  }
  private homeToolsChanged():void {
    if(!this.ready||this.editing||this.heroActive){this.homeToolsMotionGeneration++;this.homeToolsMoving=false;return;}
    const layout=workspaceLayout(this.screenWidth,this.screenHeight,this.safeTop,this.safeBottom,this.canvasAspect);
    const target=layout.floating&&(this.homeToolsOpen||this.scheduleOpen||this.backgroundOpen)?layout.expandedBoardY:layout.boardY;
    const generation=++this.homeToolsMotionGeneration;this.homeToolsMoving=true;
    const motion=canvasToolsMotion(this.homeToolsOpen||this.scheduleOpen||this.backgroundOpen);
    motion.onFinish=()=>{if(this.alive&&generation===this.homeToolsMotionGeneration)this.homeToolsMoving=false;};
    this.getUIContext().animateTo(motion,()=>{this.boardTop=target;this.timingHeaderActive=this.scheduleOpen;this.backgroundHeaderActive=this.backgroundOpen&&!this.floatingHome();});
  }
  private layoutBoard(): void {
    const layout=workspaceLayout(this.screenWidth,this.screenHeight,this.safeTop,this.safeBottom,this.canvasAspect);
    this.boardScale=layout.boardW/BOARD_W;this.boardHeight=layout.boardH;this.boardLeft=layout.boardX;this.boardTop=layout.floating&&(this.homeToolsOpen||this.scheduleOpen||this.backgroundOpen)?layout.expandedBoardY:layout.boardY;
    this.panelLeft=layout.panelX;this.panelTop=layout.panelY;this.panelWidth=layout.panelW;this.panelHeight=layout.panelH;
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

  private editorWorkspace():EditorWorkspace {return editorWorkspace(this.screenWidth,this.screenHeight,this.safeTop,this.safeBottom);}
  private editorLandscape(): boolean { return this.editorWorkspace().wide; }
  private editorViewportWidth(): number { return this.editorWorkspace().previewW; }
  private previewPaneHeight(): number {
    const workspace=this.editorWorkspace();
    return workspace.wide?workspace.body:Math.max(workspace.body*.22,Math.min(workspace.body*.60,workspace.body-(this.editorSheetHeightVp||workspace.body*.40)));
  }
  private editorControlHeight():number {return this.editorWorkspace().body*(this.editorExpanded?.78:.40);}
  private editingAngle(): number { return this.preview.rot; }
  private previewViewportCard:FridgeCard|null=null;
  private previewViewportKey:string='';
  private previewViewportValue:EditorViewport=new EditorViewport();
  private previewFringeCard:FridgeCard|null=null;
  private previewFringeTab:number=-1;
  private previewFringe:number[]=[0,0,0,0];
  private previewViewport(): EditorViewport {
    const width=this.editorViewportWidth(),landscape=this.editorLandscape(),pane=this.previewPaneHeight();
    const key=[this.screenHeight,this.safeTop,this.safeBottom,width,landscape,pane,this.settingsTab].join(':');
    if(this.previewViewportCard===this.preview&&this.previewViewportKey===key)return this.previewViewportValue;
    if(this.previewFringeCard!==this.preview||this.previewFringeTab!==this.settingsTab){
      const overflow=compositionOverflow(this.preview,1);
      this.previewFringe=this.settingsTab===0?[0,0,0,0]:[overflow.left,overflow.top,overflow.right,overflow.bottom];
      this.previewFringeCard=this.preview;this.previewFringeTab=this.settingsTab;
    }
    this.previewViewportValue=editorViewport(this.preview.w, this.preview.h, this.editingAngle(),width,
      this.screenHeight, this.safeTop, this.safeBottom,landscape,pane,this.previewFringe);
    this.previewViewportCard=this.preview;this.previewViewportKey=key;return this.previewViewportValue;
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
    if(this.scheduledName||this.scheduleTransition){this.getUIContext().getPromptAction().showToast({message:'请先恢复原始画布再编辑'});return;}
    if (this.heroActive || this.arriving) return;
    this.editorExpanded=false;this.editorSheetHeightVp=0;this.editorBackPending=false;
    this.heroHideContent = false; this.select(id, true); this.scatter = 0; this.showEditorContent = false; this.showBackgroundOptions = false; this.showLayerOptions = false;this.editorSection=0;this.editorSheetTab=0;this.settingsTab=this.preview.capability!==null?1:0;
    this.heroRect = this.boardRect();
    if (created) {
      const rect = new SceneRect(); rect.w = 28; rect.h = 28 * this.preview.h / this.preview.w;
      rect.x = this.panelLeft + this.panelWidth - 38; rect.y = this.panelTop + 22 - rect.h / 2; this.heroRect = rect;
    }
    this.layerId=this.preview.capability!==null?'capability':(this.preview.elements.find((el:CanvasElement)=>el.behindCapability)?.id??'');this.syncFields();
    this.creatingTransition = created; this.heroBase = this.editorRect(); this.setHeroPose(this.heroRect); this.setTransitionClip(true);
    this.editorMounted = true; this.editorReady = true; this.scroller.scrollTo({ xOffset: 0, yOffset: 0 }); this.editorOpacity = 0; this.boardOpacity = 1; this.heroActive = true; this.editing = true;this.editorSheetOpen=false;this.homeToolsOpen=false;
    this.prepareEditorMotion(() => {
      if (!this.alive || !this.editing || !this.heroActive) return;
      this.getUIContext().animateTo({ duration: 380, curve: Curve.Friction, expectedFrameRateRange: this.frameRate, onFinish: () => { if (this.alive) { this.heroActive = false; this.creatingTransition = false; this.retireChrome();this.layoutBoard();if(this.editorBackPending){this.editorBackPending=false;this.closeEditor();}else{this.editorSheetOpen=!this.editorLandscape();} } } }, () => {
        this.setHeroPose(this.editorRect()); this.setTransitionClip(false); this.scatter = 1; this.boardOpacity = 0; this.editorOpacity = 1;
      });
    });
  }
  private retireChrome(): void {
    this.retiredChrome = this.chromeSnapshot; this.chromeSnapshot = undefined;
  }
  private async prepareEditorMotion(start: () => void): Promise<void> {
    let completed=false;
    const finish=():void=>{if(completed)return;completed=true;clearTimeout(deadline);if(this.alive&&this.heroActive)start();};
    // A snapshot is an optimization, never a prerequisite for opening controls.
    const deadline=setTimeout(finish,300);
    const signature = [this.selectedId, this.layerId, this.settingsTab, this.revision, this.screenWidth, this.screenHeight,
      this.appDark, this.showBackgroundOptions, this.showLayerOptions, this.undoAvailable, this.redoAvailable,
      this.scroller.currentOffset().yOffset].join(':');
    if (this.retiredChrome !== undefined && this.chromeSignature === signature) {
      this.chromeSnapshot = this.retiredChrome; this.retiredChrome = undefined;
      this.getUIContext().postFrameCallback(new PreparedTransition(finish)); return;
    }
    if (this.retiredChrome !== undefined) { this.retiredChrome.release(); this.retiredChrome = undefined; }
    // Material samples moving pixels behind it and cannot be renderGroup-cached.
    // Capture the tools once; keep the actual card surface alive and interactive
    // tools hidden only during the transition. Restore native material afterward.
    this.getUIContext().postFrameCallback(new PreparedTransition(async () => {
      try {
        const snapshot = await this.getUIContext().getComponentSnapshot().get('editorMotionChrome', {scale: .75, waitUntilRenderFinished: false});
        if (completed || !this.alive || !this.heroActive) { snapshot.release(); return; }
        this.chromeSignature = signature; this.chromeSnapshot = snapshot;
      } catch (_) { /* Native tools remain a usable fallback if capture is unavailable. */ }
      if (!this.alive || !this.editing || !this.heroActive) return;
      this.getUIContext().postFrameCallback(new PreparedTransition(finish));
    }));
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
  private appControl(): string { return AppDesign.control(this.appDark); }
  private appText(): string { return AppDesign.text(this.appDark); }
  private appMuted(): string { return AppDesign.muted(this.appDark); }
  private setHeroPose(rect: SceneRect): void {
    this.heroScale = rect.w / this.heroBase.w; this.heroX = rect.x; this.heroY = rect.y; this.heroAngle = rect.rot;
  }
  private closeEditor(): void {
    if (this.heroActive || !this.editing) return;
    if (this.previewTimer >= 0 || this.gestureGroup.length > 0) this.flushPreview();
    const origin=this.editorRect();this.editorSheetOpen=false;this.editorExpanded=false;this.editorSheetHeightVp=0;
    this.creatingTransition = false; this.heroHideContent = this.settingsTab === 0;
    this.heroBase = origin; this.setHeroPose(this.heroBase); this.setTransitionClip(false); this.heroActive = true;
    // Publish the edited card to the board once, before it fades back in.
    this.renderBoard();
    this.prepareEditorMotion(() => { this.getUIContext().animateTo({ duration: 340, curve: Curve.Friction, expectedFrameRateRange: this.frameRate, onFinish: () => {
      if (this.alive) { this.editing = false; this.editorReady = false; this.heroActive = false; this.editorBackPending=false; this.retireChrome(); this.selectedId = ''; this.persist(true); this.scheduleBackground(); this.incomingTemplateChanged(); }
    } }, () => { this.setHeroPose(this.boardRect()); this.setTransitionClip(true); this.editorOpacity = 0; this.boardOpacity = 1; this.scatter = 0; }); });
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
      // A desktop tap is navigation, not an instruction to rebuild the same canvas.
      if(!id && !this.routedId){
        AppStorage.setOrCreate('routeCanvasId','');this.scheduleForegroundRefresh();return;
      }
      this.backgroundGeneration++;
      await this.store.init(this.context);if(canvas)await this.store.openCanvas(canvas);
      await primeRenderContours(this.store.state.cards,storageSnapshot(this.store.state));
      if(!this.alive)return;
      this.refreshCanvasList();this.canvasAspect=this.store.state.canvasAspect;this.canvasDimension=this.store.state.canvasDimension;this.canvasBackground=this.store.state.background;
      this.retireChrome();this.editing=false;this.heroActive=false;this.viewing=false;this.selectedId='';this.activeBoardId='';this.boardOpacity=1;this.render();this.layoutBoard();
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
    const next = (this.timedScene?.state??this.store.state).cards.map((card: FridgeCard) => cardRenderSnapshot(card));
    if (next.length === this.cards.length && next.every((card: FridgeCard, index: number) => card === this.cards[index])) return;
    // Geometry edits keep the board and layer collections alive. Replacing both
    // containers forces every card/layer builder through the release frame.
    if(next.length===this.cards.length&&next.every((c:FridgeCard,i:number)=>c.id===this.cards[i].id)){
      for(let i=0;i<next.length;i++)if(next[i]!==this.cards[i]){this.cardMap[next[i].id]=next[i];this.cards[i]=next[i];}
      return;
    }
    this.cards = next;
    const map: Record<string, FridgeCard> = {};
    this.cards.forEach((item: FridgeCard) => { map[item.id] = item; });
    this.cardMap = map; this.cardIds = this.cards.map((item: FridgeCard) => item.id);
  }
  private render(): void {
    if (!this.editing) this.renderBoard();
    const card = this.current(); if (card !== null) this.preview = cardRenderSnapshot(card);
    this.revision += 1; this.syncPreviewFields();
    if(this.editing)this.editorSection=Math.min(this.editorSection,this.editorTools().length-1);
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
    if (this.previewTimer >= 0) clearTimeout(this.previewTimer); this.previewTimer = -1; if(this.layerMotion.id==='capability'&&this.current()?.capability)this.current()!.capability!.readingEdge=this.layerMotion.edge; this.change(); this.layerMotion.clear(); this.layerDrag=''; this.gestureGroup = '';
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
    this.titleValue = card?.capability?.title ?? '';
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
    refreshNormalSceneLayout(this.store.state);
    this.normalLayoutId=this.store.state.sceneBaseLayoutId;
    this.store.state.canvasAspect = this.canvasAspect; this.store.state.canvasDimension = this.canvasDimension;
    this.queueReadingTints();this.queueRelief();
    this.store.save(syncWidgets).catch((e: Error) => { this.error = e.message === '桌面组件同步未完成' ? '桌面同步暂未完成，点此重试' : '保存失败，点此重试'; });
  }
  private reliefTimer:number=-1;
  private reliefBusy:boolean=false;
  private reliefGeneration:number=0;
  private reliefKeys:Map<string,string>=new Map();
  private reliefKey(c:FridgeCard):string{return [c.w,c.h,c.cutout,c.subjectVersion,c.paper,c.material,c.subjectPhoto,c.ink].join(':');}
  private queueRelief():void{
    if(!this.alive||!this.ready||this.reliefBusy)return;
    if(this.reliefTimer>=0)clearTimeout(this.reliefTimer);
    this.reliefTimer=setTimeout(()=>{this.reliefTimer=-1;this.prepareRelief();},180);
  }
  private async prepareRelief():Promise<void>{
    if(!this.alive)return;
    if(this.activeBoardId||this.gestureGroup||this.heroActive||this.layerDrag)return;
    const id=this.store.state.canvasId,generation=++this.reliefGeneration;
    const sources=this.store.state.cards.filter((c:FridgeCard)=>c.shape==='subject'&&c.cutout.startsWith('file://')&&(!c.reliefSrc||this.reliefKeys.get(c.id)!==this.reliefKey(c)));
    if(!sources.length)return;
    const keys=sources.map((c:FridgeCard)=>this.reliefKey(c));
    this.reliefBusy=true;
    try{
      const result=JSON.parse(await taskpool.execute(new taskpool.Task(prepareSceneRelief,JSON.stringify(sources))) as string) as Record<string,string>;
      if(!this.alive||id!==this.store.state.canvasId||generation!==this.reliefGeneration)return;
      let changed=false;
      for(let i=0;i<sources.length;i++){
        const c=this.store.state.cards.find((v:FridgeCard)=>v.id===sources[i].id);
        if(c&&keys[i]===this.reliefKey(c)&&result[c.id]){this.reliefKeys.set(c.id,keys[i]);if(c.reliefSrc!==result[c.id]){c.reliefSrc=result[c.id];changed=true;}}
      }
      if(changed)this.render();
    }catch(_) { /* Keep the vector surface if derived artwork is unavailable. */ }finally{this.reliefBusy=false;
      if(this.alive&&(id!==this.store.state.canvasId||this.store.state.cards.some((c:FridgeCard)=>c.shape==='subject'&&c.cutout.startsWith('file://')&&(!sources.some((s:FridgeCard)=>s.id===c.id)||sources.some((s:FridgeCard,i:number)=>s.id===c.id&&keys[i]!==this.reliefKey(c))))))this.queueRelief();
    }
  }
  private readingTintKey(card:FridgeCard):string {return hash(cardSource(card)+'|'+card.subjectVersion);}
  private queueReadingTints():void {
    if(!this.alive||!this.ready||this.readingTintBusy)return;
    if(this.readingTintTimer>=0)clearTimeout(this.readingTintTimer);
    this.readingTintTimer=setTimeout(()=>{this.readingTintTimer=-1;this.refreshReadingTints();},900);
  }
  private async refreshReadingTints():Promise<void> {
    if(!this.alive||!this.pageVisible||!this.appWindowFocused||this.appBackgrounded)return;
    if(this.activeBoardId||this.gestureGroup||this.heroActive||this.layerDrag||this.arriving){this.queueReadingTints();return;}
    const requests:ReadingTintRequest[]=this.store.state.cards.filter((c:FridgeCard)=>c.capability!==null&&c.capability.k!=='album'&&cardSource(c).startsWith('file://')&&c.capability.readingTintKey!==this.readingTintKey(c)).map((c:FridgeCard):ReadingTintRequest=>({id:c.id,src:cardSource(c),key:this.readingTintKey(c)}));
    if(!requests.length)return;
    const canvasId=this.store.state.canvasId;this.readingTintBusy=true;
    try {
      const json=await taskpool.execute(new taskpool.Task(prepareReadingTints,JSON.stringify(requests))) as string;
      if(!this.alive||canvasId!==this.store.state.canvasId)return;
      if(this.activeBoardId||this.gestureGroup||this.heroActive||this.layerDrag||this.arriving)return;
      let changed=false;
      for(const result of JSON.parse(json) as ReadingTintResult[]) {
        const card=this.store.state.cards.find((c:FridgeCard)=>c.id===result.id);
        if(card?.capability&&this.readingTintKey(card)===result.key){card.capability.readingTint=result.tint;card.capability.readingTintKey=result.key;changed=true;}
      }
      if(changed){this.render();this.store.save(true).catch(()=>{});}
    }catch(_){}finally{this.readingTintBusy=false;}
  }
  private clamp(card: FridgeCard): void {
    clampCardGeometry(card,BOARD_W,BOARD_H,BOARD_W/this.canvasAspect);
  }
  private canAddCards(count: number): boolean {
    try { if(this.sceneEditing&&this.store.state.cards.length+count>1)throw new Error('定时场景只保留一张中央卡片');assertCanvasCapacity(this.store.state.cards.length, count); return true; }
    catch (e) { this.getUIContext().getPromptAction().showToast({message:(e as Error).message}); return false; }
  }
  private addCard(): void {
    if(this.scheduledName){this.getUIContext().getPromptAction().showToast({message:'请先恢复原始画布再添加卡片'});return;}
    if (this.busy || this.canvasChanging || !this.canAddCards(1)) return;
    const card = new FridgeCard(); card.id = this.store.newId();
    const offset = (this.cards.length % 6) * 20; card.x += offset; card.y += offset;
    this.clamp(card); this.store.addCard(card); this.select(card.id); this.change(); this.openEditor(card.id, true);
  }
  private capabilitySelection:number=0;
  private async setCapability(k: string): Promise<void> {
    const selection=++this.capabilitySelection;
    const card = this.current(); if (card === null) return;
    if (card.capability?.k === k) { this.capabilityPickerOpen=false;this.settingsTab=1;this.layerId = 'capability'; this.syncFields(); this.scroller.scrollTo({ xOffset: 0, yOffset: 0 }); return; }
    if (k === 'none') { card.capability = null; this.layerId = ''; }
    else {
      let cap: CapBlock = { k:k,readingBlend:k==='album'?undefined:preferredReadingStyle(k),readingStyle:'surface' };
      if (k === 'countdown' || k === 'anniversary') {
        const date = new Date(); cap.date = date.getFullYear() + '-' + ('0' + (date.getMonth() + 1)).slice(-2) + '-' + ('0' + date.getDate()).slice(-2);
        cap.title = '';
      }
      if(k==='timetable') {
        try {
          const saved=await this.store.savedTimetable();
          if(!this.alive||selection!==this.capabilitySelection||this.current()!==card||this.store.findCard(card.id)!==card)return;
          if(saved)cap=useSavedTimetable(cap,saved);
          else {const d=new Date();d.setDate(d.getDate()-((d.getDay()+6)%7));cap.semester=d.getFullYear()+'-'+('0'+(d.getMonth()+1)).slice(-2)+'-'+('0'+d.getDate()).slice(-2);cap.courses=[];}
        }catch(e){this.getUIContext().getPromptAction().showToast({message:(e as Error).message});return;}
      }
      if (k === 'worldclock') cap.zone = 'Asia/Shanghai';
      if(k==='album') {card.html=undefined;card.shape='rect';card.frame=false;this.settingsTab=1;}
      this.settingsTab=1;card.capability = cap; card.capBox = capabilityPreset(card,'center'); this.layerId = 'capability';
    }
    this.capabilityPickerOpen=false;this.editorSheetTab=0;this.syncFields();this.editorSection=Math.min(3,this.editorTools().length-1); this.change(); this.scroller.scrollTo({ xOffset: 0, yOffset: 0 }); this.refreshCapabilities();
  }
  private addElement(kind: string): void {
    const card = this.current(); if (card === null || card.capability?.k==='album') return;
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
    else {if(card.html?.previewElementId===this.layerId)card.html=undefined;card.elements = card.elements.filter((e: CanvasElement) => e.id !== this.layerId);}
    this.layerId = ''; this.syncFields(); this.change();
  }
  @Builder
  copyTargets() {
    Scroll(){Column({space:12}) {
      Text('复制到').fontSize(20).fontWeight(FontWeight.Medium).fontColor(this.appText()).width('100%')
      Text('画布').fontSize(14).fontColor(this.appMuted()).width('100%')
      ForEach(this.canvasEntries.filter(c=>c.id!==this.store.state.canvasId),(entry:CanvasEntry)=>{Button(entry.name,{type:ButtonType.ROUNDED_RECTANGLE}).width('100%').height(48).backgroundColor(this.appControl()).fontColor(this.appText()).onClick(()=>this.copyInto(entry.id))},(entry:CanvasEntry)=>entry.id)
      Text('定时场景 · 一张中央卡片').fontSize(14).fontColor(this.appMuted()).width('100%')
      ForEach(this.sceneEntries.filter(c=>c.id!==this.store.state.canvasId),(entry:CanvasEntry)=>{Button(entry.name,{type:ButtonType.ROUNDED_RECTANGLE}).width('100%').height(48).backgroundColor(this.appControl()).fontColor(this.appText()).onClick(()=>this.copyInto(entry.id))},(entry:CanvasEntry)=>entry.id)
      Button('新建定时场景并复制',{type:ButtonType.Capsule,buttonStyle:ButtonStyleMode.NORMAL}).width('100%').height(44).backgroundColor(this.appControl()).fontColor(this.appText()).enabled(this.sceneEntries.length<12).onClick(()=>this.editTimedScene('',true,this.current()))
    }.width('100%').padding(20)}.width('100%').height('100%').scrollBar(BarState.Off)
  }
  private async copyInto(id:string,replace:boolean=false):Promise<void> {
    const card=this.current();if(!card||this.busy)return;this.busy=true;
    try{await this.store.save(false);if(!replace&&this.store.catalog.scenes.some(c=>c.id===id)&&(await this.store.canvasSnapshot(id)).cards.length>0){this.getUIContext().showAlertDialog({title:'替换中央卡片？',message:'目标场景只能保存一张卡片，原来的中央卡片会被替换。',primaryButton:{value:'取消',action:()=>{}},secondaryButton:{value:'替换',action:()=>this.copyInto(id,true)}});return;}await this.store.copyCardTo(card,id,replace);this.copyTargetOpen=false;this.getUIContext().getPromptAction().showToast({message:'已复制；原卡片保留'});}catch(e){this.templateError('复制未完成',e as Error);}finally{this.busy=false;}
  }
  private duplicate(): void {
    if (this.busy || this.canvasChanging || !this.canAddCards(1)) return;
    const card = this.current(); if (card === null) return;
    const copy = JSON.parse(JSON.stringify(card)) as FridgeCard; copy.id = this.store.newId(); copy.groupId = ''; copy.x += 16; copy.y += 16;
    copy.elements.forEach((e: CanvasElement) => {const old=e.id;e.id = this.store.newId();if(copy.html?.previewElementId===old)copy.html.previewElementId=e.id;});
    this.clamp(copy); this.store.addCard(copy); this.select(copy.id); this.change();
  }
  private deleteCard(id: string): void {
    if(this.scheduledName||this.scheduleTransition){this.getUIContext().getPromptAction().showToast({message:'请先恢复原始画布再编辑'});return;}
    this.getUIContext().showAlertDialog({ title: '删除卡片？', message: '卡片中的内容也会删除。',
      primaryButton: { value: '取消', action: () => {} },
      secondaryButton: { value: '删除', fontColor: '#C43A35', action: () => {
        this.beginCardDeletion(id);
      } }
    });
  }
  private async beginCardDeletion(id:string):Promise<void> {
    if(this.deletionId||!this.store.findCard(id))return;
    const canvas=this.store.state.canvasId,card=this.sceneCard(id);
    this.deletionId=id;
    this.deletionX=this.sceneX(id)-24;this.deletionY=this.sceneY(id)-24;
    const scale=this.sceneScale(id);
    this.deletionW=(card.w*this.boardScale+48)*scale;this.deletionH=(card.h*this.boardScale+48)*scale;
    this.deletionAngle=this.editing?this.surfaceAngle():card.rot;
    // A failed or slow capture must never block a confirmed deletion.
    this.deletionTimer=setTimeout(()=>this.finishCardDeletion(),1000);
    try {
      const pixelScale=this.getUIContext().vp2px(1);
      const captureScale=Math.min(1,640/(Math.max(this.deletionW,this.deletionH)*pixelScale));
      const bitmap=await this.getUIContext().getComponentSnapshot().get('deleteFace_'+id,{scale:captureScale,waitUntilRenderFinished:false});
      if(!this.alive||this.deletionId!==id||this.store.state.canvasId!==canvas){bitmap.release();return;}
      clearTimeout(this.deletionTimer);
      this.deletionBitmap=bitmap;
      this.deletionTimer=setTimeout(()=>this.finishCardDeletion(),1400);
    }catch(_){this.finishCardDeletion();}
  }
  private finishCardDeletion():void {
    if(this.deletionTimer>=0)clearTimeout(this.deletionTimer);this.deletionTimer=-1;
    const id=this.deletionId;if(!id)return;
    this.deletionId='';const bitmap=this.deletionBitmap;this.deletionBitmap=undefined;
    const wasEditing=this.editing;
    this.store.removeCard(id);cleanGroups(this.store.state.cards);this.selectedId='';
    if(this.groupSelection.includes(id))this.groupSelection=this.groupSelection.filter(value=>value!==id);
    this.editing=false;this.editorMounted=false;this.editorReady=false;this.heroActive=false;this.boardOpacity=1;this.scatter=0;
    // Deletion has no editor values to validate or clone. Publish only the board.
    this.renderBoard();if(wasEditing)this.layoutBoard();
    if(this.saveTimer>=0)clearTimeout(this.saveTimer);
    this.scheduleBackground();this.saveTimer=setTimeout(()=>this.persist(true),120);
    // Let the Image detach before releasing its native storage.
    if(bitmap)setTimeout(()=>bitmap.release(),80);
  }
  private boardInteraction(id: string, active: boolean): void {
    if (active) { this.scheduleGeneration++;this.selectedId=id; const card = this.store.findCard(id); this.movingGroupIds = card === null ? [] : groupMembers(this.store.state.cards, card).filter((c: FridgeCard) => c.id !== id).map((c: FridgeCard) => c.id); this.boardMotion.ids = this.movingGroupIds.length > 0 ? [id, ...this.movingGroupIds] : []; }
    else {this.boardMotion.guideVertical=false;this.boardMotion.guideHorizontal=false; this.boardMotion.offset = { x: 0, y: 0 }; this.boardMotion.ids = []; this.movingGroupIds = []; }
    this.activeBoardId = active ? id : '';
    if (this.saveTimer >= 0) clearTimeout(this.saveTimer); this.saveTimer = -1;
    if (!active) {
      this.scheduleBackground();
      // Commit and interaction-end belong to the same gesture. Publish once,
      // after the geometry handoff; backgrounding still flushes immediately.
      this.saveTimer = setTimeout(() => { this.saveTimer = -1; if (this.alive) this.persist(true); }, 32);
    }
  }
  private commitGeometry(updated: FridgeCard): void {
    const card = this.store.findCard(updated.id); if (card === null) return;
    const dx = updated.x - card.x, dy = updated.y - card.y;
    const translating=updated.w === card.w && updated.h === card.h && updated.rot === card.rot;
    if (translating) { for (const peer of groupMembers(this.store.state.cards, card)) if (peer.id !== card.id) { peer.x += dx; peer.y += dy; } }
    this.boardMotion.offset = { x: 0, y: 0 };
    card.x = updated.x; card.y = updated.y; card.w = updated.w; card.h = updated.h; card.rot = updated.rot;
    if(!translating)this.clamp(card);
    // Geometry handoff only updates the visible board; hydrate inspector on entry.
    if (this.editing || this.viewing) this.render(); else this.renderBoard();
    if (this.saveTimer >= 0) clearTimeout(this.saveTimer);
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
  private async enhancePhoto(subject:boolean):Promise<void> {
    if(!this.context||this.enhancementOpen||this.enhancingSubject||this.enhancingBackground||this.busy||this.backgroundBusy)return;
    if(!supportsSuperResolution()){this.getUIContext().getPromptAction().showToast({message:'此功能需要 HarmonyOS API 26 及支持超分的设备'});return;}
    const card=subject?this.current():null,canvasId=this.store.state.canvasId;
    const src=subject?(card?.cutout??''):this.canvasBackground.src;
    if(!src)return;
    const filesDir=this.context.filesDir;
    if(subject)this.enhancingSubject=true;else this.enhancingBackground=true;
    let enhanced='';
    const discard=(uri:string):void=>{if(uri.startsWith('file://'))fileIo.unlink(uri.slice(7)).catch(()=>{});};
    try {
      enhanced=await taskpool.execute(new taskpool.Task(enhanceImageJob,src,filesDir,subject)) as string;
      const valid=():boolean=>this.alive&&this.store.state.canvasId===canvasId&&(subject?card!==null&&this.store.findCard(card.id)===card&&card.cutout===src:this.canvasBackground.mode==='photo'&&this.canvasBackground.src===src);
      if(!valid()){discard(enhanced);return;}
      const result=enhanced;
      this.enhancementDialog=new CustomDialogController({builder:EnhancementPreview({original:src,enhanced:result,appDark:this.appDark,previewWidth:Math.max(160,Math.min(340,this.screenWidth-80,this.screenHeight-this.safeTop-this.safeBottom-260)),
        onDiscard:()=>{this.enhancementOpen=false;discard(result);},onUse:()=>{
          this.enhancementOpen=false;
          if(!valid()){discard(result);return;}
          if(subject&&card){card.cutout=result;this.change();}
          else{const bg=normalizeBackground(JSON.parse(JSON.stringify(this.canvasBackground)) as CanvasBackground);bg.src=result;this.applyBackground(bg);}
        }}),customStyle:true,autoCancel:true,openAnimation:settingsDialogOpen(),closeAnimation:settingsDialogClose()});
      this.enhancementOpen=true;this.enhancementDialog.open();
    } catch(error) {this.enhancementOpen=false;if(enhanced)discard(enhanced);if(this.alive)this.getUIContext().getPromptAction().showToast({message:'未修改原图：'+(error as Error).message});}
    finally{if(subject)this.enhancingSubject=false;else this.enhancingBackground=false;}
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
  onPageHide(): void { this.pageVisible=false;this.cancelForegroundRefresh();this.flushPendingEdits(); }
  private compareReading():void {
    if(!this.current()?.capability||this.readingComparisonOpen||this.capabilityPickerOpen)return;
    this.readingComparisonOpen=true;
  }
  onPageShow(): void { this.pageVisible=true;if(this.ready)this.scheduleForegroundRefresh(); }
  private taskSheetHeight(expanded:boolean=false):number {
    return Math.min(expanded?720:560,this.screenHeight*(expanded?.88:.70));
  }
  @Builder
  editorTaskSheet() {
    if(this.readingComparisonOpen){ReadingComparison({card:this.preview,appDark:this.appDark})}
    else{this.capabilityPickerSheet()}
  }
  private updateExtraCapability(id:string,next:CapBlock):void {
    const card=this.store.findCard(id);if(!card||card.capability?.k!==next.k)return;
    const courseDataChanged=next.k==='timetable'&&!sameTimetable(card.capability,next);
    if(next.k==='album'&&(next.albumPresentation??'cover')!==(card.capability.albumPresentation??'cover')) {
      if(next.albumPresentation==='row')card.h=card.w/2;else card.h=card.w;
    }
    card.capability=next;this.syncFields();this.change();
    if(courseDataChanged&&this.store.findCard(id)?.capability===next)this.store.rememberTimetable(next).catch(()=>{if(this.alive)this.getUIContext().getPromptAction().showToast({message:'课表未能保存，请重试修改；现有本地课表已保留'});});
  }
  private async reuseTimetable(id:string):Promise<void> {
    const card=this.store.findCard(id);if(card?.capability?.k!=='timetable')return;
    const previous=card.capability;
    try {
      const saved=await this.store.savedTimetable();
      if(!this.alive||this.store.findCard(id)!==card||card.capability!==previous)return;
      if(!saved){this.getUIContext().getPromptAction().showToast({message:'还没有已保存的课表，请先导入或添加课程'});return;}
      this.updateExtraCapability(id,useSavedTimetable(previous,saved));
    }catch(e){if(this.alive)this.getUIContext().getPromptAction().showToast({message:(e as Error).message});}
  }
  private async refreshCapabilities():Promise<void> {
    if(!this.ready||!this.alive||!this.pageVisible||!this.appWindowFocused||this.appBackgrounded||this.arriving||this.heroActive||this.activeBoardId||this.layerDrag||this.gestureGroup.length>0||this.refreshingCapabilities||!this.context)return;
    this.refreshingCapabilities=true;const canvasId=this.store.state.canvasId,generation=this.foregroundGeneration;
    const sources:FridgeCard[]=[],previous:CapBlock[]=[],results:CapBlock[]=[],keys:string[]=[];
    try {
      for(const card of this.store.state.cards.slice()) {
        const cap=card.capability;if(!needsDataRefresh(cap)||!cap)continue;
        const key=capabilityRequestKey(cap),next=await readCapability(cap,this.context);
        if(!this.alive||!this.pageVisible||!this.appWindowFocused||this.appBackgrounded||generation!==this.foregroundGeneration||this.store.state.canvasId!==canvasId)return;
        sources.push(card);previous.push(cap);results.push(next);keys.push(key);
      }
      if(this.gestureGroup||this.layerDrag||this.activeBoardId||this.arriving||this.heroActive||this.appBackgrounded){this.scheduleForegroundRefresh();return;}
      let changed=false;
      sources.forEach((card:FridgeCard,index:number)=>{
        const cap=previous[index],next=results[index];
        if(this.store.findCard(card.id)!==card||card.capability!==cap||capabilityRequestKey(cap)!==keys[index])return;
        if(cap.k==='battery'&&cap.percent===next.percent&&cap.charging===next.charging&&cap.chargeState===next.chargeState&&cap.refreshState===next.refreshState)return;
        if(JSON.stringify(next)===JSON.stringify(cap))return;
        card.capability=next;changed=true;
      });
      if(changed){this.render();this.persist(true);this.updateScheduledScene(true);}
    }finally{this.refreshingCapabilities=false;}
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
        if(!this.viewing&&this.canvasBackground.frameStyle!=='none'){CanvasFrame({material:this.canvasBackground.frameMaterial,style:this.canvasBackground.frameStyle}).width(BOARD_W*this.boardScale).height(this.boardHeight).position({x:this.boardLeft,y:this.boardTop}).opacity(this.boardOpacity).zIndex(100003).hitTestBehavior(HitTestMode.None)}
        if(this.scheduledFocusId && !this.editing) {
          ForEach(this.cards.filter((card:FridgeCard)=>card.id===this.scheduledFocusId),(card:FridgeCard)=>{
            Button({type:ButtonType.ROUNDED_RECTANGLE,buttonStyle:ButtonStyleMode.NORMAL}) {}
              .width(card.w*this.boardScale+this.focusedFringe(card).left+this.focusedFringe(card).right).height(card.h*this.boardScale+this.focusedFringe(card).top+this.focusedFringe(card).bottom).backgroundColor(Color.Transparent)
              .position({x:this.boardLeft+card.x*this.boardScale-this.focusedFringe(card).left,y:this.boardTop+card.y*this.boardHeight/BOARD_H-this.focusedFringe(card).top})
              .zIndex(100004).enabled(!this.scheduleTransition).accessibilityText('关闭中央展示并恢复画布').onClick((event:ClickEvent)=>{if(cardContainsPoint(card,event.x-this.focusedFringe(card).left,event.y-this.focusedFringe(card).top,this.boardScale))this.restoreScheduledScene();})
          },(card:FridgeCard)=>card.id)
        }
        if(this.scheduledName && !this.editing) {
          Button(this.scheduleOverride?'结束预览':this.timedScene?.focusId?'点击恢复':this.scheduledName+' · 返回编辑',{type:ButtonType.Capsule,buttonStyle:ButtonStyleMode.NORMAL})
            .height(44).fontSize(13).fontColor(this.appText()).backgroundColor(this.appSurface()).attributeModifier(immersiveChrome(this.appDark))
            .position({x:this.boardLeft+12,y:this.boardTop+12}).zIndex(100005).enabled(!this.scheduleTransition).onClick(()=>this.restoreScheduledScene())
        }
        if(!this.editing && !this.viewing && !this.arriving && !this.groupSelecting && this.selectedGroup().length>1) {
          GroupSelection({motion:this.boardMotion,box:this.selectedGroupBox(),minimum:groupMinimumScale(this.selectedGroup()),maximum:this.groupMaximumScale(),
            viewportW:BOARD_W*this.boardScale,viewportH:this.boardHeight,
            onBegin:()=>this.beginGroupTransform(),onFinish:(scale:number,angle:number)=>this.finishGroupTransform(scale,angle),onCancel:()=>this.cancelGroupTransform()})
            .position({x:this.boardLeft,y:this.boardTop}).zIndex(100003).hitTestBehavior(this.homeToolsMoving?HitTestMode.None:HitTestMode.Transparent)
        }
          // The embedded sheet belongs to the stable window root, not a rebuilding navigation body.
          Column().width(1).height(1).hitTestBehavior(HitTestMode.None).accessibilityLevel('no')
            .bindSheet($$this.editorSheetOpen,this.editorSectionSheet,{
              mode:SheetMode.EMBEDDED,preferType:SheetType.BOTTOM,
              detents:[this.editorWorkspace().body*.40+this.safeBottom,this.editorWorkspace().body*.78+this.safeBottom],
              detentSelection:this.editorControlHeight()+this.safeBottom,
              showClose:false,dragBar:true,enableOutsideInteractive:true,maskColor:Color.Transparent,
              backgroundColor:this.appSurface(),blurStyle:BlurStyle.NONE,scrollSizeMode:ScrollSizeMode.CONTINUOUS,
              onHeightDidChange:(height:number)=>this.editorSheetHeightChanged(height),
              onDetentsDidChange:(height:number)=>{const expanded=this.getUIContext().px2vp(height)>this.editorWorkspace().body*.60;this.editorExpanded=expanded;},
              onWillDismiss:(action:DismissSheetAction)=>this.dismissEditorSheet(action),onWillSpringBackWhenDismiss:(action:SpringBackAction)=>action.springBack()
            })
        if(!this.editing&&!this.viewing&&!this.arriving&&!this.groupSelecting&&this.selectedGroup().length<2&&!this.scheduledName&&!this.scheduleTransition) {
          ForEach(this.cardIds.filter((id:string)=>id===this.selectedId),(id:string)=>{
            BoardCard({controlsOnly:true,card:this.cardMap[id],motion:this.boardMotion,selected:true,scaleFactor:this.boardScale,yScaleFactor:this.boardHeight/BOARD_H,
              boardLeft:this.boardLeft,boardTop:this.boardTop,controlViewportWidth:BOARD_W*this.boardScale,controlViewportHeight:this.boardHeight,
              onDelete:(id:string)=>this.deleteCard(id),onEdit:(id:string)=>this.openEditor(id),
              onInteraction:(active:boolean)=>this.boardInteraction(id,active),onCommit:(next:FridgeCard)=>this.commitGeometry(next)})
          },(id:string)=>id)
        }
        if (this.editorMounted) { this.editor() }
        if (this.chromeSnapshot !== undefined) {
          Image(this.chromeSnapshot).width(this.screenWidth).height(this.screenHeight - this.safeTop - EDITOR_SAFE_GAP)
            .position({x:0,y:this.safeTop + EDITOR_SAFE_GAP}).opacity(this.editorOpacity).hitTestBehavior(HitTestMode.None)
        }
        if (this.viewing) { this.detail() }
        Column().width(1).height(1).position({x:this.navMenuX,y:this.navMenuY}).hitTestBehavior(HitTestMode.None).accessibilityLevel('no')
          .bindMenu(this.navMenuOpen,this.navMenuItems,{placement:Placement.BottomRight,systemMaterial:chromeMaterial(),backgroundColor:AppDesign.popup(this.appDark),onDisappear:()=>this.finishNavMenu(this.navMenuResult)})
        if(this.deletionId){
          Column().width('100%').height('100%').backgroundColor(Color.Transparent).hitTestBehavior(HitTestMode.Block).zIndex(200000)
          if(this.deletionBitmap!==undefined){CardDeletionFlight({bitmap:this.deletionBitmap,faceWidth:this.deletionW,faceHeight:this.deletionH,originX:this.deletionX,originY:this.deletionY,angle:this.deletionAngle,viewportWidth:this.screenWidth,viewportHeight:this.screenHeight,onDone:()=>this.finishCardDeletion()}).zIndex(200001)}
        }
      }
    }.width('100%').height('100%').backgroundColor(this.appBackground())

      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
      .onAreaChange((_: Area, area: Area) => {
        const width = Number(area.width), height = Number(area.height);
        if (width > 0 && height > 0 && (width!==this.screenWidth || height!==this.screenHeight)) { this.screenWidth = width; this.screenHeight = height; AppStorage.setOrCreate('workspaceHeight',height);if(this.editing&&!this.heroActive)this.editorSheetOpen=!this.editorLandscape(); this.layoutBoard(); }
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
        ForEach(this.startupCardCount>=0?this.cardIds.slice(0,this.startupCardCount):this.cardIds, (id: string) => {
          Stack({ alignContent: Alignment.TopStart }) {
            Stack({ alignContent: Alignment.TopStart }) {
            BoardCard({ showControls:false,layerMotion:this.layerMotion, controlViewportWidth: BOARD_W * this.boardScale, controlViewportHeight: this.boardHeight, motion: this.boardMotion, card: this.sceneCard(id), localCoordinates: true, scatterAngle: 0, editingSurface: this.editing,
              displayAngle: id === this.selectedId ? this.surfaceAngle() : this.cardMap[id].rot + this.scatter * (this.cardMap[id].z % 2 === 0 ? 9 : -9),
              selected: this.selectedId === id && !this.editing && !this.groupSelecting && this.selectedGroup().length < 2, scaleFactor: this.boardScale, yScaleFactor: this.boardHeight / BOARD_H,
              animateContent:this.editing&&!this.heroActive&&id===this.selectedId,
              hideContent: this.editing && id === this.selectedId && (this.heroActive ? this.heroHideContent : this.settingsTab === 0),
              movingLayerId: id === this.selectedId ? this.layerDrag : '',
              moveX: id === this.selectedId && this.editing ? this.layerDX * this.boardScale / this.editorScale() : 0, moveY: id === this.selectedId && this.editing ? this.layerDY * this.boardScale / this.editorScale() : 0, tick: capabilityRenderTick(this.sceneCard(id).capability,this.tick),
              getAlignmentAnchor:(card:FridgeCard)=>{const box=groupBox(groupMembers(this.store.state.cards,card),this.boardHeight/this.boardScale);return {x:box.x+box.w/2,y:box.y+box.h/2};},
              getMoveBounds: (card: FridgeCard) => groupDragBounds(this.store.state.cards, card, this.boardHeight/this.boardScale),
              onMove: (x: number, y: number) => { if (this.movingGroupIds.length > 0) { this.boardMotion.offset = { x: x, y: y }; } },
              onSelect: (id: string) => this.selectLayerCard(id), onDelete: (id: string) => this.deleteCard(id),
              onEdit: (id: string) => this.openEditor(id), onInteraction: (active: boolean) => this.boardInteraction(id, active), onCommit: (updated: FridgeCard) => this.commitGeometry(updated) })
          }.width(this.sceneCard(id).w * this.boardScale + 48).height(this.sceneCard(id).h * this.boardScale + 48)
            .scale({ x: this.sceneScale(id)*this.groupScale(id), y: this.sceneScale(id)*this.groupScale(id), centerX: this.groupPivotX(id), centerY: this.groupPivotY(id) })
            .rotate({angle:this.boardMotion.transformIds.includes(id)?this.boardMotion.pose.angle:0,centerX:this.groupPivotX(id),centerY:this.groupPivotY(id)})
            .position({ x: 0, y: 0 })
            .translate({ x: this.sceneX(id) - 24 - this.creationClipX(id) + this.arrivalX(id) + this.scheduleOffset(id,true),
              y: this.sceneY(id) - 24 - this.creationClipY(id) + this.arrivalY(id) + this.scheduleOffset(id,false) })
            .hitTestBehavior(this.editing || this.arriving || this.homeToolsMoving || this.scheduledName.length>0 || this.scheduleTransition ? HitTestMode.None : HitTestMode.Transparent)
          }.width(this.creationClip(id) ? this.transitionClipW : this.screenWidth)
            .height(this.creationClip(id) ? this.transitionClipH : this.screenHeight)
            .position({ x: this.creationClipX(id), y: this.creationClipY(id) })
            .borderRadius(this.creationClip(id) ? this.transitionClipRadius : 0).clip(this.creationClip(id))
            .opacity(this.deletionBitmap!==undefined&&this.deletionId===id?0:this.editing && id === this.selectedId ? 1 : this.boardOpacity)
            .zIndex(this.activeBoardId === id || this.boardMotion.ids.includes(id) ? 100000 + this.cardMap[id].z / (1 + this.cardMap[id].z) : this.cardMap[id].z)
            .hitTestBehavior(this.editing || this.arriving || this.homeToolsMoving || this.scheduledName.length>0 || this.scheduleTransition ? HitTestMode.None : HitTestMode.Transparent)
        }, (id: string) => id)
        CenterGuides({motion:this.boardMotion}).width(BOARD_W*this.boardScale).height(this.boardHeight).position({x:this.boardLeft,y:this.boardTop}).zIndex(200001).hitTestBehavior(HitTestMode.None)
      }.width(this.screenWidth).height(this.screenHeight)
        .position({ x: 0, y: 0 }).translate({ x: -this.sceneClipX(), y: -this.sceneClipY() }).hitTestBehavior(HitTestMode.Transparent)
    }.width(this.creatingTransition ? this.screenWidth : this.editing ? (this.heroActive ? this.transitionClipW : this.screenWidth) : BOARD_W * this.boardScale)
      .height(this.creatingTransition ? this.screenHeight : this.editing ? (this.heroActive ? this.transitionClipH : this.screenHeight) : this.boardHeight)
      .position({ x: 0, y: 0 }).translate({ x: this.sceneClipX(), y: this.sceneClipY() })
      .borderRadius(this.creatingTransition ? 0 : this.editing ? (this.heroActive ? this.transitionClipRadius : 0) : (this.canvasBackground.frameStyle==='none'?24:BOARD_W*this.boardScale*31/600)).clip(true)
      .hitTestBehavior(this.editing || this.arriving || this.homeToolsMoving || this.scheduledName.length>0 || this.scheduleTransition ? HitTestMode.None : HitTestMode.Transparent)
  }
  @Builder
  board() {
    Stack({ alignContent: Alignment.TopStart }) {
      Stack({ alignContent: Alignment.TopStart }) {
        CanvasBackdrop({ sceneBackground: this.canvasBackground,showFrame:false }).width('100%').height('100%')
        Column().width('100%').height('100%').onClick(() => { this.selectedId = ''; })
        if (this.cards.length === 0) {
          Text('放一张自己的卡片').fontSize(16).fontColor('#989898').width('100%').height('100%').textAlign(TextAlign.Center).hitTestBehavior(HitTestMode.None)
        }
      }.width(BOARD_W * this.boardScale).height(this.boardHeight).borderRadius(this.canvasBackground.frameStyle==='none'?24:BOARD_W*this.boardScale*31/600).clip(true).backgroundColor(this.canvasBackground.mode==='transparent'?Color.Transparent:Color.White)
        .border({ width: this.canvasBackground.frameStyle==='none'?.5:0, color: '#E9E9E9' }).id('homeCanvasSurface')
        .position({ x: this.boardLeft, y: this.boardTop })
      if(this.floatingHome()){this.homeDock()}else{this.homeLayers()}
    }.width('100%').height('100%').opacity(this.arriving ? 1 : this.boardOpacity).accessibilityLevel(this.editing || this.viewing ? 'no-hide-descendants' : 'auto').hitTestBehavior(this.editing || this.viewing || this.canvasChanging ? HitTestMode.BLOCK_DESCENDANTS : HitTestMode.Default)
  }
  private floatingHome():boolean {return workspaceLayout(this.screenWidth,this.screenHeight,this.safeTop,this.safeBottom,this.canvasAspect).floating;}
  private homeToolsHeight():number {const limit=Math.min(560,Math.max(200,(this.screenHeight-this.safeTop-this.safeBottom)*(this.screenHeight<600?.78:.56)));return Math.min(limit,Math.max(232,216+Math.min(4,this.cards.length)*72));}
  private backgroundPopupHome():boolean {return this.floatingHome();}
  private compactTimingLabel():boolean {return !this.floatingHome()&&(this.panelWidth<440||this.backgroundHeaderActive&&this.panelWidth<520);}
  @Builder
  phoneTools() {
    Stack({alignContent:Alignment.TopStart}) {this.homeLayers(true)}
      .width(this.screenWidth-32).height(this.homeToolsHeight()).hitTestBehavior(this.homeToolsMoving?HitTestMode.BLOCK_DESCENDANTS:HitTestMode.Default)
  }
  private closeBackgroundEditor():void {
    this.backgroundOpen=false;this.updateScheduledScene(true);
  }
  private backgroundToolsHeight():number {
    const extra=this.canvasBackground.mode==='solid'?160:this.canvasBackground.mode==='photo'?140:this.canvasBackground.mode==='transparent'?72:92;
    return Math.min(this.homeToolsHeight(),320+extra+(this.canvasBackground.frameStyle==='none'?0:56));
  }
  @Builder
  phoneBackgroundTools() {
    Column(){this.backgroundEditor()}.width(this.floatingHome()?this.screenWidth-32:this.panelWidth).height(this.backgroundToolsHeight())
  }
  @Builder
  phoneTimingTools() {
    Column(){this.scheduleEditor()}.width(this.screenWidth-32).height(this.homeToolsHeight())
  }
  @Builder
  timingButton(size:number) {
    Button({type:ButtonType.Capsule,buttonStyle:ButtonStyleMode.NORMAL}) {
      Row({space:4}) {
        SymbolGlyph($r('sys.symbol.timer')).fontSize(18).fontColor([this.appText()]).hitTestBehavior(HitTestMode.None)
        if(!this.compactTimingLabel()){Text('定时').fontSize(13).fontColor(this.appText()).hitTestBehavior(HitTestMode.None)}
      }
    }.height(size).constraintSize({minWidth:44}).layoutWeight(!this.floatingHome()&&this.timingHeaderActive?1:0).padding({left:this.floatingHome()?12:8,right:this.floatingHome()?12:8}).backgroundColor(this.appControl()).attributeModifier(immersiveChrome(this.appDark))
      .accessibilityText(this.sceneEditing?'完成定时场景编辑':'定时：场景与画布轮换').onClick(()=>{if(this.sceneEditing){this.leaveTimedScene();return;}if(this.scheduleOpen){this.scheduleOpen=false;this.updateScheduledScene(true);}else this.openScenePanel();})
      .bindPopup(this.floatingHome()&&this.scheduleOpen,{builder:this.phoneTimingTools,placement:Placement.Top,width:this.screenWidth-32,radius:24,transition:canvasToolsTransition(),systemMaterial:popupMaterial(this.appDark),popupColor:AppDesign.popup(this.appDark),backgroundBlurStyle:BlurStyle.COMPONENT_THICK,enableArrow:false,autoCancel:true,focusable:true,mask:{color:Color.Transparent},onStateChange:(event)=>{if(!event.isVisible){this.scheduleOpen=false;this.updateScheduledScene(true);}}})
  }
  @Builder
  homeBackgroundButton(size:number) {
      Button({type:this.floatingHome()?ButtonType.Circle:ButtonType.Capsule,buttonStyle:ButtonStyleMode.NORMAL}) {
        Row({space:6}) {
          SymbolGlyph($r('sys.symbol.paintpalette')).fontSize(22).fontColor([this.appText()]).hitTestBehavior(HitTestMode.None)
          if(this.backgroundHeaderActive&&!this.floatingHome()){Text('背景').fontSize(13).fontColor(this.appText()).hitTestBehavior(HitTestMode.None)}
        }.hitTestBehavior(HitTestMode.None)
      }.constraintSize({minWidth:size}).layoutWeight(this.backgroundHeaderActive&&!this.floatingHome()?1:0).height(size).padding({left:this.floatingHome()?0:8,right:this.floatingHome()?0:8}).attributeModifier(immersiveChrome(this.appDark)).accessibilityText('画布背景')
        .enabled(!this.scheduledName&&!this.scheduleTransition).onClick(()=>{if(this.backgroundOpen)this.closeBackgroundEditor();else this.openBackgroundEditor();})
        .bindPopup(this.backgroundOpen&&this.backgroundPopupHome(),{builder:this.phoneBackgroundTools,placement:Placement.Top,width:this.floatingHome()?this.screenWidth-32:this.panelWidth,radius:24,transition:canvasToolsTransition(),systemMaterial:popupMaterial(this.appDark),popupColor:AppDesign.popup(this.appDark),backgroundBlurStyle:BlurStyle.COMPONENT_THICK,enableArrow:false,autoCancel:true,focusable:true,mask:{color:Color.Transparent},onStateChange:(event)=>{if(!event.isVisible&&this.backgroundOpen&&this.floatingHome())this.closeBackgroundEditor();}})
  }
  @Builder
  homeDock() {
    Row({space:8}) {
      Button({type:ButtonType.Capsule,buttonStyle:ButtonStyleMode.NORMAL}) {
        Row({space:8}) {
          if(this.screenWidth>=360){SymbolGlyph($r('sys.symbol.square_stack_3d')).fontSize(20).fontColor([this.appText()])}
          Text('画布').fontSize(15).fontWeight(FontWeight.Medium).fontColor(this.appText()).maxLines(1).textOverflow({overflow:TextOverflow.Ellipsis}).layoutWeight(1)
          SymbolGlyph($r('sys.symbol.chevron_up')).fontSize(12).fontColor([this.appMuted()]).rotate({angle:this.homeToolsOpen?180:0})
        }.width('100%').hitTestBehavior(HitTestMode.None)
      }.height(48).layoutWeight(1).padding({left:12,right:12}).attributeModifier(immersiveChrome(this.appDark))
        .accessibilityText('展开画布工具 '+this.canvasName).onClick(()=>{this.refreshCanvasList();this.scheduleOpen=false;this.backgroundOpen=false;this.homeToolsOpen=!this.homeToolsOpen;})
        .bindPopup(this.homeToolsOpen,{builder:this.phoneTools,placement:Placement.Top,width:this.screenWidth-32,radius:24,transition:canvasToolsTransition(),systemMaterial:popupMaterial(this.appDark),popupColor:AppDesign.popup(this.appDark),backgroundBlurStyle:BlurStyle.COMPONENT_THICK,enableArrow:false,autoCancel:true,focusable:true,mask:{color:Color.Transparent},onStateChange:(event)=>{if(!event.isVisible)this.homeToolsOpen=false;}})
      this.timingButton(48)
      this.homeBackgroundButton(48)
      Button({type:ButtonType.Circle,buttonStyle:ButtonStyleMode.NORMAL}) {
        SymbolGlyph($r('sys.symbol.plus')).fontSize(22).fontColor([this.appText()]).hitTestBehavior(HitTestMode.None)
      }.width(48).height(48).attributeModifier(immersiveChrome(this.appDark)).accessibilityText('添加卡片').enabled(!this.scheduledName&&!this.scheduleTransition).onClick(()=>this.addCard())
    }.width(Math.min(360,this.screenWidth-32)).position({x:(this.screenWidth-Math.min(360,this.screenWidth-32))/2,y:this.screenHeight-this.safeBottom-68})
  }
  private selectLayerCard(id: string): void {
    if(this.scheduledName||this.scheduleTransition){this.getUIContext().getPromptAction().showToast({message:'请先恢复原始画布再编辑'});return;}
    if (!this.groupSelecting) { if(this.selectedId===id)this.selectedId='';else this.select(id); return; }
    this.groupSelection = this.groupSelection.includes(id) ? this.groupSelection.filter((value: string) => value !== id) : this.groupSelection.concat([id]);
  }
  private confirmGroup(): void {
    if (this.groupSelection.length < 2) return;
    combineCards(this.store.state.cards, this.groupSelection, this.store.newId()); this.groupSelecting = false; this.groupSelection = []; this.renderBoard(); this.persist(true);
  }
  private selectedGroup():FridgeCard[] {
    const card=this.cardMap[this.selectedId];return card&&card.groupId?this.cards.filter((c:FridgeCard)=>c.groupId===card.groupId):[];
  }
  private selectedGroupBox():GroupBox {
    const logical=groupBox(this.selectedGroup(),this.boardHeight/this.boardScale),box=new GroupBox();
    box.x=logical.x*this.boardScale;box.y=logical.y*this.boardScale;box.w=logical.w*this.boardScale;box.h=logical.h*this.boardScale;return box;
  }
  private groupScale(id:string):number{return this.boardMotion.transformIds.includes(id)?this.boardMotion.pose.scale:1;}
  private groupPivotX(id:string):number {if(!this.boardMotion.transformIds.includes(id))return 24;return this.boardMotion.pivot.x-this.sceneX(id)+24;}
  private groupPivotY(id:string):number {if(!this.boardMotion.transformIds.includes(id))return 24;return this.boardMotion.pivot.y-this.sceneY(id)+24;}
  private groupMaximumScale():number {let max=4;for(const c of this.selectedGroup())max=Math.min(max,320/c.w,420/c.h);return Math.max(groupMinimumScale(this.selectedGroup()),max);}
  private beginGroupTransform():void {
    if(this.saveTimer>=0)clearTimeout(this.saveTimer);this.saveTimer=-1;
    const b=this.selectedGroupBox();this.boardMotion.pivot={x:this.boardLeft+b.x+b.w/2,y:this.boardTop+b.y+b.h/2};
    this.boardMotion.pose=new GroupPose();this.boardMotion.transformIds=this.selectedGroup().map((c:FridgeCard)=>c.id);
  }
  private cancelGroupTransform():void {this.boardMotion.pose=new GroupPose();this.boardMotion.transformIds=[];}
  private finishGroupTransform(scale:number,angle:number):void {
    const card=this.current();if(card===null){this.cancelGroupTransform();return;}
    const members=groupMembers(this.store.state.cards,card),height=this.boardHeight/this.boardScale;
    transformGroup(members,groupBox(members,height),height,scale,angle);
    this.cancelGroupTransform();this.renderBoard();this.scheduleBackground();this.persist(true);
  }
  private releaseGroup(): void {
    const card = this.store.findCard(this.selectedId); if (card === null) return; this.cancelGroupTransform(); ungroupCards(this.store.state.cards, card.groupId); this.renderBoard(); this.persist(true);
  }
  @Builder
  homeLayerRow(id: string) {
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
                      if(this.cardMap[id].shape==='subject'&&this.cardMap[id].subjectPhoto&&this.cardMap[id].cutout) {
                        Image(this.cardMap[id].cutout).width(44).height(44).objectFit(ImageFit.Contain).draggable(false)
                      } else {
                      CardCanvas({card:this.cardMap[id],scaleFactor:Math.min(44/this.cardMap[id].w,44/this.cardMap[id].h),tick:capabilityRenderTick(this.cardMap[id].capability,this.tick)})
                        .width(this.cardMap[id].w*Math.min(44/this.cardMap[id].w,44/this.cardMap[id].h)).height(this.cardMap[id].h*Math.min(44/this.cardMap[id].w,44/this.cardMap[id].h))
                      }
                    }.width(44).height(44).hitTestBehavior(HitTestMode.None)
                    Column({space:4}) {
                      Text(layerLabel(this.cardMap[id])).fontSize(14).maxLines(1).textOverflow({overflow:TextOverflow.Ellipsis}).fontColor(this.appText()).width('100%')
                      Text((this.orderedCards()[0]?.id===id?'最上层 · ':'')+(this.cardMap[id].capability!==null?typeLabel(this.cardMap[id].capability?.k??''):'自定义')).fontSize(11).fontColor(this.appMuted()).width('100%')
                    }.layoutWeight(1).hitTestBehavior(HitTestMode.None)
                  }.width('100%')
                }.layoutWeight(1).height(48).padding(0).backgroundColor(Color.Transparent)
                  .accessibilityText('选择卡片 '+layerLabel(this.cardMap[id])).onClick(()=>this.selectLayerCard(id))
                if (!this.groupSelecting) {
                  Button('编辑',{type:ButtonType.Capsule,buttonStyle:ButtonStyleMode.NORMAL}).height(AppDesign.controlHeight).fontSize(13).backgroundColor(this.appControl()).fontColor(this.appText()).enabled(!this.groupSelecting&&!this.scheduledName).onClick(()=>this.openEditor(id))
                  Button({type:ButtonType.Circle,buttonStyle:ButtonStyleMode.NORMAL,role:ButtonRole.ERROR}) {
                    SymbolGlyph($r('sys.symbol.trash')).fontSize(18).fontColor(['#C43A35']).hitTestBehavior(HitTestMode.None)
                  }.width(44).height(44).backgroundColor(this.appControl()).enabled(!this.groupSelecting&&!this.scheduledName).accessibilityText('删除 '+layerLabel(this.cardMap[id])).onClick(()=>this.deleteCard(id))
                }
              }.width('100%').padding(8).borderRadius(12).backgroundColor(this.appSurface()).border({width:!this.groupSelecting&&this.selectedId===id?1.5:0,color:this.appMuted()})
  }
  private homePanelTransition(timing:boolean):TransitionEffect {
    return TransitionEffect.OPACITY.combine(TransitionEffect.scale({x:.92,y:.88,centerX:timing?'65%':'20%',centerY:0}))
      .combine(TransitionEffect.translate({y:-16})).animation(canvasToolsMotion(true));
  }
  @Builder
  homeLayers(floating:boolean=false) {
      Column({ space: 12 }) {
        Row({space:floating?8:6}) {

          Button({type:ButtonType.Capsule, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL}) {
            Row({space:6}) {
              Text(this.sceneEditing?'定时场景 · '+this.canvasName:'画布').fontSize(floating?17:15).fontWeight(FontWeight.Medium).fontColor(this.appText()).maxLines(1).textOverflow({overflow:TextOverflow.Ellipsis}).layoutWeight(!floating&&(this.timingHeaderActive||this.backgroundHeaderActive)?0:1)
              if(floating||!(this.timingHeaderActive||this.backgroundHeaderActive)){SymbolGlyph($r('sys.symbol.chevron_down')).fontSize(14).fontColor([this.appText()]).hitTestBehavior(HitTestMode.None)}
            }.width(!floating&&(this.timingHeaderActive||this.backgroundHeaderActive)?'auto':'100%')
          }.id('shareCanvas').padding({left:floating?12:8,right:floating?12:8}).accessibilityText('切换画布 '+this.canvasName).height(44).layoutWeight(!floating&&(this.timingHeaderActive||this.backgroundHeaderActive)?0:1).constraintSize({maxWidth:!floating&&(this.timingHeaderActive||this.backgroundHeaderActive)?this.panelWidth*.45:this.panelWidth}).fontSize(12).fontColor(this.appText()).backgroundColor(this.appControl()).onClick(()=>{if(this.sceneEditing){this.leaveTimedScene();return;}if(this.canvasChanging)return;if(this.scheduleOpen||this.backgroundOpen){this.scheduleOpen=false;this.backgroundOpen=false;return;}this.refreshCanvasList();this.canvasCreating=false;this.canvasRenameId='';if(!floating)this.homeToolsOpen=false;this.scheduleOpen=false;this.canvasPickerOpen=!this.canvasPickerOpen;})
            .bindPopup(this.canvasPickerOpen,{builder:this.canvasPicker,placement:Placement.Top,width:this.canvasPopupWidth(),radius:20,transition:canvasToolsTransition(),systemMaterial:popupMaterial(this.appDark),popupColor:AppDesign.popup(this.appDark),backgroundBlurStyle:BlurStyle.COMPONENT_THICK,enableArrow:true,autoCancel:true,focusable:true,mask:{color:Color.Transparent},onStateChange:(event)=>{if(!event.isVisible){this.canvasPickerOpen=false;this.canvasCreating=false;}}})
          if(!floating){this.timingButton(44);this.homeBackgroundButton(44)}
          Button(this.groupSelecting ? '取消' : '多选', { type: ButtonType.Capsule, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL }).width(48).padding({left:8,right:8}).height(44).fontSize(13).backgroundColor(this.appControl()).fontColor(this.appText()).enabled(!this.scheduledName).onClick(() => { this.scheduleOpen=false;this.backgroundOpen=false;this.groupSelecting = !this.groupSelecting; this.groupSelection = []; })
          if(!floating) {
          Button({ type: ButtonType.Circle, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL }) {SymbolGlyph($r('sys.symbol.plus')).fontSize(22).fontColor([Color.White]).hitTestBehavior(HitTestMode.None)}.width(44).height(AppDesign.controlHeight).fontSize(24).backgroundColor('#262626').fontColor(Color.White).accessibilityText('添加卡片').enabled(!this.scheduledName&&!this.scheduleTransition).onClick(() => this.addCard())
          } else {
            Button('导入',{type:ButtonType.Capsule,buttonStyle:ButtonStyleMode.NORMAL}).id('importTemplate').height(44).fontSize(13).padding({left:12,right:12}).backgroundColor(this.appControl()).fontColor(this.appText()).enabled(!this.sharing&&!this.backgroundBusy).onClick(()=>this.pickTemplate())
          }
        }.width('100%')
        if (!this.scheduleOpen&&!this.backgroundOpen&&this.cards.length >= CANVAS_CARD_TARGET) {
          Row({space:8}) {
            Text(this.cards.length + ' / ' + CANVAS_CARD_LIMIT).fontSize(12).fontColor(this.appMuted())
              .accessibilityText('当前画布 '+this.cards.length+' 张卡片，最多 '+CANVAS_CARD_LIMIT+' 张')
            Text(canvasCapacityHint(this.cards.length)).fontSize(12).fontColor(this.appMuted()).layoutWeight(1).maxLines(2)
          }.width('100%')
        }
        Stack({ alignContent: Alignment.Bottom }) {
        if(!floating&&this.scheduleOpen) {
          Column(){this.scheduleEditor()}.width('100%').height('100%').transition(this.homePanelTransition(true))
        } else if(!floating&&this.backgroundOpen) {
          Column(){this.backgroundEditor()}.width('100%').height('100%').transition(this.homePanelTransition(true))
        } else {
        Stack({alignContent:Alignment.Bottom}){
        List({space:8}) {
          ForEach(layerSections(this.orderedCards()), (section: LayerSection) => {
            ForEach(section.ids,(id:string,index:number)=>{
              ListItem() {
                Column({space:4}) {
                  if(index===0&&section.title.length>0) { Text(section.title).fontSize(12).fontWeight(FontWeight.Medium).fontColor(this.appMuted()).width('100%').padding({left:8,top:8,bottom:4}) }
                  this.homeLayerRow(id)
                }.width('100%')
              }
            },(id:string)=>id)
          }, (section:LayerSection)=>section.id+':'+section.title+':'+section.ids.join(','))
        }.width('100%').height('100%').contentEndOffset(this.homeActionHeight()+8).cachedCount(1).scrollBar(BarState.Off)
        if (this.homeActionHeight() > 0) {
        Column({ space: 12 }) {
        if (this.groupSelecting) {
          Row() {
            Button('组合 ' + this.groupSelection.length + ' 张卡片', { type: ButtonType.Capsule, buttonStyle:ButtonStyleMode.EMPHASIZED, role:ButtonRole.NORMAL })
              .height(44).fontSize(14).padding({left:20,right:20}).backgroundColor(this.groupSelection.length>1?AppDesign.selected(this.appDark):this.appControl()).fontColor(this.groupSelection.length>1?AppDesign.onSelected(this.appDark):this.appMuted()).opacity(1).attributeModifier(immersiveChrome(this.appDark,this.groupSelection.length>1))
              .accessibilityText('组合选中的 '+this.groupSelection.length+' 张卡片').accessibilityDescription(this.groupSelection.length<2?'至少选择两张卡片才能组合':'组合所选卡片').onClick(() => this.confirmGroup())
            Blank()
          }.width('100%')
        }
        if (!this.groupSelecting && this.selectedId.length > 0) {
          Row({space:8}) {
            Button('上移一层', { type: ButtonType.Capsule, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL }).layoutWeight(1).padding({left:6,right:6}).height(AppDesign.controlHeight).fontSize(12).backgroundColor(this.appControl()).fontColor(this.appText()).attributeModifier(immersiveChrome(this.appDark)).onClick(() => this.moveCardLayer(this.selectedId, true))
            Button('下移一层', { type: ButtonType.Capsule, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL }).layoutWeight(1).padding({left:6,right:6}).height(AppDesign.controlHeight).fontSize(12).backgroundColor(this.appControl()).fontColor(this.appText()).attributeModifier(immersiveChrome(this.appDark)).onClick(() => this.moveCardLayer(this.selectedId, false))
            Button('复制',{type:ButtonType.Capsule,buttonStyle:ButtonStyleMode.NORMAL})
              .layoutWeight(1).padding({left:6,right:6}).height(44).fontSize(12).fontColor(this.appText()).backgroundColor(this.appControl()).attributeModifier(immersiveChrome(this.appDark)).accessibilityText('复制卡片').bindMenu([{value:'复制',action:()=>this.duplicate()},{value:'复制到别的场景',action:()=>this.copyTargetOpen=true}],{systemMaterial:chromeMaterial(),backgroundColor:AppDesign.popup(this.appDark)})
              .bindSheet($$this.copyTargetOpen,this.copyTargets,{height:this.taskSheetHeight(),showClose:true,backgroundColor:this.appBackground()})
            if((this.cardMap[this.selectedId]?.groupId??'').length>0) { Button('取消组合',{type:ButtonType.Capsule,buttonStyle:ButtonStyleMode.NORMAL}).layoutWeight(1).padding({left:6,right:6}).height(44).fontSize(12).backgroundColor(this.appControl()).fontColor(this.appText()).attributeModifier(immersiveChrome(this.appDark)).onClick(()=>this.releaseGroup()) }
          }.width('100%')
        }
        }.width('100%').padding({top:8,bottom:8})
        }
        }.width('100%').height('100%').transition(this.homePanelTransition(false))
        }
        }.width('100%').layoutWeight(1)
      }.width(floating?this.screenWidth-32:this.panelWidth).height(floating?this.homeToolsHeight():this.panelHeight).padding(12).backgroundColor(floating?Color.Transparent:this.appSurface()).borderRadius(AppDesign.sectionRadius)
        .position({x:floating?0:this.panelLeft,y:floating?0:this.panelTop})
  }
  private homeActionHeight():number {return this.groupSelecting?60:this.selectedId.length===0?0:60;}
  private backgroundLabel(): string {
    return this.canvasBackground.mode === 'transparent' ? '桌面透明' : this.canvasBackground.mode === 'smart' ? '智能取色' : this.canvasBackground.mode === 'blend' ? '智能多色' : this.canvasBackground.mode === 'photo' ? '本地照片' : this.canvasBackground.mode === 'preset' ? '柔色预设' : '纯色';
  }
  private applyBackground(bg: CanvasBackground): void {
    this.backgroundGeneration += 1; this.backgroundBusy = false; this.canvasBackground = bg; this.store.state.background = bg;
    this.persist(true);
  }
  private scheduleBackground(): void {
    if (this.timedScene||!['smart','blend'].includes(this.canvasBackground.mode) || !this.ready) return;
    if (this.backgroundTimer >= 0) clearTimeout(this.backgroundTimer);
    this.backgroundTimer = setTimeout(() => { this.backgroundTimer = -1; this.refreshBackground(); }, 1200);
  }
  private async refreshBackground(force: boolean = false): Promise<void> {
    if (this.timedScene||this.scheduleTransition||this.context === null || !['smart','blend'].includes(this.canvasBackground.mode)) return;
    if(this.deletionId||this.activeBoardId||this.gestureGroup||this.heroActive||this.arriving){this.scheduleBackground();return;}
    this.store.state.background = this.canvasBackground; this.store.state.canvasAspect = this.canvasAspect;
    const signature = backgroundSignature(this.store.state);
    if (!force && signature === this.canvasBackground.signature) return;
    const generation = ++this.backgroundGeneration; this.backgroundBusy = true;
    const state = new FridgeState(); state.background = this.canvasBackground; state.canvasAspect = this.canvasAspect;
    state.cards = this.store.state.cards.map((card: FridgeCard) => cardRenderSnapshot(card));
    try {
      const json = await taskpool.execute(new taskpool.Task(createSmartBackground, JSON.stringify(state), this.context.filesDir)) as string;
      if (!this.alive || generation !== this.backgroundGeneration) return;
      if(this.deletionId||signature!==backgroundSignature(this.store.state)){this.scheduleBackground();return;}
      const next = normalizeBackground(JSON.parse(json) as CanvasBackground); this.applyBackground(next);
    } catch (_) { if (this.alive && generation === this.backgroundGeneration) this.getUIContext().getPromptAction().showToast({ message: '取色未完成，保留原背景，请重试' }); }
    finally { if (generation === this.backgroundGeneration) this.backgroundBusy = false; }
  }
  private chooseBackgroundMode(mode: string): void {
    if (mode === 'photo') { if (this.canvasBackground.photo.length > 0) { this.openBackgroundCrop(this.canvasBackground.photo); } else this.pickBackgroundPhoto(); return; }
    const bg = new CanvasBackground(); bg.frameStyle = this.canvasBackground.frameStyle; bg.frameMaterial = this.canvasBackground.frameMaterial; bg.mode = mode; bg.color = this.canvasBackground.color; bg.photo = this.canvasBackground.photo;
    this.applyBackground(bg); if (mode === 'smart' || mode === 'blend') this.refreshBackground(true);
  }
  private backgroundColorKey(): string { return 'canvas:' + this.store.state.canvasId; }
  private setBackgroundColor(color: string, key: string): void {
    if (!this.alive || key !== this.backgroundColorKey() || this.canvasBackground.mode !== 'solid') return;
    const bg = new CanvasBackground(); bg.frameStyle = this.canvasBackground.frameStyle; bg.frameMaterial = this.canvasBackground.frameMaterial; bg.color = color || '#FFFFFF'; bg.photo = this.canvasBackground.photo; this.applyBackground(bg);
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
    this.photoCropDialog = new CustomDialogController({ builder: PhotoCrop({ source: src, aspect: this.canvasAspect, appDark: this.appDark, viewportWidth:this.screenWidth, viewportHeight:this.screenHeight-this.safeTop-this.safeBottom,
      onApply: (zoom: number, x: number, y: number) => { this.commitBackgroundCrop(src, zoom, x, y); } }), customStyle: true, openAnimation: settingsDialogOpen(), closeAnimation: settingsDialogClose(), autoCancel: false });
    this.photoCropDialog.open();
  }
  private async commitBackgroundCrop(src: string, zoom: number, x: number, y: number): Promise<void> {
    if (this.context === null) return; this.backgroundBusy = true; const generation = ++this.backgroundGeneration;
    try {
      const result = await taskpool.execute(new taskpool.Task(cropBackgroundPhoto, src, this.context.filesDir, this.canvasAspect, zoom, x, y)) as string;
      if (!this.alive || generation !== this.backgroundGeneration) return;
      const bg = new CanvasBackground(); bg.frameStyle = this.canvasBackground.frameStyle; bg.frameMaterial = this.canvasBackground.frameMaterial; bg.mode = 'photo'; bg.src = result; bg.photo = src; this.applyBackground(bg);
    } catch (_) { if (this.alive) this.getUIContext().getPromptAction().showToast({ message: '照片调整失败，请重试' }); }
    finally { if (generation === this.backgroundGeneration) this.backgroundBusy = false; }
  }
  private setBackgroundPreset(index: number): void {
    const palettes: string[][] = [['#C5B6A3','#83949A','#D5B6A9'],['#9EAF96','#B6B0C5','#D9C9A5'],['#859EB5','#B8C7C2','#C5B7AD']];
    const bg = new CanvasBackground(); bg.frameStyle = this.canvasBackground.frameStyle; bg.frameMaterial = this.canvasBackground.frameMaterial; bg.mode = 'blend'; bg.color = palettes[index][0];
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
  private openBackgroundEditor():void {
    if(!this.context)return;
    this.homeToolsOpen=false;this.scheduleOpen=false;this.canvasPickerOpen=false;this.backgroundOpen=true;
  }
  @Builder
  backgroundEditor() {
    Scroll() {
      Column({ space: 12 }) {
        Text('画布背景').fontSize(17).fontWeight(FontWeight.Medium).fontColor(this.appText()).width('100%')
        Column({ space: 12 }) {
          SettingsSegmented({labels:['纯色','取色','多色','照片','透明'],selectedIndex:this.canvasBackground.mode==='preset'?2:Math.max(0,['solid','smart','blend','photo','transparent'].indexOf(this.canvasBackground.mode)),appDark:this.appDark,
            onSelect:(index:number)=>{if(!this.backgroundBusy)this.chooseBackgroundMode(['solid','smart','blend','photo','transparent'][index]);}}).enabled(!this.backgroundBusy)
          Stack({alignContent:Alignment.TopStart}) {ForEach([this.canvasBackground.mode],(_mode:string)=>{
          Column({space:12}) {
          Text('画框').fontSize(13).fontColor(this.appMuted()).width('100%')
          SettingsSegmented({labels:['无框','浅色','深色','跟随系统'],selectedIndex:Math.max(0,['none','light','dark','auto'].indexOf(this.canvasBackground.frameStyle)),appDark:this.appDark,onSelect:(index:number)=>{const bg=normalizeBackground(this.canvasBackground);bg.frameStyle=['none','light','dark','auto'][index];this.applyBackground(bg);}})
          if(this.canvasBackground.frameStyle!=='none'){SettingsSegmented({labels:['白岩','胡桃木','浅橡木'],selectedIndex:Math.max(0,['stone','walnut','oak'].indexOf(this.canvasBackground.frameMaterial)),appDark:this.appDark,onSelect:(index:number)=>{const bg=normalizeBackground(this.canvasBackground);bg.frameMaterial=['stone','walnut','oak'][index];this.applyBackground(bg);}})}
          if(this.canvasBackground.mode==='transparent'){
            Text('只显示卡片，桌面壁纸透过空白处；卡片仍限制在小组件范围内。空画布会显示可见的添加提示。').fontSize(13).fontColor(this.appMuted()).width('100%')}
          if (this.canvasBackground.mode === 'solid') {
            ColorSetting({label:'背景颜色',color:this.canvasBackground.color,canReset:false,sourceKey:this.backgroundColorKey(),appDark:this.appDark,
              onPick:(color:string,key:string)=>this.setBackgroundColor(color,key),onFallback:()=>this.chooseBackgroundColor()})
            Flex({ wrap: FlexWrap.Wrap }) {
              ForEach(['#FFFFFF','#F1EEE6','#E9E5DF','#E2E8E2','#E3E9EF','#292B2B'], (color: string) => {
                Button({ type: ButtonType.Circle, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL }).width(44).height(44).backgroundColor(color).margin({ right: 8, bottom: 8 })
                  .border({ width: this.canvasBackground.color === color ? 2 : .5, color: this.appMuted() }).accessibilityText('背景色 '+color)
                  .onClick(() => { const bg = new CanvasBackground(); bg.frameStyle = this.canvasBackground.frameStyle; bg.frameMaterial = this.canvasBackground.frameMaterial; bg.color = color; bg.photo = this.canvasBackground.photo; this.applyBackground(bg); })
              }, (color: string) => color)
            }.width('100%')
          }
          if (this.canvasBackground.mode === 'smart' || this.canvasBackground.mode === 'blend') {
            Text(this.backgroundBusy ? '正在从本地卡片提取颜色' : this.canvasBackground.mode === 'smart' ? '根据全部可见卡片取色，降低饱和度以衬托作品。' : '移动时保持当前配色；换图或改色后更新，也可手动重新取色。').fontSize(13).fontColor(this.appMuted()).width('100%')
            Button('重新取色', { type: ButtonType.Capsule, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL }).height(44).fontColor(this.appText()).backgroundColor(this.appControl()).enabled(!this.backgroundBusy).onClick(() => this.refreshBackground(true))
          }
          if (this.canvasBackground.mode === 'photo') {
            if (this.canvasBackground.photo.length > 0) { Button('调整照片', { type: ButtonType.Capsule, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL }).height(44).fontColor(this.appText()).backgroundColor(this.appControl()).enabled(!this.backgroundBusy).onClick(() => this.openBackgroundCrop(this.canvasBackground.photo)) }
            if(this.canvasBackground.src.length>0){Button(this.enhancingBackground?'正在提升清晰度':'提升清晰度',{type:ButtonType.Capsule,buttonStyle:ButtonStyleMode.NORMAL}).height(44).fontColor(this.appText()).backgroundColor(this.appControl()).enabled(!this.backgroundBusy&&!this.enhancingBackground&&!this.enhancingSubject).onClick(()=>this.enhancePhoto(false))}
            Button('选择本地照片', { type: ButtonType.ROUNDED_RECTANGLE, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL }).height(44).width('100%').fontColor(this.appText()).backgroundColor(this.appControl()).enabled(!this.backgroundBusy).onClick(() => this.pickBackgroundPhoto())
            Text('按桌面画布比例拖动、双指缩放后确认；原照片不修改。').fontSize(12).fontColor(this.appMuted()).width('100%')
          }
          }.width('100%').transition(settingsContentSwap())
          },(mode:string)=>mode)}.width('100%')
        }.width('100%').padding(12).borderRadius(20).backgroundColor(this.appSurface()).border({ width: 1, color: AppDesign.border(this.appDark) })
        Column({ space: 12 }) {
          Text('柔色预设').fontSize(16).fontColor(this.appText()).width('100%')
          Flex({ wrap: FlexWrap.Wrap }) {
            ForEach(['雾沙','庭院','海盐'], (name: string, index: number) => {
              Button(name, { type: ButtonType.Capsule, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL }).height(44).fontColor(this.appText()).backgroundColor(this.appControl()).margin({ right: 8 }).enabled(!this.backgroundBusy).onClick(() => this.setBackgroundPreset(index))
            }, (name: string) => name)
          }.width('100%')
        }.width('100%').padding(12).borderRadius(20).backgroundColor(this.appSurface()).border({ width: 1, color: AppDesign.border(this.appDark) })
      }.width('100%').constraintSize({ maxWidth: 640 }).padding({ top: 16, left: 16, right: 16, bottom: 16 })
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
  private shareCanvasHeight: number = 344;
  @Builder
  shareScene() {
    Column() {
      Stack({ alignContent: Alignment.TopStart }) {
        if (!this.shareSingle) { CanvasBackdrop({ sceneBackground: this.shareBackground,showFrame:false }).width('100%').height('100%') }
        ForEach(this.shareCards, (card: FridgeCard) => {
          CardFace({ card: card, scaleFactor: 1, tick: this.shareTick, widget: true })
            .width(card.w).height(card.h)
            .position({ x: this.shareSingle ? this.shareX : card.x, y: this.shareSingle ? this.shareY : card.y * this.shareCanvasHeight / BOARD_H })
            .rotate({ angle: card.rot, centerX: 0, centerY: '100%' }).zIndex(card.z)
        }, (card: FridgeCard) => card.id)
        if(!this.shareSingle&&this.shareBackground.frameStyle!=='none'){CanvasFrame({material:this.shareBackground.frameMaterial,style:this.shareBackground.frameStyle,square:true}).width('100%').height('100%').zIndex(100000)}
      }.width(this.shareWidth).height(this.shareCanvasHeight).backgroundColor(this.shareOpaque ? Color.White : Color.Transparent).clip(true)
      if (!this.shareSingle) {
        Row({space:2}) {
          Image($r('app.media.foreground')).width(36).height(36).objectFit(ImageFit.Contain).accessibilityText('冰箱贴 logo')
          Stack() {
            Image($rawfile('share/signature.png')).width(138).height(138 / 3).objectFit(ImageFit.Contain)
              .accessibilityText('created by 冰箱贴')
          }.width(138).height(38)
        }.width('100%').height(38).justifyContent(FlexAlign.Center).backgroundColor('#F7F5EF')
      }
    }.width(this.shareWidth).height(this.shareHeight)
  }
  private templateError(prefix:string,error:Error):void {
    if(/cancel/i.test(error.message??''))return;
    console.warn('Template operation failed: '+error.name+' '+error.message);
    this.getUIContext().getPromptAction().showToast({message:prefix+'：'+(error.message??'请重试'),duration:3500});
  }
  private shareCanvasFromPicker(id:string):void {
    this.canvasPickerOpen=false;
    // Native popup dismissal owns focus until its exit finishes; a simultaneous dialog is cancelled.
    setTimeout(()=>{if(this.alive&&!this.editing&&!this.canvasChanging)this.shareMenu(false,id);},220);
  }
  private async shareMenu(single: boolean, canvasId: string = ''): Promise<void> {
    if(this.sharing || this.context === null)return;
    const id=single?this.selectedId:'';
    this.sharing=true;
    try { const source=await this.store.canvasSnapshot(canvasId||this.store.state.canvasId);
      if(single && !source.cards.some((card:FridgeCard)=>card.id===id))return;
      const choice=await this.navChoice(single?'卡片作品':'画布作品',[single?'分享可编辑卡片':'分享可编辑画布',single?'分享卡片图片':'分享到社媒 · 画布展示图'],single?'shareCard':'shareCanvas');
      if(choice<0)return;
      if(choice===1){await this.shareArtwork(single,source,id);return;}
      const path=await taskpool.execute(new taskpool.Task(exportTemplate,JSON.stringify(source),id,this.context.filesDir,this.context.cacheDir)) as string;
      await shareTemplateFile(this.context as common.UIAbilityContext,path,single?'shareCard':'shareCanvas');
    }catch(e){this.templateError('分享未完成',e as Error);}finally{this.sharing=false;}
  }
  private incomingTemplateChanged(): void {
    if (!this.ready || !this.alive || this.appBackgrounded || this.incomingReview || this.templateReviewOpen) return;
    if (this.incomingError) {
      this.getUIContext().getPromptAction().showToast({message:this.incomingError});
      AppStorage.setOrCreate('incomingTemplateError','');
    }
    if (!this.incomingUri) return;
    if (this.editing || this.viewing) {
      if (this.incomingDeferred !== this.incomingUri) {
        this.incomingDeferred = this.incomingUri;
        this.getUIContext().getPromptAction().showToast({message:'已收到作品，返回画布后可导入'});
      }
      return;
    }
    if (this.busy || this.sharing || this.arriving || this.canvasChanging) {
      if(this.incomingTimer<0)this.incomingTimer=setTimeout(()=>{this.incomingTimer=-1;this.incomingTemplateChanged();},250); return;
    }
    const uri = this.incomingUri;
    this.incomingReview = true;
    AppStorage.setOrCreate('incomingTemplateUri','');
    this.reviewTemplate(uri).finally(()=>{this.incomingReview=false;this.incomingTemplateChanged();});
  }
  private async pickTemplate():Promise<void>{
    if(this.context===null)return;const options=new picker.DocumentSelectOptions();options.maxSelectNumber=1;options.fileSuffixFilters=['桌面作品|.fridge'];
    try{const uris=await new picker.DocumentViewPicker(this.context).select(options);if(uris.length>0)await this.reviewTemplate(uris[0]);}catch(e){this.templateError('导入未完成',e as Error);}
  }
  private async reviewTemplate(uri:string):Promise<void>{
    if(this.templateReviewOpen)return;
    try{const summary=JSON.parse(await taskpool.execute(new taskpool.Task(inspectTemplate,uri)) as string) as TemplateSummary;
      assertCanvasCapacity(summary.kind==='canvas'?0:this.store.state.cards.length,summary.count);
      if(!this.alive){if(this.context)removeStagedTemplate(uri,this.context.cacheDir);return;}
      this.templateReviewOpen=true;
      const finish=():void=>{if(this.context)removeStagedTemplate(uri,this.context.cacheDir);this.templateReviewOpen=false;this.incomingTemplateChanged();};
      this.getUIContext().showAlertDialog({cancel:finish,title:summary.kind==='card'?'导入卡片':'导入画布',message:summary.count+' 张卡片，'+summary.images+' 个图片资源。只导入设计，能力使用你的本机数据。'+(summary.kind==='canvas'?'保存为独立画布，保留现有作品。':'添加到当前画布。'),primaryButton:{value:'取消',action:finish},secondaryButton:{value:summary.kind==='canvas'?'保存新画布':'添加到画布',action:()=>{this.importTemplate(uri,summary.kind).finally(finish);}}});
    }catch(e){if(this.context)removeStagedTemplate(uri,this.context.cacheDir);this.templateReviewOpen=false;this.templateError('无法导入',e as Error);}
  }
  private async importTemplate(uri:string,kind:string):Promise<void>{
    if(this.context===null || this.busy || this.sharing || this.canvasChanging)return;
    try{this.busy=true;const available=kind==='canvas'?CANVAS_CARD_LIMIT:Math.max(0,CANVAS_CARD_LIMIT-this.store.state.cards.length);
      const state=normalizeState(JSON.parse(await taskpool.execute(new taskpool.Task(materializeTemplateUri,uri,this.context.filesDir,available)) as string) as FridgeState);
      const cards=importedCards(state,()=>this.store.newId());
      if(cards.some((c:FridgeCard)=>c.capability?.k==='timetable')) {
        const saved=await this.store.savedTimetable();
        if(saved)for(const card of cards)if(card.capability?.k==='timetable')card.capability=useSavedTimetable(card.capability,saved);
      }
      if(kind==='canvas') {
        await this.store.save(false); this.backgroundGeneration++; fitImportedCanvas(cards,state.canvasAspect,this.canvasAspect);remapSceneSchedules(state,cards,()=>this.store.newId(),this.canvasAspect); state.cards=cards; state.canvasAspect=this.canvasAspect;
        const id=this.store.createCanvas('导入的画布',state); this.busy=false; await this.chooseCanvas(id); return;
      }
      if(kind==='card'&&cards.length===1){cards[0].x=Math.max(0,(BOARD_W-cards[0].w)/2);cards[0].y=Math.max(0,(BOARD_H-cards[0].h)/2);}
      cards.forEach((c:FridgeCard)=>this.clamp(c));this.store.addCards(cards.slice().sort((a:FridgeCard,b:FridgeCard)=>a.z-b.z));this.render();this.persist(true);this.scheduleBackground();this.refreshCapabilities();
      if(cards.length>0)this.select(cards[0].id);
    }catch(e){this.templateError('导入未完成',e as Error);}finally{this.busy=false;}
  }
  private async shareArtwork(single: boolean, source: FridgeState, cardId: string): Promise<void> {
    if (this.context === null || this.heroActive || this.arriving) return;
    try {
      const formatIndex = single ? await this.navChoice('分享卡片图片',['透明 PNG','实色底 JPG'],'shareCard') : 0;
      if(formatIndex<0)return;
      this.sharing = true; this.shareSingle = single; this.shareOpaque = !single || formatIndex === 1; this.shareTick = Date.now(); this.shareBackground = normalizeBackground(JSON.parse(JSON.stringify(source.background)) as CanvasBackground);
      const card = source.cards.find((item:FridgeCard)=>item.id===cardId)??null; if (single && card === null) return;
      const artwork=single?[card!]:source.cards;
      // Export may load a detached persisted canvas, which intentionally has no
      // host-derived paths. Prepare the same relief off-thread before snapshot.
      const relief=JSON.parse(await taskpool.execute(new taskpool.Task(prepareSceneRelief,JSON.stringify(artwork))) as string) as Record<string,string>;
      this.shareCards=artwork.map((item:FridgeCard)=>{const copy=cardViewSnapshot(item);copy.reliefSrc=relief[item.id]??item.reliefSrc;return cardRenderSnapshot(copy);}).sort((a:FridgeCard,b:FridgeCard)=>a.z-b.z);
      if (single) {
        const a = card!.rot * Math.PI / 180, c = Math.cos(a), s = Math.sin(a), w = card!.w, h = card!.h;
        const xs = [0,h*s,w*c+h*s,w*c], ys = [h,h-h*c,h+w*s-h*c,h+w*s];
        this.shareX = 24-Math.min(...xs); this.shareY = 24-Math.min(...ys);
        this.shareWidth = Math.max(...xs)-Math.min(...xs)+48; this.shareHeight = Math.max(...ys)-Math.min(...ys)+48;
      } else { this.shareWidth = BOARD_W; this.shareHeight = BOARD_W/source.canvasAspect; }
      this.shareCanvasHeight = this.shareHeight;
      if (!single) this.shareHeight += 38;
      const scale = Math.min(3, 1280/this.getUIContext().vp2px(Math.max(this.shareWidth,this.shareHeight)));
      const pixel = await this.getUIContext().getComponentSnapshot().createFromBuilder(() => { this.shareScene(); }, 350, true, { scale: scale, waitUntilRenderFinished: true });
      try { await sharePixelMap(this.context as common.UIAbilityContext, pixel, single && this.shareOpaque, single ? 'shareCard' : 'shareCanvas'); }
      finally { await pixel.release(); }
    } catch (e) {
      // Action-menu cancellation has no message; actual export errors are actionable.

      this.templateError('图片分享未完成',e as Error);
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
          if(this.preview.capability!==null && ['agenda'].includes(this.preview.capability!.k)) {
            CapabilityDetails({cap:this.preview.capability!,appDark:this.appDark,tick:this.tick,onUpdate:(next:CapBlock)=>this.updateExtraCapability(this.preview.id,next)})
          } else if(this.preview.capability?.k==='timetable') {
            WeekTimetable({cap:this.preview.capability!,appDark:this.appDark,editable:false,heightLimit:Math.max(200,this.screenHeight-220)})
          } else {
            CardFace({card:this.preview,scaleFactor:this.editorScale(),tick:capabilityRenderTick(this.preview.capability,this.tick)})
              .rotate({angle:this.preview.rot,centerX:0,centerY:'100%'}).width(this.preview.w*this.editorScale()).height(this.preview.h*this.editorScale()).margin({top:24,bottom:24})
          }
          if (this.preview.capability?.k === 'calendar') {
            Row({ space: 12 }) {
              Button('上月', { type: ButtonType.Capsule, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL }).height(AppDesign.controlHeight).fontSize(14).backgroundColor(this.appControl()).fontColor(this.appText()).onClick(() => this.calendarAction('previousMonth'))
              Button('本月', { type: ButtonType.Capsule, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL }).height(AppDesign.controlHeight).fontSize(14).backgroundColor(this.appControl()).fontColor(this.appText()).onClick(() => this.calendarAction('currentMonth'))
              Button('下月', { type: ButtonType.Capsule, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL }).height(AppDesign.controlHeight).fontSize(14).backgroundColor(this.appControl()).fontColor(this.appText()).onClick(() => this.calendarAction('nextMonth'))
            }
          }

        }.width('100%').padding({ bottom: 24 })
      }.width('100%').height('100%').align(Alignment.Top).padding({ top: 76, left: 24, right: 24, bottom: this.safeBottom + 8 })
      }.titleMode(HdsNavigationTitleMode.MINI)
        .titleBar({
          content: {
            backIcon: { label: '关闭', type: TextStyleMode.NORMAL, action: () => { this.viewing = false; this.selectedId = ''; this.incomingTemplateChanged(); } },
            menu: { maxCount: 1, value: [
              { content: { label: '编辑卡片', type: TextStyleMode.NORMAL, action: () => { const id = this.selectedId; this.viewing = false; this.openEditor(id); } } }
            ] }
          },
          style: {
            blurStrategy: BlurStrategy.ADAPTIVE, thermoCtrl: true,
            scrollEffectOpts: { enableScrollEffect: true, scrollEffectType: ScrollEffectType.IMMERSIVE_GRADIENT_BLUR },
            scrollEffectStyle: { backgroundStyle: { backgroundColor: Color.Transparent, maskExtraHeight: 0, blurRadius: 16 },
              contentStyle: { menuStyle: {backgroundColor:this.appSurface(),textColor:this.appText(),iconColor:this.appText()}, backIconStyle: {backgroundColor:this.appSurface(),textColor:this.appText(),iconColor:this.appText()} } },
            systemMaterialEffect: { materialType: hdsMaterial.MaterialType.IMMERSIVE, materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE },
            originalStyle: { backgroundStyle: { backgroundColor: Color.Transparent, maskExtraHeight: 0, blurRadius: 16 },
              contentStyle: { menuStyle: {backgroundColor:this.appSurface(),textColor:this.appText(),iconColor:this.appText()}, backIconStyle: {backgroundColor:this.appSurface(),textColor:this.appText(),iconColor:this.appText()} } }
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
              this.editorStage()
              this.editorSectionSheet()
            }.width('100%').layoutWeight(1)
          } else {this.editorStage()}
        }.width('100%').height('100%').padding({ top: EDITOR_NAV_INSET }).backgroundColor(Color.Transparent)
      }.titleMode(HdsNavigationTitleMode.MINI)
        .titleBar({
          content: {
            backIcon: { icon:new SymbolGlyphModifier($r('sys.symbol.arrow_left')).fontSize(20).fontColor([this.appText()]),label:'返回画布',type:IconStyleMode.NORMAL,isEnabled:!this.heroActive,action:()=>this.closeEditor() },
            menu: { maxCount: 4, value: [
              { content: { icon: new SymbolGlyphModifier($r('sys.symbol.rectangle_and_arrowshape_turn_up_right')).fontColor([this.appText()]), label: '分享卡片', type: IconStyleMode.NORMAL, componentId: 'shareCard', isEnabled: !this.sharing && !this.heroActive, action: () => this.shareMenu(true) } },
              { content: { icon:new SymbolGlyphModifier($r('sys.symbol.arrow_counterclockwise')).fontColor([this.appText()]),label:'撤销',type:IconStyleMode.NORMAL,isEnabled:this.undoAvailable&&!this.heroActive,action:()=>this.restoreHistory(false) } },
              { content: { icon:new SymbolGlyphModifier($r('sys.symbol.arrow_clockwise')).fontColor([this.appText()]),label:'重做',type:IconStyleMode.NORMAL,isEnabled:this.redoAvailable&&!this.heroActive,action:()=>this.restoreHistory(true) } },
              { content: { label: '完成', type: TextStyleMode.NORMAL, isEnabled: !this.heroActive, action: () => this.closeEditor() } }
            ] }
          },
          style: {
            blurStrategy: BlurStrategy.ADAPTIVE, thermoCtrl: true,
            scrollEffectOpts: { enableScrollEffect: true, scrollEffectType: ScrollEffectType.IMMERSIVE_GRADIENT_BLUR },
            scrollEffectStyle: { backgroundStyle: { backgroundColor: Color.Transparent, maskExtraHeight: 0, blurRadius: 16 },
              contentStyle: { menuStyle: {backgroundColor:this.appSurface(),textColor:this.appText(),iconColor:this.appText()}, backIconStyle: {backgroundColor:this.appSurface(),textColor:this.appText(),iconColor:this.appText()} } },
            systemMaterialEffect: { materialType: hdsMaterial.MaterialType.IMMERSIVE, materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE },
            originalStyle: { backgroundStyle: { backgroundColor: Color.Transparent, maskExtraHeight: 0, blurRadius: 16 },
              contentStyle: { menuStyle: {backgroundColor:this.appSurface(),textColor:this.appText(),iconColor:this.appText()}, backIconStyle: {backgroundColor:this.appSurface(),textColor:this.appText(),iconColor:this.appText()} } }
          }
        })
        .bindSheet(this.capabilityPickerOpen||this.readingComparisonOpen,this.editorTaskSheet,{height:this.taskSheetHeight(true),detents:[this.taskSheetHeight(true)],preferType:this.screenWidth>=600?SheetType.CENTER:SheetType.BOTTOM,width:Math.min(560,this.screenWidth-24),showClose:true,dragBar:true,backgroundColor:this.appBackground(),blurStyle:BlurStyle.COMPONENT_THIN,onDisappear:()=>{this.capabilityPickerOpen=false;this.readingComparisonOpen=false;}})
        .id('editorMotionChrome').bindToScrollable([this.scroller]).hideBackButton(false).hideToolBar(true).mode(NavigationMode.Stack).width('100%').height('100%').backgroundColor(Color.Transparent)
    }.width('100%').height('100%').padding({ top: this.safeTop + EDITOR_SAFE_GAP }).opacity(this.editorOpacity)
      .hitTestBehavior(!this.editing || this.heroActive ? HitTestMode.None : HitTestMode.Default)
      .visibility(this.editing && this.chromeSnapshot === undefined ? Visibility.Visible : Visibility.Hidden)
      .accessibilityLevel(this.editing ? 'yes' : 'no-hide-descendants')
  }
  private finishNavMenu(index:number):void {
    const resolve=this.navMenuResolve;this.navMenuResolve=null;this.navMenuOpen=false;if(resolve)resolve(index);
  }
  private navChoice(title:string,labels:string[],anchor:string):Promise<number> {
    if(this.navMenuResolve)return Promise.resolve(-1);
    this.navMenuResult=-1;
    this.navMenuX=this.screenWidth-72;this.navMenuY=this.safeTop+64;
    try {
      const rect=this.getUIContext().getComponentUtils().getRectangleById(anchor);
      if(rect.size.width>0){this.navMenuX=Math.min(this.screenWidth-16,this.getUIContext().px2vp(rect.windowOffset.x+rect.size.width));this.navMenuY=this.getUIContext().px2vp(rect.windowOffset.y+rect.size.height)+4;}
    }catch(_){}
    return new Promise<number>((resolve)=>{
      this.navMenuResolve=resolve;this.navMenuItems=labels.map((value:string,index:number):MenuElement=>({value:value,action:()=>{this.navMenuResult=index;this.navMenuOpen=false;}}));this.navMenuOpen=true;
    });
  }
  private async showAddMenu():Promise<void> {
    const id=this.selectedId,index=await this.navChoice('添加到卡片',this.preview.capability===null?['文字','本地图片 / GIF','形状','能力']:['文字','本地图片 / GIF','形状'],'editorLayerAdd');
    if(index>=0&&this.alive&&this.editing&&!this.heroActive&&id===this.selectedId){if(index===3)this.chooseCapability();else this.addElement(['text','image','shape'][index]);}
  }
  @Builder
  editorStage() {
    // The native sheet covers the lower stage. Do not pre-clip the layer strip
    // at its straight top edge: its rounded corners reveal the content behind it.
    Row({space:12}) {
      this.canvasEditor()
      this.editorLayers()
    }.width(this.editorWorkspace().stageW).height(this.editorWorkspace().body).alignItems(VerticalAlign.Top).clip(this.editorLandscape())
  }
  @Builder
  editorLayers() {
    Scroll() {Column({space:8}) {this.layerEntries()}.width('100%').padding({top:8,bottom:8,right:4})}
      .id('editorLayerStrip').width(this.editorWorkspace().layersW).height(this.previewPaneHeight()+(this.editorLandscape()?0:64)).scrollable(ScrollDirection.Vertical).align(Alignment.Top).scrollBar(BarState.Off)
  }
  private capabilityHasEditableData():boolean {return ['countdown','anniversary','worldclock','agenda','timetable','album'].includes(this.preview.capability?.k??'');}
  private editorTools():string[] {
    return this.preview.capability?.k==='album'?['样式','封面与资料']:this.layerId==='capability'?(this.capabilityHasEditableData()?['样式','位置','颜色','数据']:['样式','位置','颜色']):this.layerId.length?(this.elementPreview.kind==='image'?['图片','位置']:['外观','位置','颜色']):['形状','底色'];
  }
  private openEditorSection(index:number):void {
    if(this.heroActive||this.editorSection===index)return;this.editorSection=index;this.editorSheetTab=0;this.scroller.scrollTo({xOffset:0,yOffset:0});
  }
  private dismissEditorSheet(action:DismissSheetAction):void {
    if(action.reason===DismissReason.PRESS_BACK){this.editorSheetOpen=false;action.dismiss();if(this.heroActive)this.editorBackPending=true;else this.closeEditor();}else this.expandEditor(false);
  }
  private editorSheetHeightChanged(height:number):void {
    if(!this.editing||this.heroActive||this.editorLandscape())return;
    // The native sheet owns gesture, velocity and settling. Follow its actual height,
    // including spring-back, rather than starting another animation on every frame.
    const next=Math.max(0,this.getUIContext().px2vp(height)-this.safeBottom);
    if(Math.abs(next-this.editorSheetHeightVp)>.25)this.editorSheetHeightVp=next;
  }
  private expandEditor(value:boolean):void {if(this.heroActive)return;this.editorExpanded=value;}
  @Builder
  editorInspector() {
    // Native SegmentButton is inexpensive to select, but changing its button count forces a synchronous layout flush.
    Stack() {ForEach([this.editorTools().join('|')],(toolsKey:string)=>{
      SettingsSegmented({labels:this.editorTools(),selectedIndex:this.editorSection,appDark:this.appDark,onSelect:(index:number)=>this.openEditorSection(index)})
        .transition(settingsReveal())
    },(toolsKey:string)=>toolsKey)}.width('100%').height(48)
  }
  private editorSheetHeight():number {return Math.min(520,Math.max(300,this.screenHeight*.52),this.screenHeight-this.safeTop-80);}
  private sectionTabs():string[] {return this.preview.capability?.k==='album'?['封面库','资料','轮换']:this.preview.capability?.k==='timetable'?['显示','课表','校历']:[];}
  @Builder
  editorSectionSheet() {
    Column({space:10}) {
      this.editorInspector()
      if(this.sectionTabs().length>0 && (this.preview.capability?.k==='album'&&this.editorSection===1 || this.layerId==='capability'&&this.editorSection===3)) {SettingsSegmented({labels:this.sectionTabs(),selectedIndex:this.editorSheetTab,appDark:this.appDark,onSelect:(i:number)=>{this.editorSheetTab=i;this.scroller.scrollTo({xOffset:0,yOffset:0});}})}
      Scroll(this.scroller) {
        Stack({alignContent:Alignment.TopStart}) {ForEach([this.layerId+':'+this.editorSection+':'+this.editorSheetTab],(sectionKey:string)=>{Column({space:16}) {
          if(this.preview.capability?.k==='album') {
            if(this.editorSection===0) {this.albumStyleChoices()}
            else {Column() {this.capabilityDataPanel()}.width('100%').padding(16).backgroundColor(this.appSurface()).borderRadius(20)}
          } else if(this.layerId==='capability'&&this.preview.capability!==null) {
            if(this.editorSection===0) {this.capabilityStyleChoices()}
            else if(this.editorSection===1) {this.layerLayoutContents()}
            else if(this.editorSection===2) {Column() {this.colorRow('内容颜色','ink')}.width('100%').padding(16).backgroundColor(this.appSurface()).borderRadius(20)}
            else {Column() {this.capabilityDataPanel()}.width('100%').padding(16).backgroundColor(this.appSurface()).borderRadius(20)}
          } else if(this.layerId.length>0) {
            if(this.editorSection===0) {this.elementFields()}
            else if(this.editorSection===1) {this.layerLayoutContents()}
            else if(this.elementPreview.kind==='image') {Text('照片保留原始颜色').fontSize(14).fontColor(this.appMuted())}
            else {this.colorRow('元素颜色','element')}
          } else {
            if(this.editorSection===0) {this.appearancePanel()}
            else {this.baseColorPanel()}
          }
        }.width('100%').padding({bottom:24}).transition(settingsContentSwap())},(sectionKey:string)=>sectionKey)}.width('100%')
      }.width('100%').layoutWeight(1).align(Alignment.Top).scrollBar(BarState.Off)
        // Share the native sheet gesture: expand first upwards; scroll to the top first downwards.
        .nestedScroll({scrollForward:this.editorLandscape()?NestedScrollMode.SELF_ONLY:NestedScrollMode.PARENT_FIRST,scrollBackward:this.editorLandscape()?NestedScrollMode.SELF_ONLY:NestedScrollMode.SELF_FIRST})
    }.width(this.editorLandscape()?this.editorWorkspace().panelW:this.screenWidth)
      .height(this.editorLandscape()?this.editorWorkspace().body:'100%')
      // The native sheet paints/clips its entire surface, including grabber and bottom safe area.
      // A second rounded background here would create a rectangular seam below the grabber.
      .padding({left:12,right:12,top:8,bottom:4}).backgroundColor(this.editorLandscape()?this.appSurface():Color.Transparent).clip(true)
  }
  @Builder
  albumStyleChoices() {
    EditorVisualChoices({card:this.preview,mode:'album',selected:this.preview.capability?.albumPresentation??'cover',appDark:this.appDark,onChoose:(key:string)=>{const cap=this.current()?.capability;if(cap){const next=JSON.parse(JSON.stringify(cap)) as CapBlock;next.albumPresentation=key;this.updateExtraCapability(this.preview.id,next);}}})
    Text('封面固定为正方形；信息款显示专辑名与歌手，超出行数自动省略。').fontSize(12).fontColor(this.appMuted()).width('100%')
  }
  @Builder
  capabilityStyleChoices() {
    EditorVisualChoices({card:this.preview,selected:this.preview.capability?.readingBlend??'',appDark:this.appDark,onChoose:(key:string)=>this.chooseReadingComposition(key)})
    Text('表面材质').fontSize(14).fontWeight(FontWeight.Medium).fontColor(this.appText()).width('100%')
    EditorVisualChoices({card:this.preview,mode:'material',selected:this.preview.capability?.readingMaterial??'paper',appDark:this.appDark,onChoose:(key:string)=>{const cap=this.current()?.capability;if(cap){cap.readingMaterial=key;this.change();}}})
    if(this.preview.capability?.readingBlend==='sticker') {
      Text('贴合方式').fontSize(14).fontWeight(FontWeight.Medium).fontColor(this.appText()).width('100%')
      SettingsSegmented({labels:['左侧','右侧'],selectedIndex:this.preview.capability.readingEdge==='right'?1:0,appDark:this.appDark,onSelect:(i:number)=>this.setCapabilityAttachment(i===0?'left':'right',this.preview.capability?.readingOutside===true)})
      SettingsSegmented({labels:['内贴合','外贴合'],selectedIndex:this.preview.capability.readingOutside?1:0,appDark:this.appDark,onSelect:(i:number)=>this.setCapabilityAttachment(this.preview.capability?.readingEdge||'left',i===1)})
    }
    if(this.preview.capability?.readingBlend==='tag') {HookPlacement({hookLocation:this.preview.capability.readingHook??.2,appDark:this.appDark,onChoose:(p:number)=>{const cap=this.current()?.capability;if(cap){cap.readingHook=p;this.change();}}})}
    Text('大小与位置在预览中直接调整；内容会随时间变化，衬底自动适应。').fontSize(12).fontColor(this.appMuted()).width('100%')
    Column() {this.capabilityPanel()}.width('100%').padding(16).backgroundColor(this.appSurface()).borderRadius(20)
  }
  private setCapabilityAttachment(side:string,outer:boolean):void {
    const c=this.current();if(!c?.capability)return;c.capability.readingEdge=side;c.capability.readingOutside=outer;
    const a=edgeAttachment(c,c.capBox,side,outer);c.capBox.x=a.box.x;c.capBox.y=a.box.y;c.capBox.rot=0;this.change();
  }
  @Builder
  paperPresets() {
    Scroll() {Row({space:8}) {
      ForEach(THEMES,(theme:string)=>{
        Button({type:ButtonType.Circle,buttonStyle:ButtonStyleMode.NORMAL}) {}.width(44).height(44).backgroundColor(materialColors(theme,'','')[0]).border({width:this.preview.material===theme&&!this.preview.paper?2:.5,color:this.preview.material===theme&&!this.preview.paper?this.appText():AppDesign.border(this.appDark)})
          .accessibilityText(['白色','米色','牛皮纸','绿色','蓝色','粉色','黑色'][THEMES.indexOf(theme)]).onClick(()=>{const card=this.current();if(card){card.material=theme;card.paper='';this.change();}})
      },(theme:string)=>theme)
    }}.layoutWeight(1).height(48).scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off).align(Alignment.Start)
  }
  private editorCanvasHeight(): number { return this.previewViewport().height; }
  private selectionGeometry(): SelectionHandles {
    return selectionHandles(this.touchBox(this.layerId), this.preview.w * this.editorScale(), this.preview.h * this.editorScale(),
      this.editingAngle(), this.editorViewportWidth(), this.editorCanvasHeight(), this.previewViewport().left, this.previewViewport().top);
  }
  @Builder
  canvasEditor() {
    Stack({ alignContent: Alignment.TopStart }) {
      Column().width('100%').height('100%').backgroundColor(Color.Transparent).onClick(() => this.chooseLayer(''))
      Stack({ alignContent: Alignment.TopStart }) {
        ForEach(this.preview.elements.filter((el: CanvasElement) => this.preview.capability?.k!=='album' && el.behindCapability && this.settingsTab === 0), (el: CanvasElement) => { this.layerTouch(el.id) }, (el: CanvasElement) => el.id)
        if (this.settingsTab === 1 && this.preview.capability !== null && this.preview.capability.k!=='album') { this.layerTouch('capability') }
        ForEach(this.preview.elements.filter((el: CanvasElement) => this.preview.capability?.k!=='album' && !el.behindCapability && this.settingsTab === 1), (el: CanvasElement) => { this.layerTouch(el.id) }, (el: CanvasElement) => el.id)
      }.width(this.preview.w * this.editorScale()).height(this.preview.h * this.editorScale())
        .rotate({ angle: this.editingAngle(), centerX: 0, centerY: '100%' })
        .position({ x: this.previewViewport().left, y: this.previewViewport().top })

      if (this.preview.capability?.k!=='album' && this.layerId.length > 0 && (this.layerId!=='capability'||this.preview.capability!==null)  ) {
        EditorLayerHandles({attachmentCard:this.layerId==='capability'?this.preview:null,motion:this.layerMotion,targetId:this.layerId,box:this.boxPreview,factor:this.layerId==='capability'?1:subjectSurfaceFactor(this.preview),
          contentW:this.preview.w*this.editorScale(),contentH:this.preview.h*this.editorScale(),angle:this.editingAngle(),viewportWidth:this.editorViewportWidth(),viewportHeight:this.editorCanvasHeight(),
          left:this.previewViewport().left,top:this.previewViewport().top,appDark:this.appDark,onStart:(e)=>this.startTransform(this.layerId,e),onResize:(e)=>this.resizeElement(e),onRotate:(e)=>this.rotateElement(e),onEnd:()=>this.flushPreview(),onCancel:()=>this.cancelTransform()})
      }

    }.width(this.editorViewportWidth()).height(this.editorCanvasHeight())

  }
  private elementTouchBox(element: CanvasElement): ElementBox {
    const f = subjectSurfaceFactor(this.preview), inset = (1 - f) / 2;
    const box = new ElementBox(); box.x = inset + element.x * f; box.y = inset + element.y * f;
    box.w = element.w * f; box.h = element.h * f; box.rot = element.rot; return box;
  }
  private finishLayerDrag(cancelled: boolean = false): void {
    if (cancelled) { const box = this.currentBox(); if (box !== null) { box.x = this.layerStartX; box.y = this.layerStartY; } if(this.layerId==='capability'&&this.current()!==null)this.current()!.capFree=this.layerFreeStart; }
    if(!cancelled&&this.layerId==='capability'&&this.current()?.capability)this.current()!.capability!.readingEdge=this.layerMotion.edge;
    this.syncFields(); this.change(); this.layerMotion.clear(); this.layerDrag = ''; this.layerDX = 0; this.layerDY = 0; this.gestureGroup = '';
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
    this.layerFreeStart=card?.capFree??false;
    if (id === 'capability' && card !== null) {card.capBox = JSON.parse(JSON.stringify(capabilityPlacement(card))) as ElementBox;card.capFree=true;}
    const box = this.currentBox(); if (box === null) return;
    this.resizeStart = JSON.parse(JSON.stringify(box)) as ElementBox;
    this.rotateStart = box.rot;
    this.layerDrag=id;this.layerMotion.edge=id==='capability'?(card?.capability?.readingEdge??''):'';this.layerMotion.update(id,box);
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
    const min = this.layerId==='capability'?cardCapabilityMinimum(this.preview,true,Math.max(0,nextW)*this.preview.w):new ElementBox();
    const minW = this.layerId === 'capability' ? min.w / this.preview.w : .04;
    const minH = this.layerId === 'capability' ? min.h / this.preview.h : .04;
    if (this.currentElement()?.kind === 'image') {
      const minFactor = Math.max(.04 / this.resizeStart.w, .04 / this.resizeStart.h);
      const factor = Math.max(minFactor, Math.min(nextW / this.resizeStart.w, (1 - this.resizeStart.x) / this.resizeStart.w, (1 - this.resizeStart.y) / this.resizeStart.h));
      box.w = this.resizeStart.w * factor; box.h = this.resizeStart.h * factor;
    } else if(this.layerId==='capability') {
      const limit=isReadingComposition(this.preview.capability?.readingBlend??'')?3:1;
      box.w=Math.min(limit,Math.max(minW,nextW));box.h=Math.min(limit,Math.max(minH,nextH));
    } else {
      box.w = Math.max(minW, Math.min(1 - box.x, nextW)); box.h = Math.max(minH, Math.min(1 - box.y, nextH));
    }
    // Keep the opposite corner still when resizing a rotated element.
    const local = this.resizeStart.rot * Math.PI / 180, c = Math.cos(local), sn = Math.sin(local);
    const dw = (this.resizeStart.w - box.w) * w, dh = (this.resizeStart.h - box.h) * h;
    const outside=this.layerId==='capability'&&isReadingComposition(this.preview.capability?.readingBlend??'');
    box.x = Math.max(outside?-2:0, Math.min(outside?2:1-box.w, this.resizeStart.x + (dw * (1 - c) + dh * sn) / (2 * w)));
    box.y = Math.max(outside?-2:0, Math.min(outside?2:1-box.h, this.resizeStart.y + (dh * (1 - c) - dw * sn) / (2 * h)));
    if(this.layerId==='capability'&&this.layerMotion.edge==='right')box.x=this.resizeStart.x+this.resizeStart.w-box.w;
    if(this.layerId==='capability'&&this.layerMotion.edge==='bottom')box.y=this.resizeStart.y+this.resizeStart.h-box.h;
    if(this.layerId==='capability'&&this.preview.capability?.readingBlend==='sticker'){const a=edgeAttachment(this.preview,box,this.preview.capability.readingEdge||'left',this.preview.capability.readingOutside===true);box.x=a.box.x;box.y=a.box.y;box.rot=0;}
    this.layerMotion.update(this.layerId,box);
  }
  private rotateElement(e: GestureEvent): void {
    if(this.layerId==='capability'&&this.preview.capability?.readingBlend==='sticker')return;
    const live = this.currentBox(); if (live === null) return;
    const offset = this.fingerOffset(e);
    let delta = Math.atan2(this.rotationVector.y + offset.y, this.rotationVector.x + offset.x) - Math.atan2(this.rotationVector.y, this.rotationVector.x);
    if (delta > Math.PI) delta -= 2 * Math.PI; if (delta < -Math.PI) delta += 2 * Math.PI;
    const value = this.rotateStart + delta * 180 / Math.PI;
    live.rot = Math.abs(value - Math.round(value / 15) * 15) < 3 ? Math.round(value / 15) * 15 : value;
    if(this.layerId==='capability'&&Math.abs(live.rot)>3)this.layerMotion.edge='';
    this.layerMotion.update(this.layerId,live);
  }
  private moveElement(e: GestureEvent): void {
    const live = this.currentBox(); if (live === null) return;
    const f = this.layerId === 'capability' ? 1 : subjectSurfaceFactor(this.preview);
    const width = this.preview.w * this.editorScale() * f, height = this.preview.h * this.editorScale() * f;
    const angle = this.editingAngle() * Math.PI / 180;
    const offset = this.fingerOffset(e);
    const dx = offset.x * Math.cos(angle) + offset.y * Math.sin(angle), dy = -offset.x * Math.sin(angle) + offset.y * Math.cos(angle);
    const previous=new ElementBox();previous.x=live.x;previous.y=live.y;previous.w=live.w;previous.h=live.h;
    const free=this.layerId==='capability'&&isReadingComposition(this.preview.capability?.readingBlend??'');
    live.x = Math.max(free?-2:0, Math.min(free?2:1-live.w, this.layerStartX + dx / width));
    live.y = Math.max(free?-2:0, Math.min(free?2:1-live.h, this.layerStartY + dy / height));
    const centerX = (1 - live.w) / 2, centerY = (1 - live.h) / 2;
    if (this.layerId !== 'capability' && Math.abs(live.x - centerX) * width < 5) live.x = centerX;
    if (this.layerId !== 'capability' && Math.abs(live.y - centerY) * height < 5) live.y = centerY;
    if(this.layerId==='capability'){
      if(this.preview.capability?.readingBlend==='sticker'){
        const attached=edgeAttachment(this.preview,live,this.preview.capability.readingEdge||'left',this.preview.capability.readingOutside===true);live.x=attached.box.x;live.y=attached.box.y;live.rot=0;this.layerMotion.edge=attached.side;
      }else{const fitted=constrainCapabilityDrag(this.preview,live,previous);live.x=fitted.x;live.y=fitted.y;}
    }
    this.layerMotion.update(this.layerId,live);
  }
  private cancelTransform(): void {
    const box = this.currentBox(); if (box !== null) { box.x = this.resizeStart.x; box.y = this.resizeStart.y; box.w = this.resizeStart.w; box.h = this.resizeStart.h; box.rot = this.resizeStart.rot; }
    if(this.layerId==='capability'&&this.current()!==null)this.current()!.capFree=this.layerFreeStart;
    this.layerMotion.edge=this.current()?.capability?.readingEdge??'';this.flushPreview();
  }
  private touchBox(id: string): ElementBox {
    if (id === 'capability') {const b=capabilityPlacement(this.preview),c=this.preview;return c.capability?.readingBlend==='sticker'?edgeAttachment(c,b,c.capability.readingEdge||'left',c.capability.readingOutside===true).box:b;}
    return this.elementTouchBox(this.preview.elements.find((el: CanvasElement) => el.id === id) ?? new CanvasElement());
  }
  @Builder
  layerTouch(id: string) {
    EditorLayerTarget({attachmentCard:id==='capability'?this.preview:null,motion:this.layerMotion,targetId:id,box:id==='capability'?capabilityPlacement(this.preview):this.preview.elements.find((el)=>el.id===id)??new ElementBox(),
      factor:id==='capability'?1:subjectSurfaceFactor(this.preview),selected:this.layerId===id,
      onSelect:()=>{this.layerId=id;this.syncFields();},onStart:(e)=>{
        this.layerId=id;this.beginFinger(e,this.editingAngle()+(this.currentBox()?.rot??0));this.layerDrag=id;const card=this.current();
        this.layerFreeStart=card?.capFree??false;
        if(id==='capability'&&card!==null){card.capBox=JSON.parse(JSON.stringify(capabilityPlacement(card))) as ElementBox;card.capFree=true;}
        const live=this.currentBox();this.layerStartX=live?.x??0;this.layerStartY=live?.y??0;if(live){this.layerMotion.edge=id==='capability'?(card?.capability?.readingEdge??''):'';this.layerMotion.update(id,live);}this.syncFields();
      },onUpdate:(e)=>this.moveElement(e),onEnd:(e)=>{this.moveElement(e);this.finishLayerDrag();},onCancel:()=>this.finishLayerDrag(true)})
  }

  private chooseLayer(id: string): void {
    if(this.layerId===id)return;
    this.scroller.scrollTo({ xOffset: 0, yOffset: 0 });
    // Each inserted inspector/content node owns its native TransitionEffect.
    // An outer animateTo forces native SegmentButton option changes to flush the whole page synchronously.
    this.layerId=id;this.settingsTab=id==='capability'||this.layerElement(id)?.behindCapability===false?1:0;this.showLayerOptions=false;this.showBackgroundOptions=false;this.syncFields();
    this.editorSection=Math.min(this.editorSection,this.editorTools().length-1);this.editorSheetTab=0;
  }
  private layerElement(id: string): CanvasElement | null { return this.preview.elements.find((el: CanvasElement) => el.id === id) ?? null; }
  private layerTitle(id:string):string {
    if(id==='capability')return typeLabel(this.preview.capability?.k??'');
    if(id.length===0)return '主体底板';
    return this.layerElement(id)?.kind==='image'?'图片':this.layerElement(id)?.kind==='shape'?'形状':'文字';
  }
  @Builder
  layerCapabilitySymbol() {
    if(this.preview.capability?.k==='battery'){SymbolGlyph($r('sys.symbol.bolt_fill')).fontSize(30).fontColor([this.appText()])}
    else if(['clock','worldclock','countdown'].includes(this.preview.capability?.k??'')){SymbolGlyph($r('sys.symbol.clock')).fontSize(30).fontColor([this.appText()])}
    else {SymbolGlyph($r('sys.symbol.calendar')).fontSize(30).fontColor([this.appText()])}
  }
  private layerBaseScale():number {return Math.min(48/this.preview.w,48/this.preview.h);}
  private layerBaseSource:FridgeCard|null=null;
  private layerBaseValue:FridgeCard=new FridgeCard();
  private layerBaseCard():FridgeCard {
    if(this.layerBaseSource===this.preview)return this.layerBaseValue;
    const card=cardStorageShell(this.preview);card.capability=null;card.capBox=new ElementBox();card.elements=[];
    this.layerBaseSource=this.preview;this.layerBaseValue=card;return card;
  }
  @Builder
  layerThumbnail(id:string) {
    Stack() {
      if(id.length===0) {
        Column() {CardFace({card:this.layerBaseCard(),scaleFactor:this.layerBaseScale(),tick:0,hideContent:true})}
          .width(this.preview.w*this.layerBaseScale()).height(this.preview.h*this.layerBaseScale())
      } else if(id==='capability' && this.preview.capability?.k==='album' && this.preview.capability.albumCover) {
        Image(this.preview.capability.albumCover).width(48).height(48).objectFit(ImageFit.Contain).borderRadius(4).draggable(false)
      } else if(this.layerElement(id)?.kind==='image') {
        Image(this.layerElement(id)?.src??'').width(48).height(48).objectFit(ImageFit.Contain).draggable(false)
      } else if(this.layerElement(id)?.kind==='shape') {
        Column().width(40).height(this.layerElement(id)?.primitive==='line'?3:40).borderRadius(this.layerElement(id)?.primitive==='circle'?12:4).backgroundColor(this.layerElement(id)?.color||this.appText())
      } else if(id==='capability' && this.preview.capability!==null) {this.layerCapabilitySymbol()}
      else if(id.length===0) {SymbolGlyph($r('sys.symbol.plus')).fontSize(18).fontColor([this.appText()])}
      else {Text(id==='capability'?typeLabel(this.preview.capability?.k??'').slice(0,2):'A').fontSize(id==='capability'?12:18).fontWeight(FontWeight.Medium).fontColor(this.appText())}
    }.width(72).height(48).alignContent(Alignment.Center).hitTestBehavior(HitTestMode.None)
  }
  @Builder
  layerEntry(id:string) {
    Stack({alignContent:Alignment.TopStart}) {
      Button({type:ButtonType.ROUNDED_RECTANGLE, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL}) {
        Column({space:6}) {
          this.layerThumbnail(id)
          Text(this.layerTitle(id)).fontSize(12).fontColor(this.appText()).maxLines(1).textOverflow({overflow:TextOverflow.Ellipsis})
        }.width('100%').padding({left:6,right:6})
      }.width('100%').height(88).backgroundColor(Color.Transparent)
        .accessibilityText('选择图层 '+this.layerTitle(id)).onClick(()=>this.chooseLayer(id))
      if(id.length>0 && this.layerId===id) {
        Button({type:ButtonType.Circle,buttonStyle:ButtonStyleMode.NORMAL,role:ButtonRole.ERROR}) {
          Stack(){SymbolGlyph($r('sys.symbol.xmark')).fontSize(13).fontColor(['#FFFFFF'])}.width(24).height(24).borderRadius(12).backgroundColor('#C43A35').hitTestBehavior(HitTestMode.None)
        }.width(44).height(44).padding(0).backgroundColor(Color.Transparent).accessibilityText('删除图层 '+this.layerTitle(id)).onClick(()=>{if(this.layerId===id)this.removeElement();})
      }
    }.width(this.editorWorkspace().layersW-4).height(88).borderRadius(18)
      .backgroundColor(this.appSurface()).border({width:this.layerId===id?2:0,color:this.appDark?'#E6D3A2':'#B29A64'})
  }
  @Builder
  layerEntries() {
    if(this.preview.capability?.k==='album') {this.layerEntry('capability')} else {
      this.layerEntry('')
      ForEach(this.preview.elements.slice().reverse(),(el:CanvasElement)=>{this.layerEntry(el.id)},(el:CanvasElement)=>el.id)
      if(this.preview.capability!==null) {this.layerEntry('capability')}
      Button({type:ButtonType.ROUNDED_RECTANGLE,buttonStyle:ButtonStyleMode.NORMAL}) {
        Column({space:8}) {SymbolGlyph($r('sys.symbol.plus')).fontSize(24).fontColor([this.appText()]);Text('添加图层').fontSize(12).fontColor(this.appText())}.hitTestBehavior(HitTestMode.None)
      }.id('editorLayerAdd').width(this.editorWorkspace().layersW-4).height(80).padding(8).backgroundColor(this.appSurface()).borderRadius(18).onClick(()=>this.showAddMenu())
    }
  }
  @Builder
  elementFields() {
    if (this.layerId.length > 0 && this.layerId !== 'capability') {
      Column({ space: 12 }) {
        Text('元素样式').fontSize(16).fontWeight(FontWeight.Medium).fontColor(this.appText()).width('100%')
        if (this.elementPreview.kind === 'text') {
          TextArea({ text: this.textValue, placeholder: '文字内容' }).height(72).fontSize(16).fontColor(this.appText()).placeholderColor(this.appMuted()).backgroundColor(this.appControl()).borderRadius(12).border({ width: .5, color: AppDesign.border(this.appDark) })
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
      }.width('100%').padding(16).backgroundColor(this.appSurface()).borderRadius(AppDesign.sectionRadius).clip(true)
    }
  }
  private appearanceSheetHeight():number {
    return Math.min(this.preview.cutout.length>0?500:340,this.screenHeight*.78);
  }
  @Builder
  appearanceSheet() {
    Column({space:12}) {
      Text('底板形状与边缘').fontSize(20).fontWeight(FontWeight.Medium).fontColor(this.appText()).width('100%').padding({right:40})
      Scroll(){this.appearancePanel()}.width('100%').layoutWeight(1).align(Alignment.Top).scrollBar(BarState.Off)
    }.width('100%').height('100%').padding(20)
  }
  @Builder
  layerLayoutSheet() {this.layerLayoutContents()}
  @Builder
  layerLayoutContents() {
    Column({space:12}) {
        if (this.layerId !== 'capability') {
          if (this.settingsTab === 0) {
            Button('铺满底板', { type: ButtonType.ROUNDED_RECTANGLE, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL }).width('100%').height(AppDesign.controlHeight).fontSize(13).backgroundColor(this.appControl()).fontColor(this.appText())
              .onClick(() => { const el = this.currentElement(); if (el !== null) { el.x = 0; el.y = 0; el.w = 1; el.h = 1; el.rot = 0; this.change(); } })
          }
        }
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
        if (this.layerId !== 'capability') {
          Row({ space: 8 }) {
            Button('复制元素', { type: ButtonType.Capsule, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL }).layoutWeight(1).padding({left:6,right:6}).height(AppDesign.controlHeight).fontSize(12).backgroundColor(this.appControl()).fontColor(this.appText()).onClick(() => this.duplicateElement())
            Button('上移一层', { type: ButtonType.Capsule, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL }).layoutWeight(1).padding({left:6,right:6}).height(AppDesign.controlHeight).fontSize(12).backgroundColor(this.appControl()).fontColor(this.appText()).onClick(() => this.moveElementOrder(true))
            Button('下移一层', { type: ButtonType.Capsule, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL }).layoutWeight(1).padding({left:6,right:6}).height(AppDesign.controlHeight).fontSize(12).backgroundColor(this.appControl()).fontColor(this.appText()).onClick(() => this.moveElementOrder(false))
        }.width('100%')

        }
        Flex({ wrap: FlexWrap.Wrap }) {
          if (this.layerId.length > 0 && this.layerId !== 'capability') {
          Button(this.settingsTab === 0 ? '移到内容层' : '移到最上层', { type: ButtonType.ROUNDED_RECTANGLE, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL }).margin({ right: 8, bottom: 8 }).height(AppDesign.controlHeight).fontSize(13).fontColor(this.appText()).backgroundColor(this.appControl())
            .onClick(() => { const card = this.current(), el = this.currentElement(); if (card !== null && el !== null) { el.behindCapability = false; this.settingsTab = 1;  card.elements = card.elements.filter((e: CanvasElement) => e.id !== el.id).concat([el]); this.change(); } })
          Button(this.settingsTab === 1 ? '移到背景层' : '移到最下层', { type: ButtonType.ROUNDED_RECTANGLE, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL }).margin({ right: 8, bottom: 8 }).height(AppDesign.controlHeight).fontSize(13).fontColor(this.appText()).backgroundColor(this.appControl())
            .onClick(() => { const card = this.current(), el = this.currentElement(); if (card !== null && el !== null) {
              el.behindCapability = true; this.settingsTab = 0;  card.elements = [el].concat(card.elements.filter((e: CanvasElement) => e.id !== el.id)); this.change();
            } })
          }
        }

    }.width('100%').padding(16).backgroundColor(this.appControl()).borderRadius(20)
  }
  private chooseCapability(): void {
    this.capabilityPickerOpen=true;
  }
  @Builder
  capabilityPickerSheet() {
    CapabilityPicker({selected:this.preview.capability?.k??'none',appDark:this.appDark,onClose:()=>this.capabilityPickerOpen=false,
      onChoose:(key:string)=>{if(this.editing&&!this.heroActive)this.setCapability(key);}})
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

      if (this.preview.capability?.k === 'countdown' || this.preview.capability?.k === 'anniversary') {
        TextInput({ text: this.titleValue, placeholder: '名称' }).height(AppDesign.controlHeight).borderRadius(AppDesign.controlRadius).fontSize(16).fontColor(this.appText()).placeholderColor(this.appMuted()).backgroundColor(this.appControl())
          .onChange((v: string) => { this.titleValue = v; const cap = this.current()?.capability; if (cap !== null && cap !== undefined) { cap.title = v; this.change(); } })
        Button('日期  ' + (this.preview.capability?.date ?? ''), { type: ButtonType.ROUNDED_RECTANGLE, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL }).height(AppDesign.controlHeight).fontColor(this.appText()).backgroundColor(this.appControl()).onClick(() => this.pickDate())
      }
      if (this.preview.capability?.k === 'worldclock') {
        TimeCapabilitySettings({cap:this.preview.capability!,appDark:this.appDark,onUpdate:(next:CapBlock)=>this.updateExtraCapability(this.preview.id,next)})
      }

      if(this.preview.capability!==null && ['album','battery','agenda','timetable'].includes(this.preview.capability!.k)) {
        CapabilitySettings({section:this.preview.capability?.k==='timetable'?['display','courses','calendar'][this.editorSheetTab]:this.preview.capability?.k==='album'?['library','metadata','rotation'][this.editorSheetTab]:'all',tick:this.tick,cap:this.preview.capability!,cardId:this.preview.id,appDark:this.appDark,onReuseTimetable:(id:string)=>this.reuseTimetable(id),onUpdate:(id:string,next:CapBlock)=>this.updateExtraCapability(id,next)})
      }
    }.width('100%')
  }
  private chooseReadingComposition(blend:string):void {
    const card=this.current();if(!card?.capability||!readingStyles(card.capability.k).includes(blend))return;
    card.capability.readingBlend=blend;card.capability.readingStyle='surface';card.capability.readingEdge=blend==='sticker'?(card.capability.readingEdge||'left'):'';
    card.capBox=editorReadingPlacement(card,blend);card.capFree=true;
    if(blend==='sticker'){const a=edgeAttachment(card,card.capBox,card.capability.readingEdge||'left',card.capability.readingOutside===true);card.capBox.x=a.box.x;card.capBox.y=a.box.y;card.capBox.rot=0;}
    this.change();

  }
  private arrangeCapability(anchor:string):void {
    const card=this.current();if(card===null || card.capability===null)return;
    card.capFree=false;card.capBox=capabilityPreset(card,anchor);this.change();
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
  baseColorPanel() {
    Column({space:12}) {
      if(this.preview.cutout.length>0) {
        Text('主体外观').fontSize(14).fontColor(this.appText()).width('100%')
        SettingsSegmented({labels:['只用形状','主体照片作底图'],selectedIndex:this.preview.subjectPhoto?1:0,appDark:this.appDark,
          onSelect:(index:number)=>{const card=this.current();if(card){card.subjectPhoto=index===1;this.change();}}})
      }
      if(this.preview.shape!=='subject'||!this.preview.subjectPhoto) {
        Row({space:8}) {this.paperPresets();ColorSetting({compact:true,label:'底色',color:this.paperValue||materialColors(this.preview.material,this.preview.paper,this.preview.ink)[0],automatic:!this.paperValue,canReset:false,sourceKey:this.cardColorKey('paper'),appDark:this.appDark,onPick:(color:string,key:string)=>this.setCardColor('paper',color,key),onFallback:()=>this.chooseColor('paper')}).width(48)}.width('100%')
      }
    }.width('100%').padding(12).backgroundColor(this.appSurface()).borderRadius(20)
  }
  @Builder
  appearancePanel() {
    Column({ space: 12 }) {
      EditorVisualChoices({card:this.preview,mode:'shape',selected:this.preview.shape,appDark:this.appDark,onChoose:(key:string)=>{const card=this.current();if(card){card.shape=key;if(key==='subject')card.h=card.w/card.subjectAspect;this.change();}}})
      Button(this.busy ? '正在处理照片' : '用照片主体作为形状', { type: ButtonType.ROUNDED_RECTANGLE, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL }).height(AppDesign.controlHeight).width('100%').fontSize(14)
        .fontColor(this.appText()).backgroundColor(this.appControl()).enabled(!this.busy).onClick(() => this.pickImage(true))
      if (this.preview.cutout.length > 0 && this.preview.shape !== 'subject') {
        Button('恢复主体形状', { type: ButtonType.ROUNDED_RECTANGLE, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL }).height(AppDesign.controlHeight).fontColor(this.appText()).backgroundColor(this.appControl())
          .onClick(() => { const card = this.current(); if (card !== null) { card.shape = 'subject'; card.h = card.w / card.subjectAspect; this.change(); } })
      }
      if (this.preview.cutout.length > 0) {
        Button(this.enhancingSubject?'正在提升清晰度':'提升清晰度',{type:ButtonType.Capsule,buttonStyle:ButtonStyleMode.NORMAL}).height(44).fontColor(this.appText()).backgroundColor(this.appControl()).enabled(!this.busy&&!this.enhancingSubject&&!this.enhancingBackground).onClick(()=>this.enhancePhoto(true))

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
