import { FridgeState, CapBlock } from './CardSchema';
import { cardCapabilities } from './TemplateSources';
import { needsDataRefresh } from './CapabilityData';
import { readCapability } from './CapabilityService';
/** Detached display values, including the private sources of an atomic template. */
export async function projectCapabilityData(state:FridgeState,context:Context):Promise<FridgeState>{
 const values:CapBlock[][]=await Promise.all(state.cards.map(async(card):Promise<CapBlock[]>=>Promise.all(cardCapabilities(card).map(async(cap):Promise<CapBlock>=>{
   if(!(cap.k==='battery'||cap.k==='agenda'&&cap.agendaSource==='system'))return cap;
   const value=needsDataRefresh(cap)?await readCapability(cap,context):JSON.parse(JSON.stringify(cap)) as CapBlock;value.attemptedAt=undefined;value.updatedAt=undefined;return value;
 }))));
 if(!values.some((caps,index)=>JSON.stringify(caps)!==JSON.stringify(cardCapabilities(state.cards[index]))))return state;
 const next=JSON.parse(JSON.stringify(state)) as FridgeState;
 values.forEach((caps,index)=>{const card=next.cards[index];if(card.capability)card.capability=caps[0];if(card.template?.sources)card.template.sources=caps.slice(card.capability?1:0);});return next;
}
