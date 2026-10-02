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
  const prefs = await preferences.getPreferences(context, 'fridge_store');
  const dims = JSON.parse(await prefs.get('fridge_form_dims_json', '{}') as string) as Record<string, string>;
  for (const id of Object.keys(dims)) {
    try {
      await updateWidget(id, json, dims[id]);
    } catch (e) {
      hilog.warn(0x0000, 'WidgetSync', 'update %{public}s: %{public}s', id, (e as Error).message);
    }
  }
}
