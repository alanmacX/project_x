import { activeAlbum } from './AlbumRotation';
import { compactContours } from './ContourGeometry';
import { fileIo } from '@kit.CoreFileKit';
import { FridgeState, ShapePoint, normalizeState } from './CardSchema';
import { widgetImageKey } from './WidgetImageKey';
export interface WidgetPayload {
  background: string; cards: string;
  images: Record<string, Object>; descriptors: number[]; manifest: string;
}
/** Parse/normalize/serialize large masks and prepare file descriptors away from the UI thread. */
@Concurrent
export async function prepareWidgetPayload(json: string, contourCache: string = '', previousManifest: string = '',reliefJson:string='{}'): Promise<WidgetPayload> {
  const frameTime=Date.now();
  const state: FridgeState = normalizeState(JSON.parse(json) as FridgeState), payload: WidgetPayload = { background: '{}', cards: '[]', images: {}, descriptors: [], manifest: '' };
  state.cards=state.cards.filter(card=>!card.hidden);
  const relief=JSON.parse(reliefJson) as Record<string,string>;
  for(const card of state.cards)card.reliefSrc=relief[card.id]??'';
  // Prepare the complete identity set before opening anything. A partial formImages map
  // replaces the system image cache; reuse is therefore all-or-nothing.
  const keys:string[]=[];
  for(const card of state.cards) {
    if(card.reliefSrc.startsWith('file://'))keys.push(widgetImageKey(card.id+'_relief',card.reliefSrc));
    if(card.cutout.startsWith('file://'))keys.push(widgetImageKey(card.id+'_subject',card.cutout));
    for(const element of card.elements)if(element.kind==='image'&&element.src.startsWith('file://'))keys.push(widgetImageKey(card.id+'_'+element.id,element.src));
    for(const element of card.elements)if(element.depthEnabled&&element.depthForeground.startsWith('file://'))keys.push(widgetImageKey(card.id+'_'+element.id+'_depth',element.depthForeground));
    if(card.capability?.k==='album') {
      const album=activeAlbum(card.capability,frameTime);
      if(album.cover.startsWith('file://'))keys.push(widgetImageKey(card.id+'_albumCover',album.cover));
      if(album.background.startsWith('file://'))keys.push(widgetImageKey(card.id+'_albumBackground',album.background));
    }
  }
  if(state.background.src.startsWith('file://'))keys.push(widgetImageKey('canvas_background',state.background.src));
  payload.manifest=JSON.stringify(keys.sort());
  const reuse=previousManifest!==''&&previousManifest===payload.manifest;
  let cache: Record<string, Object> = {};
  try {const parsed=JSON.parse(contourCache) as Record<string,Object>;if(parsed.version===1 && parsed.entries)cache=parsed.entries as Record<string,Object>;}catch(_){}
  try {
    for (const card of state.cards) {
      // Form only needs the appearance image and native data, never the HTML authoring source.
      card.html=undefined;
      const key=card.cutout?card.cutout+':'+card.subjectVersion:card.id;
      const entry=cache[key] as Record<string,Object>;
      const cached=entry?.outline as ShapePoint[][];
      // The exact immutable master must match; a disposable cache never changes shape.
      const valid=entry?.source===JSON.stringify(card.outline) && Array.isArray(cached) && cached.length===card.outline.length && cached.every(loop=>Array.isArray(loop)&&loop.length>=3&&loop.every(p=>p!==null&&Number.isFinite(p.x)&&Number.isFinite(p.y)&&p.x>=0&&p.x<=1&&p.y>=0&&p.y<=1));
      card.outline = valid ? cached : compactContours(card.outline);
      const cap=card.capability;
      if(cap?.k==='album') {
        const album=activeAlbum(cap,frameTime);cap.albumCover=album.cover;cap.albumBackground=album.background;cap.title=album.title;cap.artist=album.artist;cap.albumId=album.id;cap.albumItems=[];cap.albumRotationMinutes=0;
        for(const field of ['albumCover','albumBackground']) {
          const src=field==='albumCover'?cap.albumCover??'':cap.albumBackground??'';
          if(!src.startsWith('file://'))continue;
          const key=widgetImageKey(card.id+'_'+field,src);let mapped='';
          try {if(!reuse){const file=await fileIo.open(src.slice(7),fileIo.OpenMode.READ_ONLY);payload.descriptors.push(file.fd);payload.images[key]=file.fd;}mapped='memory://'+key;}catch(_){payload.manifest='';}
          if(field==='albumCover')cap.albumCover=mapped;else cap.albumBackground=mapped;
        }
      }
      if(card.reliefSrc.startsWith('file://')){
        const key=widgetImageKey(card.id+'_relief',card.reliefSrc);
        try{if(!reuse){const file=await fileIo.open(card.reliefSrc.slice(7),fileIo.OpenMode.READ_ONLY);payload.descriptors.push(file.fd);payload.images[key]=file.fd;}card.reliefSrc='memory://'+key;}catch(_){payload.manifest='';card.reliefSrc='';}
      }
      if (card.cutout.startsWith('file://')) {
        const key = widgetImageKey(card.id + '_subject', card.cutout);
        try {
          if(!reuse){const file = await fileIo.open(card.cutout.slice(7), fileIo.OpenMode.READ_ONLY);
          payload.descriptors.push(file.fd); payload.images[key] = file.fd;} card.cutout = 'memory://' + key;
        } catch (_) { payload.manifest=''; card.cutout = ''; card.shape = 'rect'; }
      }
      for (const element of card.elements) {
        if(element.depthEnabled&&element.depthForeground.startsWith('file://')){
          const key=widgetImageKey(card.id+'_'+element.id+'_depth',element.depthForeground);
          try{if(!reuse){const file=await fileIo.open(element.depthForeground.slice(7),fileIo.OpenMode.READ_ONLY);payload.descriptors.push(file.fd);payload.images[key]=file.fd;}element.depthForeground='memory://'+key;}catch(_){payload.manifest='';element.depthForeground='';element.depthEnabled=false;}
        }else if(!element.depthEnabled)element.depthForeground='';
        if (element.kind === 'image' && element.src.startsWith('file://')) {
          const key = widgetImageKey(card.id + '_' + element.id, element.src);
          try {
            if(!reuse){const file = await fileIo.open(element.src.slice(7), fileIo.OpenMode.READ_ONLY);
            payload.descriptors.push(file.fd); payload.images[key] = file.fd;} element.src = 'memory://' + key;
          } catch (_) { payload.manifest=''; element.src = ''; }
        }
      }
    }
    if (state.background.src.startsWith('file://')) {
      const key = widgetImageKey('canvas_background', state.background.src);
      try { if(!reuse){const file = await fileIo.open(state.background.src.slice(7), fileIo.OpenMode.READ_ONLY);
        payload.descriptors.push(file.fd); payload.images[key] = file.fd;} state.background.src = 'memory://' + key;
      } catch (_) { payload.manifest=''; state.background.src = ''; }
    }
    payload.background = JSON.stringify(state.background);
    payload.cards = JSON.stringify(state.cards);
    return payload;
  } catch (e) {
    for (const fd of payload.descriptors) { try { fileIo.closeSync(fd); } catch (_) {} }
    throw e as Error;
  }
}
