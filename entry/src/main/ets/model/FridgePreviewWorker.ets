import { fileIo } from '@kit.CoreFileKit';
import { materializeTemplateUri, inspectTemplate } from './TemplateIO';
export interface PreviewPackageResult {json:string;version:number;}
/** Preview extracts into an isolated cache directory, never the user's canvas store. */
@Concurrent
export async function loadPreviewPackage(uri:string,cacheDir:string,revision:number):Promise<string> {
 const folder=cacheDir+'/fridge_preview_'+revision;
 fileIo.mkdirSync(folder);
 try {const summary=JSON.parse(await inspectTemplate(uri)) as PreviewPackageResult;const result:PreviewPackageResult={json:await materializeTemplateUri(uri,folder),version:summary.version};return JSON.stringify(result);}catch(e){fileIo.rmdirSync(folder);throw e as Error;}
}
@Concurrent
export async function clearPreviewPackage(cacheDir:string,revision:number):Promise<void> {
 const folder=cacheDir+'/fridge_preview_'+revision;
 try {for(const name of fileIo.listFileSync(folder))fileIo.unlinkSync(folder+'/'+name);fileIo.rmdirSync(folder);}catch(_){ }
}
