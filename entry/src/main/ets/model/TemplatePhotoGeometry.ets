import { CanvasElement, ElementBox } from './CardSchema';
import { CardTemplate } from './CardTemplate';
/** One camera for the original image and the extracted foreground; no independently floating duplicate. */
export function templatePhotoBox(photo:CanvasElement,config:CardTemplate,width:number,height:number,cover:boolean,subject:boolean=false):ElementBox{
 const box=new ElementBox(),aspect=Math.max(.01,(photo.depthSourceAspect||1)*(subject?photo.depthCrop.w/Math.max(.001,photo.depthCrop.h):1)),scale=cover?Math.max(width/aspect,height):Math.min(width/aspect,height);
 box.w=scale*aspect*config.zoom;box.h=scale*config.zoom;box.x=(width-box.w)/2+config.offsetX*width;box.y=(height-box.h)/2+config.offsetY*height;return box;
}
export function templateSubjectBox(photo:CanvasElement,frame:ElementBox):ElementBox{
 const box=new ElementBox(),crop=photo.depthCrop;box.x=frame.x+crop.x*frame.w;box.y=frame.y+crop.y*frame.h;box.w=crop.w*frame.w;box.h=crop.h*frame.h;return box;
}
