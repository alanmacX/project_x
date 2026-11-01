import { validDay } from './HolidayCalendar';
import { activeAlbum } from './AlbumRotation';
import { FridgeCard, CapBlock, CanvasElement } from './CardSchema';
import { calendarCells, progressOf, daysLeftOf } from './CapabilityCalendar';
import { clockOffset, lunarReading } from './TimeCapabilities';
import { agendaItems, timeText, semesterWeek, courseInstances } from './CapabilityData';
import { weekLessons } from './TimetableLayout';
import { depthPhotoBox } from './DepthComposition';
export class TemplateMark {
    kind: string = 'rect';
    x: number = 0;
    y: number = 0;
    w: number = 0;
    h: number = 0;
    r: number = 0;
    color: string = '#222823';
    end: string = '';
    angle: number = 0;
    opacity: number = 1;
    text: string = '';
    lines: number = 1;
    size: number = 16;
    weight: number = 400;
    align: string = 'left';
    font: string = 'sans-serif';
    start: number = 0;
    sweep: number = 360;
    stroke: number = 0;
    layer: number = 0;
    src: string = '';
}
export class TemplateScene {
    marks: TemplateMark[] = [];
    background: string = '#F1EDE3';
    ink: string = '#30362D';
    accent: string = '#B6593D';
}
export function templateColors(card: FridgeCard): string[] {
    const id = card.template?.id ?? '', p = card.template?.palette ?? '';
    if (p === 'cobalt')
        return ['#2443A2', '#F5EDDA', '#EABB65'];
    if (p === 'cream')
        return ['#EFE7D8', '#40382C', '#B75C3D'];
    if (p === 'ink')
        return ['#16191C', '#EEE8D8', '#B8CD85'];
    if (['standby', 'calendar-month', 'flip', 'countdown-orbit', 'mix-modular'].includes(id))
        return ['#17191D', '#F0EEE5', '#DFA471'];
    if (['day-timeline', 'world-duo', 'lunar-night'].includes(id))
        return ['#20344B', '#EEF4FA', '#A5CEF2'];
    if (id === 'dial')
        return ['#BBCFDA', '#FFFAF0', '#E782BA'];
    if (id === 'date-poster')
        return ['#EF593C', '#FFF4DB', '#FFF4DB'];
    if (id === 'countdown-poster')
        return ['#DADF39', '#26321C', '#26321C'];
    if (id === 'anniversary-type')
        return ['#3649BF', '#F9E7BE', '#F9E7BE'];
    if (id === 'year-arc')
        return ['#34253C', '#F0E5F2', '#C69ED6'];
    if (id === 'battery-ring')
        return ['#111A15', '#B4EF9E', '#B4EF9E'];
    if (id === 'battery-cell')
        return ['#CCE7D5', '#1B523B', '#83BE96'];
    if (id === 'battery-segments')
        return ['#D5D8B2', '#35452E', '#35452E'];
    if (id === 'course-next')
        return ['#E8A8BA', '#542339', '#8C5267'];
    if (id === 'lunar-seal')
        return ['#AB3F32', '#F6E7D3', '#F6E7D3'];
    if (['portrait', 'anniversary-photo', 'date-strip'].includes(id))
        return ['#C9D3B9', '#283D2C', '#52734A'];
    if (id === 'album-record')
        return ['#D87C4E', '#38231B', '#273F85'];
    if (id === 'album-cover')
        return ['#1C2C63', '#E9EDFF', '#A4B7EA'];
    return ['#F1EDE3', '#403B30', '#9A6048'];
}
export function templateContrastInk(color:string):string {const light=parseInt(color.slice(1,3),16)*.2126+parseInt(color.slice(3,5),16)*.7152+parseInt(color.slice(5,7),16)*.0722;return light>155?'#26312A':'#FFFFFF';}
export function templatePhoto(card: FridgeCard): CanvasElement | undefined { return card.elements.find(e => e.kind === 'image' && e.src.length > 0); }
/** Logical 300-square scene. All hosts consume the same positions and reading data. */
export function cardTemplateScene(card: FridgeCard, tick: number): TemplateScene {
    tick = Number.isFinite(tick)&&tick>0?tick:Date.now();
    const s = new TemplateScene(), colors = templateColors(card);
    s.background = colors[0];
    s.ink = colors[1];
    s.accent = colors[2];
    const cap: CapBlock = card.capability ?? { k: 'clock' };
    const id = card.template?.id ?? '', now = new Date(tick || Date.now()), zone = cap.zone ?? 'Asia/Shanghai', zoned = cap.k==='worldclock'?new Date(tick-clockOffset(zone,tick)*3600000):now;
    const hour = cap.k === 'worldclock' ? zoned.getUTCHours() : now.getHours(), minute = cap.k === 'worldclock' ? zoned.getUTCMinutes() : now.getMinutes(), hh = ('0' + hour).slice(-2), mm = ('0' + minute).slice(-2), day = now.getDate(), month = now.getMonth() + 1, year = now.getFullYear(), week = ['星期日', '星期一', '星期二', '星期三', '星期四', '星期五', '星期六'][now.getDay()];
    const add = (kind: string, x: number, y: number, w: number, h: number, color: string = s.ink): TemplateMark => { const m = new TemplateMark(); m.kind = kind; m.x = x; m.y = y; m.w = w; m.h = h; m.color = color; s.marks.push(m); return m; };
    const text = (value: string, x: number, y: number, size: number = 16, color: string = s.ink, width: number = 250, align: string = 'left', weight: number = 400): TemplateMark => { const m = add('text', x, y, Math.max(1,Math.min(width,300-x)), Math.max(1,Math.min(size*1.2,300-y)), color); m.text = value.trim().replace(/\s+/g,' '); m.size = size; m.align = align; m.weight = weight; return m; };
    const rect = (x: number, y: number, w: number, h: number, color: string, r: number = 0): TemplateMark => { const m = add('rect', x, y, w, h, color); m.r = r; return m; };
    const arc = (x: number, y: number, r: number, start: number, sweep: number, color: string, width: number): TemplateMark => { const m = add('arc', x, y, r * 2, r * 2, color); m.r = r; m.start = start; m.sweep = sweep; m.stroke = width; return m; };
    const line = (x: number, y: number, a: number, b: number, color: string = s.ink, width: number = 1): TemplateMark => { const m = add('line', x, y, a, b, color); m.stroke = width; return m; };
    const image = (src: string, x: number, y: number, w: number, h: number, layer: number = 1): void => { if (src) {
        const m = add('image', x, y, w, h);
        m.src = src;
        m.layer = layer;
    } };
    const date = (): void => { text(month + '月' + day + '日', 24, 270, 12); text(week, 190, 270, 12, s.ink, 86, 'right'); };
    const photo = templatePhoto(card), personal = card.template!;
    const drawDial = (cx: number = 150, cy: number = 150, r: number = 122): void => { for (let i = 0; i < 60; i++) {
        const a = i * Math.PI / 30, inner = r - (i % 5 === 0 ? 10 : 4);
        const m = line(cx + Math.sin(a) * inner, cy - Math.cos(a) * inner, cx + Math.sin(a) * r, cy - Math.cos(a) * r, s.ink, i % 5 === 0 ? 1.5 : .6);
        m.opacity = i % 5 === 0 ? .8 : .35;
    } for (let i = 0; i < 4; i++) {
        const a = i * Math.PI / 2;
        text(['12', '3', '6', '9'][i], cx + Math.sin(a) * r * .75 - 18, cy - Math.cos(a) * r * .75 - 10, 19, s.ink, 36, 'center');
    } const hand = (a: number, len: number, width: number, color: string): void => { const rad = a * Math.PI / 180; line(cx, cy, cx + Math.sin(rad) * len, cy - Math.cos(rad) * len, color, width); }; hand((hour % 12) * 30 + minute / 2, r * .53, 6, s.ink); hand(minute * 6, r * .76, 3.5, s.ink); add('circle', cx - 3, cy - 3, 6, 6, s.accent); };
    const monthGrid = (): void => { const cells = calendarCells(now); ['日', '一', '二', '三', '四', '五', '六'].forEach((n, i) => { text(n, 18 + i * 39, 67, 12, s.ink, 30, 'center').opacity = .5; }); cells.forEach((n, i) => { if (!n)
        return; const x = 18 + i % 7 * 39, y = 96 + Math.floor(i / 7) * 32; if (n === day)
        add('circle', x + 2, y - 2, 26, 26, s.accent); text(String(n), x, y, 14, n === day ? templateContrastInk(s.accent) : s.ink, 30, 'center'); }); };
    const ring = (p: number, value: string, label: string): void => { arc(150, 142, 108, 0, 360, s.ink, 8).opacity = .12; arc(150, 142, 108, -90, Math.max(0, Math.min(1, p)) * 360, s.accent, 8); text(value, 35, 100, 65, s.ink, 230, 'center', 600); text(label, 30, 195, 14, s.ink, 240, 'center'); };
    const dayP = progressOf('dayprogress', now), yearP = progressOf('yearprogress', now), left = cap.date&&validDay(cap.date) ? daysLeftOf(cap.date, tick) : null;
    if (id === 'dial') {
        const a = rect(87, 9, 126, 282, '#6797F0', 33);
        a.end = '#E782BA';
        a.angle = minute * 6;
        a.opacity = .82;
        const b = rect(78, 36, 144, 228, '#F0DD75', 33);
        b.end = '#7DD4C8';
        b.angle = (hour % 12) * 30 + minute / 2;
        b.opacity = .76;
        if (personal.palette === 'cobalt') {
            a.color = '#638ED9';
            a.end = '#9483C9';
            b.color = '#B9E3E5';
            b.end = '#63BDC9';
        }
        else if (personal.palette === 'cream') {
            a.color = '#DB8D9E';
            a.end = '#DFA578';
            b.color = '#F6E49F';
            b.end = '#D9BA91';
        }
        else if (personal.palette === 'ink') {
            a.color = '#AA8CE0';
            a.end = '#DC8BB8';
            b.color = '#E2BEDD';
            b.end = '#949FDA';
        }
        const hand = (deg: number, len: number, width: number): void => { const rad = deg * Math.PI / 180; line(150 - Math.sin(rad) * 7, 150 + Math.cos(rad) * 7, 150 + Math.sin(rad) * len, 150 - Math.cos(rad) * len, '#FFFAF0', width); };
        hand((hour % 12) * 30 + minute / 2, 65, 7);
        hand(minute * 6, 99, 3.6);
        add('circle', 146, 146, 8, 8, '#FFFAF0');
    }
    else if (id === 'standby') {
        text(hh + ':' + mm, 16, 104, 82, s.ink, 268, 'center', 200);
        date();
    }
    else if (id === 'flip') {
        [hh, mm].forEach((v, i) => { const x = 15 + i * 141; rect(x, 54, 128, 190, '#30322F', 12).end = '#212320'; text(v, x, 80, 100, s.ink, 128, 'center', 800).font = 'digits'; line(x, 149, x + 128, 149, '#121412', 2); });
        date();
    }
    else if (id === 'portrait' || id === 'anniversary-photo') {
        if (photo) {
            if (id === 'anniversary-photo') {
                image(photo.src, 0, 0, 300, 212);
            }
            else {
                const w = 300 * Math.max(1, card.w / card.h), h = 300 * Math.max(1, card.h / card.w);
                image(photo.src, (300 - w) / 2, (300 - h) / 2, w, h);
            }
        }
        else {
            text('选择你的照片', 24, 174, 22, s.ink, 252, 'center');
        }
        if (id === 'portrait') {
            const t = text(hh + ':' + mm, 9, 7, 94, s.ink, 282, 'center', 800);
            t.layer = 2;
            t.font = 'digits';
            if (photo?.depthForeground && personal.depth) {
                const box = depthPhotoBox(photo, card.w, card.h), w = 300 * Math.max(1, card.w / card.h), h = 300 * Math.max(1, card.h / card.w);
                image(photo.depthForeground, (300 - w) / 2 + (box.x + box.w * (1 - personal.zoom) / 2 + personal.offsetX) * w, (300 - h) / 2 + (box.y + box.h * (1 - personal.zoom) / 2 + personal.offsetY) * h, box.w * w * personal.zoom, box.h * h * personal.zoom, 3);
            }
        }
        else {
            rect(0, 211, 300, 89, s.background);
            text(cap.title || '纪念日', 20, 236, 17, s.ink, 126);
            text(left === null ? '—' : String(Math.abs(left)), 156, 223, 48, s.ink, 104, 'right', 700).font = 'digits';
            text(left!==null&&left>0?'天后':'天', 268, 260, 12);
        }
    }
    else if (id.startsWith('date-')) {
        if (id === 'date-poster') {
            text(String(year), 24, 20, 13);
            text(month + '月', 210, 20, 13, s.ink, 66, 'right');
            text(String(day), 21, 45, 204, s.ink, 180, 'left', 800).font = 'digits';
            week.split('').forEach((letter, index) => { text(letter, 230, 100 + index * 31, 21, s.ink, 40, 'center'); });
        }
        else if (id === 'date-paper') {
            text(year + ' · ' + month + '月', 24, 22, 15);
            text(String(day), 22, 61, 148, s.ink, 230).font = 'serif';
            line(24, 231, 276, 231, s.ink, .5);
            date();
        }
        else {
            text(String(day), 24, 20, 127, s.ink, 105, 'left', 800).font = 'digits';
            text(month + '月', 135, 60, 29);
            text(week, 136, 102, 15);
            const start = new Date(now);
            start.setDate(day - now.getDay());
            for (let i = 0; i < 7; i++) {
                const d = new Date(start);
                d.setDate(start.getDate() + i);
                const x = 20 + i * 38;
                if (i === now.getDay())
                    rect(x, 207, 32, 70, s.accent, 16);
                text(['日', '一', '二', '三', '四', '五', '六'][i], x, 217, 12, i === now.getDay() ? templateContrastInk(s.accent) : s.ink, 32, 'center');
                text(String(d.getDate()), x, 247, 17, i === now.getDay() ? templateContrastInk(s.accent) : s.ink, 32, 'center');
            }
        }
    }
    else if (id.startsWith('calendar-')) {
        text(month + '月', 24, 17, id === 'calendar-ledger' ? 38 : 25).font = id === 'calendar-ledger' ? 'serif' : 'sans-serif';
        text(String(year), 220, 24, 13, s.ink, 56, 'right');
        if (id === 'calendar-week') {
            text(month + '月' + day + '日', 24, 94, 42);
            for (let i = 0; i < 7; i++) {
                const x = 20 + i * 38, d = new Date(now);
                d.setDate(day - now.getDay() + i);
                if (i === now.getDay())
                    rect(x, 189, 32, 68, s.accent, 16);
                text(['日', '一', '二', '三', '四', '五', '六'][i], x, 199, 12, i === now.getDay() ? templateContrastInk(s.accent) : s.ink, 32, 'center');
                text(String(d.getDate()), x, 229, 17, i === now.getDay() ? templateContrastInk(s.accent) : s.ink, 32, 'center');
            }
        }
        else
            monthGrid();
    }
    else if (id.startsWith('countdown-') || id === 'anniversary-type') {
        const n = left === null ? '—' : String(Math.abs(left)), title = cap.title || (id === 'anniversary-type' ? '纪念日' : '倒计时');
        if (id === 'countdown-orbit') {
            arc(150, 147, 115, 135, 270, s.ink, 2).opacity = .2;
            const total = cap.seed ? daysLeftOf(cap.date ?? '', new Date(cap.seed).getTime()) : 30, p = left === null ? 0 : 1 - Math.max(0, left) / Math.max(1, total);
            arc(150, 147, 115, 135, Math.max(0, Math.min(1, p)) * 270, s.accent, 3);
            text(title, 45, 38, 17, s.ink, 210, 'center');
            text(n, 45, 95, 88, s.ink, 210, 'center', 800).font = 'digits';
            text(left===null?'天':left<0?'天前':left===0?'就是今天':'天后', 80, 210, 16, s.ink, 140, 'center');
            text(left===null?'设置目标日期':cap.date??'', 40, 270, 12, s.ink, 220, 'center');
        }
        else {
            const heading=text(title, 24, 21, 18);heading.lines=2;heading.h=46;
            text(n, 24, 87, n.length > 3 ? 104 : 132, s.ink, 252, 'left', 800).font = 'digits';
            text(left===null?'天':id==='anniversary-type'?(left>0?'天后':'天'):left<0?'天前':left===0?'就是今天':'天后', 24, 249, 17);
            text(left===null?'设置日期':cap.date??'', 127, 274, 11, s.ink, 150, 'right');
            if (id === 'countdown-paper')
                line(24, 69, 276, 69, s.ink, .4);
        }
    }
    else if (id.startsWith('day-')) {
        const p = Math.floor(dayP * 100);
        if (id === 'day-dial') {
            for (let i = 0; i < 24; i++) {
                arc(150, 146, 103, i * 15 - 88, 11, s.ink, 12).opacity = .12;
                const f = Math.max(0, Math.min(1, dayP * 24 - i));
                if (f > 0)
                    arc(150, 146, 103, i * 15 - 88, f * 11, s.accent, 12);
            }
            text(p + '%', 35, 108, 65, s.ink, 230, 'center', 300);
            text('今天', 100, 177, 14, s.ink, 100, 'center');
        }
        else if (id === 'day-blocks') {
            text('一天', 24, 20);
            text(p + '%', 210, 20, 16, s.ink, 66, 'right');
            for (let i = 0; i < 24; i++) {
                const m = rect(24 + i % 6 * 43, 75 + Math.floor(i / 6) * 40, 33, 31, s.accent, 5);
                m.opacity = i < now.getHours() ? 1 : .15;
            }
            date();
        }
        else {
            text('今天', 24, 24, 18);
            text(p + '%', 24, 70, 98);
            rect(24, 213, 252, 10, s.ink, 5).opacity = .15;
            rect(24, 213, 252 * dayP, 10, s.accent, 5);
            ['00', '06', '12', '18', '24'].forEach((v, i) => { text(v, 24 + i * 59, 237, 11); });
        }
    }
    else if (id.startsWith('year-')) {
        const total=(Date.UTC(year+1,0,1)-Date.UTC(year,0,1))/86400000,passed=(Date.UTC(year,month-1,day)-Date.UTC(year,0,1))/86400000;
        if (id === 'year-dots') {
            text(String(year), 24, 20, 29, s.ink, 160, 'left', 800).font = 'digits';
            text(Math.floor(yearP * 100) + '%', 213, 28, 13);
            for (let i = 0; i < total; i++) {
                const m = add('circle', 24 + i % 25 * 10, 72 + Math.floor(i / 25) * 10, 7, 7, i === passed ? '#CF6340' : s.accent);
                m.opacity = i <= passed ? 1 : .15;
            }
            text('已过 ' + passed + ' 天', 24, 270, 12);
            text('剩余 ' + (total - passed) + ' 天', 174, 270, 12);
        }
        else if (id === 'year-arc') {
            ring(yearP, Math.floor(yearP * 100) + '%', String(year));
            text(passed + ' 天已过', 24, 270, 12);
            text((total - passed) + ' 天剩余', 180, 270, 12);
        }
        else {
            text(String(year), 24, 20, 18);
            text(Math.floor(yearP * 100) + '%', 220, 20, 13);
            for (let i = 0; i < 12; i++) {
                const x = 24 + i % 4 * 66, y = 72 + Math.floor(i / 4) * 67;
                text(String(i + 1), x, y, 12);
                rect(x, y + 20, 50, 35, s.accent, 4).opacity = .13;
                const p = i < month - 1 ? 1 : i === month - 1 ? day / new Date(year, month, 0).getDate() : 0;
                if (p > 0)
                    rect(x, y + 20, 50 * p, 35, s.accent, 4);
            }
        }
    }
    else if (id.startsWith('battery-')) {
        const value = Number.isFinite(cap.percent) && cap.percent! >= 0 ? Math.max(0, Math.min(100, cap.percent!)) : null, n = value === null ? '—' : String(value);
        if (id === 'battery-ring')
            ring((value ?? 0) / 100, n, '本机电量');
        else if (id === 'battery-cell') {
            text('本机电量', 24, 22, 18);
            const shell = rect(83, 78, 134, 194, s.ink, 15);
            shell.stroke = 5;
            shell.opacity = 1;
            rect(132, 66, 36, 8, s.ink, 2);
            if (value !== null)
                rect(88, 267 - 184 * value / 100, 124, 184 * value / 100, s.accent, 10);
            rect(91,133,118,101,s.background,5).opacity=.94;
            text(n, 88, 137, 87, s.ink, 124, 'center', 800).font = 'digits';
        }
        else {
            text('本机电量', 34, 34, 14);
            text(n, 45, 88, 102, s.ink, 210, 'center', 400).font = 'monospace';
            for (let i = 0; i < 10; i++) {
                rect(34 + i * 24, 238, 18, 29, s.ink).opacity = .1;
                if (value !== null && value > i * 10)
                    rect(34 + i * 24, 238, 18 * Math.min(1, (value - i * 10) / 10), 29, s.ink);
            }
        }
    }
    else if (id.startsWith('agenda-')) {
        text(id === 'agenda-paper' ? '日程小记' : '接下来', 24, 24, 19);
        const events = agendaItems(cap, tick).slice(0, 3);
        if (!events.length)
            text('暂无日程', 24, 123, 24);
        events.forEach((e, i) => { const y = 83 + i * 65; text(e.allDay?'全天':timeText(e.start), 24, y, 13, s.accent, 50);if(new Date(e.start).toDateString()!==now.toDateString())text((new Date(e.start).getMonth()+1)+'/'+new Date(e.start).getDate(),24,y+24,10,s.accent,50); text(e.title, 90, y, i === 0 && id === 'agenda-editorial' ? 22 : 17, s.ink, 185, 'left', 500); if (e.location)
            text(e.location, 90, y + 27, 11, s.ink, 185).opacity = .55; if (id === 'agenda-paper' || id === 'agenda-editorial' && i === 0)
            line(24, y + 48, 276, y + 48, s.ink, .3); if (id === 'agenda-timeline'&&i<events.length-1)
            line(77, y + 4, 77, y + 65, s.accent, .5); });
    }
    else if (id.startsWith('course-')) {
        if (id === 'course-week') {
            text('周课表', 24, 20, 17);
            const week = semesterWeek(cap.semester ?? '', tick);
            text(!cap.semester?'导入课表':week<1?'未开学':(cap.courses??[]).length&&week>Math.max(...(cap.courses??[]).map(c=>c.lastWeek))?'学期已结束':'第 '+Math.max(1,week)+' 周',204,20,12,s.ink,72,'right');
            const items = weekLessons(cap, Math.max(1, week)), days = items.some(e => e.day > 5) ? 7 : 5, col = 234 / days, start = Math.min(480, ...items.map(e => new Date(e.event.start).getHours() * 60)), end = Math.max(1080, ...items.map(e => new Date(e.event.end).getHours() * 60 + new Date(e.event.end).getMinutes())), span = Math.max(60, end - start);
            ['一', '二', '三', '四', '五', '六', '日'].slice(0, days).forEach((v, i) => { text(v, 48 + i * col, 60, 12, s.ink, col, 'center'); });
            for (let i = 0; i < 5; i++) {
                const stamp=Math.round(start+span*i/4);text(('0'+Math.floor(stamp/60)).slice(-2)+':'+('0'+stamp%60).slice(-2),10,85+i*44,8.5,s.ink,32,'right');
                line(46, 92 + i * 44, 282, 92 + i * 44, s.ink, .2);
            }
            items.forEach(e => { const d = new Date(e.event.start), y = 89 + (d.getHours() * 60 + d.getMinutes() - start) / span * 177, h = Math.max(12, (e.event.end - e.event.start) / 60000 / span * 177), w = (col - 3) / Math.max(1, e.lanes), x = 48 + (e.day - 1) * col + e.lane * w; rect(x, y, w - 1, h, ['#CEDAD6', '#DDD5E5', '#E2D6BD'][e.day % 3], 3); if(w>=12&&h>=14){const label=text(e.event.title,x+2,y+2,Math.min(11,w*.45),'#303C37',Math.max(1,w-4));label.h=Math.max(1,h-4);} });
        }
        else {
            const events = courseInstances(cap, tick).filter(e => e.end > tick).slice(0, 3);
            text('接下来', 24, 22, 16);
            if (!events.length)
                text((cap.courses ?? []).length ? '暂无后续课程' : '导入你的课表', 24, 126, 25);
            else if (id === 'course-next') {
                const e = events[0];
                const title=text(e.title, 24, 83, 36, s.ink, 252, 'left', 600);title.lines=2;title.h=96;
                text((new Date(e.start).toDateString()===now.toDateString()?'':(new Date(e.start).getMonth()+1)+'月'+new Date(e.start).getDate()+'日 · ')+timeText(e.start)+'—'+timeText(e.end), 24, 234, 15);
                text(e.location, 24, 266, 12);
            }
            else
                events.forEach((e, i) => { const y = 77 + i * 66; rect(21, y, 258, 57, templateContrastInk(s.ink)==='#FFFFFF'?'#FFFFFF':'#000000', 5).opacity = templateContrastInk(s.ink)==='#FFFFFF'?.6:.18; text(timeText(e.start), 29, y + 12, 12, s.accent, 50); text(e.title, 91, y + 9, 17, s.ink, 172); text(e.location, 91, y + 34, 11, s.ink, 172).opacity = .6; });
        }
    }
    else if (id.startsWith('world-')) {
        if (id === 'world-dial') {
            drawDial();
            text(cap.city||'目的地',75,207,11,s.ink,88);text(hh+':'+mm,167,207,11,s.ink,58,'right');
        }
        else if (id === 'world-duo') {
            text('本地', 25, 25, 17, s.ink, 110, 'center');
            text(cap.city || '目的地', 166, 25, 17, s.accent, 110, 'center');
            const local = new Date(tick);
            [('0' + local.getHours()).slice(-2), hh].forEach((v, i) => { text(v, 25 + i * 141, 74, 78, i ? s.accent : s.ink, 110, 'center', 800).font = 'digits'; text(i ? mm : ('0' + local.getMinutes()).slice(-2), 25 + i * 141, 177, 78, i ? s.accent : s.ink, 110, 'center', 800).font = 'digits'; });
        }
        else {
            text(cap.city || '目的地', 24, 24, 18);
            text(hh + ':' + mm, 21, 103, 83, s.ink, 258, 'center', 800).font = 'digits';
            text((zoned.getUTCMonth() + 1) + '月' + zoned.getUTCDate() + '日', 24, 270, 13);
        }
    }
    else if (id.startsWith('lunar-')) {
        const l = lunarReading(tick), parts = l.date.split(' ');
        text(l.year, 24, 22, 16);
        if (id === 'lunar-seal') {
            (parts[0] ?? '').split('').forEach((letter, index) => { text(letter, 27, 85 + index * 29, 24, s.ink, 60, 'center'); });
            text(parts[1] ?? '', 114, 57, 65, s.ink, 150).font = 'serif';
        }
        else {
            text(parts[0] ?? '', 24, 80, 52, s.ink, 252).font = 'serif';
            text(parts[1] ?? '', 24, 160, 52, s.ink, 252).font = 'serif';
        }
        date();
    }
    else if (id.startsWith('album-')) {
        const album = activeAlbum(cap, tick), cover = album.cover;
        if (id === 'album-record') {
            add('circle', 99, 30, 183, 183, '#252724');
            for (let i = 0; i < 12; i++)
                arc(190, 121, 40 + i * 4, 0, 360, '#52584C', .4);
            if(!cover)rect(22,42,164,164,'#EFE7D8',3);image(cover, 22, 42, 164, 164);
        }
        else if (id === 'album-sleeve') {
            rect(42, 21, 216, 203, '#DCD3BE', 3);
            image(cover, 62, 39, 176, 150);
        }
        else
            image(cover, 18, 18, 264, 206);
        if (!cover)
            text('选择本地封面', id==='album-record'?28:45, 100, id==='album-record'?16:20, id==='album-record'?'#40382C':s.ink, id==='album-record'?152:210, 'center');
        text(album.title || '专辑名称', 24, 243, 20, s.ink, 252, 'left', 600);
        text(album.artist || '', 24, 272, 12, s.ink, 252).opacity = .6;
    }
    else
        drawDial();
    return s;
}
