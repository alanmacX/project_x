import { ShapePoint } from './CardSchema';
export interface ControlPose {scale:number;y:number;angle:number;xShift:number;yShift:number;}
export class GroupPose { scale:number=1; angle:number=0; }
/** All members consume one atomic translation. */
@Observed
export class BoardMotion {
  // Control portal and artwork share a single atomic compositor pose.
  @Track controlId:string='';
  @Track controlPose:ControlPose={scale:1,y:0,angle:0,xShift:0,yShift:0};
  @Track guideVertical:boolean=false;
  @Track guideHorizontal:boolean=false;
  @Track ids: string[] = [];
  @Track pivot: ShapePoint = {x:0,y:0};
  @Track transformIds: string[] = [];
  @Track pose: GroupPose = new GroupPose();
  @Track offset: ShapePoint = { x: 0, y: 0 };
}
