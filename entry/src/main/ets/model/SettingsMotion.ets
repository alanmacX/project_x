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

/** Paired with the canvas lift; all motion stays in the native compositor. */
export function canvasToolsTransition():TransitionEffect {
  const effect=TransitionEffect.OPACITY.combine(TransitionEffect.translate({y:24})).combine(TransitionEffect.scale({x:.98,y:.98}));
  return TransitionEffect.asymmetric(effect.animation({duration:280,curve:Curve.Friction,expectedFrameRateRange:settingsRate}),
    TransitionEffect.OPACITY.combine(TransitionEffect.translate({y:16})).animation({duration:220,curve:Curve.EaseOut,expectedFrameRateRange:settingsRate}));
}
