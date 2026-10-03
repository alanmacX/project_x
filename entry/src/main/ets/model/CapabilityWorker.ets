import { readURL } from './URLService';
import { valueFields } from './CapabilityData';
import { textRecognition } from '@kit.CoreVisionKit';
import { image } from '@kit.ImageKit';
import { fileIo } from '@kit.CoreFileKit';
@Concurrent
export async function fetchValueFields(url:string):Promise<string> { return JSON.stringify(valueFields(await readURL(url))); }
@Concurrent
export async function recognizePickup(uri:string):Promise<string> {
  let source:image.ImageSource|null=null,pixel:image.PixelMap|null=null,file:fileIo.File|null=null,initialized=false;
  try {
    file=await fileIo.open(uri,fileIo.OpenMode.READ_ONLY);source=image.createImageSource(file.fd);
    const info=await source.getImageInfo(),scale=Math.min(1,2048/Math.max(info.size.width,info.size.height));
    pixel=await source.createPixelMap({desiredSize:{width:Math.round(info.size.width*scale),height:Math.round(info.size.height*scale)},desiredPixelFormat:image.PixelMapFormat.RGBA_8888});
    initialized=await textRecognition.init();if(!initialized)throw new Error('此设备文字识别暂不可用，可以手动填写');
    return (await textRecognition.recognizeText({pixelMap:pixel})).value;
  } finally {if(pixel)await pixel.release();if(source)await source.release();if(file)fileIo.closeSync(file.fd);if(initialized)await textRecognition.release();}
}
