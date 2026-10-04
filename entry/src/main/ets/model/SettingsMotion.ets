import { motionFrameRate } from './MotionPolicy';
const settingsRate:ExpectedFrameRateRange=motionFrameRate();
/** Short, bounded settings transitions; never attach these to artwork or a gesture update. */
export function settingsReveal():TransitionEffect {
  return TransitionEffect.asymmetric(
    TransitionEffect.OPACITY.combine(TransitionEffect.translate({y:6})).animation({duration:180,curve:Curve.EaseOut,expectedFrameRateRange:settingsRate}),
    TransitionEffect.OPACITY.animation({duration:90,curve:Curve.EaseIn,expectedFrameRateRange:settingsRate})
  );
}
export function settingsDialogOpen():AnimateParam {return {duration:200,curve:Curve.EaseOut,expectedFrameRateRange:settingsRate};}
export function settingsDialogClose():AnimateParam {return {duration:140,curve:Curve.EaseIn,expectedFrameRateRange:settingsRate};}
