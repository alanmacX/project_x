import { fileIo } from '@kit.CoreFileKit';
import { FridgeCard } from './CardSchema';
import { subjectDepthInputs, bakeSubjectDepth } from './SubjectDepthCache';
@Concurrent
export async function prepareSceneRelief(json:string):Promise<string>{
 const cards=JSON.parse(json) as FridgeCard[],result:Record<string,string>={};
 // One content-addressed source directory shared by app and Form delivery. No network.
 for(const card of cards){
  if(!card.cutout.startsWith('file://'))continue;
  const folder=card.cutout.slice(7,card.cutout.lastIndexOf('/'))+'/relief-cache';
  try{if(!await fileIo.access(folder))await fileIo.mkdir(folder);const inputs=subjectDepthInputs([card]);if(inputs.length){
   // ID is not part of the file fingerprint: identical geometry shares artwork.
   inputs[0].key='surface';const mapped=JSON.parse(await bakeSubjectDepth(JSON.stringify(inputs),folder,2)) as Record<string,string>;if(mapped.surface)result[card.id]=mapped.surface;
  }}catch(_){}
 }
 return JSON.stringify(result);
}
