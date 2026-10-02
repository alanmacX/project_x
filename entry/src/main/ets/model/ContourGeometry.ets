import { ShapePoint } from './CardSchema';
function distanceSquared(p: ShapePoint, a: ShapePoint, b: ShapePoint): number {
  const dx = b.x - a.x, dy = b.y - a.y, n = dx * dx + dy * dy;
  const t = n === 0 ? 0 : Math.max(0, Math.min(1, ((p.x - a.x) * dx + (p.y - a.y) * dy) / n));
  return (p.x - a.x - t * dx) ** 2 + (p.y - a.y - t * dy) ** 2;
}
function area(points: ShapePoint[]): number {
  let sum = 0;
  for (let i = 0; i < points.length; i++) { const a = points[i], b = points[(i + 1) % points.length]; sum += a.x * b.y - b.x * a.y; }
  return sum / 2;
}
function orient(a: ShapePoint, b: ShapePoint, c: ShapePoint): number { return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x); }
function crosses(a: ShapePoint, b: ShapePoint, c: ShapePoint, d: ShapePoint): boolean {
  if (Math.max(a.x,b.x) < Math.min(c.x,d.x) || Math.max(c.x,d.x) < Math.min(a.x,b.x) ||
    Math.max(a.y,b.y) < Math.min(c.y,d.y) || Math.max(c.y,d.y) < Math.min(a.y,b.y)) return false;
  return orient(a,b,c) * orient(a,b,d) < -1e-18 && orient(c,d,a) * orient(c,d,b) < -1e-18;
}
function simple(points: ShapePoint[]): boolean {
  for (let i = 0; i < points.length; i++) for (let j = i + 2; j < points.length; j++) {
    if (i === 0 && j === points.length - 1) continue;
    if (crosses(points[i], points[(i+1)%points.length], points[j], points[(j+1)%points.length])) return false;
  }
  return true;
}
/** Closed Douglas-Peucker with a hard maximum deviation, original vertices and preserved winding. */
export function compactLoop(loop: ShapePoint[], tolerance: number = .00035): ShapePoint[] {
  if (loop.length < 5) return loop;
  let opposite = 1, far = 0;
  for (let i = 1; i < loop.length; i++) { const d = (loop[i].x-loop[0].x)**2+(loop[i].y-loop[0].y)**2; if (d > far) { far = d; opposite = i; } }
  const points = loop.concat([loop[0]]), keep = new Uint8Array(points.length); keep[0] = 1; keep[opposite] = 1; keep[loop.length] = 1;
  // Pin deliberate corners and the paired endpoints of narrow U-turns.
  for (let i = 0; i < loop.length; i++) {
    const a = loop[(i+loop.length-1)%loop.length], p = loop[i], b = loop[(i+1)%loop.length], c = loop[(i+2)%loop.length];
    const ux=p.x-a.x, uy=p.y-a.y, vx=b.x-p.x, vy=b.y-p.y, wx=c.x-b.x, wy=c.y-b.y;
    const u=Math.hypot(ux,uy), v=Math.hypot(vx,vy), w=Math.hypot(wx,wy);
    if (u>tolerance*4 && v>tolerance*4 && Math.abs(ux*vy-uy*vx)>u*v*.2) keep[i]=1;
    if (v<tolerance*2 && u>tolerance*4 && w>tolerance*4 && ux*wx+uy*wy < -.8*u*w) { keep[i]=1; keep[(i+1)%loop.length]=1; }
  }
  const stack: number[] = []; let previous = 0;
  for (let i = 1; i < keep.length; i++) if (keep[i]) { stack.push(previous,i); previous=i; }
  const limit = tolerance * tolerance;
  while (stack.length > 0) {
    const end = stack.pop()!, start = stack.pop()!; let index = -1, maximum = limit;
    for (let i = start + 1; i < end; i++) { const d = distanceSquared(points[i], points[start], points[end]); if (d > maximum) { maximum = d; index = i; } }
    if (index >= 0) { keep[index] = 1; stack.push(start, index, index, end); }
  }
  const result = loop.filter((_: ShapePoint, i: number) => keep[i] === 1), before = area(loop), after = area(result);
  if (result.length < 3 || before * after <= 0 || Math.abs(after-before) > Math.abs(before)*.005 || !simple(result)) {
    return tolerance > .00005 ? compactLoop(loop, tolerance / 2) : loop;
  }
  return result;
}
function contains(loop: ShapePoint[], p: ShapePoint): boolean {
  let inside = false;
  for (let i = 0, j = loop.length - 1; i < loop.length; j = i++) {
    const a = loop[i], b = loop[j];
    if ((a.y > p.y) !== (b.y > p.y) && p.x < (b.x-a.x)*(p.y-a.y)/(b.y-a.y)+a.x) inside = !inside;
  }
  return inside;
}
export function compactContours(loops: ShapePoint[][], tolerance: number = .00035): ShapePoint[][] {
  const result = loops.map((loop: ShapePoint[]) => compactLoop(loop, tolerance));
  // Never merge/cross separate parts or hole boundaries.
  for (let i = 0; i < result.length; i++) for (let j = i+1; j < result.length; j++) {
    if (contains(loops[i],loops[j][0]) !== contains(result[i],result[j][0]) || contains(loops[j],loops[i][0]) !== contains(result[j],result[i][0])) return loops;
    for (let a = 0; a < result[i].length; a++) for (let b = 0; b < result[j].length; b++) {
      if (crosses(result[i][a],result[i][(a+1)%result[i].length],result[j][b],result[j][(b+1)%result[j].length])) return loops;
    }
  }
  return result.every((loop: ShapePoint[], i: number) => loop === loops[i]) ? loops : result;
}
