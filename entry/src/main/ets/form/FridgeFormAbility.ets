import { resolveScheduledScene, sceneWidgetContext, dismissScene, ScheduledScene } from '../model/SceneSchedule';
import { pushWidgets } from '../model/WidgetSync';
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
import { updateWidget } from '../model/WidgetSync';

const STORE_NAME: string = 'fridge_store';
const KEY_STATE: string = 'fridge_state_json';
const KEY_DIMS: string = 'fridge_form_dims_json';

/** Local schedules are evaluated on refresh/visibility; original documents remain unchanged. */
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

  private async displayedScene(formId:string):Promise<ScheduledScene> {
    const base=await this.loadState(formId);
    const scene=await resolveScheduledScene(base,Date.now(),async(id:string):Promise<FridgeState|null>=>{
      const prefs=await preferences.getPreferences(this.context,STORE_NAME);const catalog=readCatalog(await prefs.get('fridge_canvases_json','') as string);if(!catalog.canvases.some(c=>c.id===id))return null;
      const json=await prefs.get(canvasKey(id),'') as string;return json?normalizeState(JSON.parse(json) as FridgeState):null;
    });
    return scene;
  }
  private async pushForm(formId: string): Promise<void> {
    const scene=await this.displayedScene(formId);
    const state=scene.state;
    const dims = await this.loadDims();
    await updateWidget(formId, JSON.stringify(state), dims[formId] ?? '4*4',sceneWidgetContext(scene));
  }
  private async scheduleForm(formId:string):Promise<void> {
    const minutes=Math.min(refreshMinutes(await this.loadState(formId)),refreshMinutes((await this.displayedScene(formId)).state));
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
      await this.pushForm(formId); await this.refreshDueData(formId); await this.scheduleForm(formId);
    }).catch((e: Error) => hilog.error(0x0000, 'FridgeForm', 'update %{public}s', e.message));
  }

  onChangeFormVisibility(status:Record<string,number>):void {
    for(const id of Object.keys(status))if(status[id]===formInfo.VisibilityType.FORM_VISIBLE)this.onUpdateForm(id);
  }
  private async refreshDueData(formId:string):Promise<void> {
    let state=(await this.displayedScene(formId)).state,canvasId=state.canvasId;
    for(const original of state.cards.slice()) {
      const cap=original.capability;if(!cap||!needsDataRefresh(cap))continue;
      const key=capabilityRequestKey(cap),attempted=cap.attemptedAt??0;
      const next=await readCapability(cap,this.context);
      // Only merge this result after reloading the bound canvas; never replace a newer edit or another canvas.
      state=(await this.displayedScene(formId)).state;const card=state.cards.find((c)=>c.id===original.id);
      if(state.canvasId!==canvasId||!card?.capability||capabilityRequestKey(card.capability)!==key||(card.capability.attemptedAt??0)!==attempted)continue;
      if(cap.k==='battery'&&card.capability.percent===next.percent&&card.capability.charging===next.charging&&card.capability.chargeState===next.chargeState&&card.capability.refreshState===next.refreshState)continue;
      const prefs=await preferences.getPreferences(this.context,STORE_NAME);const raw=await prefs.get(canvasKey(canvasId),'') as string;
      const originalState=raw?normalizeState(JSON.parse(raw) as FridgeState):await this.loadState(formId);const stored=originalState.cards.find(c=>c.id===original.id);
      if(!stored?.capability||capabilityRequestKey(stored.capability)!==key||(stored.capability.attemptedAt??0)!==attempted)continue;
      stored.capability=mergeCapabilityResult(stored.capability,next);await this.saveStateAndWidgets(originalState);
    }
  }
  private actionQueue: Promise<void> = Promise.resolve();
  onFormEvent(formId: string, event: string): void {
    this.actionQueue = this.actionQueue.catch(() => {}).then(async () => {
      let message:Record<string,string>|null=null;try{message=JSON.parse(event) as Record<string,string>;}catch(_){}
      if(message?.operation==='dismissScene') {
        const base=await this.loadState(formId);
        if(dismissScene(base,message.ruleId??'',message.occurrence??'',Date.now())){await this.saveStateAndWidgets(base);await this.scheduleForm(formId);}return;
      }
      const action = parseCapabilityAction(event); if (action === null) return;
      const visible=await this.displayedScene(formId),prefs=await preferences.getPreferences(this.context,STORE_NAME);
      const json=await prefs.get(canvasKey(visible.state.canvasId),'') as string;
      let state=json?normalizeState(JSON.parse(json) as FridgeState):await this.loadState(formId),card=state.cards.find((item)=>item.id===action.cardId);
      if (card === undefined) return;
      if (!applyCalendarAction(card, action.operation)) return;
      await this.saveStateAndWidgets(state);
    }).catch((e: Error) => hilog.error(0x0000, 'FridgeForm', 'action %{public}s', e.message));
  }



  private async saveStateAndWidgets(state: FridgeState): Promise<void> {
    const prefs = await preferences.getPreferences(this.context, STORE_NAME);
    const catalogJson = await prefs.get('fridge_canvases_json','') as string;
    if (catalogJson) await prefs.put(canvasKey(state.canvasId),JSON.stringify(state));
    else await prefs.put(KEY_STATE, JSON.stringify(state)); await prefs.flush();
    await pushWidgets(this.context,JSON.stringify(state));
  }

  onRemoveForm(formId: string): void {
    this.register(formId, '', true).catch((e: Error) => hilog.warn(0x0000, 'FridgeForm', 'remove %{public}s', e.message));
  }
}
