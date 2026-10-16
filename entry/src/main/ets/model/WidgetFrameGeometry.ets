export class WidgetFrameMetrics {cornerPercent:number=8;radius:number=24;}
/** Baked corner radius is 31/48 of its tile; respect the launcher's 24vp small-widget mask. */
export function widgetFrameMetrics(width:number,height:number):WidgetFrameMetrics{
  const result=new WidgetFrameMetrics(),w=Math.max(1,width),h=Math.max(1,height);
  const corner=Math.min(Math.min(w,h)/2,Math.max(w*.08,24*48/31));
  result.cornerPercent=corner/w*100;result.radius=corner*31/48;return result;
}
