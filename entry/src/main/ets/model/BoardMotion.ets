import { ShapePoint } from './CardSchema';
/** All members consume one atomic translation. */
@Observed
export class BoardMotion {
  @Track ids: string[] = [];
  @Track offset: ShapePoint = { x: 0, y: 0 };
}
