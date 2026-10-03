import { CanvasCatalog, CanvasDocument, canvasKey, readCatalog, cloneCanvas } from './CanvasLibrary';
import { cleanGroups } from './CardGroups';
import { LatestWidgetQueue } from './LatestWidgetQueue';
import { primeRenderContours } from './RenderContours';
import { storageSnapshot } from './StorageSnapshot';
import preferences from '@ohos.data.preferences';
import { formProvider } from '@kit.FormKit';
import { clampCardGeometry } from './CanvasLayout';
import { pushWidgets } from './WidgetSync';
import { FridgeState, FridgeCard, defaultState, normalizeState } from './CardSchema';
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
    cleanGroups(doc.state.cards);doc.state.cards.forEach((c)=>clampCardGeometry(c));this.documents=this.documents.filter((c)=>c.id!==id);this.documents.push(doc);this.savedScenes[id]=json;return this.switchCanvas(id);
  }
  createCanvas(name: string, source?: FridgeState): string {
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
      await this.save(false); await this.prefs.delete(canvasKey(id)); await this.prefs.flush();
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
        cleanGroups(doc.state.cards); doc.state.cards.forEach((card: FridgeCard) => clampCardGeometry(card)); this.documents.push(doc);
        this.savedScenes[entry.id] = catalogJson ? json : '';
      }
      this.switchCanvas(this.catalog.activeId);
      await primeRenderContours(this.state.cards, storageSnapshot(this.state));
    } catch (e) { throw new Error('本地卡片数据无法读取，已保留原始记录'); }
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
    });
    this.saveQueue = pending;
    return pending.then(() => syncWidgets ? this.queueFor(id).submit(snapshot) : Promise.resolve());
  }
  nextZ(): number { return ++this.state.maxZ; }
  bringToFront(card: FridgeCard): void { card.z = this.nextZ(); }
  findCard(id: string): FridgeCard | null { return this.state.cards.find((c: FridgeCard) => c.id === id) ?? null; }
  addCard(card: FridgeCard): void { card.z = this.nextZ(); this.state.cards.push(card); }
  removeCard(id: string): void { this.state.cards = this.state.cards.filter((c: FridgeCard) => c.id !== id); }
  newId(): string { return 'c' + Date.now() + '_' + (++this.sequence); }
}
