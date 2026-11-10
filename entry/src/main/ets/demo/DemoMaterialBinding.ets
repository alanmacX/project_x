import { DemoAsset } from './DemoAssets';
import { FridgeCard, CanvasElement, ElementBox, AlbumCover } from '../model/CardSchema';
import { cardCapabilities, replaceCardCapability } from '../model/TemplateSources';
import { albumLibrary, selectAlbum } from '../model/AlbumRotation';

export function filterDemoAssets(items:DemoAsset[],filter:string):DemoAsset[]{
  return items.filter(a=>filter==='全部'||filter==='照片'&&(a.category!=='专辑'||a.photoSource===true)||filter==='抠图'&&!!a.subject||filter==='专辑'&&a.category==='专辑');
}
export function bindDemoPhoto(card:FridgeCard,item:DemoAsset,subject:boolean):void{
  const element=card.elements.find(e=>e.kind==='image')??new CanvasElement();
  if(!element.id){element.id='material_element_'+Date.now();card.elements.push(element);}
  const paired=!!card.template;
  element.kind='image';element.src=!paired&&subject&&item.subject?item.subject:item.original;
  element.x=0;element.y=0;element.w=1;element.h=1;
  element.depthSourceAspect=!paired&&subject?item.aspect*item.crop.w/item.crop.h:item.aspect;
  element.depthEnabled=paired&&!!item.subject;element.depthForeground=paired?item.subject:'';
  element.depthCrop=JSON.parse(JSON.stringify(item.crop)) as ElementBox;
  if(card.template){card.template.photoMode=card.template.photoMode==='subject'&&item.subject?'subject':'photo';card.template.photoFraming=card.template.photoMode==='photo'?'cover':'fit';card.template.zoom=1;card.template.offsetX=0;card.template.offsetY=0;card.template.depth=!!item.subject;}
}
export function demoAlbumCover(item:DemoAsset):AlbumCover{
  return {id:item.id,cover:item.albumCover||item.original,background:item.albumBackground||'',title:item.albumTitle||'',artist:item.albumArtist||''};
}
export function bindDemoAlbum(card:FridgeCard,index:number,item:DemoAsset):boolean{
  const old=cardCapabilities(card)[index];if(old?.k!=='album')return false;
  const album=demoAlbumCover(item),items=albumLibrary(old),found=items.findIndex(a=>a.id===album.id||a.cover===album.cover);
  if(found<0&&items.length>=12)return false;
  if(found>=0){album.id=items[found].id;album.title=items[found].title;album.artist=items[found].artist;items[found]=album;}else items.push(album);
  const next=selectAlbum(old,album);next.albumItems=items;next.albumSource='local';
  return replaceCardCapability(card,old,next);
}
