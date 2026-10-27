import { nextSceneBoundary } from './SceneSchedule';
import { FridgeState } from './CardSchema';
import { nextDataBoundary } from './CapabilityData';
export function refreshMinutes(state:FridgeState,now:number=Date.now()):number {
  let next=Math.min(now+30*60000,nextSceneBoundary(state,now));
  for(const card of state.cards)if(!card.hidden&&card.capability){
    const cap=card.capability;
    next=Math.min(next,cap.k==='battery'?now+5*60000:nextDataBoundary(cap,now));
    if(cap.k==='agenda'&&cap.agendaSource==='system')next=Math.min(next,now+15*60000);
  }
  return Math.max(5,Math.min(30,Math.ceil((next-now)/60000)));
}
