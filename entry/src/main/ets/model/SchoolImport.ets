import { WakeImport, WakeCourse, WakeSlot, mondayDate, wakeTime } from './WakeUpImport';
export interface SchoolAdapter {id:string;name:string;url:string;script:string;category:string;description:string;}
export interface ImportSchool {id:string;name:string;initial:string;adapters:SchoolAdapter[];}
export interface SchoolCourse {name:string;position?:string;day:number;weeks:number[];startSection?:number;endSection?:number;isCustomTime?:boolean;customStartTime?:string;customEndTime?:string;}
interface SchoolSlot {number:number;startTime:string;endTime:string;}
interface SchoolConfig {semesterStartDate?:string;}
export interface SchoolRequest {id:number;kind:string;title:string;content:string;value:string;items:string[];}
export interface SchoolSnapshot {token:string;courses:SchoolCourse[];slots:SchoolSlot[];config:SchoolConfig;done:boolean;error:string;message:string;request?:SchoolRequest;}
/** ArkWeb returns JavaScript strings as JSON string literals. Accept either API representation. */
export function webString(value:string):string {
  if(value.length>1048576)throw new Error('课表数据超过 1 MB');
  if(value.startsWith('"'))return JSON.parse(value) as string;return value;
}
export function schoolUrl(value:string):string {
  const raw=value.trim(),url=/^https?:\/\//i.test(raw)?raw:'https://'+raw;
  if(url.length>2048||/[\s<>"\\]/.test(url)||!/^https?:\/\/[^/]+/i.test(url)||/^[^/]+:\/\/[^/]*@/.test(url))throw new Error('请输入完整的教务网址');
  if(!/^https?:\/\/[a-z0-9.-]+(?::\d{1,5})?(?:[/?#]|$)/i.test(url))throw new Error('教务网址格式不正确');return url;
}
export function schoolSnapshot(value:string):SchoolSnapshot {
  const data=JSON.parse(webString(value)) as SchoolSnapshot;
  if(!data||typeof data.token!=='string')throw new Error('页面已改变，请重新读取课表');return data;
}
/** Preserve every explicit teaching week; do not turn interrupted weeks into a continuous range. */
export function parseSchoolCourses(value:string,name:string):string {
  const data=schoolSnapshot(value),out=new WakeImport();out.name=name.slice(0,80);
  if(!data.done||data.error)throw new Error('教务读取尚未完成');
  if(!Array.isArray(data.courses)||!data.courses.length||data.courses.length>128)throw new Error('未读取到课程，或超过 128 条限制');
  if(!Array.isArray(data.slots)||data.slots.length>24)throw new Error('作息数据不正确');
  out.semester=mondayDate(data.config?.semesterStartDate??'');
  for(const s of data.slots){
    const start=wakeTime(s.startTime),end=wakeTime(s.endTime);
    if(!Number.isInteger(s.number)||s.number<1||s.number>24||!start||!end||end<=start||out.slots.some((v)=>v.node===s.number))throw new Error('教务作息缺失或重复，请核对后再导入');
    out.slots.push({node:s.number,start,end});
  }
  for(const c of data.courses){
    if(!c||typeof c.name!=='string'||!c.name.trim()||!Number.isInteger(c.day)||c.day<1||c.day>7||!Array.isArray(c.weeks)||!c.weeks.length||c.weeks.length>60||c.weeks.some((w)=>!Number.isInteger(w)||w<1||w>60))throw new Error('课程名、星期或周次缺失，未导入任何课程');
    const start=c.isCustomTime?wakeTime(c.customStartTime):'',end=c.isCustomTime?wakeTime(c.customEndTime):'',a=c.startSection??0,b=c.endSection??0;
    if(c.isCustomTime?(!start||!end||end<=start):(!Number.isInteger(a)||!Number.isInteger(b)||a<1||b<a||b>24))throw new Error('课程时间或节次不正确，未导入任何课程');
    const weeks=c.weeks.filter((v,i,arr)=>arr.indexOf(v)===i).sort((a,b)=>a-b);
    for(let i=0;i<weeks.length;){
      const first=weeks[i];let last=first,j=i+1,step=1;
      if(j<weeks.length&&weeks[j]-first===2)step=2;
      while(j<weeks.length&&weeks[j]-last===step){last=weeks[j++];}
      const r:WakeCourse={name:c.name.trim().slice(0,80),room:(c.position??'').slice(0,80),day:c.day,firstWeek:first,lastWeek:last,parity:step===2?(first%2===1?1:2):0,firstNode:start?0:a,lastNode:start?0:b,start,end};
      out.courses.push(r);i=j;
      if(out.courses.length>128)throw new Error('跳周课程展开后超过 128 条，请分批导入');
    }
    if(!start)for(let n=a;n<=b;n++)if(!out.slots.some((s)=>s.node===n))out.slots.push({node:n,start:'',end:''});
  }
  out.slots.sort((a,b)=>a.node-b.node);return JSON.stringify(out);
}
