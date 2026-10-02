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
  // ArkUI @Prop may deep-copy arrays. Extracted assets have immutable, unique
  // file names, so their cache identity also survives component propagation.
  if (card.cutout.length > 0) return card.cutout + ':' + card.subjectVersion;
  const outline = cardOutline(card);
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
    const min = capabilityMinimum(card.capability, true), aspect = min.w > 0 ? min.w * card.h / (min.h * card.w) : 0;
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
const obstacleCache = new Map<string, ElementBox>();
export function capabilityBox(card: FridgeCard): ElementBox {
  const obstacles = card.elements.filter((el) => !el.behindCapability && (el.kind === 'text' || el.kind === 'image'));
  const key = card.id + ':' + card.capability?.k + ':' + card.shape + ':' + card.cutout + ':' + card.subjectBorder + ':' + outlineIdentity(card) + ':' + card.w + ':' + card.h + ':' + JSON.stringify(card.capBox) + ':' +
    JSON.stringify(obstacles.map((el) => [el.x, el.y, el.w, el.h, el.rot]));
  const cached = layoutCache.get(key); if (cached !== undefined) return cached;
  const safe = safeContentBox(card), requested = readableSlot(card, safe);
  const overlaps = (box: ElementBox, other: ElementBox): boolean => box.x < other.x + other.w && box.x + box.w > other.x && box.y < other.y + other.h && box.y + box.h > other.y;
  let result = requested;
  if (obstacles.some((el) => overlaps(requested, el))) {
    const obstacleKey = JSON.stringify([safe.x, safe.y, safe.w, safe.h]) + ':' + JSON.stringify(obstacles.map((el) => [el.x, el.y, el.w, el.h, el.rot]));
    let empty = obstacleCache.get(obstacleKey);
    if (empty === undefined) {
    const size = 40, heights: number[] = new Array<number>(size).fill(0); let best = 0;
    empty = new ElementBox(); empty.w = 0; empty.h = 0;
    for (let y = 0; y < size; y++) {
      for (let x = 0; x < size; x++) {
        const cell = new ElementBox(); cell.x = safe.x + x / size * safe.w; cell.y = safe.y + y / size * safe.h;
        cell.w = safe.w / size; cell.h = safe.h / size;
        heights[x] = obstacles.some((el) => overlaps(cell, el)) ? 0 : heights[x] + 1;
      }
      for (let right = 0; right < size; right++) {
        let height = heights[right];
        for (let left = right; left >= 0 && height > 0; left--) {
          height = Math.min(height, heights[left]); const area = height * (right - left + 1);
          if (area > best) { best = area; empty.x = safe.x + left / size * safe.w; empty.y = safe.y + (y + 1 - height) / size * safe.h;
            empty.w = (right - left + 1) / size * safe.w; empty.h = height / size * safe.h; }
        }
      }
    }
    if (obstacleCache.size > 64) obstacleCache.clear(); obstacleCache.set(obstacleKey, empty);
    }
    const min = capabilityMinimum(card.capability, true);
    if (empty.w > 0 && empty.w * card.w >= min.w - .01 && empty.h * card.h >= min.h - .01) result = readableSlot(card, empty);
    else { result = new ElementBox(); result.x = safe.x; result.y = safe.y; result.w = 0; result.h = 0; }
  }
  if (layoutCache.size > 128) layoutCache.clear(); layoutCache.set(key, result); return result;
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
  const min = capabilityMinimum(card.capability, true), requested = new ElementBox();
  requested.x = card.capBox.x; requested.y = card.capBox.y; requested.opacity = card.capBox.opacity;
  requested.w = Math.max(card.capBox.w, min.w / card.w); requested.h = Math.max(card.capBox.h, min.h / card.h);
  return fitContentBox(requested, safe);
}
export function minimumCardSize(card: FridgeCard): CapabilitySize {
  const size = new CapabilitySize(); size.w = card.shape === 'subject' ? 16 : 80; size.h = card.shape === 'subject' ? 16 : 80;
  if (card.capability === null) return size;
  const safe = safeContentBox(card), min = capabilityMinimum(card.capability, true);
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
