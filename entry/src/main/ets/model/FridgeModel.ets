import { startupMark } from './StartupTrace';
import { CanvasCatalog, CanvasDocument, canvasKey, readCatalog, cloneCanvas } from './CanvasLibrary';
import { assertCanvasCapacity } from './CanvasCapacity';
import { clampCanvasGroups, cleanGroups } from './CardGroups';
import { LatestWidgetQueue } from './LatestWidgetQueue';
import { primeRenderContours, restoreContourCache, serializeContourCache } from './RenderContours';
import { storageSnapshot } from './StorageSnapshot';
import preferences from '@ohos.data.preferences';
import { formProvider } from '@kit.FormKit';
import { pushWidgets } from './WidgetSync';
import { FridgeState, FridgeCard, defaultState, normalizeState, BOARD_W } from './CardSchema';
export { FridgeState, FridgeCard, CapBlock, CapType, CanvasElement, ElementBox, ShapePoint, BOARD_W, BOARD_H,
  CAPABILITIES, materialColors, shapeRadius, typeLabel, defaultState, normalizeState, serializeFaceCards, serializeDoorCards } from './CardSchema';

export class FridgeStore {
  private prefs: preferences.Preferences | null = null;
  private context: Context | null = null;
  private saveQueue: Promise<void> = Promise.resolve();
  private sequence: number = 0;
  private widgetQueues: Record<string,LatestWidgetQueue> = {};
  private queueFor(id:string):LatestWidgetQueue {
    if(this.widgetQueues[id]===undefined)this.widgetQueues[id]=new LatestWidgetQueue(async(json:string)=>{if(this.context!==null)await pushWidgets(this.context,json);});
    return this.widgetQueues[id];
  }
  state: FridgeState = defaultState();
  catalog: CanvasCatalog = new CanvasCatalog();
  documents: CanvasDocument[] = [];
  private lastCatalog: string = '';
  private savedScenes: Record<string,string> = {};
  get activeName(): string { return this.catalog.canvases.find((c) => c.id === this.catalog.activeId)?.name ?? '画布'; }
  switchCanvas(id: string): boolean {
    const doc = this.documents.find((c) => c.id === id); if (doc === undefined) return false;
    this.catalog.activeId = id; this.state = doc.state; return true;
  }
  async openCanvas(id:string):Promise<boolean> {
    const entry=this.catalog.canvases.find((c)=>c.id===id);if(!entry||this.prefs===null)return false;
    await this.saveQueue.catch(()=>{});
    if(this.context!==null){await preferences.removePreferencesFromCache(this.context,'fridge_store');this.prefs=await preferences.getPreferences(this.context,'fridge_store');}
    const json=await this.prefs.get(canvasKey(id),'') as string;if(!json)throw new Error('画布记录缺失，已保留目录');
    const raw=JSON.parse(json) as FridgeState;if(!Array.isArray(raw.cards))throw new Error('画布数据损坏');
    const doc=new CanvasDocument();doc.id=id;doc.name=entry.name;doc.state=normalizeState(raw);doc.state.canvasId=id;
    cleanGroups(doc.state.cards);clampCanvasGroups(doc.state.cards,BOARD_W/doc.state.canvasAspect);this.documents=this.documents.filter((c)=>c.id!==id);this.documents.push(doc);this.savedScenes[id]=json;await this.restoreContours(doc.state);return this.switchCanvas(id);
  }
  /** Export a detached snapshot; sharing an inactive canvas never changes widget bindings. */
  async canvasSnapshot(id: string): Promise<FridgeState> {
    if (id === this.state.canvasId) return normalizeState(JSON.parse(storageSnapshot(this.state)) as FridgeState);
    await this.saveQueue;
    if (!this.catalog.canvases.some((entry)=>entry.id===id) || this.prefs===null) throw new Error('画布不存在');
    const json=await this.prefs.get(canvasKey(id),'') as string;
    if (!json) throw new Error('画布记录缺失');
    const raw=JSON.parse(json) as FridgeState;
    if (!Array.isArray(raw.cards)) throw new Error('画布数据损坏');
    return normalizeState(raw);
  }
  createCanvas(name: string, source?: FridgeState): string {
    assertCanvasCapacity(0, source?.cards.length ?? 0);
    const id = 'canvas_' + Date.now() + '_' + (++this.sequence);
    const doc = new CanvasDocument(); doc.id = id; doc.name = name.trim().slice(0,40) || '新画布';
    doc.state = source === undefined ? defaultState() : cloneCanvas(source, id); doc.state.canvasId = id;
    this.documents.push(doc); this.catalog.canvases.push({id:id,name:doc.name}); this.switchCanvas(id); return id;
  }
  renameCanvas(name: string): void {
    const value = name.trim().slice(0,40); if (!value) return;
    const entry = this.catalog.canvases.find((c) => c.id === this.catalog.activeId), doc = this.documents.find((c) => c.id === this.catalog.activeId);
    if (entry) entry.name = value; if (doc) doc.name = value;
  }
  async deleteCanvas(id: string): Promise<void> {
    if (this.catalog.canvases.length <= 1 || !this.catalog.canvases.some((c)=>c.id===id)) return;
    await this.saveQueue.catch(()=>{});
    if (this.catalog.activeId === id) await this.openCanvas(this.catalog.canvases.find((c)=>c.id!==id)!.id);
    this.catalog.canvases = this.catalog.canvases.filter((c) => c.id !== id); this.documents = this.documents.filter((c) => c.id !== id);
    if (this.prefs !== null) {
      const bindings = JSON.parse(await this.prefs.get('fridge_form_bindings_json','{}') as string) as Record<string,string>;
      for (const key of Object.keys(bindings)) if (bindings[key] === id) bindings[key] = this.catalog.activeId;
      await this.prefs.put('fridge_form_bindings_json',JSON.stringify(bindings));
      await this.save(false); await this.prefs.delete(canvasKey(id)); await this.prefs.delete('fridge_render_contours_v1_'+id); await this.prefs.flush();
    }
  }
  canvasSpecs: Record<string, number> = {};
  async init(context: Context): Promise<void> {
    this.context = context;
    await this.saveQueue.catch(() => {});
    await preferences.removePreferencesFromCache(context, 'fridge_store');
    this.prefs = await preferences.getPreferences(context, 'fridge_store');
    try { this.canvasSpecs = JSON.parse(await this.prefs.get('fridge_canvas_specs_json', '{}') as string) as Record<string, number>; } catch (_) { this.canvasSpecs = {}; }
    try {
      const catalogJson = await this.prefs.get('fridge_canvases_json', '') as string;
      this.catalog = readCatalog(catalogJson); this.lastCatalog = catalogJson; this.documents = []; this.savedScenes = {};
      for (const entry of this.catalog.canvases.filter((c)=>c.id===this.catalog.activeId)) {
        let json = await this.prefs.get(canvasKey(entry.id), '') as string;
        if (!catalogJson) json = await this.prefs.get('fridge_state_json', '') as string;
        if(catalogJson && !json)throw new Error('画布记录缺失');
        const parsed = json ? JSON.parse(json) as FridgeState : defaultState();
        if (!Array.isArray(parsed.cards)) throw new Error('Invalid cards');
        const doc = new CanvasDocument(); doc.id = entry.id; doc.name = entry.name; doc.state = normalizeState(parsed); doc.state.canvasId = entry.id;
        cleanGroups(doc.state.cards); clampCanvasGroups(doc.state.cards,BOARD_W/doc.state.canvasAspect); this.documents.push(doc);
        this.savedScenes[entry.id] = catalogJson ? json : '';
      }
      this.switchCanvas(this.catalog.activeId); startupMark('storage-read');
      await this.restoreContours(this.state);
      await primeRenderContours(this.state.cards, storageSnapshot(this.state)); startupMark('contours-ready');
      this.cacheContours().catch(()=>{});
    } catch (e) { throw new Error('本地卡片数据无法读取，已保留原始记录'); }
  }
  private contourCache: Record<string,string> = {};
  private async restoreContours(state:FridgeState):Promise<void> {
    if(this.prefs===null)return;
    // A disposable derived cache must never make the original canvas unreadable.
    try {
      const json=await this.prefs.get('fridge_render_contours_v1_'+state.canvasId,'') as string;
      restoreContourCache(state.cards,json);this.contourCache[state.canvasId]=json;
    } catch (_) { /* Rebuild from the immutable master outline on a cache miss. */ }
  }
  private async cacheContours(): Promise<void> {
    if(this.prefs===null)return;
    const id=this.state.canvasId,json=serializeContourCache(this.state.cards);
    if(!json || json===this.contourCache[id])return;
    await this.prefs.put('fridge_render_contours_v1_'+id,json);await this.prefs.flush();this.contourCache[id]=json;
  }
  async refreshCanvasSpecs(): Promise<void> {
    if (this.prefs === null) return;
    const dims = JSON.parse(await this.prefs.get('fridge_form_dims_json', '{}') as string) as Record<string, string>;
    await Promise.all(Object.keys(dims).map(async (id: string) => {
      try {
        const rect = await formProvider.getFormRect(id);
        if (rect.width > 0 && rect.height > 0) this.canvasSpecs[dims[id]] = rect.width / rect.height;
      } catch (_) { /* Hosts that cannot report a rect retain the cached size. */ }
    }));
    await this.prefs.put('fridge_canvas_specs_json', JSON.stringify(this.canvasSpecs)); await this.prefs.flush();
  }
  save(syncWidgets: boolean = true): Promise<void> {
    const snapshot = storageSnapshot(this.state), id = this.state.canvasId, catalogJson = JSON.stringify(this.catalog);
    const pending = this.saveQueue.catch(() => {}).then(async () => {
      if (this.prefs === null) throw new Error('本地存储尚未就绪');
      if (snapshot !== this.savedScenes[id]) {
        // Each canvas owns a separate key. A FormExtension refresh cannot overwrite another canvas.
        await this.prefs.put('fridge_state_json', snapshot);
        await this.prefs.put(canvasKey(id), snapshot);
      }
      if (catalogJson !== this.lastCatalog) await this.prefs.put('fridge_canvases_json',catalogJson);
      if (snapshot !== this.savedScenes[id] || catalogJson !== this.lastCatalog) await this.prefs.flush();
      this.savedScenes[id] = snapshot; this.lastCatalog = catalogJson;
      await this.cacheContours().catch(()=>{});
    });
    this.saveQueue = pending;
    return pending.then(() => syncWidgets ? this.queueFor(id).submit(snapshot) : Promise.resolve());
  }
  nextZ(): number { return ++this.state.maxZ; }
  bringToFront(card: FridgeCard): void { card.z = this.nextZ(); }
  findCard(id: string): FridgeCard | null { return this.state.cards.find((c: FridgeCard) => c.id === id) ?? null; }
  addCard(card: FridgeCard): void { this.addCards([card]); }
  /** Validate the whole import before assigning layers or mutating the canvas. */
  addCards(cards: FridgeCard[]): void {
    assertCanvasCapacity(this.state.cards.length, cards.length);
    for (const card of cards) { card.z = this.nextZ(); this.state.cards.push(card); }
  }
  removeCard(id: string): void { this.state.cards = this.state.cards.filter((c: FridgeCard) => c.id !== id); }
  newId(): string { return 'c' + Date.now() + '_' + (++this.sequence); }
}
