import { fileIo } from '@kit.CoreFileKit';
import { image } from '@kit.ImageKit';
import { CapBlock } from './CardSchema';
import { imagePalette } from './BackgroundInputs';
import { blendPixels } from './BackgroundPalette';
import { albumAnchors } from './AlbumLayout';
@Concurrent
export async function importAlbumCover(uri:string,json:string,filesDir:string):Promise<string> {
  const cap=JSON.parse(json) as CapBlock,created:string[]=[];let input:fileIo.File|null=null;
  let source:image.ImageSource|null=null,pixel:image.PixelMap|null=null,packer:image.ImagePacker|null=null,file:fileIo.File|null=null;
  const stem=filesDir+'/album_'+Date.now()+'_'+Math.floor(Math.random()*1000000),cover=stem+'.jpg',background=stem+'_fluid.png';
  try {
    input=await fileIo.open(uri.startsWith('file:///')?uri.slice(7):uri,fileIo.OpenMode.READ_ONLY);
    const size=(await fileIo.stat(input.fd)).size;if(size<=0||size>24*1024*1024)throw new Error('封面文件须小于 24 MB');
    source=image.createImageSource(input.fd);const info=await source.getImageInfo(),ratio=Math.min(1,500/Math.max(info.size.width,info.size.height));pixel=await source.createPixelMap({desiredSize:{width:Math.max(1,Math.round(info.size.width*ratio)),height:Math.max(1,Math.round(info.size.height*ratio))}});
    packer=image.createImagePacker();created.push(cover);file=await fileIo.open(cover,fileIo.OpenMode.CREATE|fileIo.OpenMode.READ_WRITE);await packer.packToFile(pixel,file.fd,{format:'image/jpeg',quality:94});fileIo.closeSync(file.fd);file=null;await pixel.release();pixel=null;
    const palette=await imagePalette('file://'+cover),rgba=blendPixels(albumAnchors(palette),palette[0],320,320);
    pixel=await image.createPixelMap(rgba.buffer as ArrayBuffer,{size:{width:320,height:320},srcPixelFormat:image.PixelMapFormat.RGBA_8888,pixelFormat:image.PixelMapFormat.RGBA_8888,alphaType:image.AlphaType.OPAQUE});
    created.push(background);file=await fileIo.open(background,fileIo.OpenMode.CREATE|fileIo.OpenMode.READ_WRITE);await packer.packToFile(pixel,file.fd,{format:'image/png',quality:100});
    cap.k='album';cap.albumId='';cap.albumSource='local';cap.albumCover='file://'+cover;cap.albumBackground='file://'+background;return JSON.stringify(cap);
  } catch(e) {if(file!==null){fileIo.closeSync(file.fd);file=null;}for(const p of created){try{await fileIo.unlink(p);}catch(_){}}throw e as Error;}
  finally {if(input!==null)fileIo.closeSync(input.fd);if(file!==null)fileIo.closeSync(file.fd);if(pixel!==null)await pixel.release();if(source!==null)await source.release();if(packer!==null)await packer.release();}
}
