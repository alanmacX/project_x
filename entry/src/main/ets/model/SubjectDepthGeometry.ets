export function depthHash(value:string):string {
  let a=2166136261,b=5381;
  for(let i=0;i<value.length;i++){a=Math.imul(a^value.charCodeAt(i),16777619);b=Math.imul(b,33)^value.charCodeAt(i);}
  return (a>>>0).toString(16)+(b>>>0).toString(16);
}
export class DepthInput { key:string='';path:string='';w:number=0;h:number=0;scale:number=1;edge:string='';surface:string=''; }
export function depthArgb(color:string, opacity:number):number {
  const hex=color.slice(1),alpha=hex.length===8?parseInt(hex.slice(0,2),16):255,rgb=parseInt(hex.slice(-6),16);
  return ((Math.round(alpha*opacity)<<24)|rgb)>>>0;
}
