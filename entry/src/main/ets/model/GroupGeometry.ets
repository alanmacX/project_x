import { BOARD_H, FridgeCard, ShapePoint } from './CardSchema';
import { minimumCardSize } from './CanvasLayout';
export class GroupBox { x:number=0; y:number=0; w:number=0; h:number=0; }
/** Coordinates use board-width units on both axes, matching the rendered card proportions. */
export function groupBox(cards:FridgeCard[],height:number):GroupBox {
  const box=new GroupBox(); let left=Infinity,top=Infinity,right=-Infinity,bottom=-Infinity;
  for(const card of cards) {
    const a=card.rot*Math.PI/180,ox=card.x,oy=card.y*height/BOARD_H+card.h;
    const corners:ShapePoint[]=[{x:0,y:-card.h},{x:card.w,y:-card.h},{x:card.w,y:0},{x:0,y:0}];
    for(const p of corners) {
      const x=ox+p.x*Math.cos(a)-p.y*Math.sin(a),y=oy+p.x*Math.sin(a)+p.y*Math.cos(a);
      left=Math.min(left,x);right=Math.max(right,x);top=Math.min(top,y);bottom=Math.max(bottom,y);
    }
  }
  if(cards.length){box.x=left;box.y=top;box.w=right-left;box.h=bottom-top;} return box;
}
export function groupMinimumScale(cards:FridgeCard[]):number {
  let factor=0;for(const card of cards){const min=minimumCardSize(card);factor=Math.max(factor,min.w/card.w,min.h/card.h);}return factor;
}
/** Transform every member from the same original pose; never clamp members independently. */
export function transformGroup(cards:FridgeCard[],box:GroupBox,height:number,scale:number,angle:number):void {
  const cx=box.x+box.w/2,cy=box.y+box.h/2,a=angle*Math.PI/180;
  for(const card of cards){
    const x=(card.x-cx)*scale,y=(card.y*height/BOARD_H+card.h-cy)*scale;
    card.x=cx+x*Math.cos(a)-y*Math.sin(a);card.w*=scale;card.h*=scale;
    card.y=(cy+x*Math.sin(a)+y*Math.cos(a)-card.h)*BOARD_H/height;
    card.rot=((card.rot+angle+180)%360+360)%360-180;
  }
}
