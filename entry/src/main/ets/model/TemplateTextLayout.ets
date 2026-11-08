import { TemplateMark } from './TemplateScene';
export class TemplateTextLayout {fontSize:number=16;lineHeight:number=18;lines:string[]=[];truncated:boolean=false;}
/** Keep surrogate pairs, combining marks and joined emoji intact at an ellipsis/wrap boundary. */
export function templateClusters(value:string):string[]{
  const result:string[]=[];let join=false,regional=false;
  for(const char of Array.from(value)){
    const mark=/[\p{M}\ufe00-\ufe0f\u{1f3fb}-\u{1f3ff}\u{e0020}-\u{e007f}]/u.test(char),flag=/[\u{1f1e6}-\u{1f1ff}]/u.test(char);
    if(result.length&&(join||mark||char==='\u200d'||flag&&regional))result[result.length-1]+=char;else result.push(char);
    join=char==='\u200d';regional=flag&&!regional;
  }return result;
}
/** Identical text fitting for native Canvas, synchronous snapshot nodes and the SVG adapter. */
export function layoutTemplateText(m:TemplateMark,measure:(value:string,size:number)=>number):TemplateTextLayout{
  const out=new TemplateTextLayout(),count=Math.max(1,Math.min(3,m.lines)),width=Math.max(.1,m.w),value=m.text.trim();
  out.fontSize=Math.max(.5,Math.min(m.size,m.h/(1.12*count)));out.lineHeight=out.fontSize*1.12;
  if(!value)return out;
  if(m.font==='digits'||/^[\d+−\-—:%.]+$/.test(value)){
    const measured=measure(value,out.fontSize);if(measured>width)out.fontSize*=width/measured;
    out.lineHeight=out.fontSize*1.12;out.lines=[value];return out;
  }
  const clusters=templateClusters(value);let cursor=0;
  for(let row=0;row<count&&cursor<clusters.length;row++){
    const remaining=clusters.length-cursor,last=row===count-1,all=clusters.slice(cursor).join('');
    if(measure(all,out.fontSize)<=width){out.lines.push(all);break;}
    const suffix=last?'…':'';let lo=0,hi=remaining;
    while(lo<hi){const mid=Math.ceil((lo+hi)/2),part=clusters.slice(cursor,cursor+mid).join('')+suffix;if(measure(part,out.fontSize)<=width)lo=mid;else hi=mid-1;}
    out.lines.push(clusters.slice(cursor,cursor+lo).join('')+suffix);cursor+=Math.max(1,lo);if(last)out.truncated=true;
  }return out;
}
