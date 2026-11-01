import { FridgeCard, CapBlock } from './CardSchema';
/** The template is one editable card. Auxiliary sources belong to that card, never to the layer list. */
export function cardCapabilities(card:FridgeCard):CapBlock[]{return (card.capability?[card.capability]:[]).concat(card.template?.sources??[]);}
export function replaceCardCapability(card:FridgeCard,previous:CapBlock,next:CapBlock):boolean{
 if(card.capability===previous){card.capability=next;return true;}
 const sources=card.template?.sources,index=sources?.indexOf(previous)??-1;
 if(sources&&index>=0){sources[index]=next;return true;}return false;
}
