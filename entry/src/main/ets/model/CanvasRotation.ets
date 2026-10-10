/** One complete local day. Starts are boundaries, so gaps and overlaps cannot exist. */
export class CanvasTimeSlot { start:number=0; canvasId:string=''; }
export class CanvasRotation { enabled:boolean=false; mode:string='off'; lightId:string=''; darkId:string=''; slots:CanvasTimeSlot[]=[]; }
export function normalizeCanvasRotation(raw:CanvasRotation|undefined,ids:string[]):CanvasRotation {
  const out=new CanvasRotation();if(!raw)return out;
  out.mode=['time','theme'].includes(raw.mode)?raw.mode:'off';out.enabled=out.mode!=='off'&&raw.enabled!==false;
  out.lightId=ids.includes(raw.lightId)?raw.lightId:ids[0]??'';out.darkId=ids.includes(raw.darkId)?raw.darkId:out.lightId;
  const slots=(Array.isArray(raw.slots)?raw.slots:[]).filter(s=>s&&Number.isInteger(s.start)&&s.start>=0&&s.start<1440&&ids.includes(s.canvasId)).slice(0,12).sort((a,b)=>a.start-b.start);
  for(const slot of slots)if(!out.slots.some(s=>s.start===slot.start))out.slots.push({start:slot.start,canvasId:slot.canvasId});
  if(out.slots.length===0)out.slots=[{start:0,canvasId:ids[0]??''}];else if(out.slots[0].start!==0)out.slots.unshift({start:0,canvasId:out.slots[0].canvasId});
  out.slots=out.slots.slice(0,12);return out;
}
export function rotatedCanvas(rotation:CanvasRotation|undefined,now:number,dark:boolean,fallback:string):string {
  if(!rotation||!canvasRotationEnabled(rotation))return fallback;
  if(rotation.mode==='theme')return (dark?rotation.darkId:rotation.lightId)||fallback;
  if(rotation.mode!=='time')return fallback;
  const d=new Date(now),minute=d.getHours()*60+d.getMinutes();let id=fallback;
  for(const slot of rotation.slots)if(slot.start<=minute)id=slot.canvasId;return id;
}
export function nextCanvasBoundary(rotation:CanvasRotation|undefined,now:number):number {
  if(!rotation||!canvasRotationEnabled(rotation)||rotation.mode!=='time')return Infinity;
  const d=new Date(now);let next=Infinity;
  for(const s of rotation.slots){const at=new Date(d.getFullYear(),d.getMonth(),d.getDate(),Math.floor(s.start/60),s.start%60).getTime();if(at>now)next=Math.min(next,at);}
  const midnight=new Date(d);midnight.setHours(24,0,0,0);return Math.min(next,midnight.getTime());
}

export function canvasRotationEnabled(rotation:CanvasRotation|undefined):boolean {return rotation!==undefined&&rotation.enabled!==false&&(rotation.mode==='time'||rotation.mode==='theme');}
