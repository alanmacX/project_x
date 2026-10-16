import { image } from '@kit.ImageKit';
import { fileIo } from '@kit.CoreFileKit';
import { LengthMetrics } from '@kit.ArkUI';
import { taskpool } from '@kit.ArkTS';
import lazy { prepareSceneRelief } from '../model/SceneRelief';
import { CanvasEntry } from '../model/CanvasLibrary';
import { FridgeState, FridgeCard, BOARD_W, BOARD_H } from '../model/CardSchema';
import { GalleryItem, GalleryRow, galleryColumns, galleryRows } from '../model/CanvasGallery';
import { AppDesign } from '../model/AppDesign';
import { immersiveChrome, chromeMaterial } from '../model/ChromeMaterial';
import { storageSnapshot } from '../model/StorageSnapshot';
import { depthRenderCards } from '../model/DepthComposition';
import { cardRenderSnapshot } from '../model/CardViewSnapshot';
import { primeRenderContours } from '../model/RenderContours';
import { CanvasBackdrop } from './CanvasBackdrop';
import { CanvasFrame } from './CanvasFrame';
import { CardFace } from './CardFace';

class GalleryThumbnail {
  source: string = '';
  path: string = '';
}
// Derived previews survive navigation; no live clocks or GIFs run in the library.
const thumbnails: Map<string, GalleryThumbnail> = new Map();
let thumbnailSequence: number = 0;

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
  onCreate: (name: string) => void = () => {};
  onRename: (id: string, name: string) => void = () => {};
  onDuplicate: (id: string) => void = () => {};
  onShare: (id: string) => void = () => {};
  onDelete: (id: string) => void = () => {};
  onImport: () => void = () => {};
  onSkill: (url: string) => void = () => {};
  @State items: GalleryItem[] = [];
  @State filter: string = '';
  @State creating: boolean = false;
  @State draftName: string = '';
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
  private startCreating(): void { this.creating = true; this.draftName = ''; this.scroller.scrollEdge(Edge.Top); }
  private async loadItems(): Promise<void> {
    const generation = ++this.generation;
    this.documents.clear();
    for (const id of thumbnails.keys()) {
      if (!this.entries.some((entry: CanvasEntry) => entry.id === id)) {
        const removed = thumbnails.get(id); thumbnails.delete(id);
        if (removed) fileIo.unlink(removed.path.slice(7)).catch(() => {});
      }
    }
    this.items = this.entries.map((entry: CanvasEntry): GalleryItem => {
      const item = new GalleryItem(); item.id = entry.id; item.name = entry.name; return item;
    });
    for (const entry of this.entries) {
      if (!this.alive || generation !== this.generation) return;
      try {
        const state = await this.onLoad(entry.id);
        if (!this.alive || generation !== this.generation) return;
        this.documents.set(entry.id, state);
        this.items = this.items.map((source: GalleryItem): GalleryItem => {
          if (source.id !== entry.id) return source;
          const item = new GalleryItem(); item.id = source.id; item.name = source.name;
          item.dimension = state.canvasDimension; item.aspect = state.canvasAspect;
          item.loaded = true;
          const cached = thumbnails.get(item.id);
          if (cached?.source === storageSnapshot(state)) item.preview = cached.path;
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
        const source = storageSnapshot(state);
        const relief = JSON.parse(await taskpool.execute(new taskpool.Task(prepareSceneRelief, JSON.stringify(state.cards))) as string) as Record<string, string>;
        state.cards.forEach((card: FridgeCard) => { card.reliefSrc = relief[card.id] ?? card.reliefSrc; });
        await primeRenderContours(state.cards, source);
        if (!this.alive || generation !== this.generation) return;
        const pixel = await this.getUIContext().getComponentSnapshot().createFromBuilder(() => { this.artwork(state); }, 180, true,
          { scale: 1, waitUntilRenderFinished: true });
        const path = context.cacheDir + '/gallery_' + id + '_' + (++thumbnailSequence) + '.png';
        const packer = image.createImagePacker(); let file: fileIo.File | null = null;
        try {
          file = await fileIo.open(path, fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE);
          await packer.packToFile(pixel, file.fd, { format: 'image/png', quality: 100 });
        } finally {
          try { if (file) fileIo.closeSync(file.fd); }
          finally { try { await packer.release(); } finally { await pixel.release(); } }
        }
        const previous = thumbnails.get(id);
        const cached = new GalleryThumbnail(); cached.source = source; cached.path = 'file://' + path; thumbnails.set(id, cached);
        if (previous && previous.path !== cached.path) { try { await fileIo.unlink(previous.path.slice(7)); } catch (_) {} }
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
    const cached = thumbnails.get(id); thumbnails.delete(id);
    if (cached) fileIo.unlink(cached.path.slice(7)).catch(() => {});
  }
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
          .width(card.w).height(card.h).position({ x: card.x, y: card.y * (BOARD_W / state.canvasAspect) / BOARD_H })
          .rotate({ angle: card.rot, centerX: 0, centerY: '100%' }).zIndex(card.z)
      }, (card: FridgeCard) => card.id)
      if (state.background.frameStyle !== 'none') {
        CanvasFrame({ material: state.background.frameMaterial, style: state.background.frameStyle, square: true }).width('100%').height('100%').zIndex(100000)
      }
    }.width(BOARD_W).height(BOARD_W / state.canvasAspect).clip(true)
  }
  private columns(): number { return galleryColumns(this.viewportWidth); }
  private contentWidth(): number { return Math.min(1120, this.viewportWidth - (this.viewportWidth >= 720 ? 48 : 32)); }
  private tileWidth(wide: boolean): number { return wide ? this.contentWidth() : (this.contentWidth() - (this.columns() - 1) * 16) / this.columns(); }
  private previewHeight(item: GalleryItem, wide: boolean): number { return this.tileWidth(wide) / Math.max(.3, item.aspect); }
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
        }.width('100%').height(this.previewHeight(item, wide)).backgroundColor(AppDesign.surface(this.appDark)).borderRadius(16).clip(true)
      }.width('100%').height(this.previewHeight(item, wide)).padding(0).borderRadius(16).backgroundColor(Color.Transparent)
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
    }.width(this.tileWidth(wide)).alignItems(HorizontalAlign.Start)
  }
  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Scroll(this.scroller) {
        Column({ space: 20 }) {
          Row({ space: 8 }) {
            Column({ space: 6 }) {
              Text('我的画布').fontSize(30).fontWeight(FontWeight.Bold).fontColor(AppDesign.text(this.appDark))
              Text(this.entries.length + ' 张画布').fontSize(14).fontColor(AppDesign.muted(this.appDark))
            }.layoutWeight(1).alignItems(HorizontalAlign.Start)
            Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL }) {
              SymbolGlyph($r('sys.symbol.square_and_arrow_down')).fontSize(22).fontColor([AppDesign.text(this.appDark)]).hitTestBehavior(HitTestMode.None)
            }.width(48).height(48).attributeModifier(immersiveChrome(this.appDark)).enabled(!this.busy).accessibilityText('导入作品').onClick(() => this.onImport())
            Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL }) {
              SymbolGlyph($r('sys.symbol.plus')).fontSize(24).fontColor([AppDesign.text(this.appDark)]).hitTestBehavior(HitTestMode.None)
            }.width(48).height(48).attributeModifier(immersiveChrome(this.appDark)).enabled(!this.busy).accessibilityText('新建画布').onClick(() => this.startCreating())
            Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL }) {
              Text('⋯').fontSize(24).fontColor(AppDesign.text(this.appDark)).hitTestBehavior(HitTestMode.None)
            }.width(44).height(44).backgroundColor(Color.Transparent).accessibilityText('更多创作工具')
              .bindMenu([{ value: '创作 Skill · Gitee', action: () => this.onSkill('https://gitee.com/alanmac/fridge-signing-system') },
                { value: '创作 Skill · GitHub', action: () => this.onSkill('https://github.com/alanmacX/fridge-creating-skill') }],
                { systemMaterial: chromeMaterial(this.appDark), backgroundColor: AppDesign.popup(this.appDark) })
          }.width('100%')
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
              TextInput({ text: this.draftName, placeholder: '新画布名称' }).height(48).maxLength(40).fontColor(AppDesign.text(this.appDark))
                .backgroundColor(AppDesign.control(this.appDark)).borderRadius(12).onChange((value: string) => this.draftName = value)
              Row({ space: 8 }) {
                Text('创建后即可添加卡片').fontSize(12).fontColor(AppDesign.muted(this.appDark)).layoutWeight(1)
                Button('取消', { type: ButtonType.Capsule, buttonStyle: ButtonStyleMode.NORMAL }).height(44).backgroundColor(AppDesign.control(this.appDark)).fontColor(AppDesign.text(this.appDark)).onClick(() => this.creating = false)
                Button('创建画布', { type: ButtonType.Capsule }).height(44).backgroundColor(AppDesign.selected(this.appDark)).fontColor(AppDesign.onSelected(this.appDark))
                  .enabled(!this.busy).onClick(() => this.onCreate(this.draftName.trim() || '新画布'))
              }.width('100%')
            }.width('100%').padding(16).borderRadius(20).backgroundColor(AppDesign.surface(this.appDark))
          }
          ForEach(galleryRows(this.items, this.filter, this.columns()), (row: GalleryRow) => {
            Row({ space: 16 }) {
              ForEach(row.items, (item: GalleryItem) => { this.tile(item, row.wide) }, (item: GalleryItem) => item.id)
            }.width('100%').alignItems(VerticalAlign.Top)
          }, (row: GalleryRow) => row.id + '_' + String(row.wide))
          if (!galleryRows(this.items, this.filter, this.columns()).length) {
            Column({ space: 12 }) {
              Text(this.filter ? '还没有这个尺寸的画布' : '从第一张画布开始').fontSize(18).fontColor(AppDesign.text(this.appDark))
              Text(this.filter ? '可以先查看全部作品' : '添加照片、文字或实用卡片，创作自己的桌面作品').fontSize(14).fontColor(AppDesign.muted(this.appDark))
            }.width('100%').padding({ top: 64, bottom: 64 })
          }
        }.width(this.contentWidth()).padding({ top: this.safeTop + 24, bottom: this.safeBottom + 104 }).alignItems(HorizontalAlign.Start)
      }.width('100%').height('100%').align(Alignment.Top).scrollBar(BarState.Auto).edgeEffect(EdgeEffect.Spring).fadingEdge(true, { fadingEdgeLength: LengthMetrics.vp(12) })
      if (!this.creating) {
        Button('+ 新建画布', { type: ButtonType.Capsule, buttonStyle: ButtonStyleMode.NORMAL }).height(48).padding({ left: 24, right: 24 }).fontSize(16)
          .backgroundColor(AppDesign.selected(this.appDark)).fontColor(AppDesign.onSelected(this.appDark)).margin({ bottom: this.safeBottom + 16 })
          .enabled(!this.busy).onClick(() => this.startCreating())
      }
    }.width('100%').height('100%').backgroundColor(AppDesign.background(this.appDark))
  }
}
