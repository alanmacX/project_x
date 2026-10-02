import { display } from '@kit.ArkUI';
/** The OS retains control of power/thermal scheduling. */
export function motionFrameRate(): ExpectedFrameRateRange {
  let maximum = 60;
  try {
    const screen = display.getDefaultDisplaySync();
    maximum = Math.max(screen.refreshRate || 60, ...(screen.supportedRefreshRates ?? []));
  } catch (_) {}
  return { min: Math.min(60, maximum), expected: maximum, max: maximum };
}
