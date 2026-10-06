import { warmStartupLayouts } from './CanvasLayout';
import { FridgeState, defaultState, normalizeState, BOARD_W } from './CardSchema';
import { cleanGroups, clampCanvasGroups } from './CardGroups';
export interface CanvasLoadResult {state:FridgeState;layout:string;}
/** Parse, validate and migrate persisted contours away from the launch UI thread. */
@Concurrent
export function hydrateCanvas(json:string,id:string):string {
  const raw=json?JSON.parse(json) as FridgeState:defaultState();
  if(!Array.isArray(raw.cards))throw new Error('Invalid cards');
  const state=normalizeState(raw);state.canvasId=id;
  cleanGroups(state.cards);const layout=warmStartupLayouts(state.cards);clampCanvasGroups(state.cards,BOARD_W/state.canvasAspect);
  const result:CanvasLoadResult={state:state,layout:layout};return JSON.stringify(result);
}
