import { taskpool } from '@kit.ArkTS';
import { image } from '@kit.ImageKit';
import { fileIo } from '@kit.CoreFileKit';
import { prepareSubject, SubjectPixels } from './SubjectGeometry';
import { ShapePoint, ElementBox } from './CardSchema';

export const SUBJECT_MAX_EDGE: number = 1024;
interface PixelPayload {
  width: number;
  height: number;
  rgba: ArrayBuffer;
  outline: string;
  crop: string;
  ink: string;
}
/** No UI, segmentation service or application context is imported by the worker. */
@Concurrent
export function prepareSubjectJob(rgba: ArrayBuffer, mask: ArrayBuffer, width: number, height: number, premultiplied: boolean): PixelPayload {
  const pixels = prepareSubject(new Uint8Array(rgba), new Int32Array(mask), width, height, premultiplied);
  return { width: pixels.width, height: pixels.height, rgba: pixels.rgba.buffer as ArrayBuffer,
    outline: JSON.stringify(pixels.outline), crop: JSON.stringify(pixels.crop), ink: pixels.ink };
}
export async function processSubjectPixels(rgba: Uint8Array, mask: Int32Array, width: number, height: number, premultiplied: boolean): Promise<SubjectPixels> {
  const task = new taskpool.Task(prepareSubjectJob, rgba.buffer, mask.buffer, width, height, premultiplied);
  task.setTransferList([rgba.buffer as ArrayBuffer]);
  const payload = await taskpool.execute(task) as PixelPayload;
  const pixels = new SubjectPixels(); pixels.width = payload.width; pixels.height = payload.height;
  pixels.rgba = new Uint8Array(payload.rgba); pixels.outline = JSON.parse(payload.outline) as ShapePoint[][];
  pixels.crop = JSON.parse(payload.crop) as ElementBox; pixels.ink = payload.ink; return pixels;
}
/** Decode, copy, smooth, trace and pack old PNGs entirely in TaskPool. Only small metadata returns to the UI. */
@Concurrent
export async function repairSubjectJob(src: string, filesDir: string): Promise<string> {
  let input: fileIo.File | null = null, output: fileIo.File | null = null;
  let source: image.ImageSource | null = null, pixel: image.PixelMap | null = null;
  let processed: image.PixelMap | null = null, packer: image.ImagePacker | null = null;
  let path = '';
  try {
    input = await fileIo.open(src.slice(7), fileIo.OpenMode.READ_ONLY);
    source = image.createImageSource(input.fd);
    const original = await source.getImageInfo();
    const ratio = Math.min(1, 1024 / Math.max(original.size.width, original.size.height));
    pixel = await source.createPixelMap({ desiredPixelFormat: image.PixelMapFormat.RGBA_8888,
      desiredSize: { width: Math.max(1, Math.round(original.size.width * ratio)), height: Math.max(1, Math.round(original.size.height * ratio)) } });
    const info = await pixel.getImageInfo(), stride = Math.max(info.size.width * 4, info.stride || 0);
    const bytes = new ArrayBuffer(stride * info.size.height); await pixel.readPixelsToBuffer(bytes);
    const inputBytes = new Uint8Array(bytes), rgba = new Uint8Array(info.size.width * info.size.height * 4);
    const mask = new Int32Array(info.size.width * info.size.height);
    for (let y = 0; y < info.size.height; y++) {
      rgba.set(inputBytes.subarray(y * stride, y * stride + info.size.width * 4), y * info.size.width * 4);
      for (let x = 0; x < info.size.width; x++) mask[y * info.size.width + x] = rgba[(y * info.size.width + x) * 4 + 3];
    }
    const pixels = prepareSubject(rgba, mask, info.size.width, info.size.height, info.alphaType === image.AlphaType.PREMUL);
    processed = await image.createPixelMap(pixels.rgba.buffer as ArrayBuffer, {
      size: { width: pixels.width, height: pixels.height }, srcPixelFormat: image.PixelMapFormat.RGBA_8888,
      pixelFormat: image.PixelMapFormat.RGBA_8888, alphaType: image.AlphaType.UNPREMUL });
    path = filesDir + '/subject_smooth_' + Date.now() + '_' + Math.floor(Math.random() * 1000000) + '.png';
    output = await fileIo.open(path, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE);
    packer = image.createImagePacker(); await packer.packToFile(processed, output.fd, { format: 'image/png', quality: 100 });
    return JSON.stringify({ src: 'file://' + path, outline: pixels.outline, aspect: pixels.width / pixels.height,
      crop: pixels.crop, ink: pixels.ink });
  } catch (e) {
    if (path.length > 0) { try { await fileIo.unlink(path); } catch (_) {} }
    throw new Error((e as Error).message || '主体边缘处理失败');
  } finally {
    if (packer !== null) { try { await packer.release(); } catch (_) {} }
    if (processed !== null) { try { await processed.release(); } catch (_) {} }
    if (pixel !== null) { try { await pixel.release(); } catch (_) {} }
    if (source !== null) { try { await source.release(); } catch (_) {} }
    if (input !== null) { try { fileIo.closeSync(input.fd); } catch (_) {} }
    if (output !== null) { try { fileIo.closeSync(output.fd); } catch (_) {} }
  }
}
