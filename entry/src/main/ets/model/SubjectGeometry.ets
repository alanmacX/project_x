import { compactLoop } from './ContourGeometry';
import { ShapePoint, ElementBox, FridgeCard } from './CardSchema';
export class SubjectPixels {
  width: number = 0;
  height: number = 0;
  rgba: Uint8Array = new Uint8Array(0);
  outline: ShapePoint[][] = [];
  ink: string = '#262824';
  crop: ElementBox = new ElementBox();
}
/** Smooth raster edges through alpha; geometry compression never repeatedly cuts away corners. */
export function smoothLoop(loop: ShapePoint[]): ShapePoint[] { return compactLoop(loop); }
/** Remove isolated segmentation noise and one-pixel spurs before feathering; substantial parts survive. */
export function cleanSubjectMask(mask: Int32Array, width: number, height: number): Int32Array {
  if (mask.length !== width * height || width < 1 || height < 1) throw new Error('主体蒙版尺寸不匹配');
  if (Math.min(width, height) < 8) return new Int32Array(mask);
  const result = new Int32Array(mask), visited = new Uint8Array(mask.length), queue = new Int32Array(mask.length);
  let foreground = 0; for (const alpha of mask) if (alpha >= 128) foreground++;
  const minimum = Math.max(4, Math.floor(foreground * .00003));
  for (let i = 0; i < mask.length; i++) {
    if (visited[i] || mask[i] < 128) continue;
    let read = 0, count = 1; queue[0] = i; visited[i] = 1;
    while (read < count) {
      const point = queue[read++], x = point % width, y = Math.floor(point / width);
      for (let dy = -1; dy <= 1; dy++) for (let dx = -1; dx <= 1; dx++) {
        const nx = x + dx, ny = y + dy, next = ny * width + nx;
        if (nx >= 0 && nx < width && ny >= 0 && ny < height && !visited[next] && mask[next] >= 128) { visited[next] = 1; queue[count++] = next; }
      }
    }
    if (count < minimum) for (let j = 0; j < count; j++) result[queue[j]] = 0;
  }
  const eroded = new Uint8Array(mask.length), opened = new Uint8Array(mask.length);
  // A conservative 3×3 opening removes narrow burrs without a broad blur of the photograph.
  for (let y = 0; y < height; y++) for (let x = 0; x < width; x++) {
    let inside = true;
    for (let dy = -1; dy <= 1 && inside; dy++) for (let dx = -1; dx <= 1; dx++) {
      const nx = Math.max(0, Math.min(width - 1, x + dx)), ny = Math.max(0, Math.min(height - 1, y + dy));
      if (result[ny * width + nx] < 128) { inside = false; break; }
    }
    if (inside) eroded[y * width + x] = 1;
  }
  for (let y = 0; y < height; y++) for (let x = 0; x < width; x++) {
    let inside = false;
    for (let dy = -1; dy <= 1 && !inside; dy++) for (let dx = -1; dx <= 1; dx++) {
      const nx = Math.max(0, Math.min(width - 1, x + dx)), ny = Math.max(0, Math.min(height - 1, y + dy));
      if (eroded[ny * width + nx]) { inside = true; break; }
    }
    if (inside) opened[y * width + x] = 1;
  }
  // Preserve small but legitimate thin subjects when opening would erase the subject itself.
  let retained = 0; for (const value of opened) retained += value;
  if (retained < foreground * .8) return result;
  for (let i = 0; i < result.length; i++) if (result[i] >= 128 && !opened[i]) result[i] = 0;
  return result;
}
/** Smooth alpha in a narrow edge band; opaque interior RGB and alpha stay sharp. */
export function smoothAlpha(mask: Int32Array, width: number, height: number): Int32Array {
  if (mask.length !== width * height || width < 1 || height < 1) throw new Error('主体蒙版尺寸不匹配');
  let left = width, top = height, right = 0, bottom = 0;
  for (let y = 0; y < height; y++) for (let x = 0; x < width; x++) {
    if (mask[y * width + x] >= 128) { left = Math.min(left, x); top = Math.min(top, y); right = Math.max(right, x); bottom = Math.max(bottom, y); }
  }
  const sigma = Math.min(width, height) < 8 ? .55 : Math.max(1.4, Math.min(2.6, Math.max(right - left + 1, bottom - top + 1) / 240));
  const radius = Math.ceil(sigma * 3), weights: number[] = []; let sum = 0;
  for (let i = -radius; i <= radius; i++) { const value = Math.exp(-i * i / (2 * sigma * sigma)); weights.push(value); sum += value; }
  const horizontal = new Float32Array(mask.length), result = new Int32Array(mask.length);
  const diameter = radius * 2 + 1, full = diameter * 255;
  // Most pixels are fully inside/outside the subject. A rolling sum identifies
  // constant windows exactly, avoiding a convolution for every interior pixel.
  for (let y = 0; y < height; y++) {
    const row = y * width; let windowSum = 0;
    for (let i = -radius; i <= radius; i++) windowSum += mask[row + Math.max(0, Math.min(width - 1, i))];
    for (let x = 0; x < width; x++) {
      if (windowSum === 0) horizontal[row + x] = 0;
      else if (windowSum === full) horizontal[row + x] = 255;
      else {
        let value = 0;
        for (let i = -radius; i <= radius; i++) value += mask[row + Math.max(0, Math.min(width - 1, x + i))] * weights[i + radius];
        horizontal[row + x] = value / sum;
      }
      windowSum += mask[row + Math.min(width - 1, x + radius + 1)] - mask[row + Math.max(0, x - radius)];
    }
  }
  for (let x = 0; x < width; x++) {
    let windowSum = 0;
    for (let i = -radius; i <= radius; i++) windowSum += horizontal[Math.max(0, Math.min(height - 1, i)) * width + x];
    for (let y = 0; y < height; y++) {
      if (windowSum <= .00001) result[y * width + x] = 0;
      else if (windowSum >= full - .00001) result[y * width + x] = 255;
      else {
        let value = 0;
        for (let i = -radius; i <= radius; i++) value += horizontal[Math.max(0, Math.min(height - 1, y + i)) * width + x] * weights[i + radius];
        // Retain the fractional alpha rather than sharpening the feather back into a jagged contour.
        result[y * width + x] = Math.max(0, Math.min(255, Math.round(value / sum)));
      }
      windowSum += horizontal[Math.min(height - 1, y + radius + 1) * width + x] - horizontal[Math.max(0, y - radius) * width + x];
    }
  }
  return result;
}
/** Feather without moving the 50% silhouette: thin foreground and small holes cannot vanish. */
export function featherSubjectAlpha(mask: Int32Array, width: number, height: number): Int32Array {
  const alpha = smoothAlpha(mask, width, height);
  for (let i = 0; i < alpha.length; i++) {
    alpha[i] = mask[i] >= 128 ? Math.max(128, alpha[i]) : Math.min(127, alpha[i]);
  }
  return alpha;
}
/** Crop PNG, alpha and outline using one pixel rectangle, so their coordinate spaces agree. */
export function prepareSubject(rgba: Uint8Array, mask: Int32Array, width: number, height: number, premultiplied: boolean = false): SubjectPixels {
  if (rgba.length !== width * height * 4) throw new Error('主体照片尺寸不匹配');
  const alpha = featherSubjectAlpha(cleanSubjectMask(mask, width, height), width, height);
  let left = width, top = height, right = -1, bottom = -1;
  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      if (alpha[y * width + x] < 16) continue;
      left = Math.min(left, x); top = Math.min(top, y); right = Math.max(right, x); bottom = Math.max(bottom, y);
    }
  }
  if (right < left || bottom < top) throw new Error('未检测到可用主体');
  // A single pixel preserves the antialias fringe; the original photograph's whitespace is discarded.
  left = Math.max(0, left - 1); top = Math.max(0, top - 1);
  right = Math.min(width - 1, right + 1); bottom = Math.min(height - 1, bottom + 1);
  const result = new SubjectPixels(); result.width = right - left + 1; result.height = bottom - top + 1;
  result.crop.x = left / width; result.crop.y = top / height; result.crop.w = result.width / width; result.crop.h = result.height / height;
  result.rgba = new Uint8Array(result.width * result.height * 4); const cropped = new Int32Array(result.width * result.height);
  for (let y = 0; y < result.height; y++) {
    for (let x = 0; x < result.width; x++) {
      const src = (y + top) * width + x + left, dst = y * result.width + x;
      let colour = src;
      // Old transparent PNGs have no RGB outside the subject. Extend nearby edge colour instead of creating a black fringe.
      if (rgba[src * 4 + 3] === 0 && alpha[src] > 0) {
        let found = false;
        for (let distance = 1; distance <= 12 && !found; distance++) {
          for (let direction = 0; direction < 8; direction++) {
            const a = direction * Math.PI / 4;
            const cx = Math.max(0, Math.min(width - 1, x + left + Math.round(Math.cos(a) * distance)));
            const cy = Math.max(0, Math.min(height - 1, y + top + Math.round(Math.sin(a) * distance)));
            const candidate = cy * width + cx;
            if (rgba[candidate * 4 + 3] >= 64) { colour = candidate; found = true; break; }
          }
        }
      }
      const oldAlpha = rgba[colour * 4 + 3]; cropped[dst] = alpha[src];
      for (let channel = 0; channel < 3; channel++) {
        result.rgba[dst * 4 + channel] = premultiplied && oldAlpha > 0 ? Math.min(255, Math.round(rgba[colour * 4 + channel] * 255 / oldAlpha)) : rgba[colour * 4 + channel];
      }
      result.rgba[dst * 4 + 3] = alpha[src];
    }
  }
  let light = 0, count = 0;
  for (let i = 0; i < result.width * result.height; i++) if (result.rgba[i * 4 + 3] >= 200) {
    light += .2126 * result.rgba[i * 4] + .7152 * result.rgba[i * 4 + 1] + .0722 * result.rgba[i * 4 + 2]; count++;
  }
  result.ink = count > 0 && light / count < 145 ? '#FFFFFF' : '#262824';
  result.outline = traceMask(cropped, result.width, result.height);
  return result;
}
/** Preserve an existing card's on-board footprint while removing its transparent margins. */
export function cropCardToSubject(card: FridgeCard, crop: ElementBox): void {
  const oldW = card.w, oldH = card.h, a = card.rot * Math.PI / 180;
  const u = crop.x * oldW, v = (crop.y + crop.h) * oldH;
  card.x += u * Math.cos(a) - (v - oldH) * Math.sin(a);
  card.y += oldH + u * Math.sin(a) + (v - oldH) * Math.cos(a) - oldH * crop.h;
  card.w *= crop.w; card.h *= crop.h;
  for (const el of card.elements) {
    el.x = (el.x - crop.x) / crop.w; el.y = (el.y - crop.y) / crop.h; el.w /= crop.w; el.h /= crop.h;
  }
}
interface Edge { from: number; to: number; }
/** Trace oriented mask-cell edges, including holes and disconnected subject parts. */
export function traceMask(mask: Int32Array, width: number, height: number): ShapePoint[][] {
  if (width < 1 || height < 1 || mask.length !== width * height) throw new Error('主体蒙版尺寸不匹配');
  const step = 1; // Full-resolution threshold retains thin parts before bounded contour reduction.
  const gw = Math.ceil(width / step), gh = Math.ceil(height / step);
  const cells: boolean[] = [];
  for (let y = 0; y < gh; y++) {
    for (let x = 0; x < gw; x++) {
      cells.push(mask[Math.min(height - 1, y * step + Math.floor(step / 2)) * width + Math.min(width - 1, x * step + Math.floor(step / 2))] >= 128);
    }
  }
  const inside = (x: number, y: number): boolean => x >= 0 && y >= 0 && x < gw && y < gh && cells[y * gw + x];
  const edges: Edge[] = [];
  const add = (x1: number, y1: number, x2: number, y2: number): void => { edges.push({ from: y1 * (gw + 1) + x1, to: y2 * (gw + 1) + x2 }); };
  for (let y = 0; y < gh; y++) {
    for (let x = 0; x < gw; x++) {
      if (!inside(x, y)) continue;
      if (!inside(x, y - 1)) add(x, y, x + 1, y);
      if (!inside(x + 1, y)) add(x + 1, y, x + 1, y + 1);
      if (!inside(x, y + 1)) add(x + 1, y + 1, x, y + 1);
      if (!inside(x - 1, y)) add(x, y + 1, x, y);
    }
  }
  const outgoing = new Map<number, number[]>();
  edges.forEach((e: Edge, i: number) => { const list = outgoing.get(e.from) ?? []; list.push(i); outgoing.set(e.from, list); });
  const used = new Set<number>(); const loops: ShapePoint[][] = [];
  for (let i = 0; i < edges.length; i++) {
    if (used.has(i)) continue;
    const loop: ShapePoint[] = []; let index = i;
    for (let n = 0; n <= edges.length; n++) {
      if (used.has(index)) break;
      used.add(index); const edge = edges[index];
      loop.push({ x: (edge.from % (gw + 1)) / gw, y: Math.floor(edge.from / (gw + 1)) / gh });
      if (edge.to === edges[i].from) break;
      const next = (outgoing.get(edge.to) ?? []).find((v: number) => !used.has(v));
      if (next === undefined) break; index = next;
    }
    if (loop.length >= 4) {
      const simplified = loop.filter((p: ShapePoint, j: number) => {
        const a = loop[(j + loop.length - 1) % loop.length], b = loop[(j + 1) % loop.length];
        return Math.abs((p.x - a.x) * (b.y - p.y) - (p.y - a.y) * (b.x - p.x)) > 0.000001;
      });
      if (simplified.length >= 3) loops.push(compactLoop(simplified, .8 / Math.max(width, height)));
    }
  }
  if (loops.length === 0) throw new Error('未检测到可用主体');
  return loops;
}

