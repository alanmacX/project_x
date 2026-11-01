import { cardCapabilities } from './TemplateSources';
import { getLibraryPreferences } from './LibraryStorage';
import { capabilityRenderTick } from './CapabilityClock';
import { projectCapabilityData } from './CapabilityProjection';
import { widgetInstances, widgetInstance, WidgetGuard, acquireWidgetDelivery, releaseWidgetDelivery, widgetGuardCurrent } from './WidgetRegistry';
import { canvasRotationEnabled } from './CanvasRotation';
import { systemIsDark } from './SystemAppearance';
import { widgetBoundary, scheduleWidget } from './WidgetSchedule';
import { resolveScheduledScene, sceneWidgetContext, activeSceneRule } from './SceneSchedule';
import { normalizeState } from './CardSchema';
import { canvasKey } from './CanvasLibrary';
import { readCatalog, withScenePolicy, sceneDocumentExists } from './CanvasLibrary';
import { FridgeState } from './CardSchema';
import { hilog } from '@kit.PerformanceAnalysisKit';

import { taskpool } from '@kit.ArkTS';
import { deliverWidget } from './WidgetDelivery';
export { widgetImageKey } from './WidgetImageKey';

interface DeliveredImages { manifest:string; acknowledgedAt:number; completedAt:number; json:string; dim:string; sceneContext:string; }
const deliveredImages:Map<string,DeliveredImages>=new Map();
const deliveryQueues:Map<string,Promise<void>>=new Map();
/** Deliver the scene, including native binding serialization, without blocking app gestures. */
export async function updateWidget(formId: string, json: string, dim: string, sceneContext:string='', contourCache:string='', guard:WidgetGuard|undefined=undefined): Promise<void> {
  const queuedAt=Date.now(),overlapping=deliveryQueues.has(formId);
  // Serialize per form across canvases. Never reuse an unacknowledged image set or let
  // an older task finish after a newer document.
  const pending=(deliveryQueues.get(formId)??Promise.resolve()).catch(()=>{}).then(async()=>{
    const lease=guard?await acquireWidgetDelivery(guard):'';
    if(guard&&!lease)return;
    try{
    if(guard&&!await widgetGuardCurrent(guard))return;
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
    }finally{if(guard&&lease)await releaseWidgetDelivery(guard,lease);}
  });
  deliveryQueues.set(formId,pending);
  try {await pending;}finally{if(deliveryQueues.get(formId)===pending)deliveryQueues.delete(formId);}
}

const liveDeliveries:Map<string,string>=new Map();
const latestPush:Map<string,number>=new Map();
let pushSequence:number=0;
/** Broadcast delivery uses saved documents, including while the editor is hidden. */
export async function refreshStoredWidgets(context:Context):Promise<void> {

  const prefs=await getLibraryPreferences(context);
  for(const instance of await widgetInstances(context)) {
    if(!instance.canvasId)continue;
    const json=await prefs.get(canvasKey(instance.canvasId),'') as string;
    if(!json)continue;
    try{const state=JSON.parse(json) as FridgeState;if(!Array.isArray(state.cards)||state.canvasDimension!==instance.dimension)continue;}catch(_){continue;}
    await pushWidgets(context,json,true);return;
  }
}
export async function pushWidgets(context: Context, json: string, refreshAll:boolean=false): Promise<void> {
  const sequence=++pushSequence;

  const prefs = await getLibraryPreferences(context);
  const instances=await widgetInstances(context);
  const catalogJson = await prefs.get('fridge_canvases_json','') as string;
  const catalog = readCatalog(catalogJson);
  const canvasId = (JSON.parse(json) as FridgeState).canvasId ?? 'canvas_main';
  const sources:Map<string,Promise<string>>=new Map();
  const sourceFor=(id:string):Promise<string>=>{
    let pending=sources.get(id);if(!pending){pending=id===canvasId?Promise.resolve(json):prefs.get(canvasKey(id),'') as Promise<string>;sources.set(id,pending);}return pending;
  };
  const failures:string[]=[];
  await Promise.all(instances.map(async (instance) => {
    const id=instance.id,baseId=instance.canvasId;
    if(!baseId)return;
    let base:FridgeState;
    try {
      const source=await sourceFor(baseId);
      const raw=JSON.parse(source) as FridgeState;
      if(!Array.isArray(raw.cards)||raw.canvasDimension!==instance.dimension)throw new Error('画布损坏或尺寸与绑定不符');
      base=withScenePolicy(normalizeState(raw),catalog,systemIsDark(context));
    }catch(e) {
      // An unrelated damaged canvas must not reject this edit's healthy deliveries
      // or replace its own last displayed artwork with an empty default scene.
      if(baseId!==canvasId){hilog.warn(0,'WidgetSync','skipping unreadable bound canvas');return;}
      throw e as Error;
    }
    if(!refreshAll && baseId!==canvasId && catalog.sceneRules.length===0 && !canvasRotationEnabled(catalog.rotation) && !catalog.scenes.some(c=>c.id===canvasId)){const legacy=activeSceneRule(base,Date.now());if(legacy?.rule.kind!=='canvas'||legacy.rule.targetId!==canvasId)return;}
    latestPush.set(id,Math.max(sequence,latestPush.get(id)??0));
    const scene=await resolveScheduledScene(base,Date.now(),async(targetId:string):Promise<FridgeState|null>=>{
      if(!sceneDocumentExists(catalog,targetId))return null;
      const targetJson=await sourceFor(targetId);if(!targetJson)return null;const target=normalizeState(JSON.parse(targetJson) as FridgeState);return target.canvasDimension===instance.dimension?target:null;
    });
    const projected=await projectCapabilityData(scene.state,context);
    for(const card of projected.cards)for(const cap of cardCapabilities(card))if(cap.k==='battery')hilog.info(0,'BatteryRefresh','form=%{public}s soc=%{public}d charging=%{public}s result=%{public}s',id,cap.percent??-1,String(cap.charging===true),cap.refreshState??'');
    const sceneJson=JSON.stringify(projected);
    const liveKey=instance.revision+':'+projected.cards.map(card=>capabilityRenderTick(card.capability,Math.floor(Date.now()/60000)*60000)).join(',')+':'+sceneJson+':'+sceneWidgetContext(scene);
    if(refreshAll&&liveDeliveries.get(id)===liveKey)return;
    const now=Date.now();
    const deadline=Math.min(widgetBoundary(base,now),widgetBoundary(scene.state,now));
    for (let attempt = 0; attempt < 3; attempt++) {
      try {
        const latest=await widgetInstance(context,id);
        if(!latest||latest.revision!==instance.revision||latest.removed||latestPush.get(id)!==sequence)return;
        await updateWidget(id, sceneJson, instance.dimension,sceneWidgetContext(scene),await prefs.get('fridge_render_contours_v1_'+scene.state.canvasId,'') as string,new WidgetGuard(context,instance));
        await scheduleWidget(prefs,id,deadline,now);
        if(latestPush.get(id)===sequence)liveDeliveries.set(id,liveKey);
        return;
      }
      catch (e) {
        if((e as Error).message==='FORM_REMOVED')return; // Only onRemoveForm may retire an instance.
        if (attempt === 2) { failures.push(id); hilog.warn(0x0000, 'WidgetSync', 'update %{public}s: %{public}s', id, (e as Error).message); }
        else await new Promise<void>((resolve) => { setTimeout(resolve, attempt === 0 ? 120 : 400); });
      }
    }
  }));
  if (failures.length > 0) throw new Error('桌面组件同步未完成');
}
