import { getLibraryPreferences } from './LibraryStorage';
import { selectWidgetCanvas, WidgetGuard } from './WidgetRegistry';
import { readCatalog, canvasKey, CanvasEntry } from './CanvasLibrary';
import { normalizeState, FridgeState } from './CardSchema';
import { updateWidget } from './WidgetSync';
export { widgetDimension } from './WidgetRegistry';
export class BindableCanvas extends CanvasEntry {dimension:string='';aspect:number=1;cardCount:number=0;}
export async function bindingCanvases(context:Context):Promise<BindableCanvas[]>{
  const prefs=await getLibraryPreferences(context);
  const catalog=readCatalog(await prefs.get('fridge_canvases_json','') as string),items:BindableCanvas[]=[];
  for(const entry of catalog.canvases){try{
    const raw=await prefs.get(canvasKey(entry.id),'') as string;if(!raw)continue;
    const state=normalizeState(JSON.parse(raw) as FridgeState),item=new BindableCanvas();
    item.id=entry.id;item.name=entry.name;item.dimension=state.canvasDimension;item.aspect=state.canvasAspect;item.cardCount=state.cards.filter(c=>!c.hidden).length;items.push(item);
  }catch(_){}}
  return items;
}
export async function bindWidget(context:Context,formId:string,canvasId:string,dimension:string):Promise<void>{
  const instance=await selectWidgetCanvas(context,formId,canvasId,dimension);
  const prefs=await getLibraryPreferences(context);
  const json=await prefs.get(canvasKey(canvasId),'') as string;
  if(!json)throw new Error('画布读取失败，已保留桌面内容');
  await updateWidget(formId,json,dimension,'',await prefs.get('fridge_render_contours_v1_'+canvasId,'') as string,new WidgetGuard(context,instance));
}
