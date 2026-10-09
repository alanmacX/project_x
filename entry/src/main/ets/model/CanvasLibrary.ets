import { CanvasRotation, normalizeCanvasRotation } from './CanvasRotation';
import { SceneRule, normalizeSceneRules } from './SceneScheduleSchema';
import { FridgeState, defaultState, normalizeState } from './CardSchema';
export class CanvasEntry { id: string = ''; name: string = ''; }
export class CanvasCatalog { desktopFollowsSelection:boolean=false; scenes:CanvasEntry[]=[]; sceneRules:SceneRule[]=[]; rotation:CanvasRotation=new CanvasRotation(); scenePolicyVersion:number=2; version: number = 1; activeId: string = 'canvas_main'; canvases: CanvasEntry[] = [{ id: 'canvas_main', name: '我的画布' }]; }
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
  out.scenes=(Array.isArray(source.scenes)?source.scenes:[]).filter(c=>c&&/^[a-zA-Z0-9_-]{1,96}$/.test(c.id)&&!out.canvases.some(n=>n.id===c.id)).slice(0,12).filter((c,i,a)=>a.findIndex(n=>n.id===c.id)===i).map((c):CanvasEntry=>({id:c.id,name:typeof c.name==='string'?c.name.slice(0,40):'定时场景'}));
  out.sceneRules=normalizeSceneRules(source.sceneRules).filter(r=>r.centralOnly&&out.scenes.some(c=>c.id===r.targetId));
  out.rotation=normalizeCanvasRotation(source.rotation,out.canvases.map(c=>c.id));
  out.scenePolicyVersion=source.scenePolicyVersion===2?2:1;out.desktopFollowsSelection=source.desktopFollowsSelection===true;
  out.activeId = out.canvases.some((c) => c.id === source.activeId) ? source.activeId : out.canvases[0].id;
  return out;
}
export function boundCanvas(bindings: Record<string,string>, formId: string, catalog: CanvasCatalog): string {
  if(catalog.desktopFollowsSelection)return catalog.activeId;
  const id = bindings[formId];
  return catalog.canvases.some((c) => c.id === id) ? id : catalog.activeId;
}
export function cloneCanvas(state: FridgeState, id: string): FridgeState {
  const next = normalizeState(JSON.parse(JSON.stringify(state)) as FridgeState); next.canvasId = id; return next;
}

/** Runtime policy is catalog-owned; never serialize temporary projections into a canvas. */
export function withScenePolicy(base:FridgeState,catalog:CanvasCatalog,dark:boolean=false):FridgeState {
  const next=scenePolicyShell(base);if(catalog.scenePolicyVersion!==2)return next;next.sceneRules=catalog.sceneRules;next.canvasRotation=catalog.rotation;next.scenePolicyV2=true;next.systemDark=dark;return next;
}
export function sceneDocumentExists(catalog:CanvasCatalog,id:string):boolean {return catalog.canvases.concat(catalog.scenes).some(c=>c.id===id);}

export function scenePolicyShell(base:FridgeState):FridgeState {
  const next=new FridgeState();next.canvasId=base.canvasId;next.schemaVersion=base.schemaVersion;next.background=base.background;next.canvasAspect=base.canvasAspect;next.canvasDimension=base.canvasDimension;next.fridge=base.fridge;next.door=base.door;next.maxZ=base.maxZ;next.cards=base.cards;next.sceneRules=base.sceneRules;next.sceneLayouts=base.sceneLayouts;next.sceneBaseLayoutId=base.sceneBaseLayoutId;return next;
}
