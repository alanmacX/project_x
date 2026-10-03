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
export function importAgenda(text:string,now:number=Date.now(),offset?:((zone:string,time:number)=>number)):AgendaItem[] {
  if(text.length>1048576||!text.includes('BEGIN:VCALENDAR'))throw new Error('请选择有效的 .ics 日历文件');
  const blocks=text.replace(/\r\n[ \t]/g,'').replace(/\n[ \t]/g,'').split('BEGIN:VEVENT').slice(1),out:AgendaItem[]=[],windowEnd=now+90*86400000;
  if(blocks.length>256)throw new Error('日历超过 256 项，请导出需要的日程');
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
  return out.sort((a,b)=>a.start-b.start).filter((e:AgendaItem,i:number,list:AgendaItem[])=>list.findIndex((v)=>v.id===e.id)===i).slice(0,256);
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
