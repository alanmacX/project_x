import { image } from '@kit.ImageKit';
import { fileIo, fileUri } from '@kit.CoreFileKit';
import { systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
/** Exported files outlive the share panel; never unlink them while a receiver is reading. */
export async function sharePixelMap(context: common.UIAbilityContext, pixel: image.PixelMap, opaque: boolean, anchor: string): Promise<string> {
  const path=context.cacheDir+'/share_'+Date.now()+(opaque?'.jpg':'.png');
  let file:fileIo.File|null=null;const packer=image.createImagePacker();
  try {
    file=await fileIo.open(path,fileIo.OpenMode.CREATE|fileIo.OpenMode.READ_WRITE);
    await packer.packToFile(pixel,file.fd,{format:opaque?'image/jpeg':'image/png',quality:opaque?94:100});
  } finally {if(file!==null)fileIo.closeSync(file.fd);await packer.release();}
  const data=new systemShare.SharedData({utd:opaque?uniformTypeDescriptor.UniformDataType.JPEG:uniformTypeDescriptor.UniformDataType.PNG,
    uri:fileUri.getUriFromPath(path),title:'我的卡片作品'});
  await new systemShare.ShareController(data).show(context,{anchor:anchor,previewMode:systemShare.SharePreviewMode.DETAIL});
  return path;
}
