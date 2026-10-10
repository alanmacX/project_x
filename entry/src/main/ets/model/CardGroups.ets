import { FridgeCard } from './CardSchema';
import { dragBounds, DragBounds } from './DragGeometry';
export function groupMembers(cards: FridgeCard[], card: FridgeCard): FridgeCard[] { return card.groupId.length > 0 ? cards.filter((c: FridgeCard) => c.groupId === card.groupId) : [card]; }
export function combineCards(cards: FridgeCard[], ids: string[], groupId: string): void {
  const groups = cards.filter((c: FridgeCard) => ids.includes(c.id) && c.groupId.length > 0).map((c: FridgeCard) => c.groupId);
  const members = cards.filter((c: FridgeCard) => ids.includes(c.id) || groups.includes(c.groupId));
  if (members.length < 2) return; members.forEach((c: FridgeCard) => { c.groupId = groupId; c.depthGroup=false; });
}
export function ungroupCards(cards: FridgeCard[], groupId: string): void { if (groupId.length > 0) cards.forEach((c: FridgeCard) => { if (c.groupId === groupId) {c.groupId = '';c.depthGroup=false;} }); }
export function cleanGroups(cards: FridgeCard[]): void { cards.forEach((c: FridgeCard) => { if (c.groupId.length > 0 && cards.filter((p: FridgeCard) => p.groupId === c.groupId).length < 2) {c.groupId = '';c.depthGroup=false;} }); }
/** Intersect every member's recoverable limits; one common delta preserves overlaps and spacing. */
export function groupDragBounds(cards: FridgeCard[], card: FridgeCard, renderedHeight?: number): DragBounds {
  const result = dragBounds(card,renderedHeight);
  for (const member of groupMembers(cards, card)) { const b = dragBounds(member,renderedHeight); result.minX = Math.max(result.minX, card.x + b.minX - member.x); result.maxX = Math.min(result.maxX, card.x + b.maxX - member.x); result.minY = Math.max(result.minY, card.y + b.minY - member.y); result.maxY = Math.min(result.maxY, card.y + b.maxY - member.y); }
  return result;
}

/** Recover saved groups as rigid compositions, never reposition members separately. */
export function clampCanvasGroups(cards: FridgeCard[], renderedHeight?: number): void {
  const seen: string[] = [];
  for(const card of cards) {
    const key=card.groupId ? 'group:'+card.groupId : 'card:'+card.id;if(seen.includes(key))continue;seen.push(key);
    const bounds=groupDragBounds(cards,card,renderedHeight);
    // A group wider than the canvas cannot keep every member visible at once.
    // Preserve its composition rather than collapsing it with independent clamps.
    const x=bounds.minX<=bounds.maxX?Math.max(bounds.minX,Math.min(bounds.maxX,card.x)):card.x;
    const y=bounds.minY<=bounds.maxY?Math.max(bounds.minY,Math.min(bounds.maxY,card.y)):card.y;
    const dx=x-card.x,dy=y-card.y;
    for(const member of groupMembers(cards,card)){member.x+=dx;member.y+=dy;}
  }
}

export class LayerSection { id: string = ''; title: string = ''; ids: string[] = []; }
/** Group rows visually without rewriting the canvas stacking order. */
export function layerSections(cards: FridgeCard[]): LayerSection[] {
  const ordered = cards.slice().sort((a: FridgeCard,b: FridgeCard)=>b.z-a.z), sections: LayerSection[] = [];
  let number = 0;
  for (const card of ordered) {
    const key = card.groupId ? 'group:'+card.groupId : 'card:'+card.id;
    let section = sections.find((item: LayerSection)=>item.id===key);
    if (section === undefined) { section = new LayerSection(); section.id=key; section.title=card.groupId?(cards.some(c=>c.groupId===card.groupId&&c.depthGroup)?'景深组合 ':'组合 ')+(++number):''; sections.push(section); }
    section.ids.push(card.id);
  }
  return sections;
}
