import { FridgeCard, BOARD_W, BOARD_H } from './CardSchema';
import { clampCardGeometry } from './CanvasLayout';
import { releaseTemplateFill } from './TemplateFillPolicy';

/** Keep authored placement when a template temporarily fills its canvas. */
export function toggleTemplateCanvasFill(card:FridgeCard,aspect:number):boolean {
  const t=card.template;if(!t)return false;
  if(!t.fill){
    t.freePlacement={x:card.x,y:card.y,w:card.w,h:card.h,rot:card.rot};t.fill=true;
  }else{
    releaseTemplateFill(card,aspect);
  }
  clampCardGeometry(card,BOARD_W,BOARD_H,BOARD_W/aspect);return true;
}
