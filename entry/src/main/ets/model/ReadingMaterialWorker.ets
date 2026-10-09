import { imageSwatches } from './BackgroundInputs';
import { micaStudyTint } from './MicaMaterialStudy';
export interface ReadingTintRequest {id:string;src:string;key:string;}
export interface ReadingTintResult {id:string;key:string;tint:string;}
/** Decode tiny thumbnails once after a committed image change, never during gestures. */
@Concurrent
export async function prepareReadingTints(json:string):Promise<string> {
 const requests=JSON.parse(json) as ReadingTintRequest[],results:ReadingTintResult[]=[];
 for(const request of requests.slice(0,16)) {
  if(!request.src.startsWith('file://'))continue;
  try{results.push({id:request.id,key:request.key,tint:micaStudyTint(await imageSwatches(request.src))});}catch(_){}
 }
 return JSON.stringify(results);
}
