import { batteryInfo } from '@kit.BasicServicesKit';
import { calendarManager } from '@kit.CalendarKit';
import { abilityAccessCtrl } from '@kit.AbilityKit';
import { CapBlock, AgendaItem } from './CardSchema';
import { capabilityRequestKey, mergeCapabilityResult } from './CapabilityData';
export async function hasWholeCalendarAccess(context:Context):Promise<boolean> {
  return await abilityAccessCtrl.createAtManager().checkAccessToken(context.applicationInfo.accessTokenId,'ohos.permission.READ_WHOLE_CALENDAR')===abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
}
export async function systemAgenda(context: Context): Promise<AgendaItem[]> {
  const access=abilityAccessCtrl.createAtManager();
  if(await access.checkAccessToken(context.applicationInfo.accessTokenId,'ohos.permission.READ_WHOLE_CALENDAR')!==abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED)
    throw new Error('此安装包没有读取全部系统日历的受限权限。请导入 .ics 日历文件。');
  const manager=calendarManager.getCalendarManager(context),calendars=await manager.getAllCalendars(),now=Date.now(),out:AgendaItem[]=[];
  for(const calendar of calendars) {
    const events=await calendar.queryEventInstances(now,now+14*86400000);
    for(const e of events)out.push({id:calendar.id+'_'+(e.id??0)+'_'+(e.instanceStartTime??e.startTime),title:e.title||'未命名日程',start:e.instanceStartTime??e.startTime,end:e.instanceEndTime??e.endTime,location:e.location?.location??'',allDay:e.isAllDay===true});
  }
  return out.filter((e)=>e.end>now).sort((a,b)=>a.start-b.start).slice(0,128);
}
async function readProvider(cap: CapBlock,context: Context): Promise<CapBlock> {
  const next=JSON.parse(JSON.stringify(cap)) as CapBlock; next.attemptedAt=Date.now();
  try {
    if(cap.k==='battery') { const level=batteryInfo.batterySOC;if(level<0||level>100)throw new Error('设备暂未提供电量');next.percent=level;next.charging=batteryInfo.chargingStatus===batteryInfo.BatteryChargeState.ENABLE;next.chargeState=batteryInfo.chargingStatus===batteryInfo.BatteryChargeState.FULL?'full':next.charging?'charging':'idle'; }
    if(cap.k==='agenda'&&cap.agendaSource==='system')next.events=await systemAgenda(context);
    next.updatedAt=Date.now();next.refreshState='done';next.desc='';
  } catch(e) {next.refreshState='failed';next.desc=(e as Error).message;}
  return next;
}

interface ProviderSnapshot {value:CapBlock;expires:number;}
const snapshots:Map<string,ProviderSnapshot>=new Map();
const pendingReads:Map<string,Promise<CapBlock>>=new Map();
/** One provider read for all canvases/cards. Only provider fields travel between appearances. */
export async function readCapability(cap:CapBlock,context:Context):Promise<CapBlock>{
  if(cap.k!=='battery'&&!(cap.k==='agenda'&&cap.agendaSource==='system'))return readProvider(cap,context);
  const key=String(context.applicationInfo?.accessTokenId??0)+':'+capabilityRequestKey(cap),now=Date.now();
  const cached=snapshots.get(key);if(cached&&cached.expires>now)return mergeCapabilityResult(cap,cached.value);
  let pending=pendingReads.get(key);
  if(!pending){
    pending=readProvider(cap,context).then((value:CapBlock):CapBlock=>{
      const ttl=value.refreshState==='failed'?30000:cap.k==='battery'?1000:60000;
      snapshots.set(key,{value:value,expires:Date.now()+ttl});return value;
    });pendingReads.set(key,pending);
  }
  try{return mergeCapabilityResult(cap,await pending);}finally{if(pendingReads.get(key)===pending)pendingReads.delete(key);}
}

export function invalidateCapabilityRead(kind:string):void {
  for(const key of snapshots.keys())if(key.endsWith(':'+kind+'|'))snapshots.delete(key);
}
