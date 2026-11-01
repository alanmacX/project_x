/** Versioned, authored faces. One primary surface; supporting data slots have no card chrome. */
export interface CompositionSlot {
    id: string;
    kind: string;
    role: string;
    x: number;
    y: number;
    w: number;
    h: number;
    primary: boolean;
}
export interface CompositionDefinition {
    id: string;
    revision: number;
    name: string;
    slots: CompositionSlot[];
}
export const COMPOSITIONS: CompositionDefinition[] = [
    { id: 'mix-standby', revision: 1, name: '桌边', slots: [
            { id: 'face-desk-clock', kind: 'clock', role: '主时间', x: 0, y: 0, w: 300, h: 300, primary: true },
            { id: 'face-desk-calendar', kind: 'calendar', role: '周历', x: 22, y: 180, w: 256, h: 98, primary: false }
        ] },
    { id: 'mix-modular', revision: 1, name: '今日', slots: [
            { id: 'face-day-clock', kind: 'clock', role: '主时间', x: 0, y: 0, w: 300, h: 300, primary: true },
            { id: 'face-day-agenda', kind: 'agenda', role: '接下来的日程', x: 24, y: 151, w: 252, h: 65, primary: false },
            { id: 'face-day-battery', kind: 'battery', role: '电量', x: 24, y: 238, w: 252, h: 40, primary: false }
        ] },
    { id: 'mix-study', revision: 1, name: '课间', slots: [
            { id: 'face-study-clock', kind: 'clock', role: '时间', x: 0, y: 0, w: 300, h: 300, primary: true },
            { id: 'face-study-course', kind: 'timetable', role: '下节课', x: 22, y: 106, w: 256, h: 124, primary: false },
            { id: 'face-study-progress', kind: 'dayprogress', role: '今日进度', x: 22, y: 251, w: 256, h: 27, primary: false }
        ] },
    { id: 'mix-travel', revision: 1, name: '远行', slots: [
            { id: 'face-travel-world', kind: 'worldclock', role: '目的地时间', x: 0, y: 0, w: 300, h: 300, primary: true },
            { id: 'face-travel-countdown', kind: 'countdown', role: '出发倒计时', x: 24, y: 239, w: 252, h: 39, primary: false }
        ] },
    { id: 'mix-memory', revision: 1, name: '相片日历', slots: [
            { id: 'face-memory-photo', kind: 'anniversary', role: '照片与纪念日', x: 0, y: 0, w: 300, h: 300, primary: true },
            { id: 'face-memory-date', kind: 'date', role: '日期', x: 22, y: 20, w: 256, h: 28, primary: false },
            { id: 'face-memory-lunar', kind: 'lunar', role: '农历', x: 22, y: 265, w: 256, h: 16, primary: false }
        ] }
];
export function compositionDefinition(id: string): CompositionDefinition | undefined { return COMPOSITIONS.find(c => c.id === id); }
export function compositionSlot(id: string): CompositionSlot | undefined { for (const face of COMPOSITIONS) {
    const slot = face.slots.find(s => s.id === id);
    if (slot)
        return slot;
} return undefined; }
export function compositionOwner(id: string): CompositionDefinition | undefined { return COMPOSITIONS.find(c => c.slots.some(s => s.id === id)); }
export function compositionColors(id: string, palette: string): string[] {
    if (palette === 'cream')
        return ['#EFE8D9', '#333C43', '#B36143'];
    if (palette === 'cobalt')
        return ['#173F89', '#F5EDDB', '#ECC071'];
    if (palette === 'ink')
        return ['#131A1E', '#F1EDE4', '#B9D889'];
    if (id === 'mix-modular')
        return ['#111B22', '#F5F0E5', '#BBDD88'];
    if (id === 'mix-travel')
        return ['#172F3D', '#F2E7D4', '#E9AB69'];
    if (id === 'mix-study')
        return ['#F0EADD', '#493F33', '#A6523C'];
    if (id === 'mix-memory')
        return ['#D8DECD', '#2B4338', '#5F795F'];
    return ['#E9E8DD', '#263B4E', '#AF653D'];
}
export interface CompositionLayout {
    width: number;
    height: number;
    slots: CompositionSlot[];
}
/** Wide faces have separately authored positions, never stretched square glyphs. */
export function compositionLayout(face: CompositionDefinition, aspect: number): CompositionLayout {
    if (aspect < 1.5)
        return { width: 300, height: 300, slots: face.slots };
    const output: CompositionSlot[] = face.slots.map((s: CompositionSlot): CompositionSlot => ({ id: s.id, kind: s.kind, role: s.role, x: s.x, y: s.y, w: s.w, h: s.h, primary: s.primary }));
    if (!output.length) return { width: 300, height: 150, slots: [] };
    output[0].h = 150;
    const boxes: number[][] = face.id === 'mix-standby' ? [[176, 16, 104, 120]] : face.id === 'mix-modular' ? [[180, 18, 100, 67], [180, 103, 100, 30]] : face.id === 'mix-study' ? [[156, 18, 124, 88], [18, 119, 262, 18]] : face.id === 'mix-travel' ? [[174, 46, 104, 80]] : face.id === 'mix-memory' ? [[18, 14, 130, 22], [18, 128, 130, 12]] : [];
    if (boxes.length !== output.length - 1) return { width: 300, height: 150, slots: [] };
    boxes.forEach((b, i) => { output[i + 1].x = b[0]; output[i + 1].y = b[1]; output[i + 1].w = b[2]; output[i + 1].h = b[3]; });
    return { width: 300, height: 150, slots: output };
}
