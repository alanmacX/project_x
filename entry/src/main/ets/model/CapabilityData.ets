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
export function courseInstances(cap: CapBlock, now: number): AgendaItem[] {
  const out:AgendaItem[]=[],today=new Date(now); today.setHours(0,0,0,0);
  for(let offset=0;offset<14;offset++) {
    const d=new Date(today.getTime());d.setDate(d.getDate()+offset);const week=semesterWeek(cap.semester??'',d.getTime()),day=d.getDay()||7;
    for(const c of (cap.courses??[])) {
      if(c.day!==day || week<c.firstWeek || week>c.lastWeek || (c.parity===1&&week%2===0) || (c.parity===2&&week%2!==0)) continue;
      const start=new Date(d.getTime()),end=new Date(d.getTime());start.setHours(Number(c.start.slice(0,2)),Number(c.start.slice(3)));end.setHours(Number(c.end.slice(0,2)),Number(c.end.slice(3)));
      if(end.getTime()>now) out.push({id:c.id+'_'+offset,title:c.name,start:start.getTime(),end:end.getTime(),location:c.room,allDay:false});
    }
  }
  return out.sort((a,b)=>a.start-b.start).slice(0,3);
}
/** Contextual pickup labels only: do not mistake login verification or an order number for a pickup code. */
export function pickupCandidates(text: string): ParcelItem[] {
  const normalized=text.replace(/[０-９]/g,(c:string)=>String(c.charCodeAt(0)-65296)).replace(/[－—–]/g,'-');
  const out:ParcelItem[]=[],pattern=/(?:取件码|提货码|取货码|领取码)[\s：:是为]*([A-Za-z0-9]{1,8}(?:[ -][A-Za-z0-9]{1,8}){0,3})/g;
  let match:RegExpExecArray|null;
  while((match=pattern.exec(normalized))!==null && out.length<12) {
    const code=match[1].trim().replace(/ /g,'-'); if(!/\d/.test(code)||out.some((v)=>v.code===code)||code.length>24)continue;
    const before=normalized.slice(Math.max(0,match.index-80),match.index), after=normalized.slice(match.index,match.index+100);
    const location=(before+' '+after).match(/([\u4e00-\u9fffA-Za-z0-9·]{2,24}(?:驿站|快递柜|自提点|服务站))/);
    out.push({id:'p'+match.index,code:code,place:location?location[1]:'待填写取件地点',picked:false});
  }
  return out;
}
export function pendingParcels(cap: CapBlock): ParcelItem[] { return (cap.parcels??[]).filter((p)=>!p.picked); }
export function nextDataBoundary(cap: CapBlock, now:number):number {
  const events=cap.k==='agenda'?agendaItems(cap,now):cap.k==='timetable'?courseInstances(cap,now):[];
  const boundaries=events.reduce((all:number[],e:AgendaItem):number[]=>all.concat([e.start,e.end]),[]).filter((t)=>t>now);
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
