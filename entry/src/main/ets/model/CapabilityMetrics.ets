import { timetableCapacity, briefHeight, briefColumns } from './TimetableLayout';
import { CapBlock } from './CardSchema';
export class CapabilitySize { w: number = 112; h: number = 58; }
/** Full and compact layouts have separate readable minima; neither shrinks to microscopic text. */
export function capabilityMinimum(cap: CapBlock | null, compact: boolean = false, availableWidth: number = 0): CapabilitySize {
  const size = new CapabilitySize();
  if (cap === null) { size.w = 0; size.h = 0; return size; }
  if (cap.k === 'timetable') {
    const count=cap.timetableMode==='day'?timetableCapacity(cap):1, columns=availableWidth>=192?briefColumns(availableWidth):count>10?3:2;
    size.w = cap.timetableMode === 'day' ? columns* (columns===3?88:96) : 128;
    size.h = cap.timetableMode === 'day' ? briefHeight(count, columns) : 116;
    return size;
  }
  if (compact) {
    size.w = 80; size.h = 36;
    if (cap.k === 'worldclock') { size.w=104; size.h=76; }
    if (cap.k === 'lunar') { size.w=112; size.h=72; }
    if (cap.k === 'date') { size.w = 64; size.h = 48; }
    if (cap.k === 'calendar') { size.w = 112; size.h = 62; }
    if (cap.k === 'countdown' || cap.k === 'anniversary') { const date=new Date((cap.date??'')+'T00:00:00'),days=isNaN(date.getTime())?0:Math.abs(Math.round((date.getTime()-Date.now())/86400000));size.w = Math.max(80,Math.ceil(String(days).length*9.6+32)); size.h = 50; }
    if (cap.k === 'dayprogress' || cap.k === 'yearprogress') { size.w = 72; size.h = 52; }
    if (cap.k === 'battery') { size.w=88; size.h=44; }
    if (cap.k === 'fetch') { size.w=104; size.h=64; }
    if (['agenda'].includes(cap.k)) { size.w=120; size.h=82; }
    return size;
  }
  if (cap.k === 'worldclock') { size.w=144; size.h=112; }
  if (cap.k === 'lunar') { size.w=160; size.h=112; }
  if (cap.k === 'date') { size.w = 128; size.h = 92; }
  if (cap.k === 'calendar') { size.w = 168; size.h = 202; }
  if (cap.k === 'countdown' || cap.k === 'anniversary') { size.w = 144; size.h = 110; }
  if (cap.k === 'dayprogress' || cap.k === 'yearprogress') { size.w = 132; size.h = 92; }
  if (cap.k === 'battery') { size.w=132; size.h=96; }
  if (cap.k === 'fetch') { size.w=132; size.h=120; }
  if (['agenda'].includes(cap.k)) { size.w=164; size.h=136; }
  return size;
}
export function compactCapability(cap: CapBlock, width: number, height: number): boolean {
  const full = capabilityMinimum(cap);
  return width < full.w - .01 || height < full.h - .01;
}

export function capabilityFits(cap: CapBlock, width: number, height: number): boolean {
  const min=capabilityMinimum(cap,true,width);return width+.1>=min.w && height+.1>=min.h;
}
