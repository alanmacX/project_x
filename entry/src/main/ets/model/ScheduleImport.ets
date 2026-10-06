import { AgendaItem, CourseItem, CapBlock, normalizeCapability } from './CardSchema';
interface IcsDate { wall:number; zone:string; allDay:boolean; }
function dateParts(line:string):IcsDate {
  const value=line.slice(line.indexOf(':')+1).trim(),match=value.match(/^(\d{4})(\d{2})(\d{2})(?:T(\d{2})(\d{2})(\d{2})(Z)?)?$/);
  if(!match)throw new Error('日历日期无法读取');
  const y=Number(match[1]),m=Number(match[2])-1,d=Number(match[3]),h=Number(match[4]??0),minute=Number(match[5]??0),second=Number(match[6]??0);
  const date=new Date(Date.UTC(y,m,d,h,minute,second));
  if(date.getUTCFullYear()!==y||date.getUTCMonth()!==m||date.getUTCDate()!==d||h>23||minute>59||second>59)throw new Error('日历日期不正确');
  const zone=line.match(/TZID=([^;:]+)/);
  return {wall:date.getTime(),zone:match[7]?'UTC':zone?zone[1]:'',allDay:line.includes('VALUE=DATE')||!match[4]};
}
function instant(date:IcsDate,offset:((zone:string,time:number)=>number)|undefined):number {
  if(date.zone==='UTC')return date.wall;
  if(!date.zone){const d=new Date(date.wall);return new Date(d.getUTCFullYear(),d.getUTCMonth(),d.getUTCDate(),d.getUTCHours(),d.getUTCMinutes(),d.getUTCSeconds()).getTime();}
  if(!offset)throw new Error('该日历的命名时区无法读取');
  let value=date.wall;for(let i=0;i<3;i++)value=date.wall-offset(date.zone,value);return value;
}
function unescapeText(value:string):string {return value.replace(/\\n/gi,' ').replace(/\\([,;\\])/g,'$1');}
/** Expand supported recurrence on a worker, including exceptions and DST-aware named time zones. */
export function importAgenda(text:string,now:number=Date.now(),offset?:((zone:string,time:number)=>number),horizonDays:number=90,limit:number=256):AgendaItem[] {
  if(text.length>1048576||!text.includes('BEGIN:VCALENDAR'))throw new Error('请选择有效的 .ics 日历文件');
  const blocks=text.replace(/\r\n[ \t]/g,'').replace(/\n[ \t]/g,'').split('BEGIN:VEVENT').slice(1),out:AgendaItem[]=[],windowEnd=now+horizonDays*86400000;
  if(blocks.length>4096)throw new Error('日历超过 4096 项，请导出需要的日程');
  for(const block of blocks) {
    const lines=block.split(/\r?\n/),startLine=lines.find((l)=>l.startsWith('DTSTART'))??'',endLine=lines.find((l)=>l.startsWith('DTEND'))??'';
    if(!startLine||lines.includes('STATUS:CANCELLED'))continue;
    if(lines.some((l)=>l.startsWith('RECURRENCE-ID')))throw new Error('包含修改单次重复事件的日历，请先导出展开后的日程');
    const start:IcsDate=dateParts(startLine),end:IcsDate=endLine?dateParts(endLine):{wall:start.wall+(start.allDay?86400000:3600000),zone:start.zone,allDay:start.allDay};
    const duration=end.zone===start.zone?end.wall-start.wall:instant(end,offset)-instant(start,offset);if(duration<0)throw new Error('日程起止时间不正确');
    const title=lines.find((l)=>l.startsWith('SUMMARY:'))??'SUMMARY:未命名日程',location=lines.find((l)=>l.startsWith('LOCATION:'))??'LOCATION:',uid=(lines.find((l)=>l.startsWith('UID:'))??'UID:'+out.length).slice(4,68),ruleLine=lines.find((l)=>l.startsWith('RRULE:'))??'';
    const exceptions:number[]=[],extra:number[]=[];
    for(const l of lines.filter((v)=>v.startsWith('EXDATE')||v.startsWith('RDATE'))){const prefix=l.slice(0,l.indexOf(':')+1);for(const v of l.slice(l.indexOf(':')+1).split(',')){const time=instant(dateParts(prefix+v),offset);if(l.startsWith('EXDATE'))exceptions.push(time);else extra.push(time);}}
    const candidates:number[]=[start.wall];
    if(ruleLine) {
      const rule:Record<string,string>={};for(const field of ruleLine.slice(6).split(';')){const at=field.indexOf('=');rule[field.slice(0,at)]=field.slice(at+1);}
      if(!['DAILY','WEEKLY'].includes(rule['FREQ'])||Object.keys(rule).some((k)=>!['FREQ','INTERVAL','COUNT','UNTIL','BYDAY','WKST'].includes(k)))throw new Error('目前日历导入支持每日 / 每周重复；复杂重复请导出展开后的日程');
      const interval=Number(rule['INTERVAL']??1),count=Number(rule['COUNT']??100000),weekStart=rule['WKST']??'MO';
      if(!Number.isInteger(interval)||interval<1||interval>366||!Number.isInteger(count)||count<1||count>100000||!['MO','SU'].includes(weekStart))throw new Error('日历重复参数不正确');
      const byDay=(rule['BYDAY']??'').split(',').filter((v)=>v.length>0),days=['SU','MO','TU','WE','TH','FR','SA'];
      if(byDay.some((v)=>!days.includes(v)))throw new Error('此日历包含暂未支持的星期序号规则');
      const until=rule['UNTIL']?instant(dateParts('DTSTART:'+rule['UNTIL']),offset):windowEnd,origin=new Date(start.wall),firstDay=origin.getUTCDay(),weekBase=(firstDay-(weekStart==='MO'?1:0)+7)%7;
      candidates.length=0;let sequence=0;
      const maxDays=Math.ceil((windowEnd-start.wall)/86400000)+2;if(maxDays>5000)throw new Error('重复日程起始日期过早，请导出近期日历');
      for(let day=0;day<=Math.max(0,maxDays);day++) {
        const wall=start.wall+day*86400000,weekday=new Date(wall).getUTCDay(),eligible=rule['FREQ']==='DAILY'?day%interval===0:Math.floor((day+weekBase)/7)%interval===0;
        if(!eligible||(byDay.length?!byDay.includes(days[weekday]):rule['FREQ']==='WEEKLY'&&weekday!==firstDay))continue;
        const time=instant({wall:wall,zone:start.zone,allDay:start.allDay},offset);if(time>until||sequence>=count)break;
        sequence++;if(time+duration>now&&time<windowEnd)candidates.push(wall);
      }
    }
    for(const wall of candidates) {
      const time=instant({wall:wall,zone:start.zone,allDay:start.allDay},offset),finish=end.zone===start.zone?instant({wall:wall+duration,zone:end.zone,allDay:end.allDay},offset):time+duration;
      if(!exceptions.includes(time)&&finish>now&&time<windowEnd)out.push({id:uid+'_'+time,title:unescapeText(title.slice(8)).slice(0,160),start:time,end:finish,location:unescapeText(location.slice(9)).slice(0,160),allDay:start.allDay});
    }
    for(const time of extra)if(!exceptions.includes(time)&&time+duration>now&&time<windowEnd)out.push({id:uid+'_'+time,title:unescapeText(title.slice(8)).slice(0,160),start:time,end:time+duration,location:unescapeText(location.slice(9)).slice(0,160),allDay:start.allDay});
  }
  return out.sort((a,b)=>a.start-b.start).filter((e:AgendaItem,i:number,list:AgendaItem[])=>list.findIndex((v)=>v.id===e.id)===i).slice(0,limit);
}
export function importCourses(text:string):CourseItem[] {
  if(text.length>1048576)throw new Error('课程文件过大');
  let input:CourseItem[];
  try {input=JSON.parse(text) as CourseItem[];}catch(_){throw new Error('请选择课程 JSON 文件');}
  if(!Array.isArray(input)||input.length>128)throw new Error('课程文件必须是一组课程，最多 128 条');
  if(input.some((c:CourseItem)=>!c||!Number.isInteger(c.day)||c.day<1||c.day>7))throw new Error('课程星期必须是 1（周一）至 7（周日）');
  input.forEach((c:CourseItem,index:number)=>{if(c)c.id='course_'+Date.now()+'_'+index;});
  const cap:CapBlock={k:'timetable',courses:input},clean=normalizeCapability(cap).courses??[];
  if(clean.length!==input.length)throw new Error('部分课程缺少名称、星期或有效起止时间，请校对后重试');
  return clean;
}

export interface CourseCalendar {semester:string;courses:CourseItem[];}
/** Preserve actual exported occurrences: gaps and changed locations become distinct week runs. */
export function importCourseCalendar(text:string,offset?:((zone:string,time:number)=>number)):CourseCalendar {
  const unfolded=text.replace(/\r\n[ \t]/g,'').replace(/\n[ \t]/g,'');
  const starts=unfolded.split('BEGIN:VEVENT').slice(1).map((block:string)=>block.split('END:VEVENT')[0].split(/\r?\n/).find((l:string)=>l.startsWith('DTSTART'))??'').filter((l:string)=>l.length>0);
  if(!starts.length)throw new Error('日历中没有课程');
  if(text.length>1048576||starts.length>4096)throw new Error('课程日历过大，请只导出本学期');
  const first=Math.min(...starts.map((l:string)=>instant(dateParts(l),offset)));
  if(starts.some((l:string)=>instant(dateParts(l),offset)>first+419*86400000))throw new Error('课程跨度超过 60 周，请只导出本学期');
  const day=new Date(first);day.setHours(0,0,0,0);
  const events=importAgenda(text,day.getTime()-1,offset,420,4097);
  if(events.length>4096)throw new Error('课程次数超过 4096，请只导出本学期');
  if(!events.length||events.some((e:AgendaItem)=>e.allDay))throw new Error('请选择包含上课起止时间的课程日历，不是全天日程');
  const origin=new Date(events[0].start);origin.setHours(12,0,0,0);origin.setDate(origin.getDate()-((origin.getDay()+6)%7));
  const semester=origin.getFullYear()+'-'+('0'+(origin.getMonth()+1)).slice(-2)+'-'+('0'+origin.getDate()).slice(-2);
  const base=Date.UTC(origin.getFullYear(),origin.getMonth(),origin.getDate()),out:CourseItem[]=[];
  for(const e of events) {
    const start=new Date(e.start),end=new Date(e.end);
    if(start.toDateString()!==end.toDateString()||e.end<=e.start)throw new Error('课程不能跨天，请检查日历');
    const week=Math.floor((Date.UTC(start.getFullYear(),start.getMonth(),start.getDate())-base)/604800000)+1;
    if(week>60)throw new Error('课程跨度超过 60 周，请只导出本学期');
    const a=('0'+start.getHours()).slice(-2)+':'+('0'+start.getMinutes()).slice(-2),b=('0'+end.getHours()).slice(-2)+':'+('0'+end.getMinutes()).slice(-2),weekday=start.getDay()||7;
    const same=out.find((c:CourseItem)=>c.name===e.title&&c.room===e.location&&c.day===weekday&&c.start===a&&c.end===b&&week>=c.firstWeek&&week<=c.lastWeek+1);
    if(same)same.lastWeek=Math.max(same.lastWeek,week);
    else out.push({id:'ics_'+out.length,name:e.title.slice(0,80),room:e.location.slice(0,80),day:weekday,start:a,end:b,firstWeek:week,lastWeek:week,parity:0});
  }
  if(out.length>128)throw new Error('转换后超过 128 条安排，请按学期或课程分开导入');
  return {semester:semester,courses:out};
}

export function mergeCourseCalendars(calendars:CourseCalendar[]):CourseCalendar {
  if(!calendars.length)throw new Error('请选择课程日历');
  const semester=calendars.map((c:CourseCalendar)=>c.semester).sort()[0],base=new Date(semester+'T12:00:00'),baseDay=Date.UTC(base.getFullYear(),base.getMonth(),base.getDate()),courses:CourseItem[]=[];
  for(const calendar of calendars) {
    const start=new Date(calendar.semester+'T12:00:00'),shift=Math.round((Date.UTC(start.getFullYear(),start.getMonth(),start.getDate())-baseDay)/604800000);
    for(const c of calendar.courses) {
      const item:CourseItem={id:'ics_'+courses.length,name:c.name,room:c.room,day:c.day,start:c.start,end:c.end,firstWeek:c.firstWeek+shift,lastWeek:c.lastWeek+shift,parity:0};
      if(item.lastWeek>60)throw new Error('课程跨越不同学期，请分开导入');
      if(!courses.some((v:CourseItem)=>v.name===item.name&&v.room===item.room&&v.day===item.day&&v.start===item.start&&v.end===item.end&&v.firstWeek===item.firstWeek&&v.lastWeek===item.lastWeek))courses.push(item);
    }
  }
  if(courses.length>128)throw new Error('合并后超过 128 条安排，请分开导入');
  return {semester:semester,courses:courses};
}
