import { timetableCapacity, briefHeight, briefColumns } from './TimetableLayout';
import { CapBlock } from './CardSchema';
export class CapabilitySize { w: number = 112; h: number = 58; }
/** Full and compact layouts have separate readable minima; neither shrinks to microscopic text. */
export function capabilityMinimum(cap: CapBlock | null, compact: boolean = false, availableWidth: number = 0): CapabilitySize {
  const size = new CapabilitySize();
  if (cap === null) { size.w = 0; size.h = 0; return size; }
  if (cap.k === 'timetable') {
    const count=cap.timetableMode==='day'?timetableCapacity(cap):1, columns=availableWidth>=192?briefColumns(availableWidth):count>10?3:2;
    size.w = cap.timetableMode === 'day' ? columns* (columns===3?88:96) : compact ? 96 : 128;
    size.h = cap.timetableMode === 'day' ? briefHeight(count, columns) : compact ? 80 : 116;
    return size;
  }
  if (compact) {
    size.w = 80; size.h = 36;
    if(cap.k==='clock') {size.w=68;size.h=32;}
    if (cap.k === 'worldclock') { size.w=104; size.h=76; }
    if (cap.k === 'lunar') { size.w=112; size.h=72; }
    if (cap.k === 'date') { size.w = 64; size.h = 48; }
    if (cap.k === 'calendar') { size.w = 112; size.h = 62; }
    if (cap.k === 'countdown' || cap.k === 'anniversary') { const date=new Date((cap.date??'')+'T00:00:00'),days=isNaN(date.getTime())?0:Math.abs(Math.round((date.getTime()-Date.now())/86400000));size.w = Math.max(72,Math.ceil(String(days).length*9.6+32)); size.h = 46; }
    if (cap.k === 'dayprogress' || cap.k === 'yearprogress') { size.w = 72; size.h = 52; }
    if (cap.k === 'battery') { size.w=64; size.h=56; }
    if (['agenda'].includes(cap.k)) { size.w=120; size.h=82; }
    return size;
  }
  if (cap.k === 'worldclock') { size.w=144; size.h=112; }
  if (cap.k === 'lunar') { size.w=160; size.h=112; }
  if (cap.k === 'date') { size.w = 128; size.h = 92; }
  if (cap.k === 'calendar') { size.w = 168; size.h = 202; }
  if (cap.k === 'countdown' || cap.k === 'anniversary') { size.w = 144; size.h = 110; }
  if (cap.k === 'dayprogress' || cap.k === 'yearprogress') { size.w = 132; size.h = 92; }
  if (cap.k === 'battery') { size.w=96; size.h=96; }
  if (['agenda'].includes(cap.k)) { size.w=164; size.h=136; }
  return size;
}
export function compactCapability(cap: CapBlock, width: number, height: number): boolean {
  const full = capabilityMinimum(cap);
  return width < full.w - .01 || height < full.h - .01;
}

export function capabilityFits(cap: CapBlock, width: number, height: number): boolean {
  const min=capabilityReadableMinimum(cap,width);return width+.1>=min.w && height+.1>=min.h;
}

// Compact typography may adapt by 20%, but never shrink without a readable floor.
// Keep the nominal metrics for rendering; layout constraints use the same floor.
export const MIN_CAPABILITY_SCALE: number = .8;
export function capabilityReadableMinimum(cap: CapBlock | null, width: number = 0): CapabilitySize {
  const min=capabilityMinimum(cap,true,width>0?width/MIN_CAPABILITY_SCALE:0);
  min.w*=MIN_CAPABILITY_SCALE; min.h*=MIN_CAPABILITY_SCALE; return min;
}
export function capabilityContentScale(cap: CapBlock, width: number, height: number): number {
  const compact=compactCapability(cap,width,height);
  const min=capabilityMinimum(cap,compact,compact?width/MIN_CAPABILITY_SCALE:width);
  return Math.min(2,width/min.w,height/min.h);
}

/** Fit a fixed-format readout before native layout; TextClock has no single-line adaptive sizing. */
export function boundedReadoutFont(nominal: number, width: number, emWidth: number): number {
  return Math.max(0, Math.min(nominal, width / Math.max(1, emWidth)));
}
