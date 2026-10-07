import { CapBlock } from './CardSchema';
export function batteryLevel(cap:CapBlock):number {
  const n=cap.percent;return typeof n==='number'&&Number.isFinite(n)&&n>=0&&n<=100?Math.round(n):-1;
}
export function batteryStatus(cap:CapBlock):string {
  if(batteryLevel(cap)<0)return '等待电量';
  if(cap.refreshState==='failed')return '上次读数';
  if(cap.chargeState==='full')return '已充满';
  if(cap.charging)return '充电中';
  return batteryLevel(cap)<=20?'电量偏低':'本机电量';
}
export function batteryTint(cap:CapBlock,ink:string):string {
  if(cap.refreshState==='failed'||batteryLevel(cap)<0)return ink;
  if(cap.charging||cap.chargeState==='full')return '#3B8868';
  return batteryLevel(cap)<=20?'#C8443D':ink;
}

/** A 288° arc leaves the bottom fifth open. Native Path commands use physical pixels; callers convert their vp diameter. */
export function batteryRingPath(diameter:number,percent:number=100):string {
  if(!Number.isFinite(diameter)||diameter<=0||!Number.isFinite(percent)||percent<=0)return '';
  const center=diameter/2,radius=diameter*.44,start=126*Math.PI/180;
  const sweep=288*Math.min(100,percent)/100,end=start+sweep*Math.PI/180;
  const x=center+radius*Math.cos(start),y=center+radius*Math.sin(start);
  return 'M '+x.toFixed(3)+' '+y.toFixed(3)+' A '+radius.toFixed(3)+' '+radius.toFixed(3)+' 0 '+(sweep>180?'1':'0')+' 1 '+(center+radius*Math.cos(end)).toFixed(3)+' '+(center+radius*Math.sin(end)).toFixed(3);
}

export class BatteryArcGlyph {
  character:string='';x:number=0;y:number=0;angle:number=0;
}
/** Read left to right through the bottom gap, with each glyph tangent to the same circle. */
export function batteryArcLabel(diameter:number,label:string,font:number):BatteryArcGlyph[] {
  const radius=diameter*.44,advance=font*.62,step=advance/radius;
  return Array.from(label).map((character:string,index:number)=>{
    const point=new BatteryArcGlyph(),offset=(index-(label.length-1)/2)*step;
    point.character=character;point.x=diameter*.5+radius*Math.sin(offset);
    point.y=diameter*.5+radius*Math.cos(offset);point.angle=-offset*180/Math.PI;
    return point;
  });
}
