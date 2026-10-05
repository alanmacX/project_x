import { FridgeCard, BOARD_W, BOARD_H } from './CardSchema';

export class DragBounds {
  minX: number = 0; maxX: number = 0; minY: number = 0; maxY: number = 0;
}
/** Shape/angle do not change during a pan. Compute recoverable bounds once. */
export function dragBounds(card: FridgeCard, renderedHeight: number = BOARD_H): DragBounds {
  const a = card.rot * Math.PI / 180, c = Math.cos(a), s = Math.sin(a);
  const xs = [0, card.h * s, card.w * c + card.h * s, card.w * c];
  const ys = [0, -card.h * c, card.w * s - card.h * c, card.w * s];
  const result = new DragBounds(), vx = Math.min(32, card.w * .2), vy = Math.min(32, card.h * .2);
  result.minX = vx - Math.max(...xs); result.maxX = BOARD_W - vx - Math.min(...xs);
  // Card sizes use width units; stored y uses BOARD_H units. Host aspect may differ.
  result.minY = (vy - card.h - Math.max(...ys)) * BOARD_H / renderedHeight;
  result.maxY = (renderedHeight - vy - card.h - Math.min(...ys)) * BOARD_H / renderedHeight;
  return result;
}
