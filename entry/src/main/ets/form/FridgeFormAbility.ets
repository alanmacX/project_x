import { readCapability } from '../model/CapabilityService';
import { refreshMinutes } from '../model/WidgetRefreshPolicy';
import { needsDataRefresh, capabilityRequestKey, mergeCapabilityResult } from '../model/CapabilityData';
import { readCatalog, canvasKey, boundCanvas } from '../model/CanvasLibrary';
import { FormExtensionAbility, formBindingData, formInfo, formProvider } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import preferences from '@ohos.data.preferences';
import { FridgeState, defaultState, normalizeState } from '../model/FridgeModel';
import { parseCapabilityAction, applyCalendarAction } from '../model/CapabilityActions';
import { fetchWeather } from '../model/WeatherService';
import { weatherNeedsRefresh } from '../model/WeatherRefresh';
import { updateWidget } from '../model/WidgetSync';

const STORE_NAME: string = 'fridge_store';
const KEY_STATE: string = 'fridge_state_json';
const KEY_DIMS: string = 'fridge_form_dims_json';

/** Registered desktop forms refresh after edits; the whiteboard phase has no door scheduler. */
export default class FridgeFormAbility extends FormExtensionAbility {
  private registrationQueue: Promise<void> = Promise.resolve();

  private async loadState(formId: string = ''): Promise<FridgeState> {
    await preferences.removePreferencesFromCache(this.context, STORE_NAME);
    const prefs = await preferences.getPreferences(this.context, STORE_NAME);
    const catalogJson = await prefs.get('fridge_canvases_json','') as string;
    const catalog = readCatalog(catalogJson), bindings = JSON.parse(await prefs.get('fridge_form_bindings_json','{}') as string) as Record<string,string>;
    const id = boundCanvas(bindings,formId,catalog);
    const json = await prefs.get(catalogJson ? canvasKey(id) : KEY_STATE, '') as string;
    return json.length > 0 ? normalizeState(JSON.parse(json) as FridgeState) : defaultState();
  }

  private async loadDims(): Promise<Record<string, string>> {
    const prefs = await preferences.getPreferences(this.context, STORE_NAME);
    return JSON.parse(await prefs.get(KEY_DIMS, '{}') as string) as Record<string, string>;
  }

  private register(formId: string, dim: string, remove: boolean = false, width: number = 0, height: number = 0): Promise<void> {
    this.registrationQueue = this.registrationQueue.catch(() => {}).then(async () => {
      const dims = await this.loadDims();
      const kept: Record<string, string> = {};
      for (const id of Object.keys(dims)) { if (id !== formId) kept[id] = dims[id]; }
      if (!remove) kept[formId] = dim;
      const prefs = await preferences.getPreferences(this.context, STORE_NAME);
      await prefs.put(KEY_DIMS, JSON.stringify(kept));
      const bindings = JSON.parse(await prefs.get('fridge_form_bindings_json','{}') as string) as Record<string,string>;
      if (remove) { const rest: Record<string,string> = {}; for(const key of Object.keys(bindings)) if(key!==formId) rest[key]=bindings[key]; await prefs.put('fridge_form_bindings_json',JSON.stringify(rest)); }
      else { if(!bindings[formId])bindings[formId]=readCatalog(await prefs.get('fridge_canvases_json','') as string).activeId; await prefs.put('fridge_form_bindings_json',JSON.stringify(bindings)); }
      if (width > 0 && height > 0 && width / height >= .3 && width / height <= 3) {
        const specs = JSON.parse(await prefs.get('fridge_canvas_specs_json', '{}') as string) as Record<string, number>;
        specs[dim] = width / height; await prefs.put('fridge_canvas_specs_json', JSON.stringify(specs));
      }
      await prefs.flush();
    });
    return this.registrationQueue;
  }

  private async pushForm(formId: string): Promise<void> {
    const state = await this.loadState(formId);
    const dims = await this.loadDims();
    await updateWidget(formId, JSON.stringify(state), dims[formId] ?? '4*4');
  }
  private async scheduleForm(formId:string):Promise<void> {
    const minutes=refreshMinutes(await this.loadState(formId));
    // Baseline 30-minute refresh is declared in the form profile. Only a nearer boundary
    // needs a one-shot request; editing the scene must not consume its daily quota.
    if(minutes<30)await formProvider.setFormNextRefreshTime(formId,minutes).catch(()=>{});
  }

  onAddForm(want: Want): formBindingData.FormBindingData {
    const id = (want.parameters?.['ohos.extra.param.key.form_identity'] ?? '') as string;
    const value = want.parameters?.['ohos.extra.param.key.form_dimension'];
    const dim: string = value === 3 || value === '3' ? '2*4' : (value === 7 || value === '7' ? '6*4' : '4*4');
    const width = Number(want.parameters?.['ohos.extra.param.key.form_width'] ?? 0), height = Number(want.parameters?.['ohos.extra.param.key.form_height'] ?? 0);
    this.register(id, dim, false, width, height).then(async () => {await this.pushForm(id);await this.refreshDueData(id);await this.scheduleForm(id);}).catch((e: Error) => {
      hilog.error(0x0000, 'FridgeForm', 'add %{public}s', e.message);
    });
    return formBindingData.createFormBindingData({ 'faceCards': '[]', 'doorCards': '[]', 'dim': dim, 'rev': 0, 'canvasWidth': width > 0 ? width : 344, 'canvasHeight': height > 0 ? height : (dim === '2*4' ? 172 : (dim === '6*4' ? 516 : 344)) });
  }

  onUpdateForm(formId: string): void {
    this.actionQueue = this.actionQueue.catch(() => {}).then(async () => {
      await this.pushForm(formId); await this.refreshDueData(formId); await this.refreshDueWeather(formId);await this.scheduleForm(formId);
    }).catch((e: Error) => hilog.error(0x0000, 'FridgeForm', 'update %{public}s', e.message));
  }

  onChangeFormVisibility(status:Record<string,number>):void {
    for(const id of Object.keys(status))if(status[id]===formInfo.VisibilityType.FORM_VISIBLE)this.onUpdateForm(id);
  }
  private async refreshDueData(formId:string):Promise<void> {
    let state=await this.loadState(formId),canvasId=state.canvasId;
    for(const original of state.cards.slice()) {
      const cap=original.capability;if(!cap||!needsDataRefresh(cap))continue;
      const key=capabilityRequestKey(cap),attempted=cap.attemptedAt??0;
      const next=await readCapability(cap,this.context);
      // Only merge this result after reloading the bound canvas; never replace a newer edit or another canvas.
      state=await this.loadState(formId);const card=state.cards.find((c)=>c.id===original.id);
      if(state.canvasId!==canvasId||!card?.capability||capabilityRequestKey(card.capability)!==key||(card.capability.attemptedAt??0)!==attempted)continue;
      if(cap.k==='battery'&&card.capability.percent===next.percent&&card.capability.charging===next.charging&&card.capability.chargeState===next.chargeState&&card.capability.refreshState===next.refreshState)continue;
      card.capability=mergeCapabilityResult(card.capability,next);await this.saveStateAndWidgets(state);
    }
  }
  private actionQueue: Promise<void> = Promise.resolve();
  onFormEvent(formId: string, event: string): void {
    this.actionQueue = this.actionQueue.catch(() => {}).then(async () => {
      const action = parseCapabilityAction(event); if (action === null) return;
      let state = await this.loadState(formId), card = state.cards.find((item) => item.id === action.cardId);
      if (card === undefined) return;
      if (action.operation === 'refreshWeather') {
        const city = card.capability?.k === 'weather' ? card.capability.city ?? '' : '';
        if (city.length === 0) return;
        card.capability!.attemptedAt = Date.now(); card.capability!.refreshState = 'refreshing'; await this.saveStateAndWidgets(state);
        const weather = await fetchWeather(city);
        // Re-read after network I/O so other edits are not overwritten by an old snapshot.
        state = await this.loadState(formId); card = state.cards.find((item) => item.id === action.cardId);
        if (card?.capability?.k !== 'weather' || card.capability.city !== city) return;
        if (weather === null) { card.capability.refreshState = 'failed'; }
        else { card.capability.temp = weather.temp; card.capability.desc = weather.desc; card.capability.updatedAt = Date.now(); card.capability.refreshState = 'done'; }
      } else if (!applyCalendarAction(card, action.operation)) return;
      await this.saveStateAndWidgets(state);
    }).catch((e: Error) => hilog.error(0x0000, 'FridgeForm', 'action %{public}s', e.message));
  }

  private async refreshDueWeather(formId: string): Promise<void> {
    let state = await this.loadState(formId);
    const cities: string[] = [];
    for (const card of state.cards) {
      if (weatherNeedsRefresh(card.capability)) {
        const city = card.capability!.city!.trim(); if (!cities.includes(city)) cities.push(city);
      }
    }
    for (const city of cities) {
      const ids = state.cards.filter((card) => weatherNeedsRefresh(card.capability) && card.capability!.city!.trim() === city).map((card) => card.id);
      const attempted = Date.now();
      for (const card of state.cards) if (ids.includes(card.id)) { card.capability!.attemptedAt = attempted; card.capability!.refreshState = 'refreshing'; }
      await this.saveStateAndWidgets(state);
      const weather = await fetchWeather(city);
      state = await this.loadState(formId);
      for (const card of state.cards) {
        const cap = card.capability;
        if (!ids.includes(card.id) || cap?.k !== 'weather' || cap.city?.trim() !== city || cap.attemptedAt !== attempted) continue;
        cap.refreshState = weather === null ? 'failed' : 'done';
        if (weather !== null) { cap.temp = weather.temp; cap.desc = weather.desc; cap.updatedAt = Date.now(); }
      }
      await this.saveStateAndWidgets(state);
    }
  }

  private async saveStateAndWidgets(state: FridgeState): Promise<void> {
    const prefs = await preferences.getPreferences(this.context, STORE_NAME);
    const catalogJson = await prefs.get('fridge_canvases_json','') as string;
    if (catalogJson) await prefs.put(canvasKey(state.canvasId),JSON.stringify(state));
    else await prefs.put(KEY_STATE, JSON.stringify(state)); await prefs.flush();
    const dims = await this.loadDims();
    const catalog=readCatalog(catalogJson),bindings=JSON.parse(await prefs.get('fridge_form_bindings_json','{}') as string) as Record<string,string>;
    await Promise.all(Object.keys(dims).filter((id:string)=>!catalogJson||boundCanvas(bindings,id,catalog)===state.canvasId).map((id: string) => updateWidget(id, JSON.stringify(state), dims[id]).catch(() => {})));
  }

  onRemoveForm(formId: string): void {
    this.register(formId, '', true).catch((e: Error) => hilog.warn(0x0000, 'FridgeForm', 'remove %{public}s', e.message));
  }
}
