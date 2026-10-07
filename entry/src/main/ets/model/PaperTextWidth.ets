import { UIContext } from '@kit.ArkUI';
const widths=new Map<string,number>();
/** Native text metrics; bounded cache means moving a label never repeatedly measures its text. */
export function paperTextWidth(context:UIContext,text:string,font:number,weight:number=400):number {
  const key=context.vp2px(1)+':'+font+':'+weight+':'+text;
  const cached=widths.get(key);if(cached!==undefined)return cached;
  const size=context.getMeasureUtils().measureTextSize({textContent:text,fontSize:font+'vp',fontWeight:String(weight)});
  const width=context.px2vp(Number(size.width));
  if(widths.size>=256)widths.clear();widths.set(key,width);return width;
}
