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
        const card = templateCard(id, face.slots[0].kind, makeId, now);
        card.template!.sources=face.slots.slice(1).map(slot=>templateCard(slot.id,slot.kind,makeId,now).capability!);
        card.w=Math.min(300,height-24 < 150 ? (height-24)*2 : 300);
        card.h=aspect>=1.5?card.w/2:card.w;
        if(card.h>height-24){card.h=height-24;card.w=card.h;}
        card.x=(BOARD_W-card.w)/2;card.y=(height-card.h)/2/height*470;
        return [card];
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
