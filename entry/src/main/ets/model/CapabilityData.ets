import { nextCityBoundary } from './TimeCapabilities';
import { parsePickupNotice } from './ParcelIntake';
import { dateKey, holidayName } from './HolidayCalendar';
import { CapBlock, CourseItem, AgendaItem, ParcelItem } from './CardSchema';
export interface ValueField { path: string; value: string; }
/** Only scalar values, bounded depth/count and own properties. Never execute remote code. */
export function valueFields(body: string): ValueField[] {
  if (body.length > 262144) throw new Error('内容过大，请使用轻量 JSON 接口');
  const trimmed = body.trim();
  if (!trimmed.startsWith('{') && !trimmed.startsWith('[')) {
    if (/<(?:html|script|!doctype)/i.test(trimmed)) throw new Error('网页需要 JavaScript 或 HTML 解析，请使用 JSON / 纯文本接口');
    return [{path:'',value:trimmed.slice(0,256)}];
  }
  const out: ValueField[] = []; walkValues(JSON.parse(trimmed) as Object,'',0,out);
  if (!out.length) throw new Error('接口没有可显示的内容'); return out;
}
function walkValues(value: Object | null, path: string, depth: number, out: ValueField[]): void {
  if(out.length>=64 || depth>8 || value===null) return;
  if(typeof value==='string'||typeof value==='number'||typeof value==='boolean') { out.push({path:path,value:String(value).slice(0,256)}); return; }
  const record = value as Record<string,Object>;
  for(const key of Object.keys(record).slice(0,64)) {
    if(['__proto__','prototype','constructor'].includes(key) || key.includes('.')) continue;
    walkValues(record[key],path?path+'.'+key:key,depth+1,out);
  }
}
export function selectValue(body: string, path: string): string {
  const list=valueFields(body), found=list.find((v)=>v.path===path);
  if(!found) throw new Error('选中的内容已不存在'); return found.value;
}
export function validSourceURL(url: string): boolean { return /^https?:\/\/[^\s/?#]+(?:[/?#][^\s]*)?$/.test(url) && url.length<=2048 && !/^https?:\/\/[^/]*@/.test(url); }
export function capabilityRequestKey(cap: CapBlock): string { return [cap.k,cap.url??'',cap.field??'',cap.agendaSource??''].join('|'); }
export function needsDataRefresh(cap: CapBlock | null, now: number = Date.now()): boolean {
  if(cap===null) return false;
  if(cap.k==='battery') return true;
  if(cap.k==='agenda') return cap.agendaSource==='system' && now-(cap.attemptedAt??0)>=15*60000;
  return cap.k==='fetch' && cap.sourceConfigured===true && validSourceURL(cap.url??'') && now-(cap.attemptedAt??0)>=Math.max(30,cap.interval??60)*60000;
}
export function agendaItems(cap: CapBlock, now: number): AgendaItem[] { return (cap.events??[]).filter((e)=>e.end>now).sort((a,b)=>a.start-b.start).slice(0,3); }
export function timeText(time: number): string { const d=new Date(time); return ('0'+d.getHours()).slice(-2)+':'+('0'+d.getMinutes()).slice(-2); }
export function eventWhen(event: AgendaItem, now: number): string {
  const d=new Date(event.start),today=new Date(now), day=new Date(d.getFullYear(),d.getMonth(),d.getDate()).getTime(), t=new Date(today.getFullYear(),today.getMonth(),today.getDate()).getTime();
  return (day===t?'今天':day===t+86400000?'明天':(d.getMonth()+1)+'月'+d.getDate()+'日')+' '+(event.allDay?'全天':timeText(event.start));
}
export function semesterWeek(semester: string, now: number): number {
  const start=new Date(semester+'T00:00:00'),d=new Date(now);
  if(isNaN(start.getTime())) return 0;
  // UTC dates avoid DST turning a semester week into 6.96 days.
  return Math.floor((Date.UTC(d.getFullYear(),d.getMonth(),d.getDate())-Date.UTC(start.getFullYear(),start.getMonth(),start.getDate()))/604800000)+1;
}
/** All effective lessons for one civil day, including finished lessons (brief/week view). */
export function coursesOnDay(cap: CapBlock, time: number): AgendaItem[] {
  const out: AgendaItem[] = [], key = dateKey(new Date(time));
  const days = cap.teachingDays ?? [], changes = cap.courseChanges ?? [];
  const override = days.slice().reverse().find((d) => d.date === key);
  const movedAway = days.some((d) => d.sourceDate === key && d.date !== key);
  const holiday = holidayName(new Date(time)).length > 0 || (cap.holidayDates ?? []).some((d) => d.date === key);
  const sourceKey = override ? override.sourceDate : (movedAway || cap.skipHolidays !== false && holiday ? '' : key);
  if (sourceKey) {
    const source = new Date(sourceKey + 'T12:00:00'), week = semesterWeek(cap.semester ?? '', source.getTime()), day = source.getDay() || 7;
    for (const c of cap.courses ?? []) {
      if (!courseInWeek(c, week) || c.day !== day || changes.some((change) => change.courseId === c.id && change.date === sourceKey)) continue;
      appendCourse(out, c, key, c.start, c.end, c.room, 'regular');
    }
  }
  if (override?.sourceDate !== '') for (const change of changes) {
    if (change.targetDate !== key) continue;
    const c = (cap.courses ?? []).find((item) => item.id === change.courseId); if (!c) continue;
    const source = new Date(change.date + 'T12:00:00');
    if ((source.getDay() || 7) !== c.day || !courseInWeek(c, semesterWeek(cap.semester ?? '', source.getTime()))) continue;
    appendCourse(out, c, key, change.start, change.end, change.room, change.id);
  }
  return out.sort((a, b) => a.start - b.start || a.end - b.end || a.id.localeCompare(b.id));
}
export function courseInWeek(c: CourseItem, week: number): boolean {
  return week >= c.firstWeek && week <= c.lastWeek && !(c.parity === 1 && week % 2 === 0) && !(c.parity === 2 && week % 2 !== 0);
}
export function courseInstances(cap: CapBlock, now: number): AgendaItem[] {
  const out: AgendaItem[] = [], day = new Date(now); day.setHours(12, 0, 0, 0);
  for (let offset = 0; offset < 14; offset++) {
    const date = new Date(day.getTime()); date.setDate(date.getDate() + offset);
    out.push(...coursesOnDay(cap, date.getTime()).filter((e) => e.end > now));
  }
  return out.sort((a, b) => a.start - b.start).slice(0, 3);
}
function appendCourse(out: AgendaItem[], course: CourseItem, date: string, startText: string, endText: string, room: string, suffix: string): void {
  const start = new Date(date + 'T' + startText + ':00'), end = new Date(date + 'T' + endText + ':00');
  out.push({id: course.id + '_' + date + '_' + suffix, courseId: course.id, title: course.name, start: start.getTime(), end: end.getTime(), location: room, allDay: false});
}
export class TimetableDisplay {
  date: number = 0;
  heading: string = '';
  empty: string = '';
  lessons: AgendaItem[] = [];
}
export const NEXT_LESSON_LEAD: number = 10 * 60000;
export const TIMETABLE_EVENING: number = 20;
export function timetableDisplay(cap: CapBlock, now: number): TimetableDisplay {
  const out = new TimetableDisplay(), today = new Date(now), tomorrow = new Date(now); tomorrow.setDate(tomorrow.getDate() + 1);
  const lessons = coursesOnDay(cap, now); let nextDay = false;
  if (cap.timetableMode === 'day') {
    nextDay = lessons.length > 0 ? lessons.every((e) => e.end <= now) : today.getHours() >= TIMETABLE_EVENING;
    out.lessons = nextDay ? coursesOnDay(cap, tomorrow.getTime()) : lessons;
    out.heading = nextDay ? '明日课程' : '今日课程';
  } else {
    // Advance at the end-of-class lead time; short lessons remain visible before they begin.
    out.lessons = lessons.filter((e) => e.start > now || e.end - NEXT_LESSON_LEAD > now).slice(0, 1);
    if (!out.lessons.length && today.getHours() >= TIMETABLE_EVENING) {
      out.lessons = coursesOnDay(cap, tomorrow.getTime()).slice(0, 1); nextDay = true;
    }
    out.heading = nextDay ? '明日第一课' : out.lessons.length && out.lessons[0].start <= now ? '正在上课' : '下一课';
  }
  if(!out.lessons.length && cap.timetableMode!=='day')out.heading='课程表';
  out.date = nextDay ? tomorrow.getTime() : now;
  const reason = teachingDayLabel(cap, out.date);
  out.empty = !(cap.courses ?? []).length ? '添加课程表' : reason || (nextDay ? '明日无课' : lessons.length ? lessons.some((e)=>e.end>now)?'本节即将结束':'今日课程已结束' : '今日无课');
  return out;
}
export function teachingDayLabel(cap:CapBlock,now:number):string {
  const date=new Date(now),key=dateKey(date),rule=(cap.teachingDays??[]).slice().reverse().find((d)=>d.date===key);
  if(rule)return rule.sourceDate===''?'校历停课':rule.sourceDate===key?'按校历上课':'补 '+rule.sourceDate.slice(5)+' 的课程';
  if((cap.courseChanges??[]).some((c)=>c.targetDate===key))return '单次调课';
  const name=(cap.holidayDates??[]).find((d)=>d.date===key)?.name||holidayName(date);
  return cap.skipHolidays!==false&&name?name+' · 假期':(cap.teachingDays??[]).some((d)=>d.sourceDate===key&&d.date!==key)?'今日课程已调走':'';
}
/** Contextual pickup labels only: do not mistake login verification or an order number for a pickup code. */
export function pickupCandidates(text: string): ParcelItem[] { return parsePickupNotice(text); }
export function pendingParcels(cap: CapBlock): ParcelItem[] { return (cap.parcels??[]).filter((p)=>!p.picked); }
export function nextDataBoundary(cap: CapBlock, now:number):number {
  const tomorrow = new Date(now); tomorrow.setDate(tomorrow.getDate()+1);
  const events=cap.k==='agenda'?agendaItems(cap,now):cap.k==='timetable'?coursesOnDay(cap,now).concat(coursesOnDay(cap,tomorrow.getTime())):[];
  const midnight=new Date(now);midnight.setHours(24,0,0,0);
  const boundaries=events.reduce((all:number[],e:AgendaItem):number[]=>all.concat([e.start,e.end]),[]).filter((t)=>t>now);
  if(cap.k==='worldclock')boundaries.push(nextCityBoundary(cap.zone??'',now));
  if(cap.k==='lunar')boundaries.push(midnight.getTime());
  if(cap.k==='timetable'||cap.k==='agenda')boundaries.push(midnight.getTime());
  if(cap.k==='timetable') {
    const evening=new Date(now);evening.setHours(TIMETABLE_EVENING,0,0,0);
    if(evening.getTime()>now)boundaries.push(evening.getTime());
    if(cap.timetableMode!=='day')for(const e of events)if(e.end-NEXT_LESSON_LEAD>now)boundaries.push(e.end-NEXT_LESSON_LEAD);
  }
  if(cap.k==='fetch')boundaries.push(Math.max(now+5*60000,(cap.attemptedAt??0)+Math.max(30,cap.interval??60)*60000));
  return boundaries.length?Math.min(...boundaries):now+30*60000;
}

export function mergeCapabilityResult(current:CapBlock,result:CapBlock):CapBlock {
  const next=JSON.parse(JSON.stringify(current)) as CapBlock;
  next.attemptedAt=result.attemptedAt;next.updatedAt=result.updatedAt;next.refreshState=result.refreshState;next.desc=result.desc;
  if(current.k==='battery'){next.percent=result.percent;next.charging=result.charging;next.chargeState=result.chargeState;}
  if(current.k==='agenda')next.events=result.events;
  if(current.k==='fetch')next.value=result.value;
  return next;
}
