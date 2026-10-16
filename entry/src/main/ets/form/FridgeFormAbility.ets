import { registerWidget, removeWidget, promoteWidget, widgetInstance, widgetInstances, WidgetGuard } from '../model/WidgetRegistry';
import { widgetDimension } from '../model/WidgetBinding';
import { canvasRotationEnabled } from '../model/CanvasRotation';
import { systemIsDark } from '../model/SystemAppearance';
import { resolveScheduledScene, sceneWidgetContext, dismissScene, ScheduledScene } from '../model/SceneSchedule';
import { pushWidgets } from '../model/WidgetSync';
import { widgetBoundary, scheduleWidget } from '../model/WidgetSchedule';
import { needsDataRefresh, capabilityRequestKey, mergeCapabilityResult } from '../model/CapabilityData';
import { readCatalog, withScenePolicy, sceneDocumentExists, canvasKey } from '../model/CanvasLibrary';
import { FormExtensionAbility, formBindingData, formProvider } from '@kit.FormKit';
import { Want, Configuration } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import preferences from '@ohos.data.preferences';
import { FridgeState, defaultState, normalizeState } from '../model/CardSchema';
import { parseCapabilityAction, applyCalendarAction } from '../model/CapabilityActions';
import { updateWidget } from '../model/WidgetSync';

const STORE_NAME: string = 'fridge_store';
const KEY_STATE: string = 'fridge_state_json';

/** Local schedules are evaluated on system refresh; original documents remain unchanged. */
export default class FridgeFormAbility extends FormExtensionAbility {
  private registrationQueue: Promise<void> = Promise.resolve();
  private appearanceDark:boolean|null=null;
  onConfigurationUpdate(config:Configuration):void {
    if(config.colorMode===undefined)return;this.appearanceDark=config.colorMode===0;
    this.actionQueue=this.actionQueue.catch(()=>{}).then(async()=>{
      const prefs=await preferences.getPreferences(this.context,STORE_NAME),catalog=readCatalog(await prefs.get('fridge_canvases_json','') as string);
      if(!canvasRotationEnabled(catalog.rotation)||catalog.rotation.mode!=='theme')return;
      for(const id of Object.keys(await this.loadDims())){await this.pushForm(id);await this.scheduleForm(id);}
    }).catch((e:Error)=>hilog.warn(0,'FridgeForm','theme refresh %{public}s',e.message));
  }

  private async loadState(formId: string = ''): Promise<FridgeState> {
    await preferences.removePreferencesFromCache(this.context, STORE_NAME);
    const prefs = await preferences.getPreferences(this.context, STORE_NAME);
    const catalogJson = await prefs.get('fridge_canvases_json','') as string;
    const catalog = readCatalog(catalogJson),instance=await widgetInstance(this.context,formId);
    if(!instance||instance.removed)throw new Error('小组件实例尚未就绪');
    const id=instance.canvasId;
    if(!id){const empty=defaultState();empty.canvasId='';empty.canvasDimension=instance.dimension;empty.background.mode='transparent';empty.background.frameStyle='none';return empty;}
    if(!catalog.canvases.some(c=>c.id===id))throw new Error('绑定画布已不存在，已保留桌面内容');
    const json=await prefs.get(canvasKey(id),'') as string;
    if(!json)throw new Error('绑定画布无法读取，已保留桌面内容');
    const source=JSON.parse(json) as FridgeState;
    if(!Array.isArray(source.cards)||source.canvasDimension!==instance.dimension)throw new Error('绑定画布尺寸不符，已保留桌面内容');
    return withScenePolicy(normalizeState(source),catalog,(this.appearanceDark??systemIsDark(this.context)));
  }

  private async loadDims():Promise<Record<string,string>>{
    const dims:Record<string,string>={};for(const item of await widgetInstances(this.context))dims[item.id]=item.dimension;return dims;
  }
  private register(formId:string,dim:string,remove:boolean=false,width:number=0,height:number=0,editFormId:string='',temporary:boolean=false):Promise<void>{
    this.registrationQueue=this.registrationQueue.catch(()=>{}).then(async()=>{
      if(remove){await removeWidget(this.context,formId);return;}
      const instance=await registerWidget(this.context,formId,dim,editFormId,temporary);
      if(!instance.ownerId&&instance.kind==='desktop'&&width>0&&height>0){
        const prefs=await preferences.getPreferences(this.context,STORE_NAME);
        const rects=JSON.parse(await prefs.get('fridge_widget_rects_json','{}') as string) as Record<string,number[]>;
        rects[instance.dimension]=[width,height];await prefs.put('fridge_widget_rects_json',JSON.stringify(rects));await prefs.flush();
      }
    });return this.registrationQueue;
  }

  private async displayedScene(formId:string):Promise<ScheduledScene> {
    const base=await this.loadState(formId);
    const scene=await resolveScheduledScene(base,Date.now(),async(id:string):Promise<FridgeState|null>=>{
      const prefs=await preferences.getPreferences(this.context,STORE_NAME);const catalog=readCatalog(await prefs.get('fridge_canvases_json','') as string);if(!sceneDocumentExists(catalog,id))return null;
      const json=await prefs.get(canvasKey(id),'') as string;if(!json)return null;const target=normalizeState(JSON.parse(json) as FridgeState);return target.canvasDimension===base.canvasDimension?target:null;
    });
    return scene;
  }
  private async contourCache(canvasId:string):Promise<string> {
    const prefs=await preferences.getPreferences(this.context,STORE_NAME);
    return await prefs.get('fridge_render_contours_v1_'+canvasId,'') as string;
  }
  private async pushForm(formId:string):Promise<void>{
    const instance=await widgetInstance(this.context,formId);if(!instance||instance.removed||!instance.canvasId)return; // Unknown/unbound restoration cannot clear cached desktop artwork.
    const scene=await this.displayedScene(formId);
    await updateWidget(formId,JSON.stringify(scene.state),instance.dimension,sceneWidgetContext(scene),await this.contourCache(scene.state.canvasId),new WidgetGuard(this.context,instance));
  }
  private async scheduleForm(formId:string):Promise<void> {
    const base=await this.loadState(formId);
    const scene=await resolveScheduledScene(base,Date.now(),async(id:string):Promise<FridgeState|null>=>{
      const prefs=await preferences.getPreferences(this.context,STORE_NAME);
      const json=await prefs.get(canvasKey(id),'') as string;if(!json)return null;const target=normalizeState(JSON.parse(json) as FridgeState);return target.canvasDimension===base.canvasDimension?target:null;
    });
    const prefs=await preferences.getPreferences(this.context,STORE_NAME),now=Date.now();
    await scheduleWidget(prefs,formId,Math.min(widgetBoundary(base,now),widgetBoundary(scene.state,now)),now);
  }

  onAddForm(want: Want): formBindingData.FormBindingData {
    const id = (want.parameters?.['ohos.extra.param.key.form_identity'] ?? '') as string;
    const value = want.parameters?.['ohos.extra.param.key.form_dimension'];
    const dim=widgetDimension(value);
    const width = Number(want.parameters?.['ohos.extra.param.key.form_width'] ?? 0), height = Number(want.parameters?.['ohos.extra.param.key.form_height'] ?? 0);
    const editFormId=want.parameters?.['ohos.extra.param.key.edit_form_id'];
    this.register(id,dim,false,width,height,typeof editFormId==='string'?editFormId:'',want.parameters?.['ohos.extra.param.key.form_temporary']===true).then(async()=>{
      await this.pushForm(id);
      if(await this.refreshDueData(id))await this.pushForm(id);await this.scheduleForm(id);
    }).catch((e: Error) => {
      hilog.error(0x0000, 'FridgeForm', 'add %{public}s', e.message);
    });
    // An onAdd callback may also restore an existing widget after a package update.
    // Return no empty scene fields: they would erase its last artwork before async storage loads.
    const initial:Record<string,Object>={'formId':id};return formBindingData.createFormBindingData(initial);
  }

  onCastToNormalForm(formId:string):void{this.registrationQueue=this.registrationQueue.catch(()=>{}).then(()=>promoteWidget(this.context,formId));this.registrationQueue.catch((e:Error)=>hilog.warn(0,'FridgeForm','promote %{public}s',e.message));}
  onUpdateForm(formId: string): void {
    this.actionQueue = this.actionQueue.catch(() => {}).then(async () => {
      try {await this.refreshDueData(formId);}catch(e){hilog.warn(0,'FridgeForm','local data refresh: %{public}s',(e as Error).message);}
      await this.pushForm(formId); await this.scheduleForm(formId);
    }).catch((e: Error) => hilog.error(0x0000, 'FridgeForm', 'update %{public}s', e.message));
  }

  private async refreshDueData(formId:string):Promise<boolean> {
    let changed=false;
    const visibleScene=await this.displayedScene(formId);let state=visibleScene.state,canvasId=state.canvasId;
    for(const original of state.cards.slice()) {
      const cap=original.capability;if(!cap||!needsDataRefresh(cap))continue;
      const key=capabilityRequestKey(cap),attempted=cap.attemptedAt??0;
      const service=await import('../model/CapabilityService');
      const next=await service.readCapability(cap,this.context);
      // Only merge this result after reloading the bound canvas; never replace a newer edit or another canvas.
      state=(await this.displayedScene(formId)).state;const card=state.cards.find((c)=>c.id===original.id);
      if(state.canvasId!==canvasId||!card?.capability||capabilityRequestKey(card.capability)!==key||(card.capability.attemptedAt??0)!==attempted)continue;
      if(cap.k==='battery'&&card.capability.percent===next.percent&&card.capability.charging===next.charging&&card.capability.chargeState===next.chargeState&&card.capability.refreshState===next.refreshState)continue;
      const prefs=await preferences.getPreferences(this.context,STORE_NAME);const sourceId=original.id===visibleScene.focusId?visibleScene.focusSourceId||canvasId:canvasId;const raw=await prefs.get(canvasKey(sourceId),'') as string;
      const originalState=raw?normalizeState(JSON.parse(raw) as FridgeState):await this.loadState(formId);const stored=originalState.cards.find(c=>c.id===original.id);
      if(!stored?.capability||capabilityRequestKey(stored.capability)!==key||(stored.capability.attemptedAt??0)!==attempted)continue;
      stored.capability=mergeCapabilityResult(stored.capability,next);await this.saveState(originalState);changed=true;
    }
    return changed;
  }
  private actionQueue: Promise<void> = Promise.resolve();
  onFormEvent(formId: string, event: string): void {
    this.actionQueue = this.actionQueue.catch(() => {}).then(async () => {
      let message:Record<string,string>|null=null;try{message=JSON.parse(event) as Record<string,string>;}catch(_){}
      if(message?.operation==='configure'){formProvider.openFormEditAbility('WidgetConfigAbility',formId,true);return;}
      if(message?.operation==='dismissScene') {
        const base=await this.loadState(formId);
        if(dismissScene(base,message.ruleId??'',message.occurrence??'',Date.now())){if(!base.scenePolicyV2){await this.saveStateAndWidgets(base);await this.scheduleForm(formId);return;}const prefs=await preferences.getPreferences(this.context,STORE_NAME),catalog=readCatalog(await prefs.get('fridge_canvases_json','') as string);catalog.sceneRules=base.sceneRules;await prefs.put('fridge_canvases_json',JSON.stringify(catalog));await prefs.flush();await this.pushForm(formId);await this.scheduleForm(formId);}return;
      }
      const action = parseCapabilityAction(event); if (action === null) return;
      const visible=await this.displayedScene(formId),prefs=await preferences.getPreferences(this.context,STORE_NAME);
      const json=await prefs.get(canvasKey(action.cardId===visible.focusId?visible.focusSourceId||visible.state.canvasId:visible.state.canvasId),'') as string;
      let state=json?normalizeState(JSON.parse(json) as FridgeState):await this.loadState(formId),card=state.cards.find((item)=>item.id===action.cardId);
      if (card === undefined) return;
      if (!applyCalendarAction(card, action.operation)) return;
      await this.saveStateAndWidgets(state);
    }).catch((e: Error) => hilog.error(0x0000, 'FridgeForm', 'action %{public}s', e.message));
  }



  private async saveState(state: FridgeState): Promise<void> {
    const prefs = await preferences.getPreferences(this.context, STORE_NAME);
    const catalogJson = await prefs.get('fridge_canvases_json','') as string;
    if (catalogJson) await prefs.put(canvasKey(state.canvasId),JSON.stringify(state));
    else await prefs.put(KEY_STATE, JSON.stringify(state)); await prefs.flush();
  }
  private async saveStateAndWidgets(state: FridgeState): Promise<void> {
    await this.saveState(state);
    await pushWidgets(this.context,JSON.stringify(state));
  }

  onRemoveForm(formId: string): void {
    this.register(formId, '', true).catch((e: Error) => hilog.warn(0x0000, 'FridgeForm', 'remove %{public}s', e.message));
  }
}
