import { CourseItem } from './CardSchema';
import { parseSchoolCourses } from './SchoolImport';
import { i18n } from '@kit.LocalizationKit';
import { fileIo } from '@kit.CoreFileKit';
import { importAgenda, importCourseCalendar, mergeCourseCalendars, CourseCalendar } from './ScheduleImport';
import { parseWakeUp, WakeImport, WakeCourse } from './WakeUpImport';
import { util } from '@kit.ArkTS';
@Concurrent
export async function importScheduleFile(uri:string,kind:string):Promise<string> {
  const file=await fileIo.open(uri,fileIo.OpenMode.READ_ONLY);
  try {const stat=await fileIo.stat(file.fd);if(stat.size>1048576)throw new Error('文件超过 1 MB');
    const buffer=new ArrayBuffer(stat.size),length=await fileIo.read(file.fd,buffer);
    const text=new util.TextDecoder('utf-8').decodeWithStream(new Uint8Array(buffer,0,length));
    if(kind==='timetable-ics'){const calendar=importCourseCalendar(text,(zone:string,time:number):number=>i18n.getTimeZone(zone).getOffset(time)),out=new WakeImport();out.name='日历课程表';out.semester=calendar.semester;out.courses=calendar.courses.map((c):WakeCourse=>({name:c.name,room:c.room,day:c.day,firstWeek:c.firstWeek,lastWeek:c.lastWeek,parity:0,firstNode:0,lastNode:0,start:c.start,end:c.end}));return JSON.stringify(out);}
    return JSON.stringify(kind==='agenda'?importAgenda(text,Date.now(),(zone:string,time:number):number=>i18n.getTimeZone(zone).getOffset(time)):parseWakeUp(text));
  } finally {fileIo.closeSync(file.fd);}
}
@Concurrent
export function parseWakeUpText(text:string):string {return JSON.stringify(parseWakeUp(text));}

@Concurrent
export function parseSchoolText(text:string,name:string):string {return parseSchoolCourses(text,name);}

@Concurrent
export async function importCalendarFiles(uris:string[]):Promise<string> {
  if(!uris.length||uris.length>32)throw new Error('一次最多选择 32 个课程日历文件');
  const calendars:CourseCalendar[]=[];
  for(const uri of uris){
    const file=await fileIo.open(uri,fileIo.OpenMode.READ_ONLY);
    try{const stat=await fileIo.stat(file.fd);if(stat.size>1048576)throw new Error('文件超过 1 MB');
      const buffer=new ArrayBuffer(stat.size),length=await fileIo.read(file.fd,buffer);
      const text=new util.TextDecoder('utf-8').decodeWithStream(new Uint8Array(buffer,0,length));
      calendars.push(importCourseCalendar(text,(zone:string,time:number):number=>i18n.getTimeZone(zone).getOffset(time)));
    }finally{fileIo.closeSync(file.fd);}
  }
  const merged=mergeCourseCalendars(calendars),out=new WakeImport();out.name='日历课程表';out.semester=merged.semester;out.courses=merged.courses.map((c):WakeCourse=>({name:c.name,room:c.room,day:c.day,firstWeek:c.firstWeek,lastWeek:c.lastWeek,parity:0,firstNode:0,lastNode:0,start:c.start,end:c.end}));return JSON.stringify(out);
}
