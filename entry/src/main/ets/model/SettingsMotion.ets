import { curves } from '@kit.ArkUI';
import { motionFrameRate } from './MotionPolicy';
const settingsRate:ExpectedFrameRateRange=motionFrameRate();
/** Short, bounded settings transitions; never attach these to artwork or a gesture update. */
export function settingsReveal():TransitionEffect {
  return TransitionEffect.asymmetric(
    TransitionEffect.OPACITY.combine(TransitionEffect.translate({y:6})).animation({duration:180,curve:curves.springMotion(.28,.86),expectedFrameRateRange:settingsRate}),
    TransitionEffect.OPACITY.animation({duration:90,curve:Curve.EaseIn,expectedFrameRateRange:settingsRate})
  );
}
export function settingsDialogOpen():AnimateParam {return {duration:200,curve:curves.springMotion(.28,.86),expectedFrameRateRange:settingsRate};}
export function settingsDialogClose():AnimateParam {return {duration:140,curve:Curve.EaseIn,expectedFrameRateRange:settingsRate};}

/** Paired with the canvas lift; all motion stays in the native compositor. */
export function canvasToolsTransition():TransitionEffect {
  const effect=TransitionEffect.OPACITY.combine(TransitionEffect.translate({y:24})).combine(TransitionEffect.scale({x:.98,y:.98}));
  return TransitionEffect.asymmetric(effect.animation({duration:280,curve:curves.springMotion(.42,.74),expectedFrameRateRange:settingsRate}),
    TransitionEffect.OPACITY.combine(TransitionEffect.translate({y:16})).animation({duration:220,curve:curves.springMotion(.36,.86),expectedFrameRateRange:settingsRate}));
}

/** Shared physical motion keeps the floating tools and artwork in phase. */
export function canvasToolsMotion(open:boolean):AnimateParam {return {curve:curves.springMotion(open ? .42 : .36,open ? .74 : .86),expectedFrameRateRange:settingsRate};}

/** Swap inspector bodies in one anchored viewport; never translate navigation controls. */
export function settingsContentSwap():TransitionEffect {
  return TransitionEffect.asymmetric(
    TransitionEffect.OPACITY.animation({duration:160,curve:Curve.EaseOut,expectedFrameRateRange:settingsRate}),
    TransitionEffect.OPACITY.animation({duration:80,curve:Curve.EaseIn,expectedFrameRateRange:settingsRate})
  );
}
