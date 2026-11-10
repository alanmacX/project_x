import { FridgeCard, BOARD_W } from './CardSchema';
import { TemplateFreePlacement } from './CardTemplate';
import { compositionDefinition } from './CompositionCatalog';

/** Relinquish only full-canvas placement; artwork, grouping and layer order remain intact. */
export function releaseTemplateFill(card:FridgeCard,aspect:number):void {
  const t=card.template;if(!t?.fill)return;t.fill=false;
  const p=t.freePlacement;
  if(p){card.x=p.x;card.y=p.y;card.w=p.w;card.h=p.h;card.rot=p.rot;}
  else{card.w=Math.min(260,BOARD_W/Math.max(.3,aspect)-24);card.h=compositionDefinition(t.id)&&aspect>=1.5?card.w/2:card.w;card.x=(BOARD_W-card.w)/2;card.y=12;card.rot=0;}
}
/** Explicit replacement selects the owner; legacy duplicates retain the topmost owner. */
export function enforceSingleTemplateFill(cards:FridgeCard[],aspect:number,preferredId:string=''):string[] {
  const full=cards.filter(card=>card.template?.fill);if(full.length<2)return [];
  const owner=full.find(card=>card.id===preferredId)??full.reduce((a,b)=>b.z>a.z?b:a);
  const released:string[]=[];
  for(const card of full)if(card!==owner){releaseTemplateFill(card,aspect);released.push(card.id);}
  return released;
}
export class TemplateFillPlacement {
  id:string='';fill:boolean=false;x:number=0;y:number=0;w:number=0;h:number=0;rot:number=0;
  freePlacement?:TemplateFreePlacement;
}
export function templateFillState(cards:FridgeCard[]):TemplateFillPlacement[]{
  return cards.filter(card=>card.template!==undefined).map((card:FridgeCard):TemplateFillPlacement=>({id:card.id,fill:card.template!.fill,x:card.x,y:card.y,w:card.w,h:card.h,rot:card.rot,freePlacement:card.template!.freePlacement?JSON.parse(JSON.stringify(card.template!.freePlacement)) as TemplateFreePlacement:undefined}));
}
/** Undo the paired placement change without replacing peers' content or live capability data. */
export function restoreTemplateFillState(entries:TemplateFillPlacement[],cards:FridgeCard[],aspect:number):void {
  for(const entry of entries){const card=cards.find(c=>c.id===entry.id);if(!card?.template)continue;
    card.x=entry.x;card.y=entry.y;card.w=entry.w;card.h=entry.h;card.rot=entry.rot;card.template.fill=entry.fill;
    card.template.freePlacement=entry.freePlacement?JSON.parse(JSON.stringify(entry.freePlacement)) as TemplateFreePlacement:undefined;
  }
  enforceSingleTemplateFill(cards,aspect);
}
