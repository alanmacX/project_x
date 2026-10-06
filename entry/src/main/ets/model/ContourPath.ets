import { ShapePoint } from './CardSchema';
/** Round only raster-scale bends, within 0.12% of the source box. Long deliberate corners stay pinned. */
export function contourPath(loops: ShapePoint[][], width: number, height: number, factor: number): string {
  const commands: string[] = [], inset = (1 - factor) / 2;
  // SVG's native parser need not scan 15 decimal digits for subpixel vertices.
  const coordinate = (value: number): string => String(Math.round(value * 100) / 100);
  for (const loop of loops) {
    if (loop.length < 3) continue;
    const before: ShapePoint[] = [], after: ShapePoint[] = [];
    for (let i = 0; i < loop.length; i++) {
      const p = loop[i], a = loop[(i + loop.length - 1) % loop.length], b = loop[(i + 1) % loop.length];
      const u = Math.hypot(p.x - a.x, p.y - a.y), v = Math.hypot(b.x - p.x, b.y - p.y);
      const radius = u > .02 && v > .02 ? 0 : Math.min(.0012, u * .2, v * .2);
      before.push({ x: p.x + (a.x - p.x) * radius / Math.max(u, .000001), y: p.y + (a.y - p.y) * radius / Math.max(u, .000001) });
      after.push({ x: p.x + (b.x - p.x) * radius / Math.max(v, .000001), y: p.y + (b.y - p.y) * radius / Math.max(v, .000001) });
    }
    commands.push('M' + coordinate((inset + before[0].x * factor) * width) + ',' + coordinate((inset + before[0].y * factor) * height));
    for (let i = 0; i < loop.length; i++) {
      const p = loop[i], q = after[i], next = before[(i + 1) % loop.length];
      if (q.x !== p.x || q.y !== p.y) commands.push('Q' + coordinate((inset + p.x * factor) * width) + ',' + coordinate((inset + p.y * factor) * height) + ' ' + coordinate((inset + q.x * factor) * width) + ',' + coordinate((inset + q.y * factor) * height));
      commands.push('L' + coordinate((inset + next.x * factor) * width) + ',' + coordinate((inset + next.y * factor) * height));
    }
    commands.push('Z');
  }
  return commands.join(' ');
}
