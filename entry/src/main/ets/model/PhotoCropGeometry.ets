export class PhotoFrame { width: number = 1; height: number = 1; left: number = 0; top: number = 0; }
/** Cover transform shared by the interactive frame and native pixel crop. */
export function photoFrame(sourceW: number, sourceH: number, frameW: number, frameH: number, zoom: number, x: number, y: number): PhotoFrame {
  const scale = Math.max(frameW / sourceW, frameH / sourceH) * Math.max(1, Math.min(5, zoom));
  const result = new PhotoFrame(); result.width = sourceW * scale; result.height = sourceH * scale;
  result.left = (frameW - result.width) / 2 + Math.max(-(result.width - frameW) / 2, Math.min((result.width - frameW) / 2, x));
  result.top = (frameH - result.height) / 2 + Math.max(-(result.height - frameH) / 2, Math.min((result.height - frameH) / 2, y));
  return result;
}
