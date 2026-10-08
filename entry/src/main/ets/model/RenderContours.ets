import { taskpool } from '@kit.ArkTS';
import { prepareContours } from './ContourWorker';
import { FridgeCard, ShapePoint } from './CardSchema';
import { hasPreparedContour, storePreparedContour } from './ContourRegistry';
export { registerRenderContour, cardOutline, releaseRenderContours, restoreContourCache, serializeContourCache } from './ContourRegistry';

/** Prime before revealing the board, so topology checks never run in its first animation frame. */
export async function primeRenderContours(cards: FridgeCard[], snapshot: string): Promise<void> {
  if (!cards.some((card: FridgeCard) => card.outline.length > 0 && !hasPreparedContour(card.outline))) return;
  const json = await taskpool.execute(new taskpool.Task(prepareContours, snapshot)) as string;
  const prepared = JSON.parse(json) as Record<string, ShapePoint[][]>;
  for (const card of cards) if (prepared[card.id] !== undefined) storePreparedContour(card.outline, prepared[card.id]);
}
