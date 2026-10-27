import { readCatalog } from './CanvasLibrary';
import { FridgeState } from './CardSchema';
export function artworkKey(key:string):boolean {
  return key==='fridge_canvases_json'||key==='fridge_state_json'||key==='fridge_saved_timetable_v1'||key.startsWith('fridge_canvas_')&&key!=='fridge_canvas_specs_json';
}
export function validateLibraryValues(values:Record<string,string>):void {
  const catalogJson=values['fridge_canvases_json'];
  if(catalogJson){
    const catalog=readCatalog(catalogJson);
    for(const entry of catalog.canvases.concat(catalog.scenes)){
      const source=values['fridge_canvas_'+entry.id];
      if(!source)throw new Error('画布记录缺失，已停止写入');
      validateCanvas(source,entry.id);
    }
  }else{
    if(Object.keys(values).some(key=>key.startsWith('fridge_canvas_')&&key!=='fridge_canvas_specs_json'))throw new Error('画布目录缺失，已停止写入');
    if(values['fridge_state_json'])validateCanvas(values['fridge_state_json']);
  }
}
export function validateCanvas(json:string,id:string=''):void {
  const state=JSON.parse(json) as FridgeState;
  if(!state||!Array.isArray(state.cards)||id&&state.canvasId!==id)throw new Error('画布记录损坏，已停止写入');
  const ids=new Set<string>();
  for(const card of state.cards){if(!card||typeof card.id!=='string'||!card.id||ids.has(card.id))throw new Error('卡片记录损坏，已停止写入');ids.add(card.id);}
}
