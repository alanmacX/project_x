import { CapBlock } from './CardSchema';
import { compositionSlot } from './CompositionCatalog';
/** Built-in designs. Artwork is local; data stays in the existing capability. */
export interface CardTemplate {
    photoMode?: string;
    background?: string;
    sources?: CapBlock[];
    version: number;
    id: string;
    palette: string;
    fill: boolean;
    depth: boolean;
    zoom: number;
    offsetX: number;
    offsetY: number;
}
export interface TemplateDefinition {
    id: string;
    kind: string;
    name: string;
    sources: string[];
}
export const CARD_TEMPLATES: TemplateDefinition[] = [
    { "id": "standby", "kind": "clock", "name": "浮字", "sources": ["clock"] },
    { "id": "dial", "kind": "clock", "name": "色盘", "sources": ["clock"] },
    { "id": "flip", "kind": "clock", "name": "翻页", "sources": ["clock"] },
    { "id": "portrait", "kind": "clock", "name": "景深照片", "sources": ["clock"] },
    { "id": "date-poster", "kind": "date", "name": "日历海报", "sources": ["date"] },
    { "id": "date-paper", "kind": "date", "name": "纸页", "sources": ["date"] },
    { "id": "date-strip", "kind": "date", "name": "一周", "sources": ["date"] },
    { "id": "calendar-month", "kind": "calendar", "name": "月历", "sources": ["calendar"] },
    { "id": "calendar-ledger", "kind": "calendar", "name": "月记", "sources": ["calendar"] },
    { "id": "calendar-week", "kind": "calendar", "name": "周历", "sources": ["calendar"] },
    { "id": "countdown-poster", "kind": "countdown", "name": "出发", "sources": ["countdown"] },
    { "id": "countdown-orbit", "kind": "countdown", "name": "环绕", "sources": ["countdown"] },
    { "id": "countdown-paper", "kind": "countdown", "name": "撕页", "sources": ["countdown"] },
    { "id": "anniversary-photo", "kind": "anniversary", "name": "相遇", "sources": ["anniversary"] },
    { "id": "anniversary-type", "kind": "anniversary", "name": "记忆", "sources": ["anniversary"] },
    { "id": "day-dial", "kind": "dayprogress", "name": "一天", "sources": ["dayprogress"] },
    { "id": "day-timeline", "kind": "dayprogress", "name": "日线", "sources": ["dayprogress"] },
    { "id": "day-blocks", "kind": "dayprogress", "name": "时块", "sources": ["dayprogress"] },
    { "id": "year-dots", "kind": "yearprogress", "name": "年点", "sources": ["yearprogress"] },
    { "id": "year-arc", "kind": "yearprogress", "name": "年轮", "sources": ["yearprogress"] },
    { "id": "year-months", "kind": "yearprogress", "name": "十二月", "sources": ["yearprogress"] },
    { "id": "battery-ring", "kind": "battery", "name": "能量环", "sources": ["battery"] },
    { "id": "battery-cell", "kind": "battery", "name": "电芯", "sources": ["battery"] },
    { "id": "battery-segments", "kind": "battery", "name": "电格", "sources": ["battery"] },
    { "id": "agenda-editorial", "kind": "agenda", "name": "留白日程", "sources": ["agenda"] },
    { "id": "agenda-timeline", "kind": "agenda", "name": "时间轴", "sources": ["agenda"] },
    { "id": "agenda-paper", "kind": "agenda", "name": "手帐", "sources": ["agenda"] },
    { "id": "course-next", "kind": "timetable", "name": "下节课", "sources": ["timetable"] },
    { "id": "course-week", "kind": "timetable", "name": "一周课表", "sources": ["timetable"] },
    { "id": "course-slips", "kind": "timetable", "name": "课程纸条", "sources": ["timetable"] },
    { "id": "world-dial", "kind": "worldclock", "name": "异地", "sources": ["worldclock"] },
    { "id": "world-duo", "kind": "worldclock", "name": "两地", "sources": ["worldclock"] },
    { "id": "world-type", "kind": "worldclock", "name": "时差", "sources": ["worldclock"] },
    { "id": "lunar-paper", "kind": "lunar", "name": "东方日历", "sources": ["lunar"] },
    { "id": "lunar-night", "kind": "lunar", "name": "月白", "sources": ["lunar"] },
    { "id": "lunar-seal", "kind": "lunar", "name": "朱印", "sources": ["lunar"] },
    { "id": "album-record", "kind": "album", "name": "唱片", "sources": ["album"] },
    { "id": "album-cover", "kind": "album", "name": "封面", "sources": ["album"] },
    { "id": "album-sleeve", "kind": "album", "name": "唱片袋", "sources": ["album"] },
    { "id": "mix-standby", "kind": "ensemble", "name": "桌边", "sources": ["clock", "calendar"] },
    { "id": "mix-modular", "kind": "ensemble", "name": "今日", "sources": ["clock", "agenda", "battery"] },
    { "id": "mix-study", "kind": "ensemble", "name": "课间", "sources": ["clock", "timetable", "dayprogress"] },
    { "id": "mix-travel", "kind": "ensemble", "name": "远行", "sources": ["worldclock", "countdown"] },
    { "id": "mix-memory", "kind": "ensemble", "name": "相片日历", "sources": ["anniversary", "date", "lunar"] }
];
export function templateDefinition(id: string): TemplateDefinition | undefined { const single=CARD_TEMPLATES.find(d=>d.id===id);if(single)return single;const slot=compositionSlot(id);return slot?{id:slot.id,kind:slot.kind,name:slot.role,sources:[slot.kind]}:undefined; }
export function normalizeCardTemplate(raw: CardTemplate | undefined): CardTemplate | undefined { if (!raw || raw.version !== 1 || !templateDefinition(raw.id))
    return undefined; const definition=templateDefinition(raw.id)!;const sources=definition.kind==='ensemble'?definition.sources.slice(1).map((k:string,index:number):CapBlock=>{const cap=raw.sources?.[index];return cap?.k===k?JSON.parse(JSON.stringify(cap)) as CapBlock:{k:k};}):undefined;return { photoMode:raw.photoMode==='photo'?'photo':'subject',background:raw.background==='smart'?'smart':'template',sources:sources,version: 1, id: raw.id, palette: ['', 'cobalt', 'cream', 'ink'].includes(raw.palette) ? raw.palette : '', fill: raw.fill === true, depth: raw.depth !== false, zoom: Math.max(.5, Math.min(1.5, Number.isFinite(raw.zoom) ? raw.zoom : 1)), offsetX: Math.max(-.35, Math.min(.35, Number.isFinite(raw.offsetX) ? raw.offsetX : 0)), offsetY: Math.max(-.35, Math.min(.35, Number.isFinite(raw.offsetY) ? raw.offsetY : 0)) }; }
export function newCardTemplate(id: string): CardTemplate { return { photoMode:'subject',background:'template',version: 1, id, palette: '', fill: false, depth: true, zoom: 1, offsetX: 0, offsetY: 0 }; }
export function copyCardTemplate(raw: CardTemplate | undefined, includeSources:boolean=true): CardTemplate | undefined { return raw ? { photoMode:raw.photoMode,background:raw.background,sources:includeSources&&raw.sources?JSON.parse(JSON.stringify(raw.sources)) as CapBlock[]:undefined, version: raw.version, id: raw.id, palette: raw.palette, fill: raw.fill, depth: raw.depth, zoom: raw.zoom, offsetX: raw.offsetX, offsetY: raw.offsetY } : undefined; }
