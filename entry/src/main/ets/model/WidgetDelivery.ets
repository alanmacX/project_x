import { FridgeState } from './CardSchema';
import { BusinessError } from '@kit.BasicServicesKit';
import { formBindingData, formProvider } from '@kit.FormKit';
import { fileIo } from '@kit.CoreFileKit';
import { prepareWidgetPayload } from './WidgetPayload';

/** Form binding also serializes the large scene; keep that native work off the UI thread. */
@Concurrent
export async function deliverWidget(formId: string, json: string, dim: string, sceneContext:string='', contourCache:string=''): Promise<void> {
  let canvasWidth = 344, canvasHeight = dim === '2*4' ? 172 : (dim === '6*4' ? 516 : 344);
  try { const rect = await formProvider.getFormRect(formId); if (rect.width > 0 && rect.height > 0) { canvasWidth = rect.width; canvasHeight = rect.height; } } catch (_) {}
  const payload = await prepareWidgetPayload(json,contourCache);
  try {
    const canvasId=(JSON.parse(json) as FridgeState).canvasId;
    const revision=Date.now();
    const data: Record<string, Object> = {
      // One atomic scene, rather than four copies of all outlines and image references.
      'scenePacket':JSON.stringify({cards:payload.cards,background:payload.background,canvasId:canvasId??'canvas_main',context:sceneContext,rev:revision}),
      'canvasId':canvasId??'canvas_main',
      'canvasWidth': canvasWidth, 'canvasHeight': canvasHeight, 'rev': revision, 'dim': dim, 'formId': formId, 'formImages': payload.images
    };
    await formProvider.updateForm(formId, formBindingData.createFormBindingData(data));
  } catch(e) {
    if((e as BusinessError).code===16501001)throw new Error('FORM_REMOVED');
    throw e as Error;
  } finally {
    for (const fd of payload.descriptors) { try { fileIo.closeSync(fd); } catch (_) {} }
  }
}
