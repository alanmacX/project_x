import { resolveScheduledScene, sceneWidgetContext, nextSceneBoundary, activeSceneRule } from './SceneSchedule';
import { refreshMinutes } from './WidgetRefreshPolicy';
import { normalizeState } from './CardSchema';
import { canvasKey } from './CanvasLibrary';
import { formProvider } from '@kit.FormKit';
import { CanvasCatalog, readCatalog, boundCanvas } from './CanvasLibrary';
import { FridgeState } from './CardSchema';
import { hilog } from '@kit.PerformanceAnalysisKit';
import preferences from '@ohos.data.preferences';

import { taskpool } from '@kit.ArkTS';
import { deliverWidget } from './WidgetDelivery';
export { widgetImageKey } from './WidgetImageKey';

/** Deliver the scene, including native binding serialization, without blocking app gestures. */
export async function updateWidget(formId: string, json: string, dim: string, sceneContext:string='', contourCache:string=''): Promise<void> {
  await taskpool.execute(new taskpool.Task(deliverWidget, formId, json, dim, sceneContext, contourCache));
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
  const deadlines=JSON.parse(await prefs.get('fridge_scene_deadlines_json','{}') as string) as Record<string,number>;
  let deadlineChanged=false;
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
    const deadline=nextSceneBoundary(base,Date.now());
    const minutes=Math.min(refreshMinutes(base),refreshMinutes(scene.state));
    for (let attempt = 0; attempt < 3; attempt++) {
      try {
        await updateWidget(id, sceneJson, dims[id],sceneWidgetContext(scene),await prefs.get('fridge_render_contours_v1_'+scene.state.canvasId,'') as string);
        if(Number.isFinite(deadline)&&minutes<30&&deadlines[id]!==deadline) {
          try {await formProvider.setFormNextRefreshTime(id,minutes);deadlines[id]=deadline;deadlineChanged=true;}catch(_){}
        }else if(!Number.isFinite(deadline)&&deadlines[id]>0){deadlines[id]=0;deadlineChanged=true;}
        return;
      }
      catch (e) {
        if((e as Error).message==='FORM_REMOVED'){removed.push(id);return;}
        if (attempt === 2) { failures.push(id); hilog.warn(0x0000, 'WidgetSync', 'update %{public}s: %{public}s', id, (e as Error).message); }
        else await new Promise<void>((resolve) => { setTimeout(resolve, attempt === 0 ? 120 : 400); });
      }
    }
  }));
  for(const id of removed)if(deadlines[id]>0){deadlines[id]=0;deadlineChanged=true;}
  if(deadlineChanged){const keptDeadlines:Record<string,number>={};for(const id of Object.keys(deadlines))if(deadlines[id]>0&&!removed.includes(id))keptDeadlines[id]=deadlines[id];await prefs.put('fridge_scene_deadlines_json',JSON.stringify(keptDeadlines));await prefs.flush();}
  if(removed.length>0) {
    const currentDims=JSON.parse(await prefs.get('fridge_form_dims_json','{}') as string) as Record<string,string>, currentBindings=JSON.parse(await prefs.get('fridge_form_bindings_json','{}') as string) as Record<string,string>;
    const keptDims:Record<string,string>={},keptBindings:Record<string,string>={};
    for(const id of Object.keys(currentDims))if(!removed.includes(id))keptDims[id]=currentDims[id];
    for(const id of Object.keys(currentBindings))if(!removed.includes(id))keptBindings[id]=currentBindings[id];
    await prefs.put('fridge_form_dims_json',JSON.stringify(keptDims));await prefs.put('fridge_form_bindings_json',JSON.stringify(keptBindings));await prefs.flush();
  }
  if (failures.length > 0) throw new Error('桌面组件同步未完成');
}
