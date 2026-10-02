import { formBindingData, formProvider } from '@kit.FormKit';
import { fileIo } from '@kit.CoreFileKit';
import { prepareWidgetPayload } from './WidgetPayload';

/** Form binding also serializes the large scene; keep that native work off the UI thread. */
@Concurrent
export async function deliverWidget(formId: string, json: string, dim: string): Promise<void> {
  let canvasWidth = 344, canvasHeight = dim === '2*4' ? 172 : (dim === '6*4' ? 516 : 344);
  try { const rect = await formProvider.getFormRect(formId); if (rect.width > 0 && rect.height > 0) { canvasWidth = rect.width; canvasHeight = rect.height; } } catch (_) {}
  const payload = await prepareWidgetPayload(json);
  try {
    const data: Record<string, Object> = {
      'fridge': 'board', 'reveal': payload.reveal, 'open': payload.open,
      'background': payload.background, 'cards': payload.cards, 'faceCards': payload.faceCards, 'doorCards': payload.doorCards,
      'canvasWidth': canvasWidth, 'canvasHeight': canvasHeight, 'rev': Date.now(), 'dim': dim, 'formId': formId, 'formImages': payload.images
    };
    await formProvider.updateForm(formId, formBindingData.createFormBindingData(data));
  } finally {
    for (const fd of payload.descriptors) { try { fileIo.closeSync(fd); } catch (_) {} }
  }
}
