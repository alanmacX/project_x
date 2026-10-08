import { CapBlock, CourseItem, TeachingDay, CourseChange, normalizeCapability } from './CardSchema';
import { HolidayDate } from './HolidayCalendar';
/** Reusable local course data, independent of a card's appearance, placement and display mode. */
export class TimetableData {
  version:number=1;
  semester:string='';
  courses:CourseItem[]=[];
  skipHolidays:boolean=true;
  holidayDates:HolidayDate[]=[];
  teachingDays:TeachingDay[]=[];
  courseChanges:CourseChange[]=[];
}
export interface TimetableStorage {read:()=>Promise<string>;write:(json:string)=>Promise<void>;}
export function timetableData(cap:CapBlock):TimetableData {
  const clean=normalizeCapability(cap),data=new TimetableData();
  data.semester=clean.semester??'';data.courses=clean.courses??[];data.skipHolidays=clean.skipHolidays!==false;
  data.holidayDates=clean.holidayDates??[];data.teachingDays=clean.teachingDays??[];data.courseChanges=clean.courseChanges??[];
  return data;
}
export function sameTimetable(a:CapBlock,b:CapBlock):boolean {return JSON.stringify(timetableData(a))===JSON.stringify(timetableData(b));}
export function useSavedTimetable(cap:CapBlock,data:TimetableData):CapBlock {
  const next=JSON.parse(JSON.stringify(cap)) as CapBlock,copy=JSON.parse(JSON.stringify(data)) as TimetableData;
  next.semester=copy.semester;next.courses=copy.courses;next.skipHolidays=copy.skipHolidays;
  next.holidayDates=copy.holidayDates;next.teachingDays=copy.teachingDays;next.courseChanges=copy.courseChanges;
  return next;
}
/** Acknowledged writes are serialized; a failed flush never replaces the last readable copy. */
export class TimetableLibrary {
  private storage:TimetableStorage;
  private loaded:Promise<void>|null=null;
  private data:TimetableData|null=null;
  private queue:Promise<void>=Promise.resolve();
  constructor(storage:TimetableStorage){this.storage=storage;}
  private load():Promise<void> {
    if(this.loaded!==null)return this.loaded;
    const pending=this.storage.read().then((json:string)=>{
      if(!json)return;const raw=JSON.parse(json) as TimetableData;
      if(!raw||raw.version!==1||typeof raw.semester!=='string'||!Array.isArray(raw.courses))throw new Error('已保存课表无法读取，原数据已保留');
      this.data=timetableData({k:'timetable',semester:raw.semester,courses:raw.courses,skipHolidays:raw.skipHolidays,holidayDates:raw.holidayDates,teachingDays:raw.teachingDays,courseChanges:raw.courseChanges});
    });
    this.loaded=pending;pending.catch(()=>{if(this.loaded===pending)this.loaded=null;});return pending;
  }
  async read():Promise<TimetableData|null> {
    await this.queue.catch(()=>{});await this.load();return this.data?JSON.parse(JSON.stringify(this.data)) as TimetableData:null;
  }
  save(cap:CapBlock,onlyIfMissing:boolean=false):Promise<void> {
    const data=timetableData(cap),json=JSON.stringify(data);
    const pending=this.queue.catch(()=>{}).then(async()=>{await this.load();if((onlyIfMissing&&this.data!==null)||JSON.stringify(this.data)===json)return;await this.storage.write(json);this.data=data;});
    this.queue=pending;return pending;
  }
  async settled():Promise<void>{await this.queue.catch(()=>{});}
}
