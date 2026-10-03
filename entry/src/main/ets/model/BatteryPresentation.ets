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
  return batteryLevel(cap)<=20?'#B85B42':ink;
}
