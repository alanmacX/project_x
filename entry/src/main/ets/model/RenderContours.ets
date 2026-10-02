import { taskpool } from '@kit.ArkTS';
import { prepareContours } from './ContourWorker';
import { compactContours } from './ContourGeometry';
import { FridgeCard, ShapePoint } from './CardSchema';

// Contours belong to immutable image assets, not to the reactive component tree.
// Keeping one entry per card avoids @Prop cloning thousands of points at every transition.
const contours = new Map<string, ShapePoint[][]>();
const compacted = new WeakMap<ShapePoint[][], ShapePoint[][]>();
export function registerRenderContour(card: FridgeCard): string {
  if (card.outline.length === 0) return card.renderContourKey;
  const key = card.id + ':' + card.cutout + ':' + card.subjectVersion;
  let outline = compacted.get(card.outline);
  if (outline === undefined) { outline = compactContours(card.outline); compacted.set(card.outline, outline); }
  contours.set(key, outline);
  return key;
}
export function cardOutline(card: FridgeCard): ShapePoint[][] {
  return card.outline.length > 0 ? card.outline : (contours.get(card.renderContourKey) ?? []);
}
export function releaseRenderContours(): void { contours.clear(); }

/** Prime before revealing the board, so topology checks never run in its first animation frame. */
export async function primeRenderContours(cards: FridgeCard[], snapshot: string): Promise<void> {
  if (!cards.some((card: FridgeCard) => card.outline.length > 0 && !compacted.has(card.outline))) return;
  const json = await taskpool.execute(new taskpool.Task(prepareContours, snapshot)) as string;
  const prepared = JSON.parse(json) as Record<string, ShapePoint[][]>;
  for (const card of cards) if (prepared[card.id] !== undefined) compacted.set(card.outline, prepared[card.id]);
}
