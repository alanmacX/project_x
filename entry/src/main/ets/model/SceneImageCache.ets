import { image } from '@kit.ImageKit';
import { FridgeState } from './CardSchema';
import { activeAlbum } from './AlbumRotation';

interface DecodedSceneImage { pixel:image.PixelMap; bytes:number; }
const decoded:Map<string,DecodedSceneImage>=new Map();
const pending:Map<string,Promise<void>>=new Map();
const IDLE_CACHE_BYTES:number=48*1024*1024;
const MAX_CACHED_SOURCES:number=32;

/** File assets are immutable/versioned. Forms and cache misses retain their normal source. */
export function sceneImage(src:string):string|image.PixelMap {
  const entry=decoded.get(src);
  if(!entry)return src;
  decoded.delete(src);decoded.set(src,entry);return entry.pixel;
}
export function sceneImageSources(state:FridgeState):string[] {
  const sources:Set<string>=new Set();
  const add=(src:string):void=>{if(src.startsWith('file://'))sources.add(src);};
  if(!['transparent','solid','smart'].includes(state.background.mode))add(state.background.src);
  for(const card of state.cards){
    if(card.hidden)continue;
    if(card.shape==='subject'&&card.subjectPhoto)add(card.cutout);
    add(card.reliefSrc);
    for(const element of card.elements){if(element.kind==='image'&&!element.animated)add(element.src);if(element.depthEnabled)add(element.depthForeground);}
    if(card.capability?.k==='album'){const album=activeAlbum(card.capability);add(album.cover);add(album.background);}
  }
  return Array.from(sources);
}
async function decode(src:string):Promise<void> {
  if(decoded.has(src))return;
  const existing=pending.get(src);if(existing){await existing;return;}
  const work=(async():Promise<void>=>{
    let source:image.ImageSource|null=null,pixel:image.PixelMap|null=null;
    try{
      source=image.createImageSource(src.slice(7));
      // Async native decoding keeps full source resolution and alpha, off the UI layout path.
      pixel=await source.createPixelMap();
      const info=await pixel.getImageInfo();
      decoded.set(src,{pixel:pixel,bytes:pixel.getBytesNumberPerRow()*info.size.height});pixel=null;
    }catch(_){/* A missing/corrupt asset uses the existing Image error/fallback path. */}
    finally{try{if(pixel)await pixel.release().catch(()=>{});}finally{if(source)await source.release().catch(()=>{});}}
  })();
  pending.set(src,work);try{await work;}finally{pending.delete(src);}
}
/** Two decoders bound transient allocations; repeated entrances share in-flight/native pixels. */
export async function prepareSceneImages(state:FridgeState):Promise<void> {
  const sources=sceneImageSources(state);let index=0;
  const worker=async():Promise<void>=>{while(index<sources.length){const src=sources[index++];await decode(src);}};
  await Promise.all([worker(),worker()]);
}
/** Call after the replacement scene's frame. Never release a visible or in-flight image. */
export function trimSceneImages(state:FridgeState):void {
  const retained=new Set(sceneImageSources(state));let bytes=0;decoded.forEach(entry=>bytes+=entry.bytes);
  for(const pair of decoded){
    const src=pair[0],entry=pair[1];
    if(bytes<=IDLE_CACHE_BYTES&&decoded.size<=MAX_CACHED_SOURCES)break;
    if(retained.has(src)||pending.has(src))continue;
    decoded.delete(src);bytes-=entry.bytes;entry.pixel.release().catch(()=>{});
  }
}
