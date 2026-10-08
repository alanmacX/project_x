import { fileIo } from '@kit.CoreFileKit';

export const TEMPLATE_UTD: string = 'com.fridgewidget.app.template';
export const TEMPLATE_MIME: string = 'application/x-fridgememo';
export function incomingTemplateUri(uri: string | undefined): string {
  return typeof uri === 'string' && uri.startsWith('file://') && uri.length <= 8192 ? uri : '';
}
/** Match only the declared file type. Anonymous granted URIs need not expose a suffix. */
export function sharedTemplateUri(utd: string, uri: string | undefined): string {
  return utd === TEMPLATE_UTD ? incomingTemplateUri(uri) : '';
}
/** Take ownership while the external grant is alive. Do not retain a sender's URI. */
@Concurrent
export async function stageIncomingTemplate(uri: string, cacheDir: string): Promise<string> {
  if (!uri.startsWith('file://') || uri.length > 8192) throw new Error('请选择本地作品文件');
  const input = await fileIo.open(uri, fileIo.OpenMode.READ_ONLY);
  const path = cacheDir + '/received_' + Date.now() + '_' + Math.floor(Math.random()*1000000) + '.fridge';
  let output: fileIo.File | null = null;
  try {
    const size = (await fileIo.stat(input.fd)).size;
    if (size <= 0 || size > 90*1024*1024) throw new Error('作品文件为空或超过 90MB');
    output = await fileIo.open(path, fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.TRUNC);
    let offset = 0;
    while (offset < size) {
      const buffer = new ArrayBuffer(Math.min(262144, size-offset));
      const count = await fileIo.read(input.fd, buffer, {offset:offset});
      if (count <= 0) throw new Error('作品文件未读取完整');
      let written = 0;
      while (written < count) {
        const bytes = new Uint8Array(buffer, written, count-written).slice();
        const n = await fileIo.write(output.fd, bytes.buffer as ArrayBuffer, {offset:offset+written});
        if (n <= 0) throw new Error('作品文件保存失败');
        written += n;
      }
      offset += count;
    }
    return 'file://' + path;
  } catch (e) {
    try { fileIo.unlinkSync(path); } catch (_) {}
    throw e as Error;
  } finally {
    fileIo.closeSync(input.fd);
    if (output !== null) fileIo.closeSync(output.fd);
  }
}

/** Only our receiving copy may be removed; selected/sender files are never owned. */
export function removeStagedTemplate(uri:string,cacheDir:string):void {
  const prefix='file://'+cacheDir+'/';
  if(!uri.startsWith(prefix)||!/^received_[0-9]+_[0-9]+\.fridge$/.test(uri.slice(prefix.length)))return;
  try{fileIo.unlinkSync(uri.slice(7));}catch(_){}
}
