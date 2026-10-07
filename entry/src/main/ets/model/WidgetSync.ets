import { widgetBoundary, scheduleWidget } from './WidgetSchedule';
import { resolveScheduledScene, sceneWidgetContext, activeSceneRule } from './SceneSchedule';
import { normalizeState } from './CardSchema';
import { canvasKey } from './CanvasLibrary';
import { readCatalog, boundCanvas } from './CanvasLibrary';
import { FridgeState } from './CardSchema';
import { hilog } from '@kit.PerformanceAnalysisKit';
import preferences from '@ohos.data.preferences';

import { taskpool } from '@kit.ArkTS';
import { deliverWidget } from './WidgetDelivery';
export { widgetImageKey } from './WidgetImageKey';

interface DeliveredImages { manifest:string; acknowledgedAt:number; completedAt:number; json:string; dim:string; sceneContext:string; }
const deliveredImages:Map<string,DeliveredImages>=new Map();
const deliveryQueues:Map<string,Promise<void>>=new Map();
/** Deliver the scene, including native binding serialization, without blocking app gestures. */
export async function updateWidget(formId: string, json: string, dim: string, sceneContext:string='', contourCache:string=''): Promise<void> {
  const queuedAt=Date.now(),overlapping=deliveryQueues.has(formId);
  // Serialize per form across canvases. Never reuse an unacknowledged image set or let
  // an older task finish after a newer document.
  const pending=(deliveryQueues.get(formId)??Promise.resolve()).catch(()=>{}).then(async()=>{
    const previous=deliveredImages.get(formId);
    if(overlapping&&previous&&queuedAt<=previous.completedAt&&Math.floor(queuedAt/60000)===Math.floor(previous.completedAt/60000)&&previous.json===json&&previous.dim===dim&&previous.sceneContext===sceneContext) {
      hilog.info(0,'WidgetPerf','coalesced overlapping identical delivery');return;
    }
    const manifest=previous&&Date.now()-previous.acknowledgedAt<60000?previous.manifest:'';
    try {
      const result=await taskpool.execute(new taskpool.Task(deliverWidget,formId,json,dim,sceneContext,contourCache,queuedAt,manifest)) as string;
      const completedAt=Date.now();
      deliveredImages.set(formId,{manifest:result,acknowledgedAt:manifest&&result===manifest?previous!.acknowledgedAt:completedAt,completedAt:completedAt,json:json,dim:dim,sceneContext:sceneContext});
    }catch(e){deliveredImages.delete(formId);throw e as Error;}
  });
  deliveryQueues.set(formId,pending);
  try {await pending;}finally{if(deliveryQueues.get(formId)===pending)deliveryQueues.delete(formId);}
}

export async function pushWidgets(context: Context, json: string): Promise<void> {
  await preferences.removePreferencesFromCache(context, 'fridge_store');
  const prefs = await preferences.getPreferences(context, 'fridge_store');
  const dims = JSON.parse(await prefs.get('fridge_form_dims_json', '{}') as string) as Record<string, string>;
  const catalogJson = await prefs.get('fridge_canvases_json','') as string;
  const catalog = readCatalog(catalogJson);
  const bindings = JSON.parse(await prefs.get('fridge_form_bindings_json','{}') as string) as Record<string,string>;
  const canvasId = (JSON.parse(json) as FridgeState).canvasId ?? 'canvas_main';
  // Migrate old forms once; subsequent app selection never rebinds them.
  let changed = false;
  for (const id of Object.keys(dims)) { if (!bindings[id]) { bindings[id] = catalog.activeId; changed = true; } }
  if (changed) { await prefs.put('fridge_form_bindings_json',JSON.stringify(bindings)); await prefs.flush(); }
  const failures: string[] = [], removed: string[] = [];
  await Promise.all(Object.keys(dims).map(async (id: string) => {
    const baseId=catalogJson?boundCanvas(bindings,id,catalog):canvasId;
    const base=normalizeState(JSON.parse(baseId===canvasId?json:await prefs.get(canvasKey(baseId),'') as string||'{}') as FridgeState);
    if(baseId!==canvasId) {const current=activeSceneRule(base,Date.now());if(current?.rule.kind!=='canvas'||current.rule.targetId!==canvasId)return;}
    const scene=await resolveScheduledScene(base,Date.now(),async(targetId:string):Promise<FridgeState|null>=>{
      if(!catalog.canvases.some(c=>c.id===targetId))return null;
      const targetJson=targetId===canvasId?json:await prefs.get(canvasKey(targetId),'') as string;return targetJson?normalizeState(JSON.parse(targetJson) as FridgeState):null;
    });
    const sceneJson=scene.ruleId?JSON.stringify(scene.state):baseId===canvasId?json:JSON.stringify(base);
    const now=Date.now();
    const deadline=Math.min(widgetBoundary(base,now),widgetBoundary(scene.state,now));
    for (let attempt = 0; attempt < 3; attempt++) {
      try {
        await updateWidget(id, sceneJson, dims[id],sceneWidgetContext(scene),await prefs.get('fridge_render_contours_v1_'+scene.state.canvasId,'') as string);
        await scheduleWidget(prefs,id,deadline,now);
        return;
      }
      catch (e) {
        if((e as Error).message==='FORM_REMOVED'){removed.push(id);return;}
        if (attempt === 2) { failures.push(id); hilog.warn(0x0000, 'WidgetSync', 'update %{public}s: %{public}s', id, (e as Error).message); }
        else await new Promise<void>((resolve) => { setTimeout(resolve, attempt === 0 ? 120 : 400); });
      }
    }
  }));
  if(removed.length>0) {
    const currentDims=JSON.parse(await prefs.get('fridge_form_dims_json','{}') as string) as Record<string,string>, currentBindings=JSON.parse(await prefs.get('fridge_form_bindings_json','{}') as string) as Record<string,string>;
    const keptDims:Record<string,string>={},keptBindings:Record<string,string>={};
    for(const id of Object.keys(currentDims))if(!removed.includes(id))keptDims[id]=currentDims[id];
    for(const id of Object.keys(currentBindings))if(!removed.includes(id))keptBindings[id]=currentBindings[id];
    await prefs.put('fridge_form_dims_json',JSON.stringify(keptDims));await prefs.put('fridge_form_bindings_json',JSON.stringify(keptBindings));await prefs.flush();
  }
  if (failures.length > 0) throw new Error('桌面组件同步未完成');
}
