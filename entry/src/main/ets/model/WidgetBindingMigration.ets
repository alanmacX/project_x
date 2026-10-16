import preferences from '@ohos.data.preferences';
import { readCatalog } from './CanvasLibrary';
/** Freeze the old displayed selection once, before any new instance gets configured. */
export async function independentBindings(prefs:preferences.Preferences):Promise<Record<string,string>>{
  const raw=await prefs.get('fridge_canvases_json','') as string;
  const bindings=JSON.parse(await prefs.get('fridge_form_bindings_json','{}') as string) as Record<string,string>;
  if(raw&&(JSON.parse(raw) as Record<string,Object>)['desktopFollowsSelection']===true){
    const catalog=readCatalog(raw),dims=JSON.parse(await prefs.get('fridge_form_dims_json','{}') as string) as Record<string,string>;
    for(const id of Object.keys(dims))bindings[id]=catalog.activeId;
    await prefs.put('fridge_form_bindings_json',JSON.stringify(bindings));
    await prefs.put('fridge_canvases_json',JSON.stringify(catalog));await prefs.flush();
  }
  return bindings;
}
