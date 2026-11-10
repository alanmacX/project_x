import { SceneRect } from './SceneLayout';

/** Match the original editor's card lift into its measured preview rectangle. */
export const CUSTOMIZER_ENTER_DURATION:number=380;
export const CUSTOMIZER_EXIT_DURATION:number=340;
export class CustomizerEntrancePose {
  x:number=0;
  y:number=0;
  scale:number=1;
  angle:number=0;
}
export function customizerEntrancePose(origin:SceneRect,target:SceneRect):CustomizerEntrancePose {
  const pose=new CustomizerEntrancePose();
  if(origin.w<=0||origin.h<=0||target.w<=0||target.h<=0)return pose;
  pose.x=origin.x+origin.w/2-target.x-target.w/2;
  pose.y=origin.y+origin.h/2-target.y-target.h/2;
  pose.scale=origin.w/target.w;
  pose.angle=origin.rot;
  return pose;
}
