import { FridgeCard } from './CardSchema';
import { capabilityPlacement, capabilityInset } from './CanvasLayout';
import { compactCapability } from './CapabilityMetrics';
export interface WidgetActionRect { operation:string; symbol:string; x:number; y:number; w:number; h:number; }
/** One geometry contract for visible controls and hit testing. Small cards use their detail link. */
export function widgetActionRects(card:FridgeCard, scale:number, time:number=Date.now()):WidgetActionRect[] {
  if(card.capability?.k!=='calendar' || scale<=0)return [];
  const box=capabilityPlacement(card),inset=capabilityInset(card),width=box.w*card.w-2*inset,height=box.h*card.h-2*inset;
  const size=44/scale;
  if(compactCapability(card.capability,width,height)||width<size*2+72||size>44)return [];
  const now=new Date(time),month=new Date(now.getFullYear(),now.getMonth()+(card.capability.calendarOffset??0),1);
  const rows=Math.ceil((month.getDay()+new Date(month.getFullYear(),month.getMonth()+1,0).getDate())/7);
  const bodyHeight=44+10+rows*22+12;
  const left=box.x*card.w+inset,top=box.y*card.h+inset+Math.max(0,(height-bodyHeight)/2);
  return [
    {operation:'previousMonth',symbol:'‹',x:left,y:top,w:size,h:size},
    {operation:'nextMonth',symbol:'›',x:left+width-size,y:top,w:size,h:size}
  ];
}
