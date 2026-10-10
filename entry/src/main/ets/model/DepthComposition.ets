import { FridgeCard, CanvasElement, ElementBox } from './CardSchema';
import { cardViewSnapshot } from './CardViewSnapshot';

/** One subject source per composition. The foreground is an offline, reusable alpha image. */
export function depthElement(card:FridgeCard):CanvasElement|undefined {
  return (card.elements??[]).find(el=>el.kind==='image'&&!el.animated&&el.depthEnabled&&(el.depthForeground??'').length>0&&(el.src??'').length>0);
}
export function hasDepthSubject(card:FridgeCard):boolean {
  return (card.shape==='subject'&&card.subjectPhoto&&card.cutout.length>0)||depthElement(card)!==undefined;
}
export function internalDepth(card:FridgeCard):boolean {
  return (card.subjectDepth&&card.shape==='subject'&&card.subjectPhoto&&card.cutout.length>0)||depthElement(card)!==undefined;
}
/** Exact ImageFit.Cover transform, including source crop. Coordinates are fractions of the photo layer. */
export function depthPhotoBox(element:CanvasElement,width:number,height:number):ElementBox {
  const result=new ElementBox(),aspect=Math.max(.001,width)/Math.max(.001,height),source=Math.max(.001,element.depthSourceAspect||1);
  const w=Math.max(1,source/aspect),h=Math.max(1,aspect/source),crop=element.depthCrop;
  result.x=(1-w)/2+crop.x*w;result.y=(1-h)/2+crop.y*h;result.w=crop.w*w;result.h=crop.h*h;
  return result;
}
export function depthOwner(card:FridgeCard):string {return card.depthPass==='foreground'?card.depthOwnerId:card.id;}
class Projection {source:FridgeCard=new FridgeCard(); z:number=0; pass:string=''; card:FridgeCard=new FridgeCard();}
const cache=new Map<string,Projection>();
function project(source:FridgeCard,pass:string,z:number,id:string=source.id):FridgeCard {
  const key=source.id+':'+pass,old=cache.get(key);
  if(old&&old.source===source&&old.z===z&&old.card.id===id)return old.card;
  const copy=cardViewSnapshot(source);copy.depthPass=pass;copy.z=z;
  copy.id=id;if(pass==='foreground')copy.depthOwnerId=source.id;
  const entry=new Projection();entry.source=source;entry.z=z;entry.pass=pass;entry.card=copy;
  if(!cache.has(key)&&cache.size>=128)cache.delete(cache.keys().next().value as string);
  cache.set(key,entry);return copy;
}
/** Render projection only: editable cards, groups, geometry and resource ownership remain unchanged. */
export function depthRenderCards(cards:FridgeCard[]):FridgeCard[] {
  const output:FridgeCard[]=[],sources=cards.filter(c=>!c.hidden&&(c.groupId??'').length>0&&c.depthGroup&&hasDepthSubject(c));
  const used:string[]=[],occupied=cards.map(c=>c.id);
  for(const card of cards){
    const source=sources.find(c=>c.id===card.id&&!used.includes(c.groupId));
    const members=source?cards.filter(c=>!c.hidden&&c.groupId===source.groupId):[];
    if(source&&members.length>1){
      used.push(source.groupId);
      output.push(project(source,'base',Math.min(...members.map(c=>c.z))-.25));
      let foregroundId=source.id+'::depth';while(occupied.includes(foregroundId))foregroundId+=':';occupied.push(foregroundId);
      output.push(project(source,'foreground',Math.max(...members.map(c=>c.z))+.25,foregroundId));
    }else output.push(card);
  }
  return used.length>0?output.sort((a,b)=>a.z-b.z):output;
}
