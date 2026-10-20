import { FridgeState, CapBlock } from './CardSchema';
import { needsDataRefresh } from './CapabilityData';
import { readCapability } from './CapabilityService';
/** Detached display values: never save a stale document over editor changes. */
export async function projectCapabilityData(state:FridgeState,context:Context):Promise<FridgeState>{
  const values:(CapBlock|null)[]=await Promise.all(state.cards.map(async(card):Promise<CapBlock|null>=>{
    const cap=card.capability;if(!cap||!(cap.k==='battery'||cap.k==='agenda'&&cap.agendaSource==='system'))return null;
    const value=needsDataRefresh(cap)?await readCapability(cap,context):JSON.parse(JSON.stringify(cap)) as CapBlock;
    // Request bookkeeping is not a pixel change. Keep it in durable source records only.
    value.attemptedAt=undefined;value.updatedAt=undefined;return value;
  }));
  if(!values.some((value,index)=>value!==null&&JSON.stringify(value)!==JSON.stringify(state.cards[index].capability)))return state;
  const next=JSON.parse(JSON.stringify(state)) as FridgeState;
  values.forEach((value,index)=>{if(value)next.cards[index].capability=value;});return next;
}
