import { fileIo } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
import { packageScene, readPackage, TemplatePackage, TemplateSummary } from './TemplatePackage';
import { FridgeCard } from './CardSchema';
import { assertCanvasCapacity, CANVAS_CARD_LIMIT } from './CanvasCapacity';
function references(pack:TemplatePackage):string[]{const paths:string[]=[pack.state.background.src,pack.state.background.photo];for(const c of pack.state.cards){paths.push(c.cutout,c.capability?.albumCover??'',c.capability?.albumBackground??'');c.elements.forEach(el=>paths.push(el.src));}return Array.from(new Set(paths.filter(p=>p.length>0)));}
function substitute(pack:TemplatePackage,from:string,to:string):void{const bg=pack.state.background;if(bg.src===from)bg.src=to;if(bg.photo===from)bg.photo=to;for(const c of pack.state.cards){if(c.cutout===from)c.cutout=to;if(c.capability){if(c.capability.albumCover===from)c.capability.albumCover=to;if(c.capability.albumBackground===from)c.capability.albumBackground=to;}c.elements.forEach(el=>{if(el.src===from)el.src=to;});}}
function readBytes(path:string,limit:number):Uint8Array{const file=fileIo.openSync(path,fileIo.OpenMode.READ_ONLY);try{const size=fileIo.statSync(file.fd).size;if(size<=0||size>limit)throw new Error('文件为空或超过大小限制');const bytes=new ArrayBuffer(size);let offset=0;while(offset<size){const chunk=new ArrayBuffer(size-offset);const count=fileIo.readSync(file.fd,chunk,{offset:offset});if(count<=0)throw new Error('文件未读取完整');new Uint8Array(bytes).set(new Uint8Array(chunk,0,count),offset);offset+=count;}return new Uint8Array(bytes);}finally{fileIo.closeSync(file.fd);}}
function writeBytes(path:string,bytes:Uint8Array):void{const f=fileIo.openSync(path,fileIo.OpenMode.CREATE|fileIo.OpenMode.READ_WRITE|fileIo.OpenMode.TRUNC);try{let offset=0;while(offset<bytes.length){const count=fileIo.writeSync(f.fd,bytes.slice(offset).buffer as ArrayBuffer,{offset:offset});if(count<=0)throw new Error('文件写入失败');offset+=count;}}finally{fileIo.closeSync(f.fd);}}
export async function exportTemplate(json:string,cardId:string,filesDir:string,cacheDir:string):Promise<string>{
  const pack=packageScene(json,cardId),codec=new util.Base64Helper();let size=0;
  for(const src of references(pack)){if(!src.startsWith('file://'+filesDir+'/'))throw new Error('作品含有尚未导入的图片');const bytes=readBytes(src.slice(7),24*1024*1024);size+=bytes.length;if(size>64*1024*1024)throw new Error('作品图片超过 64MB');const key='asset://'+pack.assets.length,match=src.toLowerCase().match(/\.(png|jpg|jpeg|gif|webp)$/);if(match===null)throw new Error('不支持的图片格式');pack.assets.push({key:key,extension:match[0],data:codec.encodeToStringSync(bytes)});substitute(pack,src,key);}
  pack.state.background.signature='';pack.state.cards.forEach((c:FridgeCard)=>{c.renderContourKey='';});
  const path=cacheDir+'/'+(cardId.length>0?'卡片':'画布')+'_'+Date.now()+'.fridge';writeBytes(path,new util.TextEncoder().encodeInto(JSON.stringify(pack)));return path;
}
export async function inspectTemplate(uri:string):Promise<string>{const p=readPackage(new util.TextDecoder().decodeWithStream(readBytes(uri,90*1024*1024)));const summary:TemplateSummary={kind:p.kind,count:p.state.cards.length,images:p.assets.length};return JSON.stringify(summary);}
export async function materializeTemplate(json:string,filesDir:string,availableCards:number=CANVAS_CARD_LIMIT):Promise<string>{
  const pack=readPackage(json),codec=new util.Base64Helper(),created:string[]=[];let total=0;
  assertCanvasCapacity(CANVAS_CARD_LIMIT-availableCards,pack.state.cards.length);
  try{for(const asset of pack.assets){const bytes=codec.decodeSync(asset.data);total+=bytes.length;if(total>64*1024*1024)throw new Error('作品图片超过 64MB');const path=filesDir+'/import_'+Date.now()+'_'+created.length+asset.extension;created.push(path);writeBytes(path,bytes);substitute(pack,asset.key,'file://'+path);}
    for(const src of references(pack))if(!src.startsWith('file://'+filesDir+'/import_'))throw new Error('作品图片引用不完整');pack.state.background.signature='';return JSON.stringify(pack.state);
  }catch(e){for(const path of created){try{fileIo.unlinkSync(path);}catch(_){}}throw e as Error;}
}

export async function materializeTemplateUri(uri:string,filesDir:string,availableCards:number=CANVAS_CARD_LIMIT):Promise<string>{return materializeTemplate(new util.TextDecoder().decodeWithStream(readBytes(uri,90*1024*1024)),filesDir,availableCards);}
