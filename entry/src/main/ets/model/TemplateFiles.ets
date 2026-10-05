import { exportTemplate as exportFile, inspectTemplate as inspectFile, materializeTemplateUri as importFile } from './TemplateIO';
import { CANVAS_CARD_LIMIT } from './CanvasCapacity';
@Concurrent
export async function exportTemplate(json:string,cardId:string,filesDir:string,cacheDir:string):Promise<string>{return await exportFile(json,cardId,filesDir,cacheDir);}
@Concurrent
export async function inspectTemplate(uri:string):Promise<string>{return await inspectFile(uri);}
@Concurrent
export async function materializeTemplateUri(uri:string,filesDir:string,availableCards:number=CANVAS_CARD_LIMIT):Promise<string>{return await importFile(uri,filesDir,availableCards);}
