import { CapBlock, AgendaItem, FridgeCard, materialColors } from './CardSchema';
/** Stable type hierarchy in card coordinates. Larger cards gain content, not inflated typography. */
export class SummaryPresentation {
  heading: string = '';
  empty: string = '';
  events: AgendaItem[] = [];
  remaining: number = 0;
}
export function summaryRowCapacity(height: number): number {
  return Math.max(1, Math.min(3, Math.floor((height - 26) / 48)));
}
export function summaryPresentation(cap: CapBlock, height: number, now: number): SummaryPresentation {
  const out = new SummaryPresentation(), capacity = summaryRowCapacity(height);
  {
    const all = (cap.events??[]).filter((event)=>event.end>now).slice().sort((a,b)=>a.start-b.start); out.heading = '接下来'; out.events = all.slice(0, capacity);
    out.remaining = all.length - out.events.length;
    out.empty = cap.agendaSource ? '暂无日程' : '尚未添加日程';
  }
  return out;
}
export function readingSurface(cap: CapBlock | null, photograph: boolean, obstructed: boolean): boolean {
  return cap !== null && (obstructed || cap.readingStyle === 'surface' || cap.readingStyle !== 'plain' && photograph);
}
function luminance(color:string):number {
  const values=[1,3,5].map((start:number)=>{const v=parseInt(color.slice(start,start+2),16)/255;return v<=.04045?v/12.92:Math.pow((v+.055)/1.055,2.4);});
  return values[0]*.2126+values[1]*.7152+values[2]*.0722;
}
export function textContrast(ink:string,background:string):number {
  if(!/^#[0-9a-fA-F]{6}$/.test(ink)||!/^#[0-9a-fA-F]{6}$/.test(background))return 1;
  const a=luminance(ink),b=luminance(background);return (Math.max(a,b)+.05)/(Math.min(a,b)+.05);
}
export function readingSurfaceColor(ink:string):string {
  const warm='#F9F6EF',dark='#252824';
  const preferred=textContrast(ink,warm)>=textContrast(ink,dark)?warm:dark;
  if(textContrast(ink,preferred)>=4.5)return preferred;
  return textContrast(ink,'#FFFFFF')>=textContrast(ink,'#000000')?'#FFFFFF':'#000000';
}
export function readingWarning(card:FridgeCard):string {
  if(card.capability===null || readingSurface(card.capability,card.shape==='subject'&&card.subjectPhoto,false))return '';
  if(card.shape==='subject'&&card.subjectPhoto)return '照片上文字可能不易辨认，可开启阅读衬底';
  const colors=materialColors(card.material,card.paper,card.ink);
  return textContrast(colors[1],colors[0])<4.5?'文字对比度偏低，可启用阅读衬底或调整内容颜色':'';
}

/** A transparent field, not a panel. Glyph halos supply local contrast without
 * replacing the photograph with a nearly opaque rectangular surface. */
export function readingVeilColor(ink: string, strength: number, blend:string = 'feather'): string {
  const alpha = Math.round(Math.max(0, Math.min(blend==='scrim'?.72:.42, strength)) * 255);
  return '#' + alpha.toString(16).padStart(2, '0') + readingSurfaceColor(ink).slice(1);
}
export function readingHalo(ink: string, scale: number, enabled: boolean, blend:string = 'feather'): ShadowOptions[] {
  if (!enabled) return [];
  const color = '#D9' + readingSurfaceColor(ink).slice(1);
  return [{ radius: (blend==='halo'?1.1:.65) * scale, color: color, offsetX: 0, offsetY: 0 },
    { radius: (blend==='halo'?2.2:1.8) * scale, color: color, offsetX: 0, offsetY: 0 }];
}
