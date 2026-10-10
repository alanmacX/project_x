import lazy { prepareSceneRelief } from './SceneRelief';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { FridgeState } from './CardSchema';
import { BusinessError } from '@kit.BasicServicesKit';
import { formBindingData, formProvider } from '@kit.FormKit';
import { fileIo } from '@kit.CoreFileKit';
import { prepareWidgetPayload } from './WidgetPayload';

/** Form binding also serializes the large scene; keep that native work off the UI thread. */
@Concurrent
export async function deliverWidget(formId: string, json: string, dim: string, sceneContext:string='', contourCache:string='', queuedAt:number=0, previousManifest:string=''): Promise<string> {
  const started=Date.now();
  let canvasWidth = 344, canvasHeight = dim === '2*4' ? 172 : (dim === '6*4' ? 516 : 344);
  try { const rect = await formProvider.getFormRect(formId); if (rect.width > 0 && rect.height > 0) { canvasWidth = rect.width; canvasHeight = rect.height; } } catch (_) {}
  const rectDone=Date.now();
  const payload = await prepareWidgetPayload(json,contourCache,previousManifest,await prepareSceneRelief(JSON.stringify((JSON.parse(json) as FridgeState).cards)));
  const prepared=Date.now();
  try {
    const state=JSON.parse(json) as FridgeState,canvasId=state.canvasId;
    const revision=Date.now();
    const data: Record<string, Object> = {
      // One atomic scene, rather than four copies of all outlines and image references.
      'scenePacket':JSON.stringify({cards:payload.cards,background:payload.background,canvasId:canvasId??'canvas_main',context:sceneContext,aspect:state.canvasAspect,rev:revision}),
      'canvasId':canvasId??'canvas_main',
      'canvasWidth': canvasWidth, 'canvasHeight': canvasHeight, 'rev': revision, 'dim': dim, 'formId': formId
    };
    // Absence means NO_OPERATION for cached images; an empty formImages is not a delta.
    if(Object.keys(payload.images).length>0)data['formImages']=payload.images;
    const binding=formBindingData.createFormBindingData(data),bound=Date.now();
    await formProvider.updateForm(formId,binding);
    hilog.info(0,'WidgetPerf','delivery queue=%{public}d rect=%{public}d prepare=%{public}d bind=%{public}d ipc=%{public}d total=%{public}d images=%{public}d json=%{public}d',queuedAt?started-queuedAt:0,rectDone-started,prepared-rectDone,bound-prepared,Date.now()-bound,Date.now()-(queuedAt||started),Object.keys(payload.images).length,payload.cards.length+payload.background.length);
    return payload.manifest;
  } catch(e) {
    if((e as BusinessError).code===16501001)throw new Error('FORM_REMOVED');
    throw e as Error;
  } finally {
    for (const fd of payload.descriptors) { try { fileIo.closeSync(fd); } catch (_) {} }
  }
}
