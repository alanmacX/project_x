import { CapBlock } from './CardSchema';
export class CapabilitySize { w: number = 112; h: number = 58; }
/** Full and compact layouts have separate readable minima; neither shrinks to microscopic text. */
export function capabilityMinimum(cap: CapBlock | null, compact: boolean = false): CapabilitySize {
  const size = new CapabilitySize();
  if (cap === null) { size.w = 0; size.h = 0; return size; }
  if (compact) {
    size.w = 80; size.h = 36;
    if (cap.k === 'date') { size.w = 64; size.h = 52; }
    if (cap.k === 'calendar') { size.w = 112; size.h = 62; }
    if (cap.k === 'countdown' || cap.k === 'anniversary') { size.w = 80; size.h = 64; }
    if (cap.k === 'weather') { size.w = 72; size.h = 56; }
    if (cap.k === 'dayprogress' || cap.k === 'yearprogress') { size.w = 72; size.h = 52; }
    return size;
  }
  if (cap.k === 'date') { size.w = 128; size.h = 92; }
  if (cap.k === 'calendar') { size.w = 168; size.h = 176; }
  if (cap.k === 'countdown' || cap.k === 'anniversary') { size.w = 144; size.h = 110; }
  if (cap.k === 'weather') { size.w = 132; size.h = 104; }
  if (cap.k === 'dayprogress' || cap.k === 'yearprogress') { size.w = 132; size.h = 92; }
  return size;
}
export function compactCapability(cap: CapBlock, width: number, height: number): boolean {
  const full = capabilityMinimum(cap);
  return width < full.w - .01 || height < full.h - .01;
}
