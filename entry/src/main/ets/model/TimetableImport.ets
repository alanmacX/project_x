import { CapBlock, CourseItem } from './CardSchema';
/** Each timetable owns its calendar. Replacement never silently borrows another school/term's exceptions. */
export function applyTimetableImport(cap:CapBlock,semester:string,courses:CourseItem[],replace:boolean,keepCalendar:boolean=false):CapBlock {
  const next=JSON.parse(JSON.stringify(cap)) as CapBlock,list:CourseItem[]=replace?[]:(next.courses??[]).slice();
  if(!replace&&list.length&&next.semester!==semester)throw new Error('开学日期不同，请选择替换或先建立另一张课程卡');
  for(const c of courses)if(!list.some((v)=>v.name===c.name&&v.room===c.room&&v.day===c.day&&v.start===c.start&&v.end===c.end&&v.firstWeek===c.firstWeek&&v.lastWeek===c.lastWeek&&v.parity===c.parity))list.push(c);
  if(list.length>128)throw new Error('合并后超过 128 条，请分成两张课程卡');
  next.semester=semester;next.courses=list;
  if(replace) {
    next.courseChanges=[];
    if(!keepCalendar){next.teachingDays=[];next.holidayDates=[];}
  }
  return next;
}
