import { FridgeState, FridgeCard, ShapePoint } from './CardSchema';
import { cardStorageShell } from './CardViewSnapshot';

// Extracted contours are immutable. Reuse their serialized representation for geometry edits.
const contours = new WeakMap<ShapePoint[][], string>();
export function storageSnapshot(state: FridgeState): string {
  const cards = state.cards.map((source: FridgeCard): string => {
    const card = cardStorageShell(source), outline = card.outline;
    let encoded = contours.get(outline);
    if (encoded === undefined) { encoded = JSON.stringify(outline); contours.set(outline, encoded); }
    card.outline = [];
    return JSON.stringify(card).replace('"outline":[]', '"outline":' + encoded);
  });
  const base = new FridgeState();
  base.canvasId = state.canvasId; base.schemaVersion = state.schemaVersion; base.canvasAspect = state.canvasAspect;
  base.canvasDimension = state.canvasDimension; base.fridge = state.fridge;
  base.sceneLayouts=state.sceneLayouts;base.sceneRules=state.sceneRules;
  base.sceneBaseLayoutId=state.sceneBaseLayoutId;
  base.background = state.background; base.door = state.door; base.maxZ = state.maxZ;
  const json = JSON.stringify(base), marker = '"cards":[]', at = json.lastIndexOf(marker);
  return json.slice(0, at) + '"cards":[' + cards.join(',') + ']' + json.slice(at + marker.length);
}
