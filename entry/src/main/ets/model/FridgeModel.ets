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
  private saveVersion: number = 0;
  private lastSaved: string = '';
  private widgetQueue: LatestWidgetQueue = new LatestWidgetQueue(async (json: string) => { if (this.context !== null) await pushWidgets(this.context, json); });
  state: FridgeState = defaultState();
  canvasSpecs: Record<string, number> = {};
  async init(context: Context): Promise<void> {
    this.context = context; this.lastSaved = '';
    await this.saveQueue.catch(() => {});
    await preferences.removePreferencesFromCache(context, 'fridge_store');
    this.prefs = await preferences.getPreferences(context, 'fridge_store');
    try { this.canvasSpecs = JSON.parse(await this.prefs.get('fridge_canvas_specs_json', '{}') as string) as Record<string, number>; } catch (_) { this.canvasSpecs = {}; }
    const json = await this.prefs.get('fridge_state_json', '') as string;
    if (json.length === 0) { this.state = defaultState(); return; }
    try {
      const parsed = JSON.parse(json) as FridgeState;
      if (!Array.isArray(parsed.cards)) throw new Error('Invalid cards');
      this.state = normalizeState(parsed); cleanGroups(this.state.cards);
      this.state.cards.forEach((card: FridgeCard) => clampCardGeometry(card));
      await primeRenderContours(this.state.cards, storageSnapshot(this.state)); // Cache derived geometry off the UI thread before interaction.
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
    const snapshot = storageSnapshot(this.state), version = ++this.saveVersion;
    const pending = this.saveQueue.catch(() => {}).then(async () => {
      if (this.prefs === null) throw new Error('本地存储尚未就绪');
      if (snapshot !== this.lastSaved) {
        await this.prefs.put('fridge_state_json', snapshot); await this.prefs.flush();
      }
      this.lastSaved = snapshot;
    });
    this.saveQueue = pending;
    return pending.then(() => syncWidgets && version === this.saveVersion ? this.widgetQueue.submit(snapshot) : Promise.resolve());
  }
  nextZ(): number { return ++this.state.maxZ; }
  bringToFront(card: FridgeCard): void { card.z = this.nextZ(); }
  findCard(id: string): FridgeCard | null { return this.state.cards.find((c: FridgeCard) => c.id === id) ?? null; }
  addCard(card: FridgeCard): void { card.z = this.nextZ(); this.state.cards.push(card); }
  removeCard(id: string): void { this.state.cards = this.state.cards.filter((c: FridgeCard) => c.id !== id); }
  newId(): string { return 'c' + Date.now() + '_' + (++this.sequence); }
}
