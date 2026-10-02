import { FridgeCard } from './CardSchema';
import { cardViewSnapshot } from './CardViewSnapshot';

/** Each gesture is one undo step; immutable subject contours stay shared. */
export class CardEditHistory {
  private previous: FridgeCard[] = [];
  private following: FridgeCard[] = [];
  private current: FridgeCard | null = null;
  private signature: string = '';
  private activeGroup: string = '';
  private key(card: FridgeCard): string {
    return JSON.stringify([card.id, card.x, card.y, card.w, card.h, card.rot, card.z, card.shape,
      card.frame, card.material, card.paper, card.ink, card.capability, card.capBox, card.elements,
      card.subjectPhoto, card.subjectBorder, card.subjectAspect, card.subjectInk, card.subjectVersion, card.cutout, card.inDoor]);
  }
  reset(card: FridgeCard): void {
    this.current = cardViewSnapshot(card); this.signature = this.key(card);
    this.previous = []; this.following = []; this.activeGroup = '';
  }
  record(card: FridgeCard, group: string = ''): void {
    if (this.current === null || this.current.id !== card.id) { this.reset(card); return; }
    const signature = this.key(card); if (signature === this.signature) return;
    if (group.length === 0 || group !== this.activeGroup) {
      this.previous.push(this.current); if (this.previous.length > 30) this.previous.shift();
    }
    if (group.length > 0 && group === this.activeGroup && this.previous.length > 0 && signature === this.key(this.previous[this.previous.length - 1])) {
      this.previous.pop(); group = '';
    }
    this.current = cardViewSnapshot(card); this.signature = signature; this.activeGroup = group; this.following = [];
  }
  canUndo(): boolean { return this.previous.length > 0; }
  canRedo(): boolean { return this.following.length > 0; }
  undo(): FridgeCard | null {
    if (this.current === null || this.previous.length === 0) return null;
    this.following.push(this.current); this.current = this.previous.pop()!;
    this.signature = this.key(this.current); this.activeGroup = ''; return cardViewSnapshot(this.current);
  }
  redo(): FridgeCard | null {
    if (this.current === null || this.following.length === 0) return null;
    this.previous.push(this.current); this.current = this.following.pop()!;
    this.signature = this.key(this.current); this.activeGroup = ''; return cardViewSnapshot(this.current);
  }
}
