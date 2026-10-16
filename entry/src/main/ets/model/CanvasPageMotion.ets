import { motionFrameRate } from './MotionPolicy';

export const CANVAS_PAGE_DURATION: number = 320;
/** Animate the complete workspace in the native compositor, preserving authored card positions. */
export function canvasPageTransition(library: boolean): TransitionEffect {
  const incoming = TransitionEffect.OPACITY.combine(TransitionEffect.translate({ x: library ? -18 : 32 }))
    .combine(TransitionEffect.scale({ x: library ? .99 : .975, y: library ? .99 : .975 }));
  const outgoing = TransitionEffect.OPACITY.combine(TransitionEffect.translate({ x: library ? -18 : 32 }))
    .combine(TransitionEffect.scale({ x: .99, y: .99 }));
  return TransitionEffect.asymmetric(
    incoming.animation({ duration: CANVAS_PAGE_DURATION, curve: Curve.Friction, expectedFrameRateRange: motionFrameRate() }),
    outgoing.animation({ duration: 220, curve: Curve.EaseInOut, expectedFrameRateRange: motionFrameRate() })
  );
}
