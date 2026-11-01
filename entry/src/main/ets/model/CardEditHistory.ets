import { CompositionPaletteEntry } from './CompositionPalette';
import { FridgeCard } from './CardSchema';
import { cardViewSnapshot } from './CardViewSnapshot';

/** Each gesture is one undo step; immutable subject contours stay shared. */
export class CardEditHistory {
  private palettes: Map<FridgeCard,CompositionPaletteEntry[]> = new Map();
  paletteState():CompositionPaletteEntry[]{return this.current?this.palettes.get(this.current)??[]:[];}
  private remember(entries:CompositionPaletteEntry[]):void {
    if(this.current)this.palettes.set(this.current,entries.map((e:CompositionPaletteEntry):CompositionPaletteEntry=>({id:e.id,palette:e.palette})));
    const live=this.previous.concat(this.following);if(this.current)live.push(this.current);
    for(const key of this.palettes.keys())if(!live.includes(key))this.palettes.delete(key);
  }
  private previous: FridgeCard[] = [];
  private following: FridgeCard[] = [];
  private current: FridgeCard | null = null;
  private signature: string = '';
  private activeGroup: string = '';
  private key(card: FridgeCard): string {
    return JSON.stringify([card.id, card.x, card.y, card.w, card.h, card.rot, card.z, card.shape,
      card.template,card.frame, card.material, card.paper, card.ink, card.capability, card.capBox, card.elements,
      card.subjectPhoto, card.subjectBorder, card.subjectAspect, card.subjectInk, card.subjectVersion, card.cutout, card.inDoor]);
  }
  reset(card: FridgeCard, palettes:CompositionPaletteEntry[]=[]): void {
    this.current = cardViewSnapshot(card); this.signature = this.key(card);
    this.previous = []; this.following = []; this.activeGroup = '';this.palettes.clear();this.remember(palettes);
  }
  record(card: FridgeCard, group: string = '', palettes:CompositionPaletteEntry[]=[]): void {
    if (this.current === null || this.current.id !== card.id) { this.reset(card,palettes); return; }
    const signature = this.key(card); if (signature === this.signature) return;
    if (group.length === 0 || group !== this.activeGroup) {
      this.previous.push(this.current); if (this.previous.length > 30) this.previous.shift();
    }
    if (group.length > 0 && group === this.activeGroup && this.previous.length > 0 && signature === this.key(this.previous[this.previous.length - 1])) {
      this.previous.pop(); group = '';
    }
    this.current = cardViewSnapshot(card); this.signature = signature; this.activeGroup = group; this.following = [];this.remember(palettes);
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
