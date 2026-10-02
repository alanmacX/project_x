import { registerRenderContour, cardOutline } from './RenderContours';
import { FridgeCard, CapBlock, ElementBox, CanvasElement } from './CardSchema';

/** Contours are immutable after extraction. Keep them shared while editable values are snapshots. */
export function cardViewSnapshot(source: FridgeCard): FridgeCard {
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
  copy.capability = source.capability === null ? null : JSON.parse(JSON.stringify(source.capability)) as CapBlock;
  copy.capBox = JSON.parse(JSON.stringify(source.capBox)) as ElementBox;
  copy.elements = source.elements.map((element: CanvasElement) => JSON.parse(JSON.stringify(element)) as CanvasElement);
  return copy;
}

const renderSnapshots = new Map<string, FridgeCard>();
const renderSignatures = new Map<string, string>();

/** A lightweight render parameter. Storage and undo snapshots retain their original contours. */
export function cardRenderSnapshot(source: FridgeCard): FridgeCard {
  const copy = cardViewSnapshot(source);
  copy.renderContourKey = registerRenderContour(source);
  copy.outline = [];
  // Compare only lightweight values. Reopening an unchanged card must not rebuild every capability.
  const signature = JSON.stringify(copy);
  const previous = renderSnapshots.get(source.id);
  if (previous !== undefined && renderSignatures.get(source.id) === signature) return previous;
  renderSignatures.set(source.id, signature); renderSnapshots.set(source.id, copy);
  return copy;
}
