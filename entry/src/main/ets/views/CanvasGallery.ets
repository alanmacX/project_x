import { widgetFrameMetrics } from '../model/WidgetFrameGeometry';
import { widgetRectangles } from '../model/WidgetGeometry';
import { GalleryThumbnail, cachedGalleryPreview, saveGalleryPreview, removeGalleryPreview } from '../model/GalleryPreviewCache';
import { HdsNavigation, HdsNavigationTitleMode, IconStyleMode, TextStyleMode } from '@kit.UIDesignKit';
import { SymbolGlyphModifier } from '@kit.ArkUI';
import { navigationChrome } from '../model/NavigationChrome';
import { CREATION_DIMENSIONS, creationDimension } from '../model/CanvasSize';
import { image } from '@kit.ImageKit';
import { fileIo } from '@kit.CoreFileKit';
import { taskpool } from '@kit.ArkTS';
import lazy { prepareSceneRelief } from '../model/SceneRelief';
import { CanvasEntry } from '../model/CanvasLibrary';
import { FridgeState, FridgeCard, BOARD_W, BOARD_H } from '../model/CardSchema';
import { GalleryItem, GalleryRow, galleryRows, galleryRowKey, galleryPreviewSize } from '../model/CanvasGallery';
import { AppDesign } from '../model/AppDesign';
import { immersiveChrome, chromeMaterial } from '../model/ChromeMaterial';
import { storageSnapshot } from '../model/StorageSnapshot';
import { depthRenderCards } from '../model/DepthComposition';
import { cardRenderSnapshot } from '../model/CardViewSnapshot';
import { primeRenderContours } from '../model/RenderContours';
import { CanvasBackdrop } from './CanvasBackdrop';
import { CanvasFrame } from './CanvasFrame';
import { CardFace } from './CardFace';

@Component
export struct CanvasGallery {
  @Prop entries: CanvasEntry[] = [];
  @Prop @Watch('reload') revision: number = 0;
  @Prop appDark: boolean = false;
  @Prop viewportWidth: number = 390;
  @Prop safeTop: number = 0;
  @Prop safeBottom: number = 0;
  @Prop busy: boolean = false;
  onLoad: (id: string) => Promise<FridgeState> = async () => new FridgeState();
  onOpen: (id: string) => void = () => {};
  onCreate: (name: string, dimension: string) => void = () => {};
  onRename: (id: string, name: string) => void = () => {};
  onDuplicate: (id: string) => void = () => {};
  onShare: (id: string) => void = () => {};
  onDelete: (id: string) => void = () => {};
  onImport: () => void = () => {};
  onSkill: (url: string) => void = () => {};
  @State items: GalleryItem[] = [];
  @State widgetRects:Record<string,number[]>={};
  @State toolsOpen: boolean = false;
  @State filter: string = '';
  @State creating: boolean = false;
  @State draftName: string = '';
  @State draftDimension: string = '4*4';
  @State renameId: string = '';
  @State renameName: string = '';
  private alive: boolean = false;
  private documents: Map<string, FridgeState> = new Map();
  private visibleIds: Set<string> = new Set();
  private pendingIds: Set<string> = new Set();
  private previewQueue: Promise<void> = Promise.resolve();
  private generation: number = 0;
  private previewTick: number = Date.now();
  private scroller: Scroller = new Scroller();

  aboutToAppear(): void { this.alive = true; this.loadItems(); }
  aboutToDisappear(): void { this.alive = false; this.generation++; }
  private reload(): void { if (this.alive) this.loadItems(); }
  private startCreating(): void { this.draftDimension = creationDimension(this.filter); this.creating = true; this.draftName = ''; this.scroller.scrollEdge(Edge.Top); }
  private async loadItems(): Promise<void> {
    const generation = ++this.generation;
    this.documents.clear();
    this.items = this.entries.map((entry: CanvasEntry): GalleryItem => {
      const item = new GalleryItem(); item.id = entry.id; item.name = entry.name; return item;
    });
    const context=this.getUIContext().getHostContext();const cacheDir=context?.cacheDir??'';
    if(context){try{this.widgetRects=await widgetRectangles(context);}catch(_){}}
    for (const entry of this.entries) {
      if (!this.alive || generation !== this.generation) return;
      try {
        const cached=await cachedGalleryPreview(cacheDir,entry.id);
        if (!this.alive || generation !== this.generation) return;
        if(cached)this.items=this.items.map((item:GalleryItem):GalleryItem=>{
          if(item.id!==entry.id)return item;
          const next=new GalleryItem();next.id=item.id;next.name=item.name;next.dimension=cached.dimension;next.aspect=cached.aspect;next.preview=cached.path;return next;
        });
        const state = await this.onLoad(entry.id);
        if (!this.alive || generation !== this.generation) return;
        this.documents.set(entry.id, state);
        this.items = this.items.map((source: GalleryItem): GalleryItem => {
          if (source.id !== entry.id) return source;
          const item = new GalleryItem(); item.id = source.id; item.name = source.name;
          item.dimension = state.canvasDimension; item.aspect = state.canvasAspect;
          item.loaded = true;

          if (cached?.source === this.previewSource(state)) item.preview = cached.path;
          return item;
        });
        if (this.visibleIds.has(entry.id)) this.requestPreview(entry.id);
      } catch (_) {
        if (!this.alive || generation !== this.generation) return;
        this.items = this.items.map((item: GalleryItem): GalleryItem => {
          if (item.id === entry.id) { const failed = new GalleryItem(); failed.id = item.id; failed.name = item.name; failed.failed = true; return failed; }
          return item;
        });
      }
    }
  }
  private requestPreview(id: string): void {
    const item = this.items.find((value: GalleryItem) => value.id === id);
    if (!this.alive || !item?.loaded || item.preview || this.pendingIds.has(id)) return;
    this.pendingIds.add(id);
    const generation = this.generation;
    this.previewQueue = this.previewQueue.catch(() => {}).then(async () => {
      try {
        const state = this.documents.get(id);
        if (!this.alive || generation !== this.generation || !state || !this.visibleIds.has(id)) return;
        const context = this.getUIContext().getHostContext(); if (!context) return;
        const source = this.previewSource(state);
        const relief = JSON.parse(await taskpool.execute(new taskpool.Task(prepareSceneRelief, JSON.stringify(state.cards))) as string) as Record<string, string>;
        state.cards.forEach((card: FridgeCard) => { card.reliefSrc = relief[card.id] ?? card.reliefSrc; });
        await primeRenderContours(state.cards, storageSnapshot(state));
        if (!this.alive || generation !== this.generation) return;
        const pixel = await this.getUIContext().getComponentSnapshot().createFromBuilder(() => { this.artwork(state); }, 180, true,
          { scale: 1, waitUntilRenderFinished: true });
        const path = context.cacheDir + '/gallery_v2_' + id + '_' + Date.now() + '.png';
        const packer = image.createImagePacker(); let file: fileIo.File | null = null;
        try {
          file = await fileIo.open(path, fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE);
          await packer.packToFile(pixel, file.fd, { format: 'image/png', quality: 100 });
        } finally {
          try { if (file) fileIo.closeSync(file.fd); }
          finally { try { await packer.release(); } finally { await pixel.release(); } }
        }
        const cached = new GalleryThumbnail(); cached.source = source; cached.path = 'file://' + path;
        cached.dimension=state.canvasDimension;cached.aspect=state.canvasAspect;
        await saveGalleryPreview(context.cacheDir,id,cached);
        if (!this.alive || generation !== this.generation) return;
        this.items = this.items.map((value: GalleryItem): GalleryItem => {
          if (value.id !== id) return value;
          const next = new GalleryItem(); next.id = value.id; next.name = value.name; next.dimension = value.dimension;
          next.aspect = value.aspect; next.loaded = true; next.preview = cached.path; return next;
        });
      } catch (_) {
        // Original artwork stays available even if a disposable preview cannot render.
        if (this.alive && generation === this.generation) this.previewUnavailable(id);
      } finally {
        this.pendingIds.delete(id);
        if (this.alive && generation !== this.generation && this.visibleIds.has(id)) this.requestPreview(id);
      }
    });
  }
  private previewUnavailable(id: string, expectedPath: string = ''): void {
    if (!this.alive || (expectedPath && this.items.find((item: GalleryItem) => item.id === id)?.preview !== expectedPath)) return;
    this.items = this.items.map((value: GalleryItem): GalleryItem => {
      if (value.id !== id) return value;
      const next = new GalleryItem(); next.id = value.id; next.name = value.name; next.dimension = value.dimension;
      next.aspect = value.aspect; next.loaded = value.loaded; next.failed = true; return next;
    });
    const dir=this.getUIContext().getHostContext()?.cacheDir??'';
    removeGalleryPreview(dir,id).catch(()=>{});
  }
  private previewFrameCorner(state:FridgeState):number{
    const rect=galleryPreviewSize(state.canvasDimension,state.canvasAspect,this.contentWidth(),this.widgetRects);return widgetFrameMetrics(rect[0],rect[1]).cornerPercent;
  }
  private previewRadius(state:FridgeState):number{
    const rect=galleryPreviewSize(state.canvasDimension,state.canvasAspect,this.contentWidth(),this.widgetRects);
    return widgetFrameMetrics(rect[0],rect[1]).radius*BOARD_W/rect[0];
  }
  private previewAspect(state:FridgeState):number {
    const rect=galleryPreviewSize(state.canvasDimension,state.canvasAspect,this.contentWidth(),this.widgetRects);return rect[0]/rect[1];
  }
  private previewSource(state:FridgeState):string {return 'v6-frame-clip:'+storageSnapshot(state)+':hostAspect='+this.previewAspect(state)+':corner='+this.previewFrameCorner(state);}
  private artworkCards(state: FridgeState): FridgeCard[] {
    return depthRenderCards(state.cards.filter((card: FridgeCard) => !card.hidden).map((card: FridgeCard) => cardRenderSnapshot(card)))
      .sort((a: FridgeCard, b: FridgeCard) => a.z - b.z);
  }
  @Builder
  artwork(state: FridgeState) {
    Stack({ alignContent: Alignment.TopStart }) {
      CanvasBackdrop({ sceneBackground: state.background, showFrame: false }).width('100%').height('100%')
      ForEach(this.artworkCards(state), (card: FridgeCard) => {
        CardFace({ card: card, scaleFactor: 1, tick: this.previewTick, widget: true })
          .width(card.w).height(card.h).position({ x: card.x, y: card.y * (BOARD_W / this.previewAspect(state)) / BOARD_H })
          .rotate({ angle: card.rot, centerX: 0, centerY: '100%' }).zIndex(card.z)
      }, (card: FridgeCard) => card.id)
      if (state.background.frameStyle !== 'none') {
        CanvasFrame({ material: state.background.frameMaterial, style: state.background.frameStyle, cornerPercent: this.previewFrameCorner(state) }).width('100%').height('100%').zIndex(100000)
      }
    }.width(BOARD_W).height(BOARD_W / this.previewAspect(state)).borderRadius(this.previewRadius(state)).clip(true)
  }
  private columns(): number { const small=galleryPreviewSize('2*2',1,this.contentWidth(),this.widgetRects)[0];return Math.max(1,Math.min(4,Math.floor((this.contentWidth()+16)/(small+16)))); }
  private contentWidth(): number { return Math.min(1120, this.viewportWidth - (this.viewportWidth >= 720 ? 48 : 32)); }
  private tileWidth(item:GalleryItem):number {return galleryPreviewSize(item.dimension,item.aspect,this.contentWidth(),this.widgetRects)[0];}
  private previewHeight(item: GalleryItem, wide: boolean): number { return galleryPreviewSize(item.dimension,item.aspect,this.contentWidth(),this.widgetRects)[1]; }
  private menu(item: GalleryItem): MenuElement[] {
    return [
      { value: '重命名', action: () => { this.renameId = item.id; this.renameName = item.name; } },
      { value: '复制画布', action: () => this.onDuplicate(item.id) },
      { value: '分享画布', action: () => this.onShare(item.id) },
      { value: '删除画布', enabled: this.entries.length > 1, action: () => this.onDelete(item.id) }
    ];
  }
  private saveName(item: GalleryItem): void {
    if (!this.renameName.trim() || this.busy) return;
    this.onRename(item.id, this.renameName.trim());
    this.items = this.items.map((value: GalleryItem): GalleryItem => {
      if (value.id !== item.id) return value;
      const next = new GalleryItem(); next.id = value.id; next.name = this.renameName.trim(); next.dimension = value.dimension;
      next.aspect = value.aspect; next.preview = value.preview; next.loaded = value.loaded; next.failed = value.failed; return next;
    });
    this.renameId = '';
  }
  @Builder
  tile(item: GalleryItem, wide: boolean) {
    Column({ space: 4 }) {
      Button({ type: ButtonType.ROUNDED_RECTANGLE, buttonStyle: ButtonStyleMode.NORMAL }) {
        Stack() {
          if (item.preview) { Image(item.preview).width('100%').height('100%').objectFit(ImageFit.Contain).draggable(false).onError(() => this.previewUnavailable(item.id, item.preview)) }
          else {
            Column({ space: 10 }) {
              SymbolGlyph($r('sys.symbol.square_stack_3d')).fontSize(28).fontColor([AppDesign.muted(this.appDark)])
              Text(item.failed ? '预览暂不可用' : item.loaded ? '正在生成预览' : '正在读取画布').fontSize(12).fontColor(AppDesign.muted(this.appDark))
            }
          }
        }.width('100%').height(this.previewHeight(item, wide)).backgroundColor(Color.Transparent).clip(true)
      }.width('100%').height(this.previewHeight(item, wide)).padding(0).borderRadius(0).backgroundColor(Color.Transparent)
        .enabled(!this.busy).accessibilityText('打开画布 ' + item.name).onClick(() => this.onOpen(item.id))
        .onVisibleAreaChange([0], (visible: boolean) => { if (visible) { this.visibleIds.add(item.id); this.requestPreview(item.id); } else this.visibleIds.delete(item.id); })
      if (this.renameId === item.id) {
        Column({ space: 4 }) {
          TextInput({ text: this.renameName, placeholder: '画布名称' }).height(44).width('100%').maxLength(40)
            .fontColor(AppDesign.text(this.appDark)).backgroundColor(AppDesign.surface(this.appDark)).borderRadius(12)
            .onChange((value: string) => this.renameName = value).onSubmit(() => this.saveName(item))
          Row({ space: 4 }) {
            Button('保存', { type: ButtonType.Capsule }).height(44).layoutWeight(1).backgroundColor(AppDesign.selected(this.appDark)).fontColor(AppDesign.onSelected(this.appDark))
              .enabled(!!this.renameName.trim() && !this.busy).onClick(() => this.saveName(item))
            Button('取消', { type: ButtonType.Capsule, buttonStyle: ButtonStyleMode.NORMAL }).height(44).layoutWeight(1)
              .backgroundColor(AppDesign.surface(this.appDark)).fontColor(AppDesign.text(this.appDark)).onClick(() => this.renameId = '')
          }.width('100%')
        }.width('100%')
      } else {
        Row({ space: 4 }) {
          Column({ space: 3 }) {
            Text(item.name).fontSize(15).fontWeight(FontWeight.Medium).fontColor(AppDesign.text(this.appDark)).maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis }).width('100%')
            Text(item.dimension.replace('*', '×')).fontSize(12).fontColor(AppDesign.muted(this.appDark)).width('100%')
          }.layoutWeight(1).alignItems(HorizontalAlign.Start)
          Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL }) {
            Text('⋯').fontSize(24).fontColor(AppDesign.text(this.appDark)).hitTestBehavior(HitTestMode.None)
          }.id('shareCanvas_' + item.id).width(44).height(44).backgroundColor(Color.Transparent).enabled(!this.busy).accessibilityText(item.name + '的更多操作')
            .bindMenu(this.menu(item), { systemMaterial: chromeMaterial(this.appDark), backgroundColor: AppDesign.popup(this.appDark) })
        }.width('100%').constraintSize({ minHeight: 48 })
      }
    }.width(this.tileWidth(item)).alignItems(HorizontalAlign.Start)
  }
  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      // Keep scrolling artwork under the system safe area; only its initial content inset avoids the title.
      Scroll(this.scroller) {
        Column({ space: 20 }) {
          Scroll() {
            Row({ space: 8 }) {
              ForEach(['', '4*4', '2*4', '2*2'], (dimension: string) => {
                Button(dimension ? dimension.replace('*', '×') : '全部', { type: ButtonType.Capsule, buttonStyle: ButtonStyleMode.NORMAL })
                  .height(44).padding({ left: 18, right: 18 }).fontSize(14)
                  .backgroundColor(AppDesign.choice(this.appDark, this.filter === dimension)).fontColor(AppDesign.choiceText(this.appDark, this.filter === dimension))
                  .onClick(() => this.filter = dimension)
              }, (dimension: string) => dimension || 'all')
            }
          }.width('100%').scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off)
          if (this.creating) {
            Column({ space: 12 }) {
              Text('画布尺寸').fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppDesign.text(this.appDark)).width('100%')
              Row({ space: 8 }) {
                ForEach(CREATION_DIMENSIONS, (dimension: string) => {
                  Button(dimension.replace('*', '×'), { type: ButtonType.Capsule, buttonStyle: ButtonStyleMode.NORMAL })
                    .height(44).layoutWeight(1).fontSize(14).padding({ left: 8, right: 8 })
                    .backgroundColor(AppDesign.choice(this.appDark, this.draftDimension === dimension))
                    .fontColor(AppDesign.choiceText(this.appDark, this.draftDimension === dimension))
                    .accessibilityText('创建 ' + dimension.replace('*', '×') + ' 画布' + (this.draftDimension === dimension ? '，已选中' : ''))
                    .onClick(() => this.draftDimension = dimension)
                }, (dimension: string) => dimension)
              }.width('100%')
              TextInput({ text: this.draftName, placeholder: '新画布名称' }).height(48).maxLength(40).fontColor(AppDesign.text(this.appDark))
                .backgroundColor(AppDesign.control(this.appDark)).borderRadius(12).onChange((value: string) => this.draftName = value)
              Row({ space: 8 }) {
                Text('创建后即可添加卡片').fontSize(12).fontColor(AppDesign.muted(this.appDark)).layoutWeight(1)
                Button('取消', { type: ButtonType.Capsule, buttonStyle: ButtonStyleMode.NORMAL }).height(44).backgroundColor(AppDesign.control(this.appDark)).fontColor(AppDesign.text(this.appDark)).onClick(() => this.creating = false)
                Button('创建画布', { type: ButtonType.Capsule }).height(44).backgroundColor(AppDesign.selected(this.appDark)).fontColor(AppDesign.onSelected(this.appDark))
                  .enabled(!this.busy).onClick(() => this.onCreate(this.draftName.trim() || '新画布', this.draftDimension))
              }.width('100%')
            }.width('100%').padding(16).borderRadius(20).backgroundColor(AppDesign.surface(this.appDark))
          }
          ForEach(galleryRows(this.items, this.filter, this.columns()), (row: GalleryRow) => {
            Row({ space: 16 }) {
              ForEach(row.items, (item: GalleryItem) => { this.tile(item, row.wide) }, (item: GalleryItem) => item.id)
            }.width('100%').alignItems(VerticalAlign.Top)
          }, (row: GalleryRow) => galleryRowKey(row))
          if (!galleryRows(this.items, this.filter, this.columns()).length) {
            Column({ space: 12 }) {
              Text(this.filter ? '还没有这个尺寸的画布' : '从第一张画布开始').fontSize(18).fontColor(AppDesign.text(this.appDark))
              Text(this.filter ? '可以先查看全部作品' : '添加照片、文字或实用卡片，创作自己的桌面作品').fontSize(14).fontColor(AppDesign.muted(this.appDark))
            }.width('100%').padding({ top: 64, bottom: 64 })
          }
        }.width(this.contentWidth()).padding({ top: 76 + this.safeTop, bottom: this.safeBottom + 104 }).alignItems(HorizontalAlign.Start)
      }.width('100%').height('100%')
        .align(Alignment.Top).clip(false).scrollBar(BarState.Auto).edgeEffect(EdgeEffect.Spring)
      // A sibling native title bar can blur the full scroll surface without clipping it at the safe area.
      HdsNavigation() {
        Column().width(1).height(1)
      }.titleMode(HdsNavigationTitleMode.MINI)
        .titleBar({ enableComponentSafeArea: true, avoidLayoutSafeArea: true, content: {
          title: { mainTitle: '我的画布', subTitle: this.entries.length + ' 张画布' },
          menu: { maxCount: 3, value: [
            { content: { icon: new SymbolGlyphModifier($r('sys.symbol.square_and_arrow_down')).fontSize(22).fontColor([AppDesign.text(this.appDark)]),
              label: '导入作品', type: IconStyleMode.NORMAL, isEnabled: !this.busy, action: () => this.onImport() } },
            { content: { icon: new SymbolGlyphModifier($r('sys.symbol.plus')).fontSize(22).fontColor([AppDesign.text(this.appDark)]),
              label: '新建画布', type: IconStyleMode.NORMAL, isEnabled: !this.busy, action: () => this.startCreating() } },
            { content: { label: '更多', type: TextStyleMode.NORMAL, isEnabled: !this.busy, action: () => this.toolsOpen = true } }
          ] }
        }, style: navigationChrome(this.appDark, true) })
        .bindToScrollable([this.scroller]).hideBackButton(true).hideToolBar(true).mode(NavigationMode.Stack)
        .width('100%').height('100%').align(Alignment.Top)
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
        .hitTestBehavior(HitTestMode.Transparent).clip(false).backgroundColor(Color.Transparent)
      Column().width(1).height(1).position({ x: this.viewportWidth - 24, y: this.safeTop + 60 }).hitTestBehavior(HitTestMode.None).accessibilityLevel('no')
        .bindMenu(this.toolsOpen, [{ value: '创作 Skill · Gitee', action: () => { this.toolsOpen = false; this.onSkill('https://gitee.com/alanmac/fridge-signing-system'); } },
          { value: '创作 Skill · GitHub', action: () => { this.toolsOpen = false; this.onSkill('https://github.com/alanmacX/fridge-creating-skill'); } }],
          { systemMaterial: chromeMaterial(this.appDark), backgroundColor: AppDesign.popup(this.appDark), onDisappear: () => this.toolsOpen = false })
      if (!this.creating) {
        Button('+ 新建画布', { type: ButtonType.Capsule, buttonStyle: ButtonStyleMode.NORMAL }).height(48).padding({ left: 24, right: 24 }).fontSize(16)
          .backgroundColor(AppDesign.selected(this.appDark)).fontColor(AppDesign.onSelected(this.appDark)).margin({ bottom: this.safeBottom + 16 })
          .enabled(!this.busy).onClick(() => this.startCreating())
      }
    }.width('100%').height('100%').backgroundColor(AppDesign.background(this.appDark))
  }
}
