import { FridgeCard, ShapePoint, BOARD_W } from './CardSchema';
import { sceneRect } from './SceneLayout';
import { cardContainsPoint } from './CardHitTest';
import { capabilityPlacement } from './CanvasLayout';

export class WidgetHit {
  id: string = '';
  operation: string = '';
}
/** Same bottom-left pivot and independent canvas axes as the FormKit scene. */
export function widgetCardPoint(card: FridgeCard, x: number, y: number, width: number, height: number): ShapePoint {
  const r = sceneRect(card, width, height), angle = card.rot * Math.PI / 180;
  const dx = x - r.x, dy = y - r.y - r.h;
  return { x: dx * Math.cos(angle) + dy * Math.sin(angle), y: -dx * Math.sin(angle) + dy * Math.cos(angle) + r.h };
}
export function widgetCanvasPoint(card: FridgeCard, x: number, y: number, width: number, height: number): ShapePoint {
  const r = sceneRect(card, width, height), angle = card.rot * Math.PI / 180;
  return { x: r.x + x * Math.cos(angle) - (y - r.h) * Math.sin(angle), y: r.y + r.h + x * Math.sin(angle) + (y - r.h) * Math.cos(angle) };
}
export function widgetHit(cards: FridgeCard[], x: number, y: number, width: number, height: number): WidgetHit {
  const hit = new WidgetHit();
  if (width <= 0 || height <= 0 || x < 0 || y < 0 || x > width || y > height) return hit;
  const radius = Math.min(24, width / 2, height / 2);
  const cx = Math.max(radius, Math.min(width - radius, x)), cy = Math.max(radius, Math.min(height - radius, y));
  if ((x - cx) ** 2 + (y - cy) ** 2 > radius ** 2) return hit;
  const scale = width / BOARD_W;
  // An opaque decorative card occludes lower capabilities, but its transparent holes do not.
  for (let i = cards.length - 1; i >= 0; i--) {
    const card = cards[i], p = widgetCardPoint(card, x, y, width, height);
    if (!cardContainsPoint(card, p.x, p.y, scale)) continue;
    if (card.capability === null) return hit;
    hit.id = card.id;
    const box = capabilityPlacement(card), rect = sceneRect(card, width, height);
    const left = box.x * rect.w, top = box.y * rect.h, right = (box.x + box.w) * rect.w, size = 24 * scale;
    if (p.y >= top && p.y <= top + size) {
      if (card.capability.k === 'calendar') {
        if (p.x >= left && p.x <= left + size) hit.operation = 'previousMonth';
        else if (p.x >= right - size && p.x <= right) hit.operation = 'nextMonth';
      } else if (card.capability.k === 'weather' && (card.capability.city ?? '').length > 0 && p.x >= right - size && p.x <= right) {
        hit.operation = card.capability.refreshState === 'refreshing' ? 'disabled' : 'refreshWeather';
      }
    }
    return hit;
  }
  return hit;
}
