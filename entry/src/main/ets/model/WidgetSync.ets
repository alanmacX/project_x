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
  const failures: string[] = [];
  await Promise.all(Object.keys(dims).map(async (id: string) => {
    for (let attempt = 0; attempt < 3; attempt++) {
      try { await updateWidget(id, json, dims[id]); return; }
      catch (e) {
        if (attempt === 2) { failures.push(id); hilog.warn(0x0000, 'WidgetSync', 'update %{public}s: %{public}s', id, (e as Error).message); }
        else await new Promise<void>((resolve) => { setTimeout(resolve, attempt === 0 ? 120 : 400); });
      }
    }
  }));
  if (failures.length > 0) throw new Error('桌面组件同步未完成');
}
