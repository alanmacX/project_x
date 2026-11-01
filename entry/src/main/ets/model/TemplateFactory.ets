import { compositionDefinition, compositionLayout } from './CompositionCatalog';
import { FridgeCard, BOARD_W } from './CardSchema';
import { templateDefinition, newCardTemplate } from './CardTemplate';

function templateCard(id: string, kind: string, makeId: () => string, now: number): FridgeCard {
    const card = new FridgeCard();
    card.id = makeId();
    card.template = newCardTemplate(id);
    card.capability = { k: kind };
    card.shape = 'rect';
    card.frame = false;
    card.rot = 0;
    card.z = 0;
    if (kind === 'anniversary' || kind === 'countdown') {
        const day = new Date(now);
        const date = day.getFullYear() + '-' + ('0' + (day.getMonth() + 1)).slice(-2) + '-' + ('0' + day.getDate()).slice(-2);
        card.capability.date = date;
        card.capability.seed = date;
    }
    if (kind === 'worldclock') card.capability.zone = 'Asia/Shanghai';
    return card;
}

export function makeTemplateCards(id: string, aspect: number, makeId: () => string, now: number = Date.now()): FridgeCard[] {
    const definition = templateDefinition(id);
    if (!definition) return [];
    const height = BOARD_W / Math.max(.3, aspect);
    const face = compositionDefinition(id);
    if (face) {
        const layout = compositionLayout(face, aspect);
        if (!layout.slots.length) return [];
        const scale = Math.min((BOARD_W - 24) / layout.width, (height - 24) / layout.height);
        const left = (BOARD_W - layout.width * scale) / 2;
        const top = (height - layout.height * scale) / 2;
        const group = makeId();
        return layout.slots.map((slot, index) => {
            const card = templateCard(slot.id, slot.kind, makeId, now);
            card.groupId = group;
            card.z = index;
            card.x = left + slot.x * scale;
            card.y = (top + slot.y * scale) / height * 470;
            card.w = slot.w * scale;
            card.h = slot.h * scale;
            return card;
        });
    }
    // An ensemble must have an authored face. Never fall back to a miniature widget grid.
    if (definition.kind === 'ensemble') return [];
    const card = templateCard(id, definition.kind, makeId, now);
    card.w = Math.min(260, height - 24);
    card.h = card.w;
    card.x = (BOARD_W - card.w) / 2;
    card.y = Math.max(12, (height - card.h) / 2) * 470 / height;
    return [card];
}
