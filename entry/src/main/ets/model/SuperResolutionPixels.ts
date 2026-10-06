/** Extend RGB into transparency; preserve alpha as a separate, immutable mask. */
export function extendSubjectColors(bytes: Uint8Array, width: number, height: number, premultiplied: boolean): Uint8Array {
  const count = width * height, rgb = new Uint8Array(bytes.length), known = new Uint8Array(count), queue = new Int32Array(count);
  let head = 0, tail = 0;
  for (let i = 0; i < count; i++) {
    const k = i * 4, a = bytes[k + 3];
    for (let c = 0; c < 3; c++) rgb[k + c] = premultiplied && a > 0 ? Math.min(255, Math.round(bytes[k + c] * 255 / a)) : bytes[k + c];
    rgb[k + 3] = 255;
    if (a >= 250) { known[i] = 1; queue[tail++] = i; }
  }
  if (!tail) throw new Error('图片没有足够清晰的不透明主体');
  while (head < tail) {
    const i = queue[head++], x = i % width;
    for (let direction = 0; direction < 4; direction++) {
      if ((direction === 0 && x === 0) || (direction === 1 && x === width - 1)) continue;
      const j = direction === 0 ? i - 1 : direction === 1 ? i + 1 : direction === 2 ? i - width : i + width;
      if (j < 0 || j >= count || known[j]) continue;
      known[j] = 1;
      const from = i * 4, to = j * 4;
      rgb[to] = rgb[from]; rgb[to + 1] = rgb[from + 1]; rgb[to + 2] = rgb[from + 2];
      queue[tail++] = j;
    }
  }
  return rgb;
}
/** Native-resized mask: only alpha is copied, never foreground RGB. */
export function copySubjectAlpha(output: Uint8Array, mask: Uint8Array): void {
  if (output.length !== mask.length) throw new Error('蒙版尺寸不一致');
  for (let i = 3; i < output.length; i += 4) output[i] = mask[i];
}
