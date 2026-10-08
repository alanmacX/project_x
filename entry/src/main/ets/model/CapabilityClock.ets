import { CapBlock } from './CardSchema';
/** Only advance a render dependency when its visible value can change. No timer per card. */
export function capabilityRenderTick(cap:CapBlock|null,now:number):number {
  if(!cap)return 0;
  if(['date','calendar','lunar','countdown','anniversary'].includes(cap.k)) {
    const date=new Date(now);date.setHours(0,0,0,0);return date.getTime();
  }
  if(cap.k==='album') {
    const period=(cap.albumRotationMinutes??0)*60000,start=cap.albumRotationStart??0;
    return period>0&&start>0?start+Math.floor(Math.max(0,now-start)/period)*period:0;
  }
  return ['clock','worldclock','dayprogress','yearprogress','timetable','agenda'].includes(cap.k)?now:0;
}
