import { ShapePoint } from './CardSchema';
export class GroupPose { scale:number=1; angle:number=0; }
/** All members consume one atomic translation. */
@Observed
export class BoardMotion {
  @Track ids: string[] = [];
  @Track pivot: ShapePoint = {x:0,y:0};
  @Track transformIds: string[] = [];
  @Track pose: GroupPose = new GroupPose();
  @Track offset: ShapePoint = { x: 0, y: 0 };
}
