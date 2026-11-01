import { TemplateScene, TemplateMark } from './TemplateSceneTypes';
import { compositionSlot, compositionOwner, compositionColors } from './CompositionCatalog';
import { FridgeCard } from './CardSchema';
import { agendaItems, timeText, eventWhen, courseInstances } from './CapabilityData';
import { progressOf, daysLeftOf, calendarCells } from './CapabilityCalendar';
import { validDay } from './HolidayCalendar';
import { clockOffset, lunarReading } from './TimeCapabilities';
/** A face's data slots use its typography and color roles, not miniature standalone widgets. */
export function compositionScene(card: FridgeCard, tick: number): TemplateScene | undefined {
    const id = card.template?.id ?? '', slot = compositionSlot(id), face = compositionOwner(id);
    if (!slot || !face)
        return undefined;
    const s = new TemplateScene(), colors = compositionColors(face.id, card.template?.palette ?? '');
    s.background = colors[0];
    s.ink = colors[1];
    s.accent = colors[2];
    s.width = 300;
    s.height = 300 * card.h / card.w;
    s.surface = slot.primary;
    const H = s.height, wide = H < 220, cap = card.capability ?? { k: slot.kind }, now = new Date(tick), hour = now.getHours(), min = now.getMinutes(), hh = ('0' + hour).slice(-2), mm = ('0' + min).slice(-2), date = (now.getMonth() + 1) + '月' + now.getDate() + '日', week = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'][now.getDay()];
    const mark = (kind: string, x: number, y: number, w: number, h: number, color: string = s.ink): TemplateMark => { const m = new TemplateMark(); m.kind = kind; m.x = x; m.y = y; m.w = w; m.h = h; m.color = color; s.marks.push(m); return m; };
    const text = (value: string, x: number, y: number, size: number, w: number = 300 - x, align: string = 'left', font: string = 'sans-serif', lines: number = 1, height: number = size * 1.2 * lines): TemplateMark => { const m = mark('text', x, y, Math.max(1, Math.min(w, 300 - x)), Math.max(1, Math.min(height, H - y))); m.text = value.trim().replace(/\s+/g, ' '); m.size = size; m.align = align; m.font = font; m.lines = lines; return m; };
    const rect = (x: number, y: number, w: number, h: number, color: string, r: number = 0): TemplateMark => { const m = mark('rect', x, y, w, h, color); m.r = r; return m; };
    const line = (x: number, y: number, x2: number, y2: number, color: string = s.ink, width: number = .6): void => { const m = mark('line', x, y, x2, y2, color); m.stroke = width; };
    const arc = (x: number, y: number, r: number, start: number, sweep: number, color: string, width: number): TemplateMark => { const m = mark('arc', x, y, r * 2, r * 2, color); m.r = r; m.start = start; m.sweep = sweep; m.stroke = width; return m; };
    const image = (src: string, x: number, y: number, w: number, h: number, r: number = 0): void => { const m = mark('image', x, y, w, h); m.src = src; m.layer = 1; m.r = r; };
    const dateHead = (): void => { text(date, 22, 19, 13, 170); text(week, 215, 19, 13, 63, 'right'); };
    if (id === 'face-desk-clock') {
        text(week, 22, 22, 14, 110);
        text(hh + ':' + mm, 18, wide ? 43 : 56, wide ? 66 : 81, wide ? 152 : 264, 'left', 'digits');
        if (!wide)
            line(22, 158, 278, 158, s.accent, .8);
        else
            line(162, 18, 162, 132, s.accent, .6);
    }
    else if (id === 'face-desk-calendar') {
        text(now.getFullYear() + ' / ' + ('0' + (now.getMonth() + 1)).slice(-2), 0, 0, H > 200 ? 30 : 17, 300);
        if (H > 200) {
            ['日', '一', '二', '三', '四', '五', '六'].forEach((v, i) => { text(v, i * 43, 57, 20, 40, 'center'); });
            calendarCells(now).forEach((day, i) => { if (!day)
                return; const x = i % 7 * 43, y = 101 + Math.floor(i / 7) * 41; if (day === now.getDate())
                rect(x + 2, y - 2, 36, 36, s.accent, 18); const m = text(String(day), x, y, 24, 40, 'center'); if (day === now.getDate())
                m.color = accentInk(s.accent); });
        }
        else {
            ['日', '一', '二', '三', '四', '五', '六'].forEach((v, i) => { const x = i * 43, d = new Date(now); d.setDate(now.getDate() - now.getDay() + i); if (i === now.getDay())
                rect(x + 1, 35, 37, H - 36, s.accent, 18); const a = text(v, x, 44, 14, 39, 'center'), b = text(String(d.getDate()), x, 77, 25, 39, 'center', 'digits'); if (i === now.getDay()) {
                a.color = accentInk(s.accent);
                b.color = accentInk(s.accent);
            } });
        }
    }
    else if (id === 'face-day-clock') {
        if (wide)
            text(date + ' · ' + week, 22, 19, 12, 133);
        else
            dateHead();
        text(hh + ':' + mm, wide ? 16 : 22, wide ? 47 : 40, wide ? 66 : 78, wide ? 150 : 256, 'left', 'digits');
        if (!wide) {
            line(24, 135, 276, 135, s.ink, .35);
            line(24, 228, 276, 228, s.ink, .35);
        }
        else
            line(165, 20, 165, 132, s.ink, .4);
    }
    else if (id === 'face-day-agenda') {
        const event = agendaItems(cap, tick)[0];
        text(event ? eventWhen(event, tick) : '接下来的日程', 0, 0, H > 120 ? 24 : 14, 300).color = s.accent;
        text(event?.title || '暂无日程', 0, H > 120 ? 44 : 26, H > 120 ? 33 : 25, 300, 'left', 'sans-serif', H > 120 ? 2 : 1, H > 120 ? 83 : 31);
        if (event?.location && H > 65)
            text(event.location, 0, H - 18, 14, 300).opacity = .6;
    }
    else if (id === 'face-day-battery') {
        const value = Number.isFinite(cap.percent) && (cap.percent ?? -1) >= 0 ? Math.min(100, cap.percent!) : null, label = value === null ? '—' : String(value);
        if (H > 65) {
            text(label + (value === null ? '' : '%'), 0, 0, 48, 300, 'center', 'digits');
            rect(0, H - 7, 300, 5, s.ink, 2).opacity = .2;
            if (value !== null)
                rect(0, H - 7, value * 3, 5, s.accent, 2);
        }
        else {
            arc(24, H / 2, 19, 0, 360, s.ink, 3).opacity = .18;
            arc(24, H / 2, 19, -90, (value ?? 0) * 3.6, s.accent, 3);
            text(label, 5, H / 2 - 9, 16, 38, 'center', 'digits');
            text('本机电量', 62, 1, 15, 238);
            text(cap.charging ? '充电中' : value === null ? '等待数据' : value + '%', 62, 25, 13, 238).opacity = .65;
        }
    }
    else if (id === 'face-study-clock') {
        text(hh + ':' + mm, 22, wide ? 26 : 25, wide ? 43 : 49, wide ? 112 : 180, 'left', 'digits');
        text(date + ' · ' + week, 22, wide ? 86 : 82, 12, wide ? 114 : 256);
        if (wide)
            line(141, 19, 141, 104, s.accent, .5);
        else {
            line(22, 99, 278, 99, s.accent, .6);
            line(22, 241, 278, 241, s.accent, .6);
        }
    }
    else if (id === 'face-study-course') {
        const e = courseInstances(cap, tick)[0];
        text(e ? '下节课' : '课程表', 0, 0, 15, 300).color = s.accent;
        text(e?.title || ((cap.courses ?? []).length ? '暂无后续课程' : '导入课表'), 0, 30, H > 180 ? 37 : 30, 300, 'left', 'sans-serif', 2, Math.min(H - 65, 88));
        if (e) {
            text(eventWhen(e, tick), 0, H - 39, 14, 300);
            text(e.location, 0, H - 17, 12, 300).opacity = .65;
        }
    }
    else if (id === 'face-study-progress') {
        const p = progressOf('dayprogress', now);
        text('今天', 0, 0, 12, 150);
        text(Math.floor(p * 100) + '%', 150, 0, 12, 150, 'right');
        rect(0, H - 4, 300, 4, s.ink, 2).opacity = .15;
        rect(0, H - 4, 300 * p, 4, s.accent, 2);
    }
    else if (id === 'face-travel-world') {
        const zoned = new Date(tick - clockOffset(cap.zone ?? 'Asia/Shanghai', tick) * 3600000), h = zoned.getUTCHours(), m = zoned.getUTCMinutes(), cx = wide ? 86 : 150, cy = wide ? 81 : 129, r = wide ? 55 : 90;
        text(cap.city || '目的地', 22, 17, 13, wide ? 125 : 155);
        if (!wide)
            text(('0' + h).slice(-2) + ':' + ('0' + m).slice(-2), 187, 17, 17, 91, 'right', 'digits');
        for (let i = 0; i < 60; i++) {
            const a = i * Math.PI / 30, inner = r - (i % 5 === 0 ? 8 : 3);
            line(cx + Math.sin(a) * inner, cy - Math.cos(a) * inner, cx + Math.sin(a) * r, cy - Math.cos(a) * r, i % 5 ? s.ink : s.accent, i % 5 ? .35 : 1.4);
        }
        const hand = (a: number, len: number, width: number, color: string): void => { const rad = a * Math.PI / 180; line(cx, cy, cx + Math.sin(rad) * len, cy - Math.cos(rad) * len, color, width); };
        hand(h % 12 * 30 + m / 2, r * .56, 4, s.ink);
        hand(m * 6, r * .82, 2, s.accent);
        mark('circle', cx - 3, cy - 3, 6, 6, s.ink);
        if (wide)
            text('本地 ' + hh + ':' + mm, 174, 17, 12, 104, 'right');
        else
            line(24, 226, 276, 226, s.accent, .45);
    }
    else if (id === 'face-travel-countdown') {
        const left = cap.date && validDay(cap.date) ? daysLeftOf(cap.date, tick) : null, value = left === null ? '—' : String(Math.abs(left)), phase = left === null ? '天' : left < 0 ? '天前' : '天后';
        text(cap.title || '出发', 0, 0, H > 100 ? 23 : 15, H > 100 ? 300 : 170);
        text(value, H > 100 ? 0 : 175, H > 100 ? 44 : 0, H > 100 ? 92 : 37, H > 100 ? 300 : 99, H > 100 ? 'left' : 'right', 'digits');
        text(phase, H > 100 ? 0 : 276, H > 100 ? 161 : 25, H > 100 ? 22 : 12, H > 100 ? 300 : 24);
    }
    else if (id === 'face-memory-photo') {
        const photo = card.elements.find(e => e.kind === 'image' && e.src.length > 0), t = card.template!, box = wide ? [148, 16, 134, 118] : [138, 58, 140, 169];
        if (photo) {
            if (t.depth && photo.depthForeground && photo.depthEnabled) {
                const aspect = Math.max(.05, photo.depthSourceAspect * photo.depthCrop.w / Math.max(.01, photo.depthCrop.h)), h = Math.min(box[3], box[2] / aspect) * t.zoom, w = h * aspect;
                image(photo.depthForeground, box[0] + (box[2] - w) / 2 + t.offsetX * box[2], box[1] + (box[3] - h) / 2 + t.offsetY * box[3], w, h);
            }
            else
                image(photo.src, box[0], box[1], box[2], box[3], 10);
        }
        const left = cap.date && validDay(cap.date) ? daysLeftOf(cap.date, tick) : null;
        const number = text(left === null ? '—' : String(Math.abs(left)), 22, wide ? 43 : 106, wide ? 57 : 88, wide ? 92 : 114, 'left', 'digits');
        number.layer = 2;
        text(left !== null && left > 0 ? '天后' : '天', wide ? 120 : 24, wide ? 90 : 218, wide ? 11 : 14, wide ? 22 : 100).layer = 2;
        const title = text(cap.title || '纪念日', 22, wide ? 112 : 244, wide ? 11 : 15, wide ? 116 : 256);
        title.layer = 2;
    }
    else if (id === 'face-memory-date') {
        text(date + ' · ' + week, 0, 0, Math.min(28, H / 1.2), 300);
    }
    else if (id === 'face-memory-lunar') {
        const lunar = lunarReading(tick);
        text(lunar.year + ' · ' + lunar.date, 0, 0, Math.min(16, H / 1.2), 300);
    }
    return s;
}
function accentInk(color: string): string { const value = parseInt(color.slice(1), 16), light = ((value >> 16) * 299 + ((value >> 8) & 255) * 587 + (value & 255) * 114) / 1000; return light > 155 ? '#26312A' : '#FFFFFF'; }
