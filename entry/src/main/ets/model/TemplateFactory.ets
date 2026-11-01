import { FridgeCard, BOARD_W } from './CardSchema';
import { templateDefinition, newCardTemplate } from './CardTemplate';
export function makeTemplateCards(id: string, aspect: number, makeId: () => string, now: number = Date.now()): FridgeCard[] {
    const definition = templateDefinition(id);
    if (!definition)
        return [];
    const ids = definition.kind === 'ensemble' ? (id === 'mix-standby' ? ['standby', 'calendar-month'] : id === 'mix-modular' ? ['standby', 'agenda-editorial', 'battery-ring'] : id === 'mix-study' ? ['standby', 'course-next', 'day-blocks'] : id === 'mix-travel' ? ['world-duo', 'countdown-poster'] : ['anniversary-photo', 'date-paper', 'lunar-paper']) : [id];
    const multiple = ids.length > 1, group = multiple ? makeId() : '', height = BOARD_W / Math.max(.3, aspect), columns = multiple ? (aspect >= 1.5 ? ids.length : 2) : 1, rows = Math.ceil(ids.length / columns), size = multiple ? Math.min(150, (BOARD_W - (columns + 1) * 12) / columns, (height - (rows + 1) * 12) / rows) : Math.min(260, height - 24), left = (BOARD_W - columns * size - (columns - 1) * 12) / 2, top = Math.max(12, (height - rows * size - (rows - 1) * 12) / 2), date = new Date(now), dateString = date.getFullYear() + '-' + ('0' + (date.getMonth() + 1)).slice(-2) + '-' + ('0' + date.getDate()).slice(-2);
    return ids.map((key, index) => { const card = new FridgeCard(); card.id = makeId(); card.template = newCardTemplate(key); card.capability = { k: templateDefinition(key)?.kind ?? 'clock' }; card.shape = 'rect'; card.frame = false; card.w = size; card.h = size; card.rot = 0; card.groupId = group; card.x = left + index % columns * (size + 12); card.y = (top + Math.floor(index / columns) * (size + 12)) * 470 / height; card.z = index; if (card.capability.k === 'countdown' || card.capability.k === 'anniversary') {
        card.capability.date = dateString;
        card.capability.seed = dateString;
    } if (card.capability.k === 'worldclock')
        card.capability.zone = 'Asia/Shanghai'; return card; });
}
