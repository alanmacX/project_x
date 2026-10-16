import { FridgeCard } from './CardSchema';

export class CardActionAnchor { x: number = 96; y: number = 120; above: boolean = false; }
/** Axis-aligned popup anchor follows rotated artwork, without rotating the toolbar itself. */
export function cardActionAnchor(card: FridgeCard, scale: number, yScale: number, boardLeft: number, boardTop: number, boardHeight: number,
  viewportWidth: number, viewportHeight: number, safeTop: number, safeBottom: number, fringe: number[] = []): CardActionAnchor {
  const result = new CardActionAnchor(), w = card.w * scale, h = card.h * scale, a = card.rot * Math.PI / 180;
  const left = -(fringe[0] ?? 0), top = -(fringe[1] ?? 0), right = w + (fringe[2] ?? 0), bottom = h + (fringe[3] ?? 0);
  const xs: number[] = [], ys: number[] = [];
  for (const x of [left, right]) for (const y of [top, bottom]) {
    xs.push(boardLeft + card.x * scale + x * Math.cos(a) - (y - h) * Math.sin(a));
    ys.push(boardTop + card.y * yScale + h + x * Math.sin(a) + (y - h) * Math.cos(a));
  }
  const minY = Math.min(...ys), maxY = Math.max(...ys), topLimit = Math.max(safeTop + 68, boardTop + 8), bottomLimit = Math.min(viewportHeight - safeBottom - 76, boardTop + boardHeight - 8);
  result.x = Math.max(96, Math.min(viewportWidth - 96, (Math.min(...xs) + Math.max(...xs)) / 2));
  result.above = maxY + 82 > bottomLimit && minY - 82 >= topLimit;
  result.y = result.above ? Math.max(topLimit + 60, minY - 22) : Math.max(topLimit, Math.min(bottomLimit - 60, maxY + 22));
  return result;
}
