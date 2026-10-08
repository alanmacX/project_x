import { FridgeCard, ElementBox, CapBlock } from './CardSchema';
import { cardViewSnapshot, cardStorageShell } from './CardViewSnapshot';
import { capabilityPlacement, cardCapabilityMinimum } from './CanvasLayout';
import { compositionPlacement, compositionOverflow, readingStyles, READING_COMPOSITIONS, READING_COMPOSITION_LABELS } from './ReadingComposition';
import { edgeAttachment } from './EdgeAttachment';
export class EditorVisualChoice {
  key:string=''; label:string=''; card:FridgeCard=new FridgeCard(); scale:number=1;
  offsetX:number=0;offsetY:number=0;
}
/** Changing the backing reserves its inset without shrinking the user's readout. */
export function editorReadingPlacement(card:FridgeCard,blend:string):ElementBox {
  const box=compositionPlacement(card,capabilityPlacement(card),blend);
  for(let i=0;i<2;i++) {
    const minimum=cardCapabilityMinimum(card,true,box.w*card.w);
    box.w=Math.max(box.w,minimum.w/card.w);box.h=Math.max(box.h,minimum.h/card.h);
  }
  return box;
}
/** Build detached candidates once per inspector session, never during a gesture or clock tick. */
export function editorVisualChoices(source:FridgeCard,mode:string):EditorVisualChoice[] {
  const keys=mode==='album'?['cover','classic','row']:mode==='shape'?['rect','round','pill','blob'].concat(source.cutout?['subject']:[]):readingStyles(source.capability?.k??'');
  // Detach large courses/elements once. Candidate variants only change scalar
  // capability fields and replace their placement box, never nested payloads.
  const detached=cardViewSnapshot(source);
  const courses=detached.capability?.courses;
  if(detached.capability)detached.capability.courses=[];
  const capabilityJSON=JSON.stringify(detached.capability);
  return keys.map((key:string):EditorVisualChoice=>{
    const choice=new EditorVisualChoice(),card=cardStorageShell(detached);if(detached.capability){card.capability=JSON.parse(capabilityJSON) as CapBlock;card.capability.courses=courses;}choice.key=key;card.rot=0;
    if(mode==='album'&&card.capability){card.capability.albumPresentation=key;card.w=key==='row'?300:180;card.h=key==='row'?150:180;choice.label=['纯封面','经典信息','横向信息'][keys.indexOf(key)];}
    else if(mode==='shape'){card.capability=null;card.capFree=false;card.elements=[];card.shape=key;if(key==='subject')card.h=card.w/card.subjectAspect;choice.label=['圆角矩形','椭圆','胶囊','自由边角','照片主体'][keys.indexOf(key)];}
    else if(card.capability){card.capability.readingBlend=key;card.capability.readingStyle='surface';card.capBox=editorReadingPlacement(card,key);card.capFree=true;card.capability.readingEdge=key==='sticker'?(source.capability?.readingEdge||'left'):'';
      if(key==='sticker'){const attached=edgeAttachment(card,card.capBox,card.capability.readingEdge,card.capability.readingOutside===true);card.capBox=attached.box;card.capBox.rot=0;}
      choice.label=READING_COMPOSITION_LABELS[READING_COMPOSITIONS.indexOf(key)];
    }
    const overflow=compositionOverflow(card,1);choice.card=card;
    choice.scale=Math.min(82/(card.w+overflow.left+overflow.right),92/(card.h+overflow.top+overflow.bottom));
    choice.offsetX=(overflow.left-overflow.right)*choice.scale/2;choice.offsetY=(overflow.top-overflow.bottom)*choice.scale/2;
    return choice;
  });
}
