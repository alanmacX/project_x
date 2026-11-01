import { FridgeCard } from './CardSchema';
import { compositionOwner } from './CompositionCatalog';
export interface CompositionPaletteEntry { id: string; palette: string; }
/** Only internal roles in the same authored face/group participate; ordinary legacy groups are untouched. */
export function compositionPaletteState(card: FridgeCard, cards: FridgeCard[]): CompositionPaletteEntry[] {
    const face = compositionOwner(card.template?.id ?? '');
    if (!face || !card.groupId) return [];
    return cards.filter(c => c.groupId === card.groupId && compositionOwner(c.template?.id ?? '')?.id === face.id)
        .map((c: FridgeCard): CompositionPaletteEntry => ({ id: c.id, palette: c.template?.palette ?? '' }));
}
export function restoreCompositionPalette(entries: CompositionPaletteEntry[], cards: FridgeCard[]): void {
    for (const entry of entries) {
        const card = cards.find(c => c.id === entry.id);
        if (card?.template) card.template.palette = entry.palette;
    }
}
export function setCompositionPalette(card: FridgeCard, cards: FridgeCard[], palette: string): void {
    const peers = compositionPaletteState(card, cards);
    for (const peer of peers) peer.palette = palette;
    restoreCompositionPalette(peers, cards);
    if (card.template) card.template.palette = palette;
}
