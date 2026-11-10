import { HtmlCardTemplate } from './HtmlCardTemplate';
import { FridgeState, FridgeCard, CanvasBackground } from './CardSchema';
import { cardViewSnapshot } from './CardViewSnapshot';
function historyCard(source:FridgeCard):FridgeCard {
  const copy=cardViewSnapshot(source);copy.html=source.html?JSON.parse(JSON.stringify(source.html)) as HtmlCardTemplate:undefined;
  copy.subjectBorder=source.subjectBorder;copy.renderContourKey=source.renderContourKey;return copy;
}
export class CanvasEditSnapshot {
  id:string='';cards:FridgeCard[]=[];background:CanvasBackground=new CanvasBackground();fillBackground?:CanvasBackground;
}
export function canvasEditSnapshot(state:FridgeState):CanvasEditSnapshot {
  const value=new CanvasEditSnapshot();value.id=state.canvasId;value.cards=state.cards.map(c=>historyCard(c));
  value.background=JSON.parse(JSON.stringify(state.background)) as CanvasBackground;
  value.fillBackground=state.fillBackground?JSON.parse(JSON.stringify(state.fillBackground)) as CanvasBackground:undefined;return value;
}
class CardDelta {beforeIndex:number=0;afterIndex:number=0;before:FridgeCard|null=null;after:FridgeCard|null=null;}
class CanvasEdit {cards:CardDelta[]=[];before:CanvasEditSnapshot=new CanvasEditSnapshot();after:CanvasEditSnapshot=new CanvasEditSnapshot();}
class CanvasStack {past:CanvasEdit[]=[];future:CanvasEdit[]=[];}
function mergeCard(current:FridgeCard,from:FridgeCard,to:FridgeCard):FridgeCard {
  to=historyCard(to);const next=historyCard(current);
  if(JSON.stringify(from.template)!==JSON.stringify(to.template))next.template=to.template;
  if(JSON.stringify(from.subjectDepth)!==JSON.stringify(to.subjectDepth))next.subjectDepth=to.subjectDepth;
  if(JSON.stringify(from.depthCapabilityFront)!==JSON.stringify(to.depthCapabilityFront))next.depthCapabilityFront=to.depthCapabilityFront;
  if(JSON.stringify(from.depthGroup)!==JSON.stringify(to.depthGroup))next.depthGroup=to.depthGroup;
  if(JSON.stringify(from.html)!==JSON.stringify(to.html))next.html=to.html;
  if(JSON.stringify(from.groupId)!==JSON.stringify(to.groupId))next.groupId=to.groupId;
  if(JSON.stringify(from.hidden)!==JSON.stringify(to.hidden))next.hidden=to.hidden;
  if(JSON.stringify(from.x)!==JSON.stringify(to.x))next.x=to.x;
  if(JSON.stringify(from.y)!==JSON.stringify(to.y))next.y=to.y;
  if(JSON.stringify(from.w)!==JSON.stringify(to.w))next.w=to.w;
  if(JSON.stringify(from.h)!==JSON.stringify(to.h))next.h=to.h;
  if(JSON.stringify(from.rot)!==JSON.stringify(to.rot))next.rot=to.rot;
  if(JSON.stringify(from.z)!==JSON.stringify(to.z))next.z=to.z;
  if(JSON.stringify(from.shape)!==JSON.stringify(to.shape))next.shape=to.shape;
  if(JSON.stringify(from.frame)!==JSON.stringify(to.frame))next.frame=to.frame;
  if(JSON.stringify(from.material)!==JSON.stringify(to.material))next.material=to.material;
  if(JSON.stringify(from.paper)!==JSON.stringify(to.paper))next.paper=to.paper;
  if(JSON.stringify(from.ink)!==JSON.stringify(to.ink))next.ink=to.ink;
  if(JSON.stringify(from.capability)!==JSON.stringify(to.capability))next.capability=to.capability;
  if(JSON.stringify(from.capBox)!==JSON.stringify(to.capBox))next.capBox=to.capBox;
  if(JSON.stringify(from.capFree)!==JSON.stringify(to.capFree))next.capFree=to.capFree;
  if(JSON.stringify(from.elements)!==JSON.stringify(to.elements))next.elements=to.elements;
  if(JSON.stringify(from.subjectPhoto)!==JSON.stringify(to.subjectPhoto))next.subjectPhoto=to.subjectPhoto;
  if(JSON.stringify(from.subjectBorder)!==JSON.stringify(to.subjectBorder))next.subjectBorder=to.subjectBorder;
  if(JSON.stringify(from.subjectAspect)!==JSON.stringify(to.subjectAspect))next.subjectAspect=to.subjectAspect;
  if(JSON.stringify(from.subjectInk)!==JSON.stringify(to.subjectInk))next.subjectInk=to.subjectInk;
  if(JSON.stringify(from.subjectVersion)!==JSON.stringify(to.subjectVersion))next.subjectVersion=to.subjectVersion;
  if(JSON.stringify(from.cutout)!==JSON.stringify(to.cutout))next.cutout=to.cutout;
  if(JSON.stringify(from.outline)!==JSON.stringify(to.outline))next.outline=to.outline;
  if(JSON.stringify(from.renderContourKey)!==JSON.stringify(to.renderContourKey))next.renderContourKey=to.renderContourKey;
  if(JSON.stringify(from.inDoor)!==JSON.stringify(to.inDoor))next.inDoor=to.inDoor;
  if(next.template&&from.template&&to.template&&JSON.stringify(from.template.sources)===JSON.stringify(to.template.sources))next.template.sources=current.template?.sources;
  return historyCard(next);
}
/** Undo a user transaction, never replay a whole stale document over live data. */
export class CanvasEditHistory {
  private stacks:Map<string,CanvasStack>=new Map();
  private stack(id:string):CanvasStack {let value=this.stacks.get(id);if(!value){value=new CanvasStack();this.stacks.set(id,value);}return value;}
  canUndo(id:string):boolean{return this.stack(id).past.length>0;}
  canRedo(id:string):boolean{return this.stack(id).future.length>0;}
  record(before:CanvasEditSnapshot,state:FridgeState):boolean {
    if(before.id!==state.canvasId)return false;
    const after=canvasEditSnapshot(state),edit=new CanvasEdit();edit.before=before;edit.after=after;
    const ids=Array.from(new Set(before.cards.concat(after.cards).map(c=>c.id)));
    for(const id of ids){const a=before.cards.find(c=>c.id===id)??null,b=after.cards.find(c=>c.id===id)??null;if(JSON.stringify(a)!==JSON.stringify(b)){const delta=new CardDelta();delta.before=a;delta.after=b;delta.beforeIndex=before.cards.findIndex(c=>c.id===id);delta.afterIndex=after.cards.findIndex(c=>c.id===id);edit.cards.push(delta);}}
    if(edit.cards.length===0&&JSON.stringify(before.background)===JSON.stringify(after.background)&&JSON.stringify(before.fillBackground)===JSON.stringify(after.fillBackground))return false;
    // Card snapshots already live in the deltas. Do not retain a second whole canvas per step.
    edit.before.cards=[];edit.after.cards=[];
    const stack=this.stack(state.canvasId);stack.past.push(edit);if(stack.past.length>40)stack.past.shift();stack.future=[];return true;
  }
  restore(state:FridgeState,redo:boolean):boolean {
    const stack=this.stack(state.canvasId),source=redo?stack.future:stack.past,target=redo?stack.past:stack.future,edit=source.pop();if(!edit)return false;
    for(const delta of edit.cards){const from=redo?delta.before:delta.after,to=redo?delta.after:delta.before,id=(to??from)!.id,index=state.cards.findIndex(c=>c.id===id);
      if(!to){if(index>=0)state.cards.splice(index,1);}else if(index<0){state.cards.splice(Math.max(0,Math.min(state.cards.length,redo?delta.afterIndex:delta.beforeIndex)),0,historyCard(to));}else state.cards[index]=from?mergeCard(state.cards[index],from,to):historyCard(to);
    }
    const from=redo?edit.before:edit.after,to=redo?edit.after:edit.before;
    if(JSON.stringify(from.background)!==JSON.stringify(to.background))state.background=JSON.parse(JSON.stringify(to.background)) as CanvasBackground;
    if(JSON.stringify(from.fillBackground)!==JSON.stringify(to.fillBackground))state.fillBackground=to.fillBackground?JSON.parse(JSON.stringify(to.fillBackground)) as CanvasBackground:undefined;
    state.maxZ=Math.max(state.maxZ,...state.cards.map(c=>c.z));target.push(edit);return true;
  }
}
