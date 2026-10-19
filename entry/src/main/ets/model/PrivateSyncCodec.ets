import { FridgeState } from './CardSchema';
/** Private sync keeps authored capability data; public sharing remains independently redacted. */
export function privateAssetPaths(state:FridgeState):string[]{
  const paths:string[]=[state.background.src,state.background.photo];
  for(const card of state.cards){paths.push(card.cutout);for(const element of card.elements)paths.push(element.src,element.depthForeground);
    const cap=card.capability;if(cap){paths.push(cap.albumCover??'',cap.albumBackground??'');for(const item of cap.albumItems??[])paths.push(item.cover,item.background);}}
  return Array.from(new Set(paths.filter(path=>typeof path==='string'&&path.length>0)));
}
export function replacePrivateAssets(json:string,from:string,to:string):string{return json.split(JSON.stringify(from)).join(JSON.stringify(to));}
export function privateSyncScene(json:string):FridgeState{
  const state=JSON.parse(json) as FridgeState;
  if(!state||state.schemaVersion!==2||!Array.isArray(state.cards)||state.cards.length>128||!state.background||!['4*4','2*4','2*2','6*4'].includes(state.canvasDimension))throw new Error('云端画布格式不正确');
  for(const card of state.cards){if(!card||!Array.isArray(card.elements))throw new Error('云端卡片格式不正确');
    card.reliefSrc='';card.depthPass='';card.renderContourKey='';
    if(card.capability?.k==='battery'){card.capability.percent=-1;card.capability.charging=false;}
    if(card.capability?.k==='agenda'&&card.capability.agendaSource!=='imported')card.capability.events=[];
  }
  state.background.signature='';return state;
}
