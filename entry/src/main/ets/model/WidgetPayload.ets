import { compactContours } from './ContourGeometry';
import { fileIo } from '@kit.CoreFileKit';
import { FridgeState, normalizeState, serializeFaceCards, serializeDoorCards } from './CardSchema';
import { widgetImageKey } from './WidgetImageKey';
export interface WidgetPayload {
  background: string; cards: string; faceCards: string; doorCards: string;
  reveal: string; open: boolean;
  images: Record<string, Object>; descriptors: number[];
}
/** Parse/normalize/serialize large masks and prepare file descriptors away from the UI thread. */
@Concurrent
export async function prepareWidgetPayload(json: string): Promise<WidgetPayload> {
  const state: FridgeState = normalizeState(JSON.parse(json) as FridgeState), payload: WidgetPayload = { background: '{}', cards: '[]', faceCards: '[]', doorCards: '[]', reveal: '', open: false, images: {}, descriptors: [] };
  try {
    for (const card of state.cards) {
      card.outline = compactContours(card.outline);
      if (card.cutout.startsWith('file://')) {
        const key = widgetImageKey(card.id + '_subject', card.cutout);
        try {
          const file = await fileIo.open(card.cutout.slice(7), fileIo.OpenMode.READ_ONLY);
          payload.descriptors.push(file.fd); payload.images[key] = file.fd; card.cutout = 'memory://' + key;
        } catch (_) { card.cutout = ''; card.shape = 'rect'; }
      }
      for (const element of card.elements) {
        if (element.kind === 'image' && element.src.startsWith('file://')) {
          const key = widgetImageKey(card.id + '_' + element.id, element.src);
          try {
            const file = await fileIo.open(element.src.slice(7), fileIo.OpenMode.READ_ONLY);
            payload.descriptors.push(file.fd); payload.images[key] = file.fd; element.src = 'memory://' + key;
          } catch (_) { element.src = ''; }
        }
      }
    }
    if (state.background.src.startsWith('file://')) {
      const key = widgetImageKey('canvas_background', state.background.src);
      try { const file = await fileIo.open(state.background.src.slice(7), fileIo.OpenMode.READ_ONLY);
        payload.descriptors.push(file.fd); payload.images[key] = file.fd; state.background.src = 'memory://' + key;
      } catch (_) { state.background.src = ''; }
    }
    payload.background = JSON.stringify(state.background);
    payload.cards = JSON.stringify(state.cards); payload.faceCards = serializeFaceCards(state);
    payload.doorCards = serializeDoorCards(state); payload.reveal = state.door.reveal; payload.open = state.door.open;
    return payload;
  } catch (e) {
    for (const fd of payload.descriptors) { try { fileIo.closeSync(fd); } catch (_) {} }
    throw e as Error;
  }
}
