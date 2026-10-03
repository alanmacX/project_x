import { FridgeState, defaultState, normalizeState } from './CardSchema';
export class CanvasEntry { id: string = ''; name: string = ''; }
export class CanvasCatalog { version: number = 1; activeId: string = 'canvas_main'; canvases: CanvasEntry[] = [{ id: 'canvas_main', name: '我的画布' }]; }
export class CanvasDocument extends CanvasEntry { state: FridgeState = defaultState(); }
export function canvasKey(id: string): string { return 'fridge_canvas_' + id; }
export function readCatalog(json: string): CanvasCatalog {
  if (!json) return new CanvasCatalog();
  const source = JSON.parse(json) as CanvasCatalog;
  if (source.version !== 1 || !Array.isArray(source.canvases) || source.canvases.length === 0) throw new Error('画布目录无法读取');
  const out = new CanvasCatalog(); out.canvases = [];
  for (const item of source.canvases) {
    if (!item || !/^[a-zA-Z0-9_-]{1,96}$/.test(item.id) || out.canvases.some((c) => c.id === item.id)) throw new Error('画布目录损坏');
    out.canvases.push({ id: item.id, name: typeof item.name === 'string' ? item.name.slice(0,40) : '未命名画布' });
  }
  out.activeId = out.canvases.some((c) => c.id === source.activeId) ? source.activeId : out.canvases[0].id;
  return out;
}
export function boundCanvas(bindings: Record<string,string>, formId: string, catalog: CanvasCatalog): string {
  const id = bindings[formId];
  return catalog.canvases.some((c) => c.id === id) ? id : catalog.activeId;
}
export function cloneCanvas(state: FridgeState, id: string): FridgeState {
  const next = normalizeState(JSON.parse(JSON.stringify(state)) as FridgeState); next.canvasId = id; return next;
}
