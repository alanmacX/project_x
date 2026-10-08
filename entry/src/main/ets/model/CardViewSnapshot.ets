import { registerRenderContour, cardOutline } from './ContourRegistry';
import { FridgeCard, CapBlock, ElementBox, CanvasElement } from './CardSchema';

/** Contours are immutable after extraction. Keep them shared while editable values are snapshots. */
export function cardViewSnapshot(source: FridgeCard): FridgeCard { return snapshotCard(source,true); }
/** Synchronously serialize this shell; its nested references must never escape into UI or undo. */
export function cardStorageShell(source: FridgeCard): FridgeCard { return snapshotCard(source,false); }
function snapshotCard(source: FridgeCard, detached: boolean): FridgeCard {
  const copy = new FridgeCard();
  copy.id = source.id; copy.groupId = source.groupId;
  copy.x = source.x;
  copy.y = source.y;
  copy.w = source.w;
  copy.h = source.h;
  copy.rot = source.rot;
  copy.z = source.z;
  copy.shape = source.shape;
  copy.frame = source.frame;
  copy.material = source.material;
  copy.paper = source.paper;
  copy.ink = source.ink;
  copy.subjectPhoto = source.subjectPhoto;
  copy.subjectBorder = true;
  copy.subjectAspect = source.subjectAspect;
  copy.subjectInk = source.subjectInk;
  copy.subjectVersion = source.subjectVersion;
  copy.cutout = source.cutout;
  copy.inDoor = source.inDoor;
  copy.outline = cardOutline(source);
  copy.renderContourKey = ''; 
  copy.capability = !detached || source.capability === null ? source.capability : JSON.parse(JSON.stringify(source.capability)) as CapBlock;
  copy.capBox = detached ? JSON.parse(JSON.stringify(source.capBox)) as ElementBox : source.capBox;
  copy.capFree = source.capFree;
  copy.elements = detached ? source.elements.map((element: CanvasElement) => JSON.parse(JSON.stringify(element)) as CanvasElement) : source.elements;
  return copy;
}

const renderSnapshots = new Map<string, FridgeCard>();
const renderSignatures = new Map<string, string>();

/** A lightweight render parameter. Storage and undo snapshots retain their original contours. */
export function cardRenderSnapshot(source: FridgeCard, prepared: boolean = false): FridgeCard {
  const contourKey = registerRenderContour(source, prepared);
  // Compare mutable values before cloning. Reopening/committing one card should
  // not deep-copy every unchanged capability, course list and background layer.
  const signature = JSON.stringify([source.id, source.groupId, source.x, source.y, source.w, source.h, source.rot, source.z,
    source.shape, source.frame, source.material, source.paper, source.ink, source.subjectPhoto, source.subjectAspect,
    source.subjectInk, source.subjectVersion, source.cutout, source.inDoor, contourKey, source.capability, source.capBox, source.capFree, source.elements]);
  const previous = renderSnapshots.get(source.id);
  if (previous !== undefined && renderSignatures.get(source.id) === signature) return previous;
  const copy = cardViewSnapshot(source); copy.renderContourKey = contourKey; copy.outline = [];
  if (!renderSnapshots.has(source.id) && renderSnapshots.size >= 128) {
    const oldest = renderSnapshots.keys().next().value as string;
    renderSnapshots.delete(oldest); renderSignatures.delete(oldest);
  }
  renderSignatures.set(source.id, signature); renderSnapshots.set(source.id, copy);
  return copy;
}
