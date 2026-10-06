import { imageSuperResolution } from '@kit.CoreVisionKit';
import { image } from '@kit.ImageKit';
import { fileIo } from '@kit.CoreFileKit';
import { deviceInfo } from '@kit.BasicServicesKit';
import { extendSubjectColors, copySubjectAlpha } from './SuperResolutionPixels';

export function supportsSuperResolution(): boolean { return deviceInfo.sdkApiVersion >= 26 && canIUse('SystemCapability.AI.Vision.VisionBase'); }
/** One bounded import-time job. No UI state, internet, or widget render work. */
@Concurrent
export async function enhanceImageJob(uri: string, filesDir: string, subject: boolean): Promise<string> {
  if (deviceInfo.sdkApiVersion < 26 || !canIUse('SystemCapability.AI.Vision.VisionBase')) throw new Error('提升清晰度需要 HarmonyOS API 26 及支持此能力的设备');
  let file:fileIo.File|null=null,output:fileIo.File|null=null,source:image.ImageSource|null=null,input:image.PixelMap|null=null;
  let opaque:image.PixelMap|null=null,result:image.PixelMap|null=null,composed:image.PixelMap|null=null,packer:image.ImagePacker|null=null;
  let analyzer:imageSuperResolution.ImageSRAnalyzer|null=null;
  const path=filesDir+'/enhanced_'+Date.now()+'_'+Math.floor(Math.random()*1000000)+(subject?'.png':'.jpg');
  try {
    file=await fileIo.open(uri.startsWith('file://')?uri.slice(7):uri,fileIo.OpenMode.READ_ONLY);source=image.createImageSource(file.fd);
    const info=await source.getImageInfo(),ratio=Math.min(1,1280/Math.max(info.size.width,info.size.height));
    input=await source.createPixelMap({desiredPixelFormat:image.PixelMapFormat.RGBA_8888,desiredSize:{width:Math.max(1,Math.round(info.size.width*ratio)),height:Math.max(1,Math.round(info.size.height*ratio))}});
    const inputInfo=await input.getImageInfo(),w=inputInfo.size.width,h=inputInfo.size.height;
    let original=new Uint8Array(0);
    if(subject){
      original=new Uint8Array(w*h*4);await input.readPixelsToBuffer(original.buffer as ArrayBuffer);
      const rgb=extendSubjectColors(original,w,h,inputInfo.alphaType===image.AlphaType.PREMUL);
      opaque=await image.createPixelMap(rgb.buffer as ArrayBuffer,{size:{width:w,height:h},srcPixelFormat:image.PixelMapFormat.RGBA_8888,pixelFormat:image.PixelMapFormat.RGBA_8888,alphaType:image.AlphaType.OPAQUE});
    }
    analyzer=await imageSuperResolution.ImageSRAnalyzer.create();
    const response=await analyzer.process({inputData:{pixelMap:opaque??input}});result=response.pixelMap;
    const out=await result.getImageInfo(),limit=Math.min(1,2048/Math.max(out.size.width,out.size.height));
    if(limit<1)await result.scale(limit,limit);
    if(subject){
      const size=(await result.getImageInfo()).size,rgba=new Uint8Array(size.width*size.height*4);await result.readPixelsToBuffer(rgba.buffer as ArrayBuffer);
      // Resize the immutable alpha mask with the native image pipeline, rather
      // than doing millions of bilinear samples in interpreted ArkTS.
      await input.scale(size.width / w, size.height / h);
      const mask = new Uint8Array(size.width * size.height * 4);
      await input.readPixelsToBuffer(mask.buffer as ArrayBuffer);
      copySubjectAlpha(rgba, mask);
      composed=await image.createPixelMap(rgba.buffer as ArrayBuffer,{size,srcPixelFormat:image.PixelMapFormat.RGBA_8888,pixelFormat:image.PixelMapFormat.RGBA_8888,alphaType:image.AlphaType.UNPREMUL});
    }
    output=await fileIo.open(path,fileIo.OpenMode.CREATE|fileIo.OpenMode.READ_WRITE);packer=image.createImagePacker();
    await packer.packToFile(composed??result,output.fd,{format:subject?'image/png':'image/jpeg',quality:96});return 'file://'+path;
  } catch(error) {
    try{await fileIo.unlink(path);}catch(_){}
    throw new Error((error as Error).message||'此设备暂时无法提升清晰度，请保留原图');
  } finally {
    if(output)fileIo.closeSync(output.fd);if(file)fileIo.closeSync(file.fd);
    if(packer)await packer.release();if(composed)await composed.release();if(result)await result.release();if(opaque)await opaque.release();if(input)await input.release();if(source)await source.release();
    if(analyzer){try{await analyzer.destroy();}catch(_){}}
  }
}
