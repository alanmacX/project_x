import { CapBlock, CourseItem, AgendaItem, TeachingDay, CourseChange } from './CardSchema';
import { HolidayDate } from './HolidayCalendar';
import { coursesOnDay, courseInWeek } from './CapabilityData';
export const LESSON_MIN_WIDTH:number=104;
export const LESSON_CELL_HEIGHT: number = 32;
export const BRIEF_HEADER_HEIGHT: number = 18;
const counts = new Map<string, number>();
class CapacityRecord {
  semester: string = '';
  courses: CourseItem[] | undefined = undefined;
  days: TeachingDay[] | undefined = undefined;
  changes: CourseChange[] | undefined = undefined;
  holidays: HolidayDate[] | undefined = undefined;
  skipHolidays: boolean = true;
  count: number = 1;
}
const identities = new WeakMap<CapBlock, CapacityRecord>();
function remember(cap: CapBlock, count: number): number {
  const record = new CapacityRecord(); record.semester=cap.semester??'';record.courses=cap.courses;record.days=cap.teachingDays;record.changes=cap.courseChanges;record.holidays=cap.holidayDates;record.skipHolidays=cap.skipHolidays!==false;record.count=count;
  identities.set(cap,record);return count;
}
/** Reserve the busiest day across the semester and explicit transfers, not just today's count. */
export function timetableCapacity(cap: CapBlock): number {
  const identity=identities.get(cap);
  if(identity && identity.semester===(cap.semester??'') && identity.courses===cap.courses && identity.days===cap.teachingDays && identity.changes===cap.courseChanges && identity.holidays===cap.holidayDates && identity.skipHolidays===(cap.skipHolidays!==false))return identity.count;
  const key = JSON.stringify([cap.semester, cap.courses, cap.teachingDays, cap.courseChanges, cap.holidayDates, cap.skipHolidays!==false]);
  const cached = counts.get(key); if (cached !== undefined) return remember(cap,cached);
  let maximum = 1;
  for (let week = 1; week <= 60; week++) {
    const days: number[] = [0, 0, 0, 0, 0, 0, 0];
    for (const c of cap.courses ?? []) if (courseInWeek(c, week)) days[c.day - 1]++;
    maximum = Math.max(maximum, ...days);
  }
  const dates = (cap.teachingDays ?? []).map((d) => d.date).concat((cap.courseChanges ?? []).map((d) => d.targetDate)).filter((d) => d.length > 0);
  for (const date of Array.from(new Set<string>(dates))) maximum = Math.max(maximum, coursesOnDay(cap, new Date(date + 'T12:00:00').getTime()).length);
  if (counts.size >= 64) counts.clear(); counts.set(key, maximum); return remember(cap,maximum);
}
export function briefColumns(width: number): number { return width >= 312 ? 3 : width >= 208 ? 2 : 1; }
/** Extra height buys readable title/room lines, never a larger copy of the same tile. */
export function lessonRowHeight(height:number,count:number,columns:number):number {
  const available=(height-BRIEF_HEADER_HEIGHT)/Math.ceil(Math.max(1,count)/Math.max(1,columns));
  return available>=60?60:available>=48?48:LESSON_CELL_HEIGHT;
}
export function lessonContext(event:AgendaItem,now:number):string {
  if(event.start>now){const minutes=Math.ceil((event.start-now)/60000);return minutes<60?'距上课 '+minutes+' 分钟':'课程时长 '+Math.round((event.end-event.start)/60000)+' 分钟';}
  return event.end>now?'剩余 '+Math.ceil((event.end-now)/60000)+' 分钟':'';
}
export function briefHeight(count: number, columns: number): number { return BRIEF_HEADER_HEIGHT + Math.ceil(Math.max(1, count) / columns) * LESSON_CELL_HEIGHT; }
export class WeekLesson {
  event: AgendaItem = {id: '', title: '', start: 0, end: 0, location: '', allDay: false};
  day: number = 1;
  lane: number = 0;
  lanes: number = 1;
}
export function weekStart(semester: string, week: number): number {
  const start = new Date(semester + 'T12:00:00'); start.setDate(start.getDate() + (week - 1) * 7); return start.getTime();
}
/** Same effective calendar engine as the widget; overlapping courses get separate lanes. */
export function weekLessons(cap: CapBlock, week: number): WeekLesson[] {
  const start = weekStart(cap.semester ?? '', week); if (isNaN(start)) return [];
  const out: WeekLesson[] = [];
  for (let day = 1; day <= 7; day++) {
    const date = new Date(start); date.setDate(date.getDate() + day - 1);
    const events = coursesOnDay(cap, date.getTime()); let cluster: WeekLesson[] = [], ends: number[] = [], clusterEnd = 0;
    for (const event of events) {
      if (event.start >= clusterEnd) { for (const item of cluster) item.lanes = ends.length; cluster = []; ends = []; }
      let lane = ends.findIndex((end) => end <= event.start); if (lane < 0) lane = ends.length;
      ends[lane] = event.end; clusterEnd = Math.max(clusterEnd, event.end);
      const item = new WeekLesson(); item.event = event; item.day = day; item.lane = lane; cluster.push(item); out.push(item);
    }
    for (const item of cluster) item.lanes = ends.length;
  }
  return out;
}
export function minuteOf(time: number): number { const d = new Date(time); return d.getHours() * 60 + d.getMinutes(); }
