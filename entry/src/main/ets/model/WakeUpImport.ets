import { CourseItem } from './CardSchema';
import { importCourses } from './ScheduleImport';
export interface WakeSlot {node:number;start:string;end:string;}
export interface WakeCourse {name:string;room:string;day:number;firstWeek:number;lastWeek:number;parity:number;firstNode:number;lastNode:number;start:string;end:string;}
interface WakeRecord {id?:number;courseName?:string;name?:string;room?:string;position?:string;day?:number;startNode?:number;endNode?:number;step?:number;startWeek?:number;endWeek?:number;type?:number;startTime?:string;endTime?:string;node?:number;}
interface WakeRoot {name?:string;tableName?:string;startDate?:string;courseDetailJson?:string;courseBaseJson?:string;timeDetailJson?:string;courses?:WakeRecord[];courseDetails?:WakeRecord[];courseBases?:WakeRecord[];timeList?:WakeRecord[];tableInfo?:WakeRoot;}
export class WakeImport {name:string='导入的课表';semester:string='';courses:WakeCourse[]=[];slots:WakeSlot[]=[];}
export function wakeTime(value:string|undefined):string {
  const m=/^(\d{1,2}):(\d{2})$/.exec(value??'');if(!m||Number(m[1])>23||Number(m[2])>59)return '';
  return ('0'+m[1]).slice(-2)+':'+m[2];
}
export function mondayDate(value:string):string {
  if(!/^\d{4}-\d{2}-\d{2}$/.test(value))return '';
  const d=new Date(value+'T12:00:00');if(!Number.isFinite(d.getTime())||d.getFullYear()!==Number(value.slice(0,4))||d.getMonth()+1!==Number(value.slice(5,7))||d.getDate()!==Number(value.slice(8)))return '';
  d.setDate(d.getDate()-((d.getDay()+6)%7));return d.getFullYear()+'-'+('0'+(d.getMonth()+1)).slice(-2)+'-'+('0'+d.getDate()).slice(-2);
}
function jsonArray(text:string):WakeRecord[] {
  let raw=text.trim();if(!raw.startsWith('['))raw=decodeURIComponent(raw.replace(/\+/g,' '));
  const arr=JSON.parse(raw) as WakeRecord[];if(!Array.isArray(arr)||arr.length>256)throw new Error('课表条目过多或格式不正确');return arr;
}
/** Independent implementation of the public WakeUp export structure; never logs in or resolves private share APIs. */
export function parseWakeUp(text:string):WakeImport {
  if(text.length>1048576)throw new Error('课表文件超过 1 MB');
  const source=text.replace(/^\uFEFF/,'').trim(),out=new WakeImport();let root:WakeRoot={},times:WakeRecord[]=[],bases:WakeRecord[]=[],records:WakeRecord[]=[];
  if(source.startsWith('[')) {
    const own=importCourses(source);if(!own.length)throw new Error('文件中没有课程');out.courses=own.map((c:CourseItem):WakeCourse=>({name:c.name,room:c.room,day:c.day,firstWeek:c.firstWeek,lastWeek:c.lastWeek,parity:c.parity,firstNode:0,lastNode:0,start:c.start,end:c.end}));return out;
  }
  try {
    const start=source.indexOf('{');if(start<0)throw new Error('missing');root=JSON.parse(source.slice(start)) as WakeRoot;
    records=root.courseDetailJson?jsonArray(root.courseDetailJson):(root.courses??root.courseDetails??root.tableInfo?.courses??[]);
    bases=root.courseBaseJson?jsonArray(root.courseBaseJson):(root.courseBases??[]);
    times=root.timeDetailJson?jsonArray(root.timeDetailJson):(root.timeList??root.tableInfo?.timeList??[]);
  } catch(_) {
    // WakeUp's documented backup is five newline-delimited JSON values.
    const lines=source.split(/\r?\n/).map((v)=>v.trim()).filter((v)=>v.length>0);
    const offset=lines.length===6?1:0;if(lines.length-offset!==5)throw new Error('请选择 WakeUp 导出的备份文件或包含课程数据的文本；在线分享口令不能直接离线读取');
    try {JSON.parse(lines[offset]);times=jsonArray(lines[offset+1]);root=JSON.parse(lines[offset+2]) as WakeRoot;bases=jsonArray(lines[offset+3]);records=jsonArray(lines[offset+4]);}
    catch(_){throw new Error('WakeUp 文件结构无法读取，请重新导出');}
  }
  if(!Array.isArray(records)||records.length===0||records.length>128||!Array.isArray(times)||times.length>24||!Array.isArray(bases)||bases.length>128)throw new Error('未找到可导入课程，或超过 128 条课程 / 24 节作息限制');
  out.name=(root.name??root.tableName??'导入的课表').slice(0,80);out.semester=mondayDate(root.startDate??root.tableInfo?.startDate??'');
  for(const t of times) {
    const node=t.node??0,start=wakeTime(t.startTime),end=wakeTime(t.endTime);
    if(!Number.isInteger(node)||node<1||node>24||!start||!end||end<=start||out.slots.some((s)=>s.node===node))throw new Error('作息时间缺失、重复或不正确，请重新导出');
    out.slots.push({node,start,end});
  }
  for(const r of records) {
    if(!r)throw new Error('课程记录不完整');
    const name=(r.courseName??r.name??bases.find((b)=>b.id===r.id)?.courseName??'').trim(),day=r.day??0,firstWeek=r.startWeek??1,lastWeek=r.endWeek??16,parity=r.type??0;
    const firstNode=r.startNode??0,lastNode=r.endNode??(firstNode+(r.step??1)-1),start=wakeTime(r.startTime),end=wakeTime(r.endTime);
    if(!name||!Number.isInteger(day)||day<1||day>7||!Number.isInteger(firstWeek)||!Number.isInteger(lastWeek)||firstWeek<1||lastWeek<firstWeek||lastWeek>60||![0,1,2].includes(parity))throw new Error('课程星期或周次不正确，未导入任何课程');
    if((start||end)&&(!start||!end||end<=start))throw new Error('课程起止时间不正确');
    if(!start&&(!Number.isInteger(firstNode)||!Number.isInteger(lastNode)||firstNode<1||lastNode<firstNode||lastNode>24))throw new Error('课程节次不正确，未导入任何课程');
    out.courses.push({name:name.slice(0,80),room:(r.room??r.position??'').slice(0,80),day,firstWeek,lastWeek,parity,firstNode:start?0:firstNode,lastNode:start?0:lastNode,start,end});
    if(!start)for(let n=firstNode;n<=lastNode;n++)if(!out.slots.some((s)=>s.node===n))out.slots.push({node:n,start:'',end:''});
  }
  out.slots.sort((a,b)=>a.node-b.node);return out;
}
export function resolveWakeUp(parsed:WakeImport,semester:string,slots:WakeSlot[]):CourseItem[] {
  if(!mondayDate(semester))throw new Error('请选择学期第一周的日期');
  const stamp=Date.now();return parsed.courses.map((r:WakeCourse,i:number):CourseItem=>{
    let start=r.start,end=r.end;
    if(!start) {
      for(let n=r.firstNode;n<=r.lastNode;n++){const s=slots.find((v)=>v.node===n);if(!s||!wakeTime(s.start)||!wakeTime(s.end)||s.end<=s.start)throw new Error('请补全第 '+n+' 节的真实作息时间');if(n>r.firstNode&&s.start<slots.find((v)=>v.node===n-1)!.end)throw new Error('作息时间有重叠，请检查第 '+n+' 节');}
      start=slots.find((s)=>s.node===r.firstNode)!.start;end=slots.find((s)=>s.node===r.lastNode)!.end;
    }
    return {id:'wake_'+stamp+'_'+i,name:r.name,room:r.room,day:r.day,start,end,firstWeek:r.firstWeek,lastWeek:r.lastWeek,parity:r.parity};
  });
}
