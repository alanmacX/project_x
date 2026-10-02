import { FridgeCard } from './CardSchema';
import { dragBounds, DragBounds } from './DragGeometry';
export function groupMembers(cards: FridgeCard[], card: FridgeCard): FridgeCard[] { return card.groupId.length > 0 ? cards.filter((c: FridgeCard) => c.groupId === card.groupId) : [card]; }
export function combineCards(cards: FridgeCard[], ids: string[], groupId: string): void {
  const groups = cards.filter((c: FridgeCard) => ids.includes(c.id) && c.groupId.length > 0).map((c: FridgeCard) => c.groupId);
  const members = cards.filter((c: FridgeCard) => ids.includes(c.id) || groups.includes(c.groupId));
  if (members.length < 2) return; members.forEach((c: FridgeCard) => { c.groupId = groupId; });
}
export function ungroupCards(cards: FridgeCard[], groupId: string): void { if (groupId.length > 0) cards.forEach((c: FridgeCard) => { if (c.groupId === groupId) c.groupId = ''; }); }
export function cleanGroups(cards: FridgeCard[]): void { cards.forEach((c: FridgeCard) => { if (c.groupId.length > 0 && cards.filter((p: FridgeCard) => p.groupId === c.groupId).length < 2) c.groupId = ''; }); }
/** Intersect every member's recoverable limits; one common delta preserves overlaps and spacing. */
export function groupDragBounds(cards: FridgeCard[], card: FridgeCard): DragBounds {
  const result = dragBounds(card);
  for (const member of groupMembers(cards, card)) { const b = dragBounds(member); result.minX = Math.max(result.minX, card.x + b.minX - member.x); result.maxX = Math.min(result.maxX, card.x + b.maxX - member.x); result.minY = Math.max(result.minY, card.y + b.minY - member.y); result.maxY = Math.min(result.maxY, card.y + b.maxY - member.y); }
  return result;
}
