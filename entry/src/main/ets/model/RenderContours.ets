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

class CachedContour { source: string = ''; outline: ShapePoint[][] = []; }
class ContourCache { version: number = 1; entries: Record<string, CachedContour> = {}; }
const encodedSources = new WeakMap<ShapePoint[][], string>();
function contourSource(outline: ShapePoint[][]): string {
  let source=encodedSources.get(outline);
  if(source===undefined){source=JSON.stringify(outline);encodedSources.set(outline,source);}return source;
}
function assetKey(card: FridgeCard): string { return card.cutout ? card.cutout+':'+card.subjectVersion : card.id; }
/** Derived geometry is disposable. Exact source matching prevents stale shapes after edits/imports. */
export function restoreContourCache(cards: FridgeCard[], json: string): number {
  if(!json || json.length>8*1024*1024)return 0;
  let cache: ContourCache;
  try { cache=JSON.parse(json) as ContourCache; } catch (_) { return 0; }
  if(cache?.version!==1 || !cache.entries)return 0;
  let restored=0;
  for(const card of cards) {
    if(!card.outline.length)continue;
    const entry=cache.entries[assetKey(card)];
    if(!entry || entry.source!==contourSource(card.outline) || !Array.isArray(entry.outline) || entry.outline.length!==card.outline.length)continue;
    let count=0;
    const valid=entry.outline.every((loop:ShapePoint[])=>Array.isArray(loop)&&loop.length>=3&&loop.every((p:ShapePoint)=>{
      count++;return count<=65536 && p!==null && p!==undefined && Number.isFinite(p.x)&&Number.isFinite(p.y)&&p.x>=0&&p.x<=1&&p.y>=0&&p.y<=1;
    }));
    if(valid){compacted.set(card.outline,entry.outline);restored++;}
  }
  return restored;
}
export function serializeContourCache(cards: FridgeCard[]): string {
  const cache=new ContourCache();
  for(const card of cards) {
    const outline=compacted.get(card.outline);if(outline===undefined || !card.outline.length)continue;
    const entry=new CachedContour();entry.source=contourSource(card.outline);entry.outline=outline;cache.entries[assetKey(card)]=entry;
  }
  if(Object.keys(cache.entries).length===0)return '';
  const json=JSON.stringify(cache);return json.length<=8*1024*1024?json:'';
}
