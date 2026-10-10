import { SceneRule } from './SceneScheduleSchema';
import { TimetableLibrary, TimetableData } from './TimetableLibrary';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { restoreStartupLayouts } from './CanvasLayout';
import { taskpool } from '@kit.ArkTS';
import { hydrateCanvas, CanvasLoadResult } from './CanvasLoadWorker';
import { startupMark } from './StartupTrace';
import { CanvasCatalog, CanvasDocument, canvasKey, readCatalog, cloneCanvas, sceneDocumentExists } from './CanvasLibrary';
import { assertCanvasCapacity } from './CanvasCapacity';
import { clampCanvasGroups, cleanGroups } from './CardGroups';
import { LatestWidgetQueue } from './LatestWidgetQueue';
import { primeRenderContours, restoreContourCache, serializeContourCache } from './RenderContours';
import { storageSnapshot } from './StorageSnapshot';
import preferences from '@ohos.data.preferences';
import { formProvider } from '@kit.FormKit';
import { pushWidgets } from './WidgetSync';
import { FridgeState, FridgeCard, CapBlock, defaultState, normalizeState, BOARD_W, BOARD_H } from './CardSchema';
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
  private sceneUpgrade:Promise<void>|null=null;
  private selectionMigrationPending:boolean=false;
  private selectionMigration:Promise<void>|null=null;
  private savedScenes: Record<string,string> = {};
  private contourSnapshot:string='';
  get activeName(): string { return this.catalog.canvases.concat(this.catalog.scenes).find((c) => c.id === this.state.canvasId)?.name ?? '画布'; }
  switchCanvas(id: string): boolean {
    const doc = this.documents.find((c) => c.id === id); if (doc === undefined) return false;
    if(this.catalog.canvases.some(c=>c.id===id))this.catalog.activeId = id; this.state = doc.state; return true;
  }
  async openCanvas(id:string):Promise<boolean> {
    const entry=this.catalog.canvases.concat(this.catalog.scenes).find((c)=>c.id===id);if(!entry||this.prefs===null)return false;
    await this.saveQueue.catch(()=>{});
    if(this.context!==null){await preferences.removePreferencesFromCache(this.context,'fridge_store');this.prefs=await preferences.getPreferences(this.context,'fridge_store');}
    const json=await this.prefs.get(canvasKey(id),'') as string;if(!json)throw new Error('画布记录缺失，已保留目录');
    const raw=JSON.parse(json) as FridgeState;if(!Array.isArray(raw.cards))throw new Error('画布数据损坏');
    const doc=new CanvasDocument();doc.id=id;doc.name=entry.name;doc.state=normalizeState(raw);doc.state.canvasId=id;
    cleanGroups(doc.state.cards);clampCanvasGroups(doc.state.cards,BOARD_W/doc.state.canvasAspect);this.documents=this.documents.filter((c)=>c.id!==id);this.documents.push(doc);this.savedScenes[id]=json;await this.restoreContours(doc.state);return this.switchCanvas(id);
  }
  /** Manual selection commits the catalog before any rendering or widget IPC.
   * All installed forms follow this explicit choice; opening/exporting documents does not rebind them. */
  async selectCanvas(id:string):Promise<boolean> {
    if(!this.catalog.canvases.some(c=>c.id===id))return false;
    await this.save(false);
    if(!await this.openCanvas(id))return false;
    // An explicit choice takes precedence over automatic rotation, retaining its configuration.
    this.catalog.rotation.enabled=false;this.catalog.desktopFollowsSelection=true;
    await this.save(false);
    await Promise.all(Object.values(this.widgetQueues).map(queue=>queue.waitForIdle()));
    if(this.prefs===null)throw new Error('本地存储尚未就绪');
    const dims=JSON.parse(await this.prefs.get('fridge_form_dims_json','{}') as string) as Record<string,string>;
    const bindings=JSON.parse(await this.prefs.get('fridge_form_bindings_json','{}') as string) as Record<string,string>;
    for(const formId of Object.keys(dims))bindings[formId]=id;
    await this.prefs.put('fridge_form_bindings_json',JSON.stringify(bindings));await this.prefs.flush();
    for(const queue of Object.values(this.widgetQueues))queue.invalidate();
    await this.save(true);return true;
  }
  /** One upgrade repair, deferred until startup is idle or the app leaves foreground. */
  repairDesktopSelection():Promise<void> {
    if(this.selectionMigration!==null)return this.selectionMigration;
    if(!this.selectionMigrationPending)return Promise.resolve();
    const pending=this.refreshWidgets().then(()=>{this.selectionMigrationPending=false;});
    this.selectionMigration=pending;
    return pending.finally(()=>{this.selectionMigration=null;});
  }
  /** Time changes the projection even when editable scene bytes are identical. */
  async refreshWidgets():Promise<void> {
    await this.save(false);
    const queue=this.queueFor(this.state.canvasId);await queue.waitForIdle();queue.invalidate();
    await queue.submit(storageSnapshot(this.state));
  }
  /** Export a detached snapshot; sharing an inactive canvas never changes widget bindings. */
  async canvasSnapshot(id: string): Promise<FridgeState> {
    if (id === this.state.canvasId) return normalizeState(JSON.parse(storageSnapshot(this.state)) as FridgeState);
    await this.saveQueue;
    if (!sceneDocumentExists(this.catalog,id) || this.prefs===null) throw new Error('画布不存在');
    const json=await this.prefs.get(canvasKey(id),'') as string;
    if (!json) throw new Error('画布记录缺失');
    const raw=JSON.parse(json) as FridgeState;
    if (!Array.isArray(raw.cards)) throw new Error('画布数据损坏');
    return normalizeState(raw);
  }
  /** Merge acknowledgements from FormExtension without overwriting editor geometry or history. */
  async reloadSceneAcknowledgements():Promise<void> {
    if(this.prefs===null||this.context===null)return;await this.saveQueue.catch(()=>{});const id=this.state.canvasId;
    await preferences.removePreferencesFromCache(this.context,'fridge_store');this.prefs=await preferences.getPreferences(this.context,'fridge_store');
    const catalog=readCatalog(await this.prefs.get('fridge_canvases_json','') as string);for(const rule of this.catalog.sceneRules){const other=catalog.sceneRules.find(r=>r.id===rule.id);if(other&&other.createdAt===rule.createdAt&&other.start===rule.start&&other.timeoutMinutes===rule.timeoutMinutes)rule.dismissed=other.dismissed;}
    const json=await this.prefs.get(canvasKey(id),'') as string;if(!json||this.state.canvasId!==id)return;
    const stored=JSON.parse(json) as FridgeState;
    if(!stored||!Array.isArray(stored.sceneRules))return;
    for(const rule of this.state.sceneRules){const other=stored.sceneRules.find(r=>r!==null&&r.id===rule.id);if(other&&typeof other.dismissed==='string'&&other.dismissed.length<=200&&other.createdAt===rule.createdAt&&other.start===rule.start&&other.end===rule.end&&other.kind===rule.kind&&other.targetId===rule.targetId)rule.dismissed=other.dismissed;}
  }
  upgradeTimedScenes():Promise<void> {
    if(this.sceneUpgrade!==null)return this.sceneUpgrade;
    if(this.catalog.scenePolicyVersion===2)return Promise.resolve();
    const pending=this.migrateTimedScenes();this.sceneUpgrade=pending;
    return pending.finally(()=>{this.sceneUpgrade=null;});
  }
  private async migrateTimedScenes():Promise<void> {
    for(const entry of this.catalog.canvases.slice()){
      let source:FridgeState;try{source=await this.canvasSnapshot(entry.id);}catch(_){hilog.warn(0,'Scene','retaining unreadable legacy canvas during schedule migration');continue;}
      for(const old of source.sceneRules){
        if(old.kind!=='focus'||this.catalog.scenes.length>=12||this.catalog.sceneRules.some(r=>r.migrationKey===entry.id+':'+old.id))continue;const card=source.cards.find(c=>c.id===old.targetId);if(!card)continue;
        // Migrate a detached document: background maintenance cannot temporarily
        // switch the active editor, or restore a canvas the user has since left.
        const doc=this.timedSceneDocument(old.name,card,source),json=storageSnapshot(doc.state);
        await this.saveQueue.catch(()=>{});if(this.prefs===null)throw new Error('本地存储尚未就绪');await this.prefs.put(canvasKey(doc.id),json);await this.prefs.flush();
        this.documents.push(doc);this.savedScenes[doc.id]=json;this.catalog.scenes.push({id:doc.id,name:doc.name});
        const rule=JSON.parse(JSON.stringify(old)) as SceneRule;rule.id=this.newId();rule.migrationKey=entry.id+':'+old.id;rule.targetId=doc.id;rule.centralOnly=true;rule.untilDismissed=false;rule.timeoutMinutes=Math.max(1,Math.min(120,(old.end-old.start+1440)%1440||15));this.catalog.sceneRules.push(rule);await this.save(false);
      }
    }
    this.catalog.scenePolicyVersion=2;await this.save(true);
  }
  private timedSceneDocument(name:string,source:FridgeCard|undefined,base:FridgeState):CanvasDocument {
    const doc=new CanvasDocument();doc.id='scene_'+Date.now()+'_'+(++this.sequence);doc.name=name.trim().slice(0,30)||'定时场景 '+(this.catalog.scenes.length+1);
    doc.state=new FridgeState();doc.state.canvasId=doc.id;doc.state.canvasAspect=base.canvasAspect;doc.state.canvasDimension=base.canvasDimension;
    doc.state.background=normalizeState(JSON.parse(storageSnapshot(base)) as FridgeState).background;doc.state.cards=source?[this.copyCard(source)]:[];return doc;
  }
  createTimedScene(name:string,source?:FridgeCard):string {
    if(this.catalog.scenes.length>=12)throw new Error('最多保存 12 个定时场景');
    const doc=this.timedSceneDocument(name,source,this.state);this.catalog.scenes.push({id:doc.id,name:doc.name});this.documents.push(doc);this.switchCanvas(doc.id);return doc.id;
  }
  copyCard(source:FridgeCard):FridgeCard {
    const card=JSON.parse(JSON.stringify(source)) as FridgeCard;card.id=this.newId();card.groupId='';
    for(const element of card.elements){const old=element.id;element.id=this.newId();if(card.html?.previewElementId===old)card.html.previewElementId=element.id;}return card;
  }
  async copyCardTo(source:FridgeCard,id:string,replace:boolean=false):Promise<void> {
    const target=await this.canvasSnapshot(id),scene=this.catalog.scenes.some(c=>c.id===id);
    if(scene&&target.cards.length>0&&!replace)throw new Error('这个场景已有中央卡片');if(scene&&replace)target.cards=[];
    assertCanvasCapacity(target.cards.length,1);const card=this.copyCard(source);card.z=++target.maxZ;
    if(scene){card.rot=0;card.x=(BOARD_W-card.w)/2;card.y=(BOARD_W/target.canvasAspect-card.h)/2/(BOARD_W/target.canvasAspect/BOARD_H);}
    target.cards.push(card);await this.saveQueue;if(this.prefs===null)throw new Error('本地存储尚未就绪');
    await this.prefs.put(canvasKey(id),storageSnapshot(target));await this.prefs.flush();this.documents=this.documents.filter(c=>c.id!==id);this.savedScenes[id]=storageSnapshot(target);
    const queue=this.queueFor(id);await queue.waitForIdle();queue.invalidate();await queue.submit(storageSnapshot(target));
  }
  async deleteTimedScene(id:string):Promise<void> {
    // A stale callback or wrong identifier must never delete a normal canvas.
    if(!this.catalog.scenes.some(scene=>scene.id===id))return;
    await this.saveQueue.catch(()=>{});
    await Promise.all(Object.values(this.widgetQueues).map(queue=>queue.waitForIdle().catch(()=>{})));
    if(this.state.canvasId===id&&!await this.openCanvas(this.catalog.activeId))throw new Error('无法恢复主画布，已保留场景');
    this.catalog.scenes=this.catalog.scenes.filter(c=>c.id!==id);this.catalog.sceneRules=this.catalog.sceneRules.filter(r=>r.targetId!==id);
    this.documents=this.documents.filter(c=>c.id!==id);await this.save(false);
    if(this.prefs){await this.prefs.delete(canvasKey(id));await this.prefs.delete('fridge_render_contours_v1_'+id);await this.prefs.flush();}
    const saved:Record<string,string>={},contours:Record<string,string>={};for(const key of Object.keys(this.savedScenes))if(key!==id)saved[key]=this.savedScenes[key];for(const key of Object.keys(this.contourCache))if(key!==id)contours[key]=this.contourCache[key];this.savedScenes=saved;this.contourCache=contours;
    const retained:Record<string,LatestWidgetQueue>={};for(const key of Object.keys(this.widgetQueues))if(key!==id)retained[key]=this.widgetQueues[key];this.widgetQueues=retained;
    for(const queue of Object.values(this.widgetQueues))queue.invalidate();await this.save(true);
  }
  adoptCanvas(state:FridgeState):void {
    const entry=this.catalog.canvases.find(c=>c.id===state.canvasId);if(!entry)return;
    const doc=new CanvasDocument();doc.id=entry.id;doc.name=entry.name;doc.state=state;this.documents=this.documents.filter(c=>c.id!==doc.id);this.documents.push(doc);this.switchCanvas(doc.id);
  }
  createCanvas(name: string, source?: FridgeState): string {
    assertCanvasCapacity(0, source?.cards.length ?? 0);
    const id = 'canvas_' + Date.now() + '_' + (++this.sequence);
    const doc = new CanvasDocument(); doc.id = id; doc.name = name.trim().slice(0,40) || '新画布';
    doc.state = source === undefined ? defaultState() : cloneCanvas(source, id); doc.state.canvasId = id;
    this.documents.push(doc); this.catalog.canvases.push({id:id,name:doc.name}); this.switchCanvas(id); return id;
  }
  renameCanvas(name: string, id: string = this.catalog.activeId): void {
    const value = name.trim().slice(0,40); if (!value) return;
    const entry = this.catalog.canvases.find((c) => c.id === id), doc = this.documents.find((c) => c.id === id);
    if (entry) entry.name = value; if (doc) doc.name = value;
  }
  async deleteCanvas(id: string): Promise<void> {
    if (this.catalog.canvases.length <= 1 || !this.catalog.canvases.some((c)=>c.id===id)) return;
    await this.saveQueue.catch(()=>{});
    // Retain legacy course data before deleting the only document that owns it.
    // Await the durable write: a failed flush must leave the canvas intact.
    const removed=await this.canvasSnapshot(id);
    const timetable=removed.cards.map((c)=>c.capability).find((cap)=>cap?.k==='timetable'&&(cap.courses??[]).length>0);
    if(timetable)await this.timetableStorage().save(timetable,true);
    // A publisher already resolving the deleted binding must finish before rebinding.
    await Promise.all(Object.values(this.widgetQueues).map((queue)=>queue.waitForIdle().catch(()=>{})));
    if (this.catalog.activeId === id) await this.openCanvas(this.catalog.canvases.find((c)=>c.id!==id)!.id);
    this.catalog.canvases = this.catalog.canvases.filter((c) => c.id !== id); this.documents = this.documents.filter((c) => c.id !== id);
    if (this.prefs !== null) {
      const bindings = JSON.parse(await this.prefs.get('fridge_form_bindings_json','{}') as string) as Record<string,string>;
      for (const key of Object.keys(bindings)) if (bindings[key] === id) bindings[key] = this.catalog.activeId;
      await this.prefs.put('fridge_form_bindings_json',JSON.stringify(bindings));
      await this.save(false); await this.prefs.delete(canvasKey(id)); await this.prefs.delete('fridge_render_contours_v1_'+id); await this.prefs.flush();
      for (const queue of Object.values(this.widgetQueues)) queue.invalidate();
      const retained: Record<string,LatestWidgetQueue> = {};
      for (const key of Object.keys(this.widgetQueues)) if (key !== id) retained[key] = this.widgetQueues[key];
      this.widgetQueues = retained;
      await this.save(true);
    }
  }
  canvasSpecs: Record<string, number> = {};
  async init(context: Context): Promise<void> {
    await this.timetableLibrary?.settled();this.timetableLibrary=null;
    this.context = context;
    await this.saveQueue.catch(() => {});
    await preferences.removePreferencesFromCache(context, 'fridge_store');
    this.prefs = await preferences.getPreferences(context, 'fridge_store');
    try { this.canvasSpecs = JSON.parse(await this.prefs.get('fridge_canvas_specs_json', '{}') as string) as Record<string, number>; } catch (_) { this.canvasSpecs = {}; }
    try {
      const catalogJson = await this.prefs.get('fridge_canvases_json', '') as string;
      this.catalog = readCatalog(catalogJson);this.selectionMigrationPending=!catalogJson||(JSON.parse(catalogJson) as CanvasCatalog).desktopFollowsSelection!==true; this.lastCatalog = catalogJson; this.documents = []; this.savedScenes = {};
      for (const entry of this.catalog.canvases.filter((c)=>c.id===this.catalog.activeId)) {
        let json = await this.prefs.get(canvasKey(entry.id), '') as string;
        if (!catalogJson) json = await this.prefs.get('fridge_state_json', '') as string;
        if(catalogJson && !json)throw new Error('画布记录缺失');
        startupMark('canvas-input');
        const hydrated=await taskpool.execute(new taskpool.Task(hydrateCanvas,json,entry.id)) as string;
        startupMark('canvas-normalized');
        const doc = new CanvasDocument(); doc.id = entry.id; doc.name = entry.name; const result=JSON.parse(hydrated) as CanvasLoadResult;doc.state=result.state;restoreStartupLayouts(result.layout);
        this.documents.push(doc);
        this.savedScenes[entry.id] = catalogJson ? json : '';
      }
      this.switchCanvas(this.catalog.activeId); startupMark('storage-read');
      await this.restoreContours(this.state);
      await primeRenderContours(this.state.cards, storageSnapshot(this.state)); startupMark('contours-ready');
      this.cacheContours().catch(()=>{});
    } catch (e) { throw new Error('本地卡片数据无法读取，已保留原始记录'); }
  }
  private timetableLibrary:TimetableLibrary|null=null;
  private timetableStorage():TimetableLibrary {
    if(this.timetableLibrary===null)this.timetableLibrary=new TimetableLibrary({
      read:async():Promise<string>=>{if(!this.prefs)throw new Error('本地存储尚未就绪');return await this.prefs.get('fridge_saved_timetable_v1','') as string;},
      write:async(json:string):Promise<void>=>{if(!this.prefs)throw new Error('本地存储尚未就绪');await this.prefs.put('fridge_saved_timetable_v1',json);await this.prefs.flush();}
    });
    return this.timetableLibrary;
  }
  /** Migrate existing timetable cards on first use, including inactive canvases, without startup work. */
  async savedTimetable():Promise<TimetableData|null> {
    const library=this.timetableStorage(),saved=await library.read();if(saved)return saved;
    for(const id of [this.state.canvasId,...this.catalog.canvases.filter((c)=>c.id!==this.state.canvasId).map((c)=>c.id)]) {
      let canvas:FridgeState;
      try{canvas=await this.canvasSnapshot(id);}catch(_){hilog.warn(0,'Timetable','skipping unreadable legacy canvas');continue;}
      const cap=canvas.cards.map((c)=>c.capability).find((c)=>c?.k==='timetable'&&(c.courses??[]).length>0);
      // Another editor operation may have saved a newer timetable during the scan.
      if(cap){await library.save(cap,true);return await library.read();}
    }
    return null;
  }
  rememberTimetable(cap:CapBlock):Promise<void>{return this.timetableStorage().save(cap);}
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
    const started=Date.now();
    const snapshot = storageSnapshot(this.state), id = this.state.canvasId, catalogJson = JSON.stringify(this.catalog);
    const captured=Date.now();
    const pending = this.saveQueue.catch(() => {}).then(async () => {
      if (this.prefs === null) throw new Error('本地存储尚未就绪');
      if (snapshot !== this.savedScenes[id]) {
        // Each canvas owns a separate key. A FormExtension refresh cannot overwrite another canvas.
        if(this.catalog.canvases.some(c=>c.id===id))await this.prefs.put('fridge_state_json', snapshot);
        await this.prefs.put(canvasKey(id), snapshot);
      }
      if (catalogJson !== this.lastCatalog){await this.prefs.put('fridge_canvases_json',catalogJson);for(const queue of Object.values(this.widgetQueues))queue.invalidate();}
      if (snapshot !== this.savedScenes[id] || catalogJson !== this.lastCatalog) await this.prefs.flush();
      this.savedScenes[id] = snapshot; this.lastCatalog = catalogJson;
      if(snapshot!==this.contourSnapshot){try{await this.cacheContours();this.contourSnapshot=snapshot;}catch(_) {}}
    });
    this.saveQueue = pending;
    return pending.then(async () => {
      const persisted=Date.now();
      if(syncWidgets)await this.queueFor(id).submit(snapshot);
      hilog.info(0,'WidgetPerf','save snapshot=%{public}d diskQueue=%{public}d delivery=%{public}d total=%{public}d',captured-started,persisted-captured,Date.now()-persisted,Date.now()-started);
    });
  }
  nextZ(): number { return ++this.state.maxZ; }
  bringToFront(card: FridgeCard): void { card.z = this.nextZ(); }
  findCard(id: string): FridgeCard | null { return this.state.cards.find((c: FridgeCard) => c.id === id) ?? null; }
  addCard(card: FridgeCard): void { this.addCards([card]); }
  /** Validate the whole import before assigning layers or mutating the canvas. */
  addCards(cards: FridgeCard[]): void {
    if(this.catalog.scenes.some(c=>c.id===this.state.canvasId)&&this.state.cards.length+cards.length>1)throw new Error('定时场景只保留一张中央卡片');
    assertCanvasCapacity(this.state.cards.length, cards.length);
    for (const card of cards) { card.z = this.nextZ(); this.state.cards.push(card); }
  }
  removeCard(id: string): void {
    const cap=this.findCard(id)?.capability;
    if(cap?.k==='timetable'&&(cap.courses??[]).length)this.timetableStorage().save(cap,true).catch(()=>hilog.warn(0,'Timetable','unable to retain legacy timetable before deletion'));
    this.state.sceneRules=this.state.sceneRules.filter(r=>r.kind!=='focus'||r.targetId!==id);this.state.sceneLayouts.forEach(l=>l.placements=l.placements.filter(p=>p.id!==id)); this.state.cards = this.state.cards.filter((c: FridgeCard) => c.id !== id); }
  newId(): string { return 'c' + Date.now() + '_' + (++this.sequence); }
}
