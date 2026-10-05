import { nextSceneBoundary } from './SceneSchedule';
import { FridgeState } from './CardSchema';
import { nextDataBoundary } from './CapabilityData';
export function refreshMinutes(state:FridgeState,now:number=Date.now()):number {
  let next=Math.min(now+30*60000,nextSceneBoundary(state,now));
  for(const card of state.cards)if(card.capability)next=Math.min(next,nextDataBoundary(card.capability,now));
  return Math.max(5,Math.min(30,Math.ceil((next-now)/60000)));
}
