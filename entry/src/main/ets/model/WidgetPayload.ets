import { activeAlbum } from './AlbumRotation';
import { compactContours } from './ContourGeometry';
import { fileIo } from '@kit.CoreFileKit';
import { FridgeState, ShapePoint, normalizeState } from './CardSchema';
import { widgetImageKey } from './WidgetImageKey';
export interface WidgetPayload {
  background: string; cards: string;
  images: Record<string, Object>; descriptors: number[];
}
/** Parse/normalize/serialize large masks and prepare file descriptors away from the UI thread. */
@Concurrent
export async function prepareWidgetPayload(json: string, contourCache: string = ''): Promise<WidgetPayload> {
  const state: FridgeState = normalizeState(JSON.parse(json) as FridgeState), payload: WidgetPayload = { background: '{}', cards: '[]', images: {}, descriptors: [] };
  let cache: Record<string, Object> = {};
  try {const parsed=JSON.parse(contourCache) as Record<string,Object>;if(parsed.version===1 && parsed.entries)cache=parsed.entries as Record<string,Object>;}catch(_){}
  try {
    for (const card of state.cards) {
      const key=card.cutout?card.cutout+':'+card.subjectVersion:card.id;
      const entry=cache[key] as Record<string,Object>;
      const cached=entry?.outline as ShapePoint[][];
      // The exact immutable master must match; a disposable cache never changes shape.
      const valid=entry?.source===JSON.stringify(card.outline) && Array.isArray(cached) && cached.length===card.outline.length && cached.every(loop=>Array.isArray(loop)&&loop.length>=3&&loop.every(p=>p!==null&&Number.isFinite(p.x)&&Number.isFinite(p.y)&&p.x>=0&&p.x<=1&&p.y>=0&&p.y<=1));
      card.outline = valid ? cached : compactContours(card.outline);
      const cap=card.capability;
      if(cap?.k==='album') {
        const album=activeAlbum(cap);cap.albumCover=album.cover;cap.albumBackground=album.background;cap.title=album.title;cap.artist=album.artist;cap.albumId=album.id;cap.albumItems=[];cap.albumRotationMinutes=0;
        for(const field of ['albumCover','albumBackground']) {
          const src=field==='albumCover'?cap.albumCover??'':cap.albumBackground??'';
          if(!src.startsWith('file://'))continue;
          const key=widgetImageKey(card.id+'_'+field,src);let mapped='';
          try {const file=await fileIo.open(src.slice(7),fileIo.OpenMode.READ_ONLY);payload.descriptors.push(file.fd);payload.images[key]=file.fd;mapped='memory://'+key;}catch(_){}
          if(field==='albumCover')cap.albumCover=mapped;else cap.albumBackground=mapped;
        }
      }
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
    payload.cards = JSON.stringify(state.cards);
    return payload;
  } catch (e) {
    for (const fd of payload.descriptors) { try { fileIo.closeSync(fd); } catch (_) {} }
    throw e as Error;
  }
}
