import { fileIo } from '@kit.CoreFileKit';
import { materializeTemplateUri } from './TemplateIO';
/** Preview extracts into an isolated cache directory, never the user's canvas store. */
@Concurrent
export async function loadPreviewPackage(uri:string,cacheDir:string,revision:number):Promise<string> {
 const folder=cacheDir+'/fridge_preview_'+revision;
 fileIo.mkdirSync(folder);
 try {return await materializeTemplateUri(uri,folder);}catch(e){fileIo.rmdirSync(folder);throw e as Error;}
}
@Concurrent
export async function clearPreviewPackage(cacheDir:string,revision:number):Promise<void> {
 const folder=cacheDir+'/fridge_preview_'+revision;
 try {for(const name of fileIo.listFileSync(folder))fileIo.unlinkSync(folder+'/'+name);fileIo.rmdirSync(folder);}catch(_){ }
}
