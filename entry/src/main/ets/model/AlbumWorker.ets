import http from '@ohos.net.http';
import { fileIo } from '@kit.CoreFileKit';
import { image } from '@kit.ImageKit';
import { ALBUM_USER_AGENT, AlbumResult, albumSearchURL, parseAlbums, albumCoverURL } from './AlbumCatalog';
import { CapBlock } from './CardSchema';
import { imagePalette } from './BackgroundInputs';
import { blendPixels } from './BackgroundPalette';
import { albumAnchors } from './AlbumLayout';
@Concurrent
export async function searchAlbums(term:string):Promise<string> {
  const client=http.createHttp();
  try {
    const response=await client.request(albumSearchURL(term),{method:http.RequestMethod.GET,header:{'User-Agent':ALBUM_USER_AGENT},expectDataType:http.HttpDataType.STRING,connectTimeout:10000,readTimeout:12000,maxLimit:1024*1024});
    if(response.responseCode!==200)throw new Error(response.responseCode===503||response.responseCode===429?'专辑目录繁忙，请稍后重试':'暂时无法搜索专辑');
    return JSON.stringify(parseAlbums(response.result as string));
  } finally {client.destroy();}
}
@Concurrent
export async function saveAlbum(json:string,filesDir:string):Promise<string> {
  const album=JSON.parse(json) as AlbumResult,client=http.createHttp(),created:string[]=[];
  let source:image.ImageSource|null=null,pixel:image.PixelMap|null=null,packer:image.ImagePacker|null=null,file:fileIo.File|null=null;
  const stem=filesDir+'/album_'+Date.now()+'_'+album.id,cover=stem+'.jpg',background=stem+'_fluid.png';
  try {
    const response=await client.request(albumCoverURL(album.id),{method:http.RequestMethod.GET,header:{'User-Agent':ALBUM_USER_AGENT},expectDataType:http.HttpDataType.ARRAY_BUFFER,connectTimeout:10000,readTimeout:18000,maxLimit:4*1024*1024});
    if(response.responseCode!==200)throw new Error(response.responseCode===404?'这张专辑暂缺封面，请选其他版本':'封面下载失败，请重试');
    const bytes=response.result as ArrayBuffer;if(bytes.byteLength===0||bytes.byteLength>4*1024*1024)throw new Error('封面大小异常');
    source=image.createImageSource(bytes);const info=await source.getImageInfo(),ratio=Math.min(1,500/Math.max(info.size.width,info.size.height));pixel=await source.createPixelMap({desiredSize:{width:Math.max(1,Math.round(info.size.width*ratio)),height:Math.max(1,Math.round(info.size.height*ratio))}});
    packer=image.createImagePacker();created.push(cover);file=await fileIo.open(cover,fileIo.OpenMode.CREATE|fileIo.OpenMode.READ_WRITE);await packer.packToFile(pixel,file.fd,{format:'image/jpeg',quality:94});fileIo.closeSync(file.fd);file=null;await pixel.release();pixel=null;
    const palette=await imagePalette('file://'+cover),rgba=blendPixels(albumAnchors(palette),palette[0],320,320);
    pixel=await image.createPixelMap(rgba.buffer as ArrayBuffer,{size:{width:320,height:320},srcPixelFormat:image.PixelMapFormat.RGBA_8888,pixelFormat:image.PixelMapFormat.RGBA_8888,alphaType:image.AlphaType.OPAQUE});
    created.push(background);file=await fileIo.open(background,fileIo.OpenMode.CREATE|fileIo.OpenMode.READ_WRITE);await packer.packToFile(pixel,file.fd,{format:'image/png',quality:100});
    const cap:CapBlock={k:'album',title:album.title,artist:album.artist,albumId:album.id,albumSource:'musicbrainz',albumCover:'file://'+cover,albumBackground:'file://'+background};return JSON.stringify(cap);
  } catch(e) {if(file!==null){fileIo.closeSync(file.fd);file=null;}for(const p of created){try{await fileIo.unlink(p);}catch(_){}}throw e as Error;}
  finally {client.destroy();if(file!==null)fileIo.closeSync(file.fd);if(pixel!==null)await pixel.release();if(source!==null)await source.release();if(packer!==null)await packer.release();}
}
