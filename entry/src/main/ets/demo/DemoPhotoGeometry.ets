import { FridgeCard } from '../model/CardSchema';
import { newCardTemplate } from '../model/CardTemplate';
import { photoControlRegion } from '../model/TemplatePhotoComposition';
import { templatePhotoBox } from '../model/TemplatePhotoGeometry';

/** Keep original-photo editing edge-to-edge without disturbing subject-mode framing. */
export function constrainDemoPhoto(card:FridgeCard):void {
  const config=card.template,photo=card.elements.find(e=>e.kind==='image');
  if(!config||!photo||config.photoMode!=='photo')return;
  config.photoFraming='cover';config.zoom=Math.max(1,Math.min(4,config.zoom));
  const region=photoControlRegion(card),origin=newCardTemplate(config.id);origin.zoom=config.zoom;
  const frame=templatePhotoBox(photo,origin,region.w,region.h,true);
  const mx=Math.max(0,(frame.w-region.w)/2/region.w),my=Math.max(0,(frame.h-region.h)/2/region.h);
  config.offsetX=Math.max(-mx,Math.min(mx,config.offsetX));
  config.offsetY=Math.max(-my,Math.min(my,config.offsetY));
}
