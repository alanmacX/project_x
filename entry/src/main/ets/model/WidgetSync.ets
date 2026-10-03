import { CanvasCatalog, readCatalog, boundCanvas } from './CanvasLibrary';
import { FridgeState } from './CardSchema';
import { hilog } from '@kit.PerformanceAnalysisKit';
import preferences from '@ohos.data.preferences';

import { taskpool } from '@kit.ArkTS';
import { deliverWidget } from './WidgetDelivery';
export { widgetImageKey } from './WidgetImageKey';

/** Deliver the scene, including native binding serialization, without blocking app gestures. */
export async function updateWidget(formId: string, json: string, dim: string): Promise<void> {
  await taskpool.execute(new taskpool.Task(deliverWidget, formId, json, dim));
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
    if (catalogJson && boundCanvas(bindings,id,catalog) !== canvasId) return;
    for (let attempt = 0; attempt < 3; attempt++) {
      try { await updateWidget(id, json, dims[id]); return; }
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
