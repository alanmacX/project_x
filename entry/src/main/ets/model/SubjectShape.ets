import { subjectSegmentation } from '@kit.CoreVisionKit';
import { image } from '@kit.ImageKit';
import { fileIo } from '@kit.CoreFileKit';
import { ShapePoint, ElementBox } from './CardSchema';
import { SubjectPixels } from './SubjectGeometry';
import { processSubjectPixels, repairSubjectJob, SUBJECT_MAX_EDGE } from './SubjectWorker';
import { taskpool } from '@kit.ArkTS';
export { traceMask } from './SubjectGeometry';

export class SubjectShapeResult {
  src: string = '';
  outline: ShapePoint[][] = [];
  aspect: number = 1;
  ink: string = '#262824';
  crop: ElementBox = new ElementBox();
}
export async function extractSubject(src: string, filesDir: string): Promise<SubjectShapeResult> {
  let input: fileIo.File | null = null, output: fileIo.File | null = null;
  let source: image.ImageSource | null = null, pixelMap: image.PixelMap | null = null;
  let processed: image.PixelMap | null = null, packer: image.ImagePacker | null = null;
  const subjectImages: image.PixelMap[] = [];
  let path: string = '';
  try {
    input = await fileIo.open(src.startsWith('file:///') ? src.slice(7) : src, fileIo.OpenMode.READ_ONLY);
    source = image.createImageSource(input.fd);
    const info = await source.getImageInfo();
    const ratio = Math.min(1, SUBJECT_MAX_EDGE / Math.max(info.size.width, info.size.height));
    pixelMap = await source.createPixelMap({ desiredSize: { width: Math.max(1, Math.round(info.size.width * ratio)), height: Math.max(1, Math.round(info.size.height * ratio)) }, desiredPixelFormat: image.PixelMapFormat.RGBA_8888 });
    try {
      if (!await subjectSegmentation.init()) throw new Error('unavailable');
    } catch (_) { throw new Error('此设备的主体分割服务不可用'); }
    const result = await subjectSegmentation.doSegmentation({ pixelMap: pixelMap }, {
      maxCount: 1, enableSubjectDetails: true, enableSubjectForegroundImage: true
    });
    if (result.fullSubject?.foregroundImage !== undefined) subjectImages.push(result.fullSubject.foregroundImage);
    for (const detail of (result.subjectDetails ?? [])) {
      if (detail.foregroundImage !== undefined && !subjectImages.includes(detail.foregroundImage)) subjectImages.push(detail.foregroundImage);
    }
    if (result.subjectCount === 0) throw new Error('没有识别到主体，请换一张主体清楚的照片');
    const subject = result.subjectDetails !== undefined && result.subjectDetails.length > 0 ? result.subjectDetails[0] : result.fullSubject;
    const size = (await pixelMap.getImageInfo()).size;
    const rgba = await readRgba(pixelMap);
    const pixels = await processSubjectPixels(rgba, subject.mattingList, size.width, size.height,
      (await pixelMap.getImageInfo()).alphaType === image.AlphaType.PREMUL);
    processed = await createSubjectPixelMap(pixels);
    path = filesDir + '/subject_' + Date.now() + '.png';
    output = await fileIo.open(path, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE);
    packer = image.createImagePacker();
    await packer.packToFile(processed, output.fd, { format: 'image/png', quality: 100 });
    const value = new SubjectShapeResult(); value.src = 'file://' + path; value.outline = pixels.outline; value.aspect = pixels.width / pixels.height; value.crop = pixels.crop; value.ink = pixels.ink;
    return value;
  } catch (e) {
    if (path.length > 0) { try { await fileIo.unlink(path); } catch (_) {} }
    throw new Error((e as Error).message || '主体分割未完成');
  } finally {
    if (packer !== null) { try { await packer.release(); } catch (_) {} }
    if (processed !== null) { try { await processed.release(); } catch (_) {} }
    for (const subjectImage of subjectImages) { try { await subjectImage.release(); } catch (_) {} }
    if (pixelMap !== null) { try { await pixelMap.release(); } catch (_) {} }
    if (source !== null) { try { await source.release(); } catch (_) {} }
    if (input !== null) { try { fileIo.closeSync(input.fd); } catch (_) {} }
    if (output !== null) { try { fileIo.closeSync(output.fd); } catch (_) {} }
    try { await subjectSegmentation.release(); } catch (_) {}
  }
}

async function createSubjectPixelMap(pixels: SubjectPixels): Promise<image.PixelMap> {
  return image.createPixelMap(pixels.rgba.buffer as ArrayBuffer, {
    size: { width: pixels.width, height: pixels.height },
    srcPixelFormat: image.PixelMapFormat.RGBA_8888, pixelFormat: image.PixelMapFormat.RGBA_8888,
    alphaType: image.AlphaType.UNPREMUL
  });
}
/** Repair previously saved cutouts locally, without invoking segmentation or a network service. */
export async function repairSubject(src: string, filesDir: string): Promise<SubjectShapeResult> {
  const json = await taskpool.execute(new taskpool.Task(repairSubjectJob, src, filesDir)) as string;
  return JSON.parse(json) as SubjectShapeResult;
}

async function readRgba(pixel: image.PixelMap): Promise<Uint8Array> {
  const info = await pixel.getImageInfo(), stride = Math.max(info.size.width * 4, info.stride || 0);
  const buffer = new ArrayBuffer(stride * info.size.height); await pixel.readPixelsToBuffer(buffer);
  const input = new Uint8Array(buffer), rgba = new Uint8Array(info.size.width * info.size.height * 4);
  for (let row = 0; row < info.size.height; row++) rgba.set(input.subarray(row * stride, row * stride + info.size.width * 4), row * info.size.width * 4);
  return rgba;
}
