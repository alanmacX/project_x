import { ParcelItem } from './CardSchema';
/** Parse only an explicit pickup label. Never infer a code from an unlabelled phone/order/OTP. */
export function parsePickupNotice(text: string): ParcelItem[] {
  const normalized=text.slice(0,16384).replace(/[０-９]/g,(c:string)=>String(c.charCodeAt(0)-65296)).replace(/[－—–]/g,'-');
  const out:ParcelItem[]=[],pattern=/(?:取件码|提货码|取货码|领取码)[\s：:是为【\[(]*([A-Za-z0-9]{1,8}(?:[ -](?=[A-Za-z0-9]*\d)[A-Za-z0-9]{1,8}){0,3})(?![A-Za-z0-9-])/g;
  let match:RegExpExecArray|null;
  while((match=pattern.exec(normalized))!==null && out.length<12) {
    const code=match[1].trim().replace(/ +/g,'-');
    if(!/\d/.test(code)||code.length>24||/^1[3-9]\d{9}$/.test(code)||/^\d{14,}$/.test(code))continue;
    const start=Math.max(0,match.index-80), end=Math.min(normalized.length,match.index+100);
    // Search close to the label first; punctuation prevents swallowing an entire notification.
    const before=normalized.slice(start,match.index).split(/[。；;\n，,]/).reverse();
    const after=normalized.slice(pattern.lastIndex,end).split(/[。；;\n，,]/);
    let place='';
    for(const part of before.concat(after)) {
      const location=part.match(/([\u4e00-\u9fffA-Za-z0-9·]{2,32}(?:驿站|快递柜|自提点|服务站))/);
      if(location) {place=location[1].replace(/^.*(?:请到|请至|前往|已到达|已到|存放于|放在|送至)/,'');break;}
    }
    if(!out.some((item)=>item.code===code&&item.place===place))out.push({id:'p'+match.index,code:code,place:place,picked:false});
  }
  return out;
}
export function mergePickupParcels(existing: ParcelItem[], confirmed: ParcelItem[], fallbackPlace: string, now: number): ParcelItem[] {
  const result=existing.slice();let index=0;
  for(const item of confirmed) {
    const code=item.code.trim().slice(0,24), place=(item.place.trim()||fallbackPlace.trim()).slice(0,80);
    if(!code||result.some((p)=>!p.picked&&p.code===code&&p.place===place))continue;
    result.unshift({id:'p'+now+'_'+index++,code:code,place:place,picked:false});
  }
  // Active records are never silently evicted to make room for new ones.
  if(result.length>64)throw new Error('包裹记录已满，请先清理已取记录');
  return result;
}
