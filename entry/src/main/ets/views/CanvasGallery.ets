import { capabilityRenderTick } from '../model/CapabilityClock';
import { sceneRect } from '../model/SceneLayout';
import { widgetFrameMetrics } from '../model/WidgetFrameGeometry';
import { widgetRectangles } from '../model/WidgetGeometry';
import { GalleryThumbnail, rememberedGalleryPreview, rememberedGalleryRects, cachedGalleryPreview, saveGalleryPreview, removeGalleryPreview } from '../model/GalleryPreviewCache';
import { HdsNavigation, HdsNavigationTitleMode, IconStyleMode, TextStyleMode } from '@kit.UIDesignKit';
import { curves, SymbolGlyphModifier } from '@kit.ArkUI';
import { navigationChrome } from '../model/NavigationChrome';
import { CREATION_DIMENSIONS } from '../model/CanvasSize';
import { image } from '@kit.ImageKit';
import { fileIo } from '@kit.CoreFileKit';
import { taskpool } from '@kit.ArkTS';
import lazy { prepareSceneRelief } from '../model/SceneRelief';
import { CanvasEntry } from '../model/CanvasLibrary';
import { FridgeState, FridgeCard, BOARD_W, BOARD_H } from '../model/CardSchema';
import { GalleryAnchor, GalleryController, GalleryItem, GalleryRow, galleryRows, galleryRowKey, galleryPreviewSize } from '../model/CanvasGallery';
import { AppDesign } from '../model/AppDesign';
import { immersiveChrome, chromeMaterial } from '../model/ChromeMaterial';
import { storageSnapshot } from '../model/StorageSnapshot';
import { depthRenderCards } from '../model/DepthComposition';
import { cardRenderSnapshot } from '../model/CardViewSnapshot';
import { primeRenderContours } from '../model/RenderContours';
import { CanvasBackdrop } from './CanvasBackdrop';
import { CanvasFrame } from './CanvasFrame';
import { CardFace } from './CardFace';

// Native offscreen capture default: measured reading backings need layout feedback before capture.
const GALLERY_MEASUREMENT_DELAY_MS:number=300;

@Component
export struct CanvasGallery {
  @Prop entries: CanvasEntry[] = [];
  @Prop @Watch('reload') revision: number = 0;
  @Prop appDark: boolean = false;
  @Prop @Watch('anchorViewportChanged') viewportWidth: number = 390;
  @Prop @Watch('anchorViewportChanged') viewportHeight:number=0;
  @Prop @Watch('anchorViewportChanged') safeTop: number = 0;
  @Prop @Watch('anchorViewportChanged') safeBottom: number = 0;
  @Prop @Watch('previewWorkChanged') busy: boolean = false;
  @Prop heroId: string = '';
  @Prop @Watch('pageVisibilityChanged') pageVisible: boolean = true;
  @Prop chromeVisible: boolean = true;
  @Prop @Watch('previewTimeChanged') previewMinute: number = 0;
  controller: GalleryController = new GalleryController();
  onLoad: (id: string) => Promise<FridgeState> = async () => new FridgeState();
  onPreviewReady: (id:string) => void = () => {};
  private decodedPreviews:Map<string,string>=new Map();
  private visibleAnchors:Map<string,GalleryAnchor>=new Map();
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
  @State sizeMenuOpen: boolean = false;
  @State sizeMenuX: number = 0;
  @State sizeMenuY: number = 0;
  @State splitOpen: boolean = false;
  @State createLabelWidth:number=64;
  @State createIconWidth:number=22;
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
  private rectsLoaded:boolean=false;
  private previewsPaused:boolean=false;
  private sourceCache:WeakMap<FridgeState,string>=new WeakMap();
  private scroller: Scroller = new Scroller();

  aboutToAppear(): void {
    this.alive = true;
    this.widgetRects=rememberedGalleryRects(this.getUIContext().getHostContext()?.cacheDir??'',this.entries.map((entry:CanvasEntry)=>entry.id));
    this.controller.resumePreviews=()=>this.previewWorkChanged();
    this.controller.pausePreviews=()=>{this.previewsPaused=true;};
    this.controller.aspect=(dimension:string,fallback:number):number=>{const rect=this.widgetRects[dimension];return rect&&rect[0]>0&&rect[1]>0?rect[0]/rect[1]:fallback;};
    this.controller.dismiss=()=>{if(!this.splitOpen)return false;this.setSplitOpen(false);return true;};
    this.controller.prepare=async(id:string)=>{await this.prepareReturn(id);};
    this.controller.previewReady=(id:string):boolean=>this.isPreviewReady(id);
    this.controller.anchor=(id:string,requireFresh:boolean=true):GalleryAnchor|null=>{
      const item=this.items.find((entry:GalleryItem)=>entry.id===id),state=this.documents.get(id);if(!item||(requireFresh&&(!state||!item.preview||item.previewSource!==this.previewSource(state))))return null;
      if(!this.pageVisible){
        const previous=this.visibleAnchors.get(id);if(!previous)return null;
        const retained=new GalleryAnchor();retained.id=id;retained.preview=item.preview;retained.x=previous.x;retained.y=previous.y;retained.w=previous.w;retained.h=previous.h;return retained;
      }
      try{
        const rect=this.getUIContext().getComponentUtils().getRectangleById('canvasPreview_'+id),ui=this.getUIContext();
        const anchor=new GalleryAnchor();anchor.id=id;anchor.preview=item.preview;anchor.x=ui.px2vp(rect.windowOffset.x);anchor.y=ui.px2vp(rect.windowOffset.y);
        anchor.w=ui.px2vp(rect.size.width);anchor.h=ui.px2vp(rect.size.height);
        // The window owner validates visibility and rotation against its measured viewport.
        if(anchor.w<=0||anchor.h<=0)return null;this.visibleAnchors.set(id,anchor);return anchor;
      }catch(_){return null;}
    };
    this.loadItems();
  }
  private anchorViewportChanged():void {this.visibleAnchors.clear();}
  private isPreviewReady(id:string):boolean {
    const item=this.items.find((value:GalleryItem)=>value.id===id),state=this.documents.get(id);
    return !!item?.preview&&!!state&&this.decodedPreviews.get(id)===item.preview&&item.previewSource===this.previewSource(state);
  }
  private previewDecoded(id:string,path:string):void {
    if(this.items.find((item:GalleryItem)=>item.id===id)?.preview!==path)return;
    this.decodedPreviews.set(id,path);
    if(this.pageVisible&&!this.busy)this.controller.anchor(id,false);
    if(this.isPreviewReady(id))this.onPreviewReady(id);
  }
  aboutToDisappear(): void { this.alive = false; this.generation++; }
  private pageVisibilityChanged():void{
    if(!this.pageVisible){this.creating=false;this.sizeMenuOpen=false;this.splitOpen=false;this.renameId='';this.toolsOpen=false;}
  }
  private previewWorkAllowed():boolean {return this.alive&&this.pageVisible&&!this.busy&&!this.previewsPaused;}
  private previewWorkChanged():void {
    if(this.pageVisible&&!this.busy)this.previewsPaused=false;
    if(this.previewWorkAllowed())this.visibleIds.forEach((id:string)=>{this.requestPreview(id);});
  }
  private previewTimeChanged():void{
    this.previewTick=Date.now();
    if(this.alive)this.visibleIds.forEach((id:string)=>{this.requestPreview(id);});
  }
  private reload(): void { if (this.alive) this.loadItems(); }
  private startCreating(dimension: string): void {
    if(this.busy || !CREATION_DIMENSIONS.includes(dimension))return;
    this.sizeMenuOpen=false;this.setSplitOpen(false);this.draftDimension=dimension;this.draftName='';this.creating=true;
  }
  private setSplitOpen(open: boolean): void {
    this.getUIContext().animateTo({duration:420,curve:curves.springMotion(.42,.78)},()=>this.splitOpen=open);
  }
  private openSizeMenu():void {
    if(this.busy)return;
    this.setSplitOpen(false);this.sizeMenuX=this.viewportWidth-96;this.sizeMenuY=this.safeTop+60;
    try{
      const ui=this.getUIContext(),rect=ui.getComponentUtils().getRectangleById('galleryAddCanvas');
      if(rect.size.width>0){this.sizeMenuX=ui.px2vp(rect.windowOffset.x+rect.size.width);this.sizeMenuY=ui.px2vp(rect.windowOffset.y+rect.size.height)+4;}
    }catch(_){}
    this.sizeMenuOpen=true;
  }
  private sizeChoices(): MenuElement[] {
    return CREATION_DIMENSIONS.map((dimension:string):MenuElement=>({value:dimension.replace('*','×')+' 画布',action:()=>this.startCreating(dimension)}));
  }
  private createNamedCanvas(): void {
    if(this.busy || !this.draftName.trim())return;
    this.creating=false;
    this.onCreate(this.draftName.trim(), this.draftDimension);
  }
  private splitWidth(): number {return Math.min(344,this.viewportWidth-32);}
  private splitSizeWidth():number{return (this.splitWidth()-48-24)/3;}
  private splitOffset(index:number):number{return -this.splitWidth()/2+this.splitSizeWidth()/2+index*(this.splitSizeWidth()+8);}
  @Builder
  creationSheet() {
    Column({space:18}) {
      Row({space:8}) {
        Text('命名画布').fontSize(22).fontWeight(FontWeight.Bold).fontColor(AppDesign.text(this.appDark)).layoutWeight(1)
        Button('取消',{type:ButtonType.Capsule,buttonStyle:ButtonStyleMode.NORMAL}).height(44).width(56).padding(0)
          .backgroundColor(Color.Transparent).fontColor(AppDesign.text(this.appDark)).onClick(()=>this.creating=false)
        Button('创建',{type:ButtonType.Capsule}).height(44).width(80).padding(0)
          .backgroundColor(AppDesign.selected(this.appDark)).fontColor(AppDesign.onSelected(this.appDark))
          .enabled(!this.busy&&!!this.draftName.trim()).onClick(()=>this.createNamedCanvas())
      }.width('100%')
      Text(this.draftDimension.replace('*','×')+' · 桌面小组件').fontSize(14).fontColor(AppDesign.muted(this.appDark)).width('100%')
      TextInput({text:this.draftName,placeholder:'输入画布名称'}).id('newCanvasName').height(52).maxLength(40)
        .backgroundColor(AppDesign.control(this.appDark)).fontColor(AppDesign.text(this.appDark)).borderRadius(16)
        .defaultFocus(true).enterKeyType(EnterKeyType.Done).onChange((value:string)=>this.draftName=value).onSubmit(()=>this.createNamedCanvas())
    }.width('100%').padding({left:24,right:24,top:24,bottom:24})
  }
  @Builder
  splitCreationButton() {
    Stack() {
      // All four pieces share the original capsule's centre. Persistent nodes stretch apart and merge back.
      ForEach(CREATION_DIMENSIONS,(dimension:string,index:number)=>{
        Button(dimension.replace('*','×'),{type:ButtonType.Capsule,buttonStyle:ButtonStyleMode.NORMAL})
          .width(this.splitSizeWidth()).height(48).fontSize(16).fontWeight(FontWeight.Medium)
          .backgroundColor(AppDesign.selected(this.appDark)).fontColor(AppDesign.onSelected(this.appDark))
          .scale({x:this.splitOpen?1:.35,y:this.splitOpen?1:.82}).opacity(this.splitOpen?1:0)
          .translate({x:this.splitOpen?this.splitOffset(index):0,y:this.splitOpen?0:6})
          .hitTestBehavior(this.splitOpen?HitTestMode.Default:HitTestMode.None).enabled(!this.busy&&this.splitOpen)
          .accessibilityLevel(this.splitOpen?'auto':'no-hide-descendants').accessibilityText('新建 '+dimension.replace('*','×')+' 画布')
          .onClick(()=>this.startCreating(dimension))
      },(dimension:string)=>dimension)
      Button({type:ButtonType.Capsule,buttonStyle:ButtonStyleMode.NORMAL}) {
        Stack() {
          Text('新建画布').maxLines(1).fontSize(16).fontWeight(FontWeight.Medium).fontColor(AppDesign.onSelected(this.appDark))
            .translate({x:(this.createIconWidth+8)/2}).opacity(this.splitOpen?0:1)
            .onSizeChange((_:SizeOptions,size:SizeOptions)=>{const width=Number(size.width);if(width>0&&Math.abs(width-this.createLabelWidth)>.1)this.createLabelWidth=width;})
            .animation({duration:this.splitOpen?90:180,delay:this.splitOpen?0:140,curve:Curve.EaseOut})
          SymbolGlyph($r('sys.symbol.plus')).fontSize(22).fontColor([AppDesign.onSelected(this.appDark)])
            .translate({x:this.splitOpen?0:-(this.createLabelWidth+8)/2}).rotate({angle:this.splitOpen?45:0})
            .onSizeChange((_:SizeOptions,size:SizeOptions)=>{const width=Number(size.width);if(width>0&&Math.abs(width-this.createIconWidth)>.1)this.createIconWidth=width;})
        }.width('100%').height('100%').hitTestBehavior(HitTestMode.None)
      }.width(this.splitOpen?48:Math.min(this.splitWidth(),Math.max(144,this.createLabelWidth+this.createIconWidth+58))).height(48).padding(0).backgroundColor(AppDesign.selected(this.appDark))
        .translate({x:this.splitOpen?(this.splitWidth()-48)/2:0})
        .accessibilityText(this.splitOpen?'收起新建画布':'新建画布，选择尺寸').enabled(!this.busy)
        .onClick(()=>this.setSplitOpen(!this.splitOpen))
    }.width(this.splitWidth()).height(56).margin({bottom:this.safeBottom+12})
      .opacity(this.pageVisible?1:0).hitTestBehavior(this.pageVisible?HitTestMode.Transparent:HitTestMode.None)
  }
  /** Returning only refreshes the active in-memory document. Preserve every
   * other row and avoid disk indexes / host IPC on the navigation path. */
  private async prepareReturn(id:string):Promise<void>{
    const previous=this.items.find((item:GalleryItem)=>item.id===id);
    if(!previous){await this.loadItems(id);return;}
    const generation=this.generation,state=await this.onLoad(id);
    if(!this.alive||generation!==this.generation)return;
    this.previewTick=Date.now();this.documents.set(id,state);
    if(previous.loaded&&!previous.failed&&previous.dimension===state.canvasDimension&&previous.aspect===state.canvasAspect)return;
    this.items=this.items.map((item:GalleryItem):GalleryItem=>{
      if(item.id!==id)return item;
      const next=new GalleryItem();next.id=item.id;next.name=item.name;next.dimension=state.canvasDimension;next.aspect=state.canvasAspect;
      next.loaded=true;next.preview=item.preview;next.previewSource=item.previewSource;return next;
    });
  }
  private async loadItems(refreshId:string=''): Promise<void> {
    const generation = ++this.generation;this.previewTick=Date.now();
    const context=this.getUIContext().getHostContext();const cacheDir=context?.cacheDir??'';
    const previous=new Map<string,GalleryItem>();this.items.forEach((item:GalleryItem)=>previous.set(item.id,item));
    this.items=this.entries.map((entry:CanvasEntry):GalleryItem=>{
      const old=previous.get(entry.id),cached=rememberedGalleryPreview(cacheDir,entry.id),item=new GalleryItem();
      item.id=entry.id;item.name=entry.name;item.dimension=old?.dimension??cached?.dimension??'';item.aspect=old?.aspect??cached?.aspect??1;
      item.preview=old?.preview||cached?.path||'';item.previewSource=old?.previewSource||cached?.source||'';item.loaded=old?.loaded??false;return item;
    });
    const ids=new Set(this.entries.map((entry:CanvasEntry)=>entry.id));
    this.documents.forEach((_:FridgeState,id:string)=>{if(!ids.has(id))this.documents.delete(id);});
    // Restore all image/size metadata before slow documents or native host queries can delay another row.
    await Promise.all(this.entries.map(async(entry:CanvasEntry)=>{
      const cached=await cachedGalleryPreview(cacheDir,entry.id);
      if(!cached||!this.alive||generation!==this.generation)return;
      this.items=this.items.map((item:GalleryItem):GalleryItem=>{
        if(item.id!==entry.id||item.preview)return item;
        const next=new GalleryItem();next.id=item.id;next.name=item.name;next.dimension=cached.dimension;next.aspect=cached.aspect;
        next.preview=cached.path;next.previewSource=cached.source;return next;
      });
    }));
    if(!this.alive||generation!==this.generation)return;
    if(context&&!this.rectsLoaded){try{this.widgetRects=await widgetRectangles(context);this.rectsLoaded=true;}catch(_){}}
    if(!this.alive||generation!==this.generation)return;
    await Promise.all(this.entries.map(async(entry:CanvasEntry)=>{
      if(refreshId&&entry.id!==refreshId&&this.documents.has(entry.id))return;
      try {
        const state=await this.onLoad(entry.id);
        if(!this.alive||generation!==this.generation)return;
        this.documents.set(entry.id,state);
        this.items=this.items.map((old:GalleryItem):GalleryItem=>{
          if(old.id!==entry.id)return old;
          const item=new GalleryItem();item.id=old.id;item.name=old.name;item.dimension=state.canvasDimension;item.aspect=state.canvasAspect;
          item.loaded=true;item.preview=old.preview;item.previewSource=old.previewSource;return item;
        });
        // Navigation waits for metadata only. Decode/snapshot visible items once the transition settles.
        if(this.visibleIds.has(entry.id))this.requestPreview(entry.id);
      }catch(_){
        if(!this.alive||generation!==this.generation)return;
        this.items=this.items.map((item:GalleryItem):GalleryItem=>{
          if(item.id!==entry.id)return item;
          const failed=new GalleryItem();failed.id=item.id;failed.name=item.name;failed.dimension=item.dimension;failed.aspect=item.aspect;
          failed.preview=item.preview;failed.previewSource=item.previewSource;failed.failed=true;return failed;
        });
      }
    }));
  }
  private requestPreview(id: string, force:boolean=false): Promise<void> {
    const item=this.items.find((value:GalleryItem)=>value.id===id),state=this.documents.get(id);
    if(!this.previewWorkAllowed()||!item?.loaded||!state||(item.preview&&item.previewSource===this.previewSource(state)))return Promise.resolve();
    if(this.pendingIds.has(id))return this.previewQueue.then(()=>{if(this.alive)return this.requestPreview(id,force);return Promise.resolve();});
    this.pendingIds.add(id);
    const generation=this.generation;
    this.previewQueue=this.previewQueue.catch(()=>{}).then(async()=>{
      try {
        if(!this.previewWorkAllowed()||generation!==this.generation||(!force&&!this.visibleIds.has(id)))return;
        const context=this.getUIContext().getHostContext();if(!context)return;
        const source=this.previewSource(state);
        const subjects=state.cards.filter((card:FridgeCard)=>card.shape==='subject'&&card.cutout.startsWith('file://'));
        const relief:Record<string,string>=subjects.length?JSON.parse(await taskpool.execute(new taskpool.Task(prepareSceneRelief,JSON.stringify(subjects))) as string) as Record<string,string>:{};
        state.cards.forEach((card:FridgeCard)=>{card.reliefSrc=relief[card.id]??card.reliefSrc;});
        await primeRenderContours(state.cards, storageSnapshot(state));
        if(!this.previewWorkAllowed()||generation!==this.generation)return;
        // syncLoad only settles image decoding. Capability labels also measure text and their paper surface
        // through onSizeChange; forcing delay=0 snapshots the fallback height before those layout passes.
        const layoutDelay=state.cards.some((card:FridgeCard)=>!card.hidden&&card.capability!==null)?GALLERY_MEASUREMENT_DELAY_MS:0;
        let pixel:image.PixelMap;
        try{pixel=await this.getUIContext().getComponentSnapshot().createFromBuilder(()=>{this.artwork(state);},layoutDelay,true,
          {scale:1,waitUntilRenderFinished:true});}
        catch(_){
          // A missing photo must not suppress every other card in this canvas preview.
          pixel=await this.getUIContext().getComponentSnapshot().createFromBuilder(()=>{this.artwork(state);},layoutDelay,false,
            {scale:1,waitUntilRenderFinished:true});
        }
        const path=context.cacheDir+'/gallery_v2_'+id+'_'+Date.now()+'.png';
        const packer=image.createImagePacker();let file:fileIo.File|null=null;
        try{file=await fileIo.open(path,fileIo.OpenMode.CREATE|fileIo.OpenMode.READ_WRITE);await packer.packToFile(pixel,file.fd,{format:'image/png',quality:100});}
        finally{try{if(file)fileIo.closeSync(file.fd);}finally{try{await packer.release();}finally{await pixel.release();}}}
        if(!this.previewWorkAllowed()||generation!==this.generation){fileIo.unlink(path).catch(()=>{});return;}
        const cached=new GalleryThumbnail();cached.source=source;cached.path='file://'+path;
        cached.dimension=state.canvasDimension;cached.aspect=state.canvasAspect;cached.rects=this.widgetRects;
        await saveGalleryPreview(context.cacheDir,id,cached);
        if(!this.alive||generation!==this.generation)return;
        this.items=this.items.map((value:GalleryItem):GalleryItem=>{
          if(value.id!==id)return value;
          const next=new GalleryItem();next.id=value.id;next.name=value.name;next.dimension=value.dimension;next.aspect=value.aspect;
          next.loaded=true;next.preview=cached.path;next.previewSource=source;return next;
        });
      }catch(_){
        // Keep the last good image while an updated disposable preview is unavailable.
        if(this.alive&&generation===this.generation)this.items=this.items.map((value:GalleryItem):GalleryItem=>{
          if(value.id!==id||value.preview)return value;
          const failed=new GalleryItem();failed.id=value.id;failed.name=value.name;failed.dimension=value.dimension;failed.aspect=value.aspect;
          failed.loaded=true;failed.failed=true;return failed;
        });
      }finally{this.pendingIds.delete(id);}
    });
    return this.previewQueue;
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
  private previewSource(state:FridgeState):string {
    let source=this.sourceCache.get(state);if(source===undefined){source=storageSnapshot(state);this.sourceCache.set(state,source);}
    return 'v11-measured-capability:'+source+':hostAspect='+this.previewAspect(state)+':corner='+this.previewFrameCorner(state)+':ticks='+state.cards.map((card:FridgeCard)=>capabilityRenderTick(card.capability,this.previewTick)).join(',');
  }
  private artworkCards(state: FridgeState): FridgeCard[] {
    return depthRenderCards(state.cards.filter((card: FridgeCard) => !card.hidden).map((card: FridgeCard) => cardRenderSnapshot(card)))
      .sort((a: FridgeCard, b: FridgeCard) => a.z - b.z);
  }
  @Builder
  artwork(state: FridgeState) {
    Stack({ alignContent: Alignment.TopStart }) {
      CanvasBackdrop({ snapshot:true, sceneBackground: state.background, showFrame: false }).width('100%').height('100%')
      ForEach(this.artworkCards(state), (card: FridgeCard) => {
        CardFace({ snapshot:true, card: card, scaleFactor: 1, tick: capabilityRenderTick(card.capability,this.previewTick), widget: true })
          .width(card.w).height(card.h).position(sceneRect(card,BOARD_W,BOARD_W/this.previewAspect(state)))
          .rotate({ angle: card.rot, centerX: 0, centerY: '100%' }).zIndex(card.z)
      }, (card: FridgeCard) => card.id)
      if (state.background.frameStyle !== 'none') {
        CanvasFrame({ snapshot:true, material: state.background.frameMaterial, style: state.background.frameStyle, cornerPercent: this.previewFrameCorner(state) }).width('100%').height('100%').zIndex(100000)
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
      next.aspect = value.aspect; next.preview = value.preview; next.previewSource = value.previewSource; next.loaded = value.loaded; next.failed = value.failed; return next;
    });
    this.renameId = '';
  }
  @Builder
  tile(item: GalleryItem, wide: boolean) {
    Column({ space: 4 }) {
      Button({ type: ButtonType.ROUNDED_RECTANGLE, buttonStyle: ButtonStyleMode.NORMAL }) {
        Stack() {
          if (item.preview) { Image(item.preview).syncLoad(true).width('100%').height('100%').objectFit(ImageFit.Contain).draggable(false).onComplete(()=>this.previewDecoded(item.id,item.preview)).onError(() => this.previewUnavailable(item.id, item.preview)) }
          else {
            Column({ space: 10 }) {
              SymbolGlyph($r('sys.symbol.square_stack_3d')).fontSize(28).fontColor([AppDesign.muted(this.appDark)])
              if(item.failed){Text('预览暂不可用').fontSize(12).fontColor(AppDesign.muted(this.appDark))}
            }
          }
        }.width('100%').height(this.previewHeight(item, wide)).backgroundColor(Color.Transparent).clip(true)
          .opacity(this.heroId===item.id ? .001 : 1)
      }.id('canvasPreview_'+item.id).width('100%').height(this.previewHeight(item, wide)).padding(0).borderRadius(widgetFrameMetrics(this.tileWidth(item),this.previewHeight(item,wide)).radius).clip(true).backgroundColor(Color.Transparent)
        .accessibilityText('打开画布 ' + item.name).onClick(() => { if(!this.busy){this.controller.anchor(item.id,false);this.onOpen(item.id);} })
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
      // Native background sampling must remain in window coordinates: never cache or transform this root.
      Column().width('100%').height('100%').backgroundColor(AppDesign.background(this.appDark))
        .opacity(this.pageVisible?1:0).hitTestBehavior(HitTestMode.None)
      // Keep scrolling artwork under the system safe area; only its initial content inset avoids the title.
      HdsNavigation() {
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
        .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP])
        .opacity(this.pageVisible?1:0).align(Alignment.Top).clip(false).scrollBar(BarState.Auto).edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
      }.titleMode(HdsNavigationTitleMode.MINI)
        .titleBar({ enableComponentSafeArea: true, avoidLayoutSafeArea: true, content: {
          title: { mainTitle: '我的画布', subTitle: this.entries.length + ' 张画布' },
          menu: { maxCount: 3, value: [
            { content: { icon: new SymbolGlyphModifier($r('sys.symbol.square_and_arrow_down')).fontSize(22).fontColor([AppDesign.text(this.appDark)]),
              label: '导入作品', type: IconStyleMode.NORMAL, isEnabled: !this.busy, action: () => this.onImport() } },
            { content: { icon: new SymbolGlyphModifier($r('sys.symbol.plus')).fontSize(22).fontColor([AppDesign.text(this.appDark)]),
              label: '新建画布', componentId:'galleryAddCanvas', type: IconStyleMode.NORMAL, isEnabled: !this.busy, action: () => this.openSizeMenu() } },
            { content: { label: '更多', type: TextStyleMode.NORMAL, isEnabled: !this.busy, action: () => this.toolsOpen = true } }
          ] }
        }, style: navigationChrome(this.appDark, true) })
        .bindToScrollable([this.scroller]).hideBackButton(true).hideToolBar(true).mode(NavigationMode.Stack)
        .width('100%').height('100%').align(Alignment.Top)
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
        .hideTitleBar(!this.chromeVisible)
        .hitTestBehavior(HitTestMode.Transparent).clip(false).backgroundColor(Color.Transparent)
      Column().width(1).height(1).position({ x: this.viewportWidth - 24, y: this.safeTop + 60 }).hitTestBehavior(HitTestMode.None).accessibilityLevel('no')
        .bindMenu(this.toolsOpen, [{ value: '创作 Skill · Gitee', action: () => { this.toolsOpen = false; this.onSkill('https://gitee.com/alanmac/fridge-signing-system'); } },
          { value: '创作 Skill · GitHub', action: () => { this.toolsOpen = false; this.onSkill('https://github.com/alanmacX/fridge-creating-skill'); } }],
          { systemMaterial: chromeMaterial(this.appDark), backgroundColor: AppDesign.popup(this.appDark), onDisappear: () => this.toolsOpen = false })
      Column().width(1).height(1).position({x:this.sizeMenuX,y:this.sizeMenuY}).hitTestBehavior(HitTestMode.None).accessibilityLevel('no')
        .bindMenu(this.sizeMenuOpen,this.sizeChoices(),{placement:Placement.BottomRight,systemMaterial:chromeMaterial(this.appDark),backgroundColor:AppDesign.popup(this.appDark),onDisappear:()=>this.sizeMenuOpen=false})
      this.splitCreationButton()
    }.width('100%').height('100%').backgroundColor(Color.Transparent)
      .bindSheet($$this.creating,this.creationSheet,{height:SheetSize.FIT_CONTENT,preferType:this.viewportWidth>=600?SheetType.CENTER:SheetType.BOTTOM,
        width:Math.min(480,this.viewportWidth),keyboardAvoidMode:SheetKeyboardAvoidMode.TRANSLATE_AND_RESIZE,showClose:false,dragBar:false,backgroundColor:AppDesign.background(this.appDark),onDisappear:()=>this.creating=false})
  }
}
