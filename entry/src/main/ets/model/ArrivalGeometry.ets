import { FridgeCard, ShapePoint } from './CardSchema';
import { sceneRect } from './SceneLayout';

/** Return along the nearest canvas edge, without crossing unrelated cards' paths. */
export function arrivalOffset(card: FridgeCard, width: number, height: number): ShapePoint {
  const r = sceneRect(card, width, height), a = card.rot * Math.PI / 180;
  const c = Math.cos(a), s = Math.sin(a);
  const xs = [r.x, r.x + r.h * s, r.x + r.w * c + r.h * s, r.x + r.w * c];
  const ys = [r.y + r.h, r.y + r.h - r.h * c, r.y + r.h + r.w * s - r.h * c, r.y + r.h + r.w * s];
  const left = Math.min(...xs), right = Math.max(...xs), top = Math.min(...ys), bottom = Math.max(...ys);
  const cx = Math.max(0, Math.min(1, (left + right) / (2 * width)));
  const cy = Math.max(0, Math.min(1, (top + bottom) / (2 * height)));
  if (Math.min(cx, 1 - cx) < Math.min(cy, 1 - cy)) return { x: cx < .5 ? -right - 24 : width - left + 24, y: 0 };
  return { x: 0, y: cy < .5 ? -bottom - 24 : height - top + 24 };
}
