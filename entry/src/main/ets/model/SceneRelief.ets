import { fileIo } from '@kit.CoreFileKit';
import { FridgeCard } from './CardSchema';
import { DepthInput } from './SubjectDepthGeometry';
import { subjectDepthInputs, bakeSubjectDepth } from './SubjectDepthCache';
@Concurrent
export async function prepareSceneRelief(json:string):Promise<string>{
 const cards=JSON.parse(json) as FridgeCard[],result:Record<string,string>={};
 const folders:Map<string,DepthInput[]>=new Map();
 for(const card of cards){
  if(!card.cutout.startsWith('file://'))continue;
  const inputs=subjectDepthInputs([card]);if(!inputs.length)continue;
  const folder=card.cutout.slice(7,card.cutout.lastIndexOf('/'))+'/relief-cache',batch=folders.get(folder)??[];
  batch.push(inputs[0]);folders.set(folder,batch);
 }
 // One bake/cleanup scan per directory, independent of card count. IDs remain
 // delivery keys; the raster fingerprint is canonicalized by bakeSubjectDepth.
 for(const entry of folders){
  const folder=entry[0],inputs=entry[1];
  try{if(!await fileIo.access(folder))await fileIo.mkdir(folder);
   const mapped=JSON.parse(await bakeSubjectDepth(JSON.stringify(inputs),folder,2)) as Record<string,string>;
   for(const id of Object.keys(mapped))result[id]=mapped[id];
  }catch(_){}
 }
 return JSON.stringify(result);
}
