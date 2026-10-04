import { readingSurface } from './CapabilityPresentation';
import { cardOutline } from './RenderContours';
import { FridgeCard, ElementBox, ShapePoint, BOARD_W, BOARD_H } from './CardSchema';
import { capabilityMinimum, CapabilitySize } from './CapabilityMetrics';

function outlineIntervals(y: number, loops: ShapePoint[][]): number[] {
  const xs: number[] = [];
  for (const loop of loops) {
    for (let i = 0, j = loop.length - 1; i < loop.length; j = i++) {
      const a = loop[i], b = loop[j];
      if ((a.y > y) !== (b.y > y)) xs.push((b.x - a.x) * (y - a.y) / (b.y - a.y) + a.x);
    }
  }
  return xs.sort((a: number, b: number) => a - b);
}
function spanInside(left: number, right: number, intervals: number[]): boolean {
  for (let i = 0; i + 1 < intervals.length; i += 2) if (left >= intervals[i] && right <= intervals[i + 1]) return true;
  return false;
}
/** Largest interior rectangle; never place a capability across a subject's transparent holes. */
export function subjectInterior(loops: ShapePoint[][], preferredAspect: number = 0): ElementBox {
  const size = 48, heights: number[] = new Array<number>(size).fill(0);
  let area = 0, score = 0; const box = new ElementBox(); box.x = 0; box.y = 0; box.w = 0; box.h = 0;
  for (let y = 0; y < size; y++) {
    const top = outlineIntervals((y + .05) / size, loops), middle = outlineIntervals((y + .5) / size, loops), bottom = outlineIntervals((y + .95) / size, loops);
    for (let x = 0; x < size; x++) {
      const left = (x + .05) / size, right = (x + .95) / size;
      const yes = spanInside(left, right, top) && spanInside(left, right, middle) && spanInside(left, right, bottom);
      heights[x] = yes ? heights[x] + 1 : 0;
    }
    for (let right = 0; right < size; right++) {
      let height = heights[right];
      for (let left = right; left >= 0 && height > 0; left--) {
        height = Math.min(height, heights[left]); const value = height * (right - left + 1);
        const candidate = preferredAspect > 0 ? Math.min((right - left + 1) / preferredAspect, height) : value;
        if (candidate > score || (candidate === score && value > area)) { score = candidate; area = value; box.x = left / size; box.y = (y + 1 - height) / size; box.w = (right - left + 1) / size; box.h = height / size; }
      }
    }
  }
  const padding = Math.min(0.012, box.w / 12, box.h / 12);
  box.x += padding; box.y += padding; box.w -= 2 * padding; box.h -= 2 * padding;
  return box;
}
// Extraction replaces the contour array; snapshots share it. A cache lookup must
// never serialize thousands of points on the UI thread.
const outlineIds = new WeakMap<ShapePoint[][], number>();
let nextOutlineId: number = 1;
function outlineIdentity(card: FridgeCard): string {
  if(card.shape!=='subject')return card.shape;
  // ArkUI @Prop may deep-copy arrays. Extracted assets have immutable, unique
  // file names, so their cache identity also survives component propagation.
  if (card.cutout.length > 0) return card.cutout + ':' + card.subjectVersion;
  const outline = cardOutline(card);
  if(outline.length===0)return 'empty';
  let id = outlineIds.get(outline);
  if (id === undefined) { id = nextOutlineId++; outlineIds.set(outline, id); }
  return String(id);
}
const subjectCache = new Map<string, ElementBox>();
export function subjectSurfaceFactor(card: FridgeCard): number {
  return card.shape === 'subject' && card.subjectBorder ? Math.max(.5, Math.min(1 - 6 / card.w, 1 - 6 / card.h)) : 1;
}
export function safeContentBox(card: FridgeCard): ElementBox {
  if (card.shape === 'subject' && cardOutline(card).length > 0) {
    const min = cardCapabilityMinimum(card, true), aspect = min.w > 0 ? min.w * card.h / (min.h * card.w) : 0;
    // Cache the normalized interior independently of the pixel-size white edge.
    // Proportional resizing keeps this aspect stable; floating-point noise must not rescan the outline.
    const key = Math.round(aspect * 1000000) + ':' + outlineIdentity(card);
    let interior = subjectCache.get(key);
    if (interior === undefined) {
      interior = subjectInterior(cardOutline(card), aspect);
      if (subjectCache.size > 32) subjectCache.clear(); subjectCache.set(key, interior);
    }
    const box = new ElementBox(), factor = subjectSurfaceFactor(card), inset = (1 - factor) / 2;
    box.x = inset + interior.x * factor; box.y = inset + interior.y * factor; box.w = interior.w * factor; box.h = interior.h * factor;
    return box;
  }
  const box = new ElementBox();
  const inset = card.shape === 'round' ? 0.15 : (card.shape === 'blob' ? 0.12 : (card.shape === 'pill' ? 0.15 : 0.06));
  box.x = inset; box.y = inset; box.w = 1 - 2 * inset; box.h = 1 - 2 * inset;
  return box;
}
export function fitContentBox(requested: ElementBox, safe: ElementBox): ElementBox {
  const box = new ElementBox(); box.w = Math.min(requested.w, safe.w); box.h = Math.min(requested.h, safe.h);
  box.x = Math.max(safe.x, Math.min(safe.x + safe.w - box.w, requested.x));
  box.y = Math.max(safe.y, Math.min(safe.y + safe.h - box.h, requested.y));
  box.rot = 0; box.opacity = requested.opacity; return box;
}
const layoutCache = new Map<string, ElementBox>();
const MASK_SIZE: number = 96;
class InteriorMask { integral: number[] = []; }
const maskCache = new Map<string, InteriorMask>();
function interiorMask(card: FridgeCard): InteriorMask {
  const key=outlineIdentity(card),cached=maskCache.get(key);if(cached!==undefined)return cached;
  const mask=new InteriorMask(),stride=MASK_SIZE+1;mask.integral=new Array<number>(stride*stride).fill(0);
  const loops=cardOutline(card);
  for(let y=0;y<MASK_SIZE;y++) {
    const samples=[outlineIntervals(y/MASK_SIZE,loops),outlineIntervals((y+.5)/MASK_SIZE,loops),outlineIntervals((y+1)/MASK_SIZE,loops)];
    let row=0;
    for(let x=0;x<MASK_SIZE;x++) {
      row+=samples.every((span:number[])=>spanInside(x/MASK_SIZE,(x+1)/MASK_SIZE,span))?0:1;
      mask.integral[(y+1)*stride+x+1]=mask.integral[y*stride+x+1]+row;
    }
  }
  if(maskCache.size>=128)maskCache.delete(Array.from(maskCache.keys())[0]);maskCache.set(key,mask);return mask;
}
/** Convex regular shapes need only four analytic corner checks, even while resizing. */
function regularContains(card:FridgeCard,box:ElementBox):boolean {
  if(box.x<0 || box.y<0 || box.x+box.w>1.000001 || box.y+box.h>1.000001)return false;
  for(const x of [box.x,box.x+box.w]) for(const y of [box.y,box.y+box.h]) {
    if(card.shape==='round') {if(Math.pow((x-.5)*2,2)+Math.pow((y-.5)*2,2)>1.000001)return false;}
    else {
      const top=y<.5,left=x<.5,fraction=top?(left?.28:.12):(left?.18:.26),radius=card.shape==='pill'?Math.min(card.w,card.h)/2:16;
      const rx=card.shape==='blob'?fraction:Math.min(.5,radius/card.w),ry=card.shape==='blob'?fraction:Math.min(.5,radius/card.h),cx=left?rx:1-rx,cy=top?ry:1-ry;
      if((left?x<cx:x>cx)&&(top?y<cy:y>cy)&&Math.pow((x-cx)/rx,2)+Math.pow((y-cy)/ry,2)>1.000001)return false;
    }
  }
  return true;
}
function maskContains(mask: InteriorMask,box:ElementBox):boolean {
  const l=Math.max(0,Math.floor(box.x*MASK_SIZE+1e-7)),t=Math.max(0,Math.floor(box.y*MASK_SIZE+1e-7));
  const r=Math.min(MASK_SIZE,Math.ceil((box.x+box.w)*MASK_SIZE-1e-7)),b=Math.min(MASK_SIZE,Math.ceil((box.y+box.h)*MASK_SIZE-1e-7)),stride=MASK_SIZE+1;
  return box.x>=0 && box.y>=0 && box.x+box.w<=1.000001 && box.y+box.h<=1.000001 && mask.integral[b*stride+r]-mask.integral[t*stride+r]-mask.integral[b*stride+l]+mask.integral[t*stride+l]===0;
}
/** Position across the entire silhouette, preserving size and intentional compositions. */
export function fitCapabilityPosition(card:FridgeCard,requested:ElementBox):ElementBox {
  if(card.shape==='subject'&&cardOutline(card).length===0)return fitContentBox(requested,safeContentBox(card));
  const f=subjectSurfaceFactor(card),inset=(1-f)/2,box=new ElementBox();
  box.w=requested.w/f;box.h=requested.h/f;box.x=(requested.x-inset)/f;box.y=(requested.y-inset)/f;box.opacity=requested.opacity;
  const mask=card.shape==='subject'?interiorMask(card):undefined;
  const contains=(candidate:ElementBox):boolean=>mask!==undefined?maskContains(mask,candidate):regularContains(card,candidate);
  if(!contains(box)) {
    let best=Number.MAX_VALUE,bx=0,by=0;
    for(let y=0;y+box.h*MASK_SIZE<=MASK_SIZE;y++) for(let x=0;x+box.w*MASK_SIZE<=MASK_SIZE;x++) {
      const nx=x/MASK_SIZE,ny=y/MASK_SIZE,distance=Math.pow((nx-box.x)*card.w,2)+Math.pow((ny-box.y)*card.h,2);
      if(distance>=best)continue;
      const candidate=new ElementBox();candidate.x=nx;candidate.y=ny;candidate.w=box.w;candidate.h=box.h;
      if(contains(candidate)){best=distance;bx=nx;by=ny;}
    }
    if(best===Number.MAX_VALUE)return readableSlot(card,safeContentBox(card));
    box.x=bx;box.y=by;
  }
  box.x=inset+box.x*f;box.y=inset+box.y*f;box.w*=f;box.h*=f;return box;
}
/** Gesture path uses constant-time mask queries, never a contour scan or nearest-position search. */
export function constrainCapabilityDrag(card:FridgeCard,requested:ElementBox,previous:ElementBox):ElementBox {
  if(card.shape==='subject'&&cardOutline(card).length===0)return fitContentBox(requested,safeContentBox(card));
  const f=subjectSurfaceFactor(card),inset=(1-f)/2,mask=card.shape==='subject'?interiorMask(card):undefined;
  const valid=(x:number,y:number):boolean=>{const box=new ElementBox();box.x=(x-inset)/f;box.y=(y-inset)/f;box.w=requested.w/f;box.h=requested.h/f;return mask!==undefined?maskContains(mask,box):regularContains(card,box);};
  if(valid(requested.x,requested.y))return requested;
  const result=new ElementBox();result.w=requested.w;result.h=requested.h;result.opacity=requested.opacity;
  let low=0,high=1;
  for(let i=0;i<10;i++){const middle=(low+high)/2;if(valid(previous.x+(requested.x-previous.x)*middle,previous.y+(requested.y-previous.y)*middle))low=middle;else high=middle;}
  result.x=previous.x+(requested.x-previous.x)*low;result.y=previous.y+(requested.y-previous.y)*low;
  if(valid(requested.x,result.y))result.x=requested.x;
  if(valid(result.x,requested.y))result.y=requested.y;
  return result;
}
export function capabilityObstructed(card:FridgeCard):boolean {
  return card.elements.some((el)=>!el.behindCapability && (el.kind==='text'||el.kind==='image') && card.capBox.x<el.x+el.w && card.capBox.x+card.capBox.w>el.x && card.capBox.y<el.y+el.h && card.capBox.y+card.capBox.h>el.y);
}
export function capabilityBox(card: FridgeCard): ElementBox {
  const minimum=cardCapabilityMinimum(card,true,card.w*card.capBox.w);
  const key=minimum.w+':'+minimum.h+':'+card.shape+':'+outlineIdentity(card)+':'+card.subjectBorder+':'+card.w+':'+card.h+':'+JSON.stringify(card.capBox);
  const cached=layoutCache.get(key);if(cached!==undefined)return cached;
  const requested=new ElementBox();requested.x=card.capBox.x;requested.y=card.capBox.y;requested.opacity=card.capBox.opacity;
  requested.w=Math.max(card.capBox.w,minimum.w/card.w);requested.h=Math.max(card.capBox.h,minimum.h/card.h);
  const result=fitCapabilityPosition(card,requested);
  if(layoutCache.size>128)layoutCache.clear();layoutCache.set(key,result);return result;
}
export function resizeFactor(w: number, h: number, dx: number, dy: number, angle: number): number {
  const a = angle * Math.PI / 180;
  const x = dx * Math.cos(a) + dy * Math.sin(a), y = -dx * Math.sin(a) + dy * Math.cos(a);
  return 1 + (x * w - y * h) / (w * w + h * h);
}
export function capabilityPlacement(card: FridgeCard): ElementBox {
  const box = capabilityBox(card); if (box.w > 0 && box.h > 0) return box;
  const safe = safeContentBox(card), overlay = readableSlot(card, safe);
  return overlay;
}
/** Permit cropped compositions, while keeping a recoverable portion inside the canvas. */
export function clampCardGeometry(card: FridgeCard, width: number = BOARD_W, height: number = BOARD_H): void {
  const a = card.rot * Math.PI / 180, c = Math.cos(a), s = Math.sin(a);
  const xs: number[] = [0, card.h * s, card.w * c + card.h * s, card.w * c];
  const ys: number[] = [0, -card.h * c, card.w * s - card.h * c, card.w * s];
  const visibleX = Math.min(32, card.w * .2), visibleY = Math.min(32, card.h * .2);
  card.x = Math.max(visibleX - Math.max(...xs), Math.min(width - visibleX - Math.min(...xs), card.x));
  card.y = Math.max(visibleY - card.h - Math.max(...ys), Math.min(height - visibleY - card.h - Math.min(...ys), card.y));
}

function readableSlot(card: FridgeCard, safe: ElementBox): ElementBox {
  const min = cardCapabilityMinimum(card, true, card.w*safe.w), requested = new ElementBox();
  requested.x = card.capBox.x; requested.y = card.capBox.y; requested.opacity = card.capBox.opacity;
  requested.w = Math.max(card.capBox.w, min.w / card.w); requested.h = Math.max(card.capBox.h, min.h / card.h);
  return fitContentBox(requested, safe);
}
export function minimumCardSize(card: FridgeCard): CapabilitySize {
  const size = new CapabilitySize(); size.w = card.shape === 'subject' ? 16 : 80; size.h = card.shape === 'subject' ? 16 : 80;
  if (card.capability === null) return size;
  const safe = safeContentBox(card), min = cardCapabilityMinimum(card, true, card.w*safe.w);
  size.w = Math.max(card.shape === 'subject' ? 16 : 80, min.w / Math.max(.0001, safe.w)); size.h = Math.max(card.shape === 'subject' ? 16 : 80, min.h / Math.max(.0001, safe.h));
  return size;
}
/** Expand proportionally and refuse a shape whose interior cannot support this capability on the board. */
export function ensureCapabilitySize(card: FridgeCard): boolean {
  const min = minimumCardSize(card), factor = Math.max(1, min.w / card.w, min.h / card.h);
  const w = card.w * factor, h = card.h * factor;
  if (w > 320 + .01 || h > 420 + .01) return false;
  card.w = w; card.h = h; clampCardGeometry(card); return true;
}

/** Attach subject controls to the actual silhouette near each corner, including concave shapes. */
export function cardHandlePoint(card: FridgeCard, right: boolean, bottom: boolean): ShapePoint {
  const target: ShapePoint = { x: right ? 1 : 0, y: bottom ? 1 : 0 };
  if (card.shape !== 'subject' || cardOutline(card).length === 0) return target;
  let best = Number.MAX_VALUE, point = target;
  for (const loop of cardOutline(card)) for (const p of loop) {
    const distance = Math.pow((p.x - target.x) * card.w, 2) + Math.pow((p.y - target.y) * card.h, 2);
    if (distance < best) { best = distance; const f = subjectSurfaceFactor(card), inset = (1 - f) / 2; point = { x: inset + p.x * f, y: inset + p.y * f }; }
  }
  return point;
}

/** Backing and inset belong to layout, so a photo subject never silently loses readable space. */
export function capabilityInset(card: FridgeCard): number {
  return readingSurface(card.capability, card.shape === 'subject' && card.subjectPhoto, capabilityObstructed(card)) ? 8 : 0;
}
export function cardCapabilityMinimum(card: FridgeCard, compact: boolean = true, width: number = 0): CapabilitySize {
  const inset = capabilityInset(card), size = capabilityMinimum(card.capability, compact, Math.max(0,width - inset*2));
  if(card.capability!==null) { size.w += inset*2; size.h += inset*2; } return size;
}
/** Presets choose a readable island inside the actual silhouette; artwork geometry stays intact. */
export function capabilityPreset(card: FridgeCard, anchor: string): ElementBox {
  const safe = safeContentBox(card), min = cardCapabilityMinimum(card, false, card.w*safe.w), box = new ElementBox();
  box.w = Math.min(safe.w,Math.max(cardCapabilityMinimum(card,true).w,min.w)/card.w);
  box.h = Math.min(safe.h,min.h/card.h); box.x = safe.x + (safe.w-box.w)/2;
  box.y = safe.y + (safe.h-box.h)*(anchor==='top'?0:anchor==='bottom'?1:.5);
  box.opacity=1; return box;
}
