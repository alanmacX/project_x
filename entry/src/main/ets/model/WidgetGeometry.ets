import preferences from '@ohos.data.preferences';
import { formProvider } from '@kit.FormKit';
/** Native launcher rectangles are in vp, matching ArkUI preview dimensions. */
export async function widgetRectangles(context:Context):Promise<Record<string,number[]>>{
  const prefs=await preferences.getPreferences(context,'fridge_store');
  const rects=JSON.parse(await prefs.get('fridge_widget_rects_json','{}') as string) as Record<string,number[]>;
  const dims=JSON.parse(await prefs.get('fridge_form_dims_json','{}') as string) as Record<string,string>;
  const visited:Set<string>=new Set();
  for(const id of Object.keys(dims)){
    if(visited.has(dims[id]))continue;
    try{const rect=await formProvider.getFormRect(id);if(rect.width>0&&rect.height>0){rects[dims[id]]=[rect.width,rect.height];visited.add(dims[id]);}}catch(_){}
  }
  await prefs.put('fridge_widget_rects_json',JSON.stringify(rects));await prefs.flush();return rects;
}
