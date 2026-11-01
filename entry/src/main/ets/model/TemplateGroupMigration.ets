import { FridgeCard } from './CardSchema';
import { compositionOwner, compositionLayout } from './CompositionCatalog';
/** Coalesce only intact pre-release built-in faces. Free compositions and moved/missing roles remain untouched. */
export function unifyTemplateGroups(cards:FridgeCard[],aspect:number):FridgeCard[]{
 const removed:string[]=[],replacements:Map<string,FridgeCard>=new Map();
 for(const primary of cards){
  const face=compositionOwner(primary.template?.id??'');if(!face||!primary.groupId||primary.template?.id!==face.slots[0].id||primary.rot!==0)continue;
  const members=cards.filter(c=>c.groupId===primary.groupId);if(members.length!==face.slots.length)continue;
  const layout=compositionLayout(face,primary.w/primary.h),scale=primary.w/layout.width,boardHeight=344/Math.max(.3,aspect),baseY=primary.y/470*boardHeight;
  const ordered:FridgeCard[]=[];let valid=true;
  for(const slot of layout.slots){const card=members.find(c=>c.template?.id===slot.id);
   if(!card||(!slot.primary&&card.elements.length>0)||card.hidden!==primary.hidden||card.rot!==0||card.template?.palette!==primary.template?.palette||Math.abs(card.x-(primary.x+slot.x*scale))>.1||Math.abs(card.y/470*boardHeight-(baseY+slot.y*scale))>.1||Math.abs(card.w-slot.w*scale)>.1||Math.abs(card.h-slot.h*scale)>.1){valid=false;break;}ordered.push(card);
  }
  if(!valid)continue;
  const card=JSON.parse(JSON.stringify(primary)) as FridgeCard;card.template!.id=face.id;card.template!.sources=ordered.slice(1).map(c=>c.capability!);card.groupId='';
  replacements.set(primary.id,card);removed.push(...ordered.slice(1).map(c=>c.id));
 }
 return replacements.size?cards.filter(c=>!removed.includes(c.id)).map(c=>replacements.get(c.id)??c):cards;
}
