/** Published mainland China holiday schedules; no extrapolation to unpublished years. */
export interface HolidayPeriod { start: string; end: string; name: string; }
export interface HolidayDate { date: string; name: string; }
export const HOLIDAY_PERIODS: HolidayPeriod[] = [
  {start:'2025-01-01',end:'2025-01-01',name:'元旦'},
  {start:'2025-01-28',end:'2025-02-04',name:'春节'},
  {start:'2025-04-04',end:'2025-04-06',name:'清明节'},
  {start:'2025-05-01',end:'2025-05-05',name:'劳动节'},
  {start:'2025-05-31',end:'2025-06-02',name:'端午节'},
  {start:'2025-10-01',end:'2025-10-08',name:'国庆／中秋'},
  {start:'2026-01-01',end:'2026-01-03',name:'元旦'},
  {start:'2026-02-15',end:'2026-02-23',name:'春节'},
  {start:'2026-04-04',end:'2026-04-06',name:'清明节'},
  {start:'2026-05-01',end:'2026-05-05',name:'劳动节'},
  {start:'2026-06-19',end:'2026-06-21',name:'端午节'},
  {start:'2026-09-25',end:'2026-09-27',name:'中秋节'},
  {start:'2026-10-01',end:'2026-10-07',name:'国庆节'}
];
const WORK_DAYS: string[] = ['2025-01-26','2025-02-08','2025-04-27','2025-09-28','2025-10-11',
  '2026-01-04','2026-02-14','2026-02-28','2026-05-09','2026-09-20','2026-10-10'];
export function dateKey(date: Date): string { return date.getFullYear()+'-'+('0'+(date.getMonth()+1)).slice(-2)+'-'+('0'+date.getDate()).slice(-2); }
export function validDay(value: string): boolean {
  if(typeof value!=='string'||!/^\d{4}-\d{2}-\d{2}$/.test(value))return false;
  const date=new Date(value+'T12:00:00');return Number.isFinite(date.getTime())&&dateKey(date)===value;
}
export function holidayKnown(year: number): boolean { return year===2025||year===2026; }
export function holidayName(date: Date): string {
  const key=dateKey(date),period=HOLIDAY_PERIODS.find((p:HolidayPeriod)=>key>=p.start&&key<=p.end);return period?.name??'';
}
export function holidayMarker(date: Date): string { return holidayName(date)?'休':WORK_DAYS.includes(dateKey(date))?'班':''; }
export function daysBetween(start: string,end: string): string[] {
  if(!validDay(start)||!validDay(end)||end<start)throw new Error('请选择有效的起止日期');
  const out:string[]=[],date=new Date(start+'T12:00:00');
  while(dateKey(date)<=end&&out.length<=120){out.push(dateKey(date));date.setDate(date.getDate()+1);}
  if(out.length>120)throw new Error('单次最多设置 120 天');return out;
}
/** All-day, explicit-date ICS only; recurrence is rejected rather than silently misread. */
export function holidayFileDates(text:string):HolidayDate[] {
  if(text.length>1048576||!text.includes('BEGIN:VCALENDAR'))throw new Error('请选择有效的节假日日历 .ics 文件');
  const blocks=text.replace(/\r?\n[ \t]/g,'').match(/BEGIN:VEVENT[\s\S]*?END:VEVENT/g)??[],out:HolidayDate[]=[];
  for(const block of blocks){
    if(/\n(?:RRULE|RDATE|EXDATE|RECURRENCE-ID)[;:]/.test(block))throw new Error('请导出含明确日期的假期日历，不支持循环规则');
    const start=block.match(/(?:^|\n)DTSTART(?:;VALUE=DATE)?:([0-9]{8})\r?\n/),end=block.match(/(?:^|\n)DTEND(?:;VALUE=DATE)?:([0-9]{8})\r?\n/);
    if(!start)throw new Error('假期日历须为全天事件，普通日程请从日程能力导入');
    const key=(v:string):string=>v.slice(0,4)+'-'+v.slice(4,6)+'-'+v.slice(6);
    const first=key(start[1]);let last=first;
    if(end){const exclusive=key(end[1]);if(!validDay(exclusive)||exclusive<=first)throw new Error('假期结束日期无效');const date=new Date(exclusive+'T12:00:00');date.setDate(date.getDate()-1);last=dateKey(date);}
    const name=(block.match(/(?:^|\n)SUMMARY(?:;[^:]*)?:([^\r\n]*)/)?.[1]??'校历假期').replace(/\\n/g,' ').replace(/\\([,;\\])/g,'$1').slice(0,60);
    for(const date of daysBetween(first,last))if(!out.some((v:HolidayDate)=>v.date===date))out.push({date:date,name:name});
    if(out.length>512)throw new Error('假期日历超过 512 天');
  }
  if(!out.length)throw new Error('文件中没有明确的全天假期');return out;
}
