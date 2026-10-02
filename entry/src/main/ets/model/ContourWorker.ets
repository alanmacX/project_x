import { compactContours } from './ContourGeometry';
import { FridgeState } from './CardSchema';
/** The UI receives only derived contours; master geometry remains untouched. */
@Concurrent
export function prepareContours(json: string): string {
  const state = JSON.parse(json) as FridgeState, outlines: Record<string, Object> = {};
  for (const card of state.cards) if (card.outline.length > 0) outlines[card.id] = compactContours(card.outline);
  return JSON.stringify(outlines);
}
