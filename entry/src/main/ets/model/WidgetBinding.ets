import { independentBindings } from './WidgetBindingMigration';
import preferences from '@ohos.data.preferences';
import { readCatalog, canvasKey, CanvasEntry } from './CanvasLibrary';
import { normalizeState, FridgeState } from './CardSchema';
import { updateWidget } from './WidgetSync';
export class BindableCanvas extends CanvasEntry {dimension:string='';aspect:number=1;}
export function widgetDimension(value:Object|undefined):string{return value===2||value==='2'?'2*2':value===3||value==='3'?'2*4':'4*4';}
export async function bindingCanvases(context:Context):Promise<BindableCanvas[]>{
  await preferences.removePreferencesFromCache(context,'fridge_store');const prefs=await preferences.getPreferences(context,'fridge_store');
  const catalog=readCatalog(await prefs.get('fridge_canvases_json','') as string),items:BindableCanvas[]=[];
  for(const entry of catalog.canvases){try{
    const raw=await prefs.get(canvasKey(entry.id),'') as string;if(!raw)continue;
    const state=normalizeState(JSON.parse(raw) as FridgeState),item=new BindableCanvas();
    item.id=entry.id;item.name=entry.name;item.dimension=state.canvasDimension;item.aspect=state.canvasAspect;items.push(item);
  }catch(_){}}
  return items;
}
export async function bindWidget(context:Context,formId:string,canvasId:string,dimension:string):Promise<void>{
  if(!formId)throw new Error('缺少小组件实例');
  await preferences.removePreferencesFromCache(context,'fridge_store');const prefs=await preferences.getPreferences(context,'fridge_store');
  const catalog=readCatalog(await prefs.get('fridge_canvases_json','') as string);
  if(!catalog.canvases.some(c=>c.id===canvasId))throw new Error('画布已不存在');
  const state=normalizeState(JSON.parse(await prefs.get(canvasKey(canvasId),'') as string) as FridgeState);
  if(state.canvasDimension!==dimension)throw new Error('请选择相同尺寸的画布');
  const bindings=await independentBindings(prefs);
  const dims=JSON.parse(await prefs.get('fridge_form_dims_json','{}') as string) as Record<string,string>;
  if(dims[formId]&&dims[formId]!==dimension)throw new Error('小组件尺寸已变化，请重新打开设置');
  bindings[formId]=canvasId;dims[formId]=dimension;
  await prefs.put('fridge_form_bindings_json',JSON.stringify(bindings));await prefs.put('fridge_form_dims_json',JSON.stringify(dims));await prefs.flush();
  await updateWidget(formId,JSON.stringify(state),dimension,'',await prefs.get('fridge_render_contours_v1_'+canvasId,'') as string);
}
