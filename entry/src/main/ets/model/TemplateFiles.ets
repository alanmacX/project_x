import { exportTemplate as exportFile, inspectTemplate as inspectFile, materializeTemplateUri as importFile } from './TemplateIO';
@Concurrent
export async function exportTemplate(json:string,cardId:string,filesDir:string,cacheDir:string):Promise<string>{return await exportFile(json,cardId,filesDir,cacheDir);}
@Concurrent
export async function inspectTemplate(uri:string):Promise<string>{return await inspectFile(uri);}
@Concurrent
export async function materializeTemplateUri(uri:string,filesDir:string):Promise<string>{return await importFile(uri,filesDir);}
