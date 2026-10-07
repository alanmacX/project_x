import { ShapePoint, BOARD_W, BOARD_H } from './CardSchema';
import { DragBounds } from './DragGeometry';
export interface AlignmentResult {x:number;y:number;vertical:boolean;horizontal:boolean;}
/** Stored y is normalized; centres and tolerance use actual rendered canvas units. */
export function alignToCanvas(x:number,y:number,origin:ShapePoint,anchor:ShapePoint,height:number,scale:number,bounds:DragBounds):AlignmentResult {
  const centreX=anchor.x+x-origin.x,centreY=anchor.y+(y-origin.y)*height/BOARD_H;
  const shiftX=BOARD_W/2-centreX,shiftY=height/2-centreY;
  const targetX=x+shiftX,targetY=y+shiftY*BOARD_H/height;
  const vertical=Math.abs(shiftX)*scale<=4&&targetX>=bounds.minX&&targetX<=bounds.maxX;
  const horizontal=Math.abs(shiftY)*scale<=4&&targetY>=bounds.minY&&targetY<=bounds.maxY;
  return {x:vertical?targetX:x,y:horizontal?targetY:y,vertical:vertical,horizontal:horizontal};
}
