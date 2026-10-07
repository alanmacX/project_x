import { edgeAttachment } from './EdgeAttachment';
import { readingStyles, defaultReadingStyle } from './ReadingStylePolicy';
import { FridgeCard, ElementBox } from './CardSchema';
export { readingStyles } from './ReadingStylePolicy';
export const READING_COMPOSITIONS:string[]=['bare','badge','sticker','tag'];
export const READING_COMPOSITION_LABELS:string[]=['笔触','徽章','边缘自适应','挂钩'];
export const READING_COMPOSITION_NOTES:string[]=['半透明笔触，贴近内容区域','电量专用圆形徽章','沿卡片左右边缘滑动，选择内贴合或外贴合','穿孔挂钩，上沿留出内容避让区'];
export function isReadingComposition(blend:string):boolean {return READING_COMPOSITIONS.includes(blend);}
export function compositionSuggestion(kind:string):string {return defaultReadingStyle(kind);}
/** Smooth fixed-complexity silhouette; generated in native pixel coordinates, no outline scan. */
export function compositionPath(blend:string,w:number,h:number,edge:string=''):string {
  if(!Number.isFinite(w)||!Number.isFinite(h)||w<=0||h<=0)return '';
  if(edge) {
    const raw='M 0 18 C 25 8 31 12 52 9 C 76 1 93 10 96 30 C 100 55 91 79 93 85 C 66 96 45 89 26 95 C 15 94 4 94 0 82 L 0 18 Z';
    let axis=0,x=0;return raw.replace(/-?\d+(?:\.\d+)?/g,(v:string)=>{if(axis++%2===0){x=Number(v);return '@';}const y=Number(v),a=edge==='top'?100-y:edge==='right'?100-x:edge==='bottom'?y:x,b=edge==='top'?x:edge==='right'?100-y:edge==='bottom'?100-x:y;return String(a*w/100)+' '+String(b*h/100);}).replace(/@ /g,'');
  }
  if(blend==='space')return `M ${w*.12} ${h*.3} C ${-w*.02} ${h*.03} ${w*.25} ${-h*.04} ${w*.38} ${h*.1} C ${w*.57} ${-h*.05} ${w*.7} ${h*.06} ${w*.74} ${h*.15} C ${w*1.02} ${h*.05} ${w*1.05} ${h*.36} ${w*.94} ${h*.49} C ${w*1.08} ${h*.75} ${w*.83} ${h*1.02} ${w*.64} ${h*.89} C ${w*.46} ${h*1.08} ${w*.21} ${h*.99} ${w*.18} ${h*.86} C ${-w*.04} ${h*.94} ${-w*.06} ${h*.52} ${w*.12} ${h*.3} Z`;
  return `M ${w*.08} ${h*.09} C ${w*.24} ${-h*.03} ${w*.43} ${h*.09} ${w*.6} ${h*.05} C ${w*.81} ${-h*.03} ${w*1.02} ${h*.07} ${w*.96} ${h*.3} C ${w*.91} ${h*.51} ${w*1.06} ${h*.72} ${w*.94} ${h*.9} C ${w*.78} ${h*1.05} ${w*.58} ${h*.91} ${w*.39} ${h*.96} C ${w*.19} ${h*1.04} ${-w*.01} ${h*.93} ${w*.04} ${h*.73} C ${w*.1} ${h*.5} ${-w*.04} ${h*.28} ${w*.08} ${h*.09} Z`;
}
/** Layout is persisted once, then edited normally. Never reposition on refresh or tick. */
export function compositionPlacement(card:FridgeCard,box:ElementBox,blend:string):ElementBox {
  const out=new ElementBox();out.w=box.w;out.h=box.h;out.x=box.x;out.y=box.y;out.opacity=box.opacity;out.rot=box.rot;
  if(blend==='space')out.x=-out.w*.3;
  if(blend==='dock')out.x=.55;
  if(blend==='tag')out.y=Math.min(1-out.h,.7-out.h*.5);
  return out;
}

export function compositionPadding(blend:string):number {return blend==='space'?10:blend==='bare'?8:blend==='sticker'?6:4;}
export class CompositionOverflow {left:number=0;top:number=0;right:number=0;bottom:number=0;}
/** Cache fringe includes external attachments, including their rotated corners. */
export function compositionOverflow(card:FridgeCard,scale:number):CompositionOverflow {
 const out=new CompositionOverflow();if(!card.capFree||!isReadingComposition(card.capability?.readingBlend??''))return out;
 const b=card.capability?.readingBlend==='sticker'?edgeAttachment(card,card.capBox,card.capability.readingEdge||'left',card.capability.readingOutside===true).box:card.capBox,w=b.w*card.w,h=b.h*card.h,a=b.rot*Math.PI/180;
 const rw=Math.abs(Math.cos(a))*w+Math.abs(Math.sin(a))*h,rh=Math.abs(Math.sin(a))*w+Math.abs(Math.cos(a))*h;
 const cx=(b.x+b.w/2)*card.w,cy=(b.y+b.h/2)*card.h,fringe=['tag','dock'].includes(card.capability?.readingBlend??'')?50:Math.max(w,h)*.06;
 out.left=Math.max(0,-(cx-rw/2-fringe))*scale;out.top=Math.max(0,-(cy-rh/2-fringe))*scale;
 out.right=Math.max(0,cx+rw/2+fringe-card.w)*scale;out.bottom=Math.max(0,cy+rh/2+fringe-card.h)*scale;return out;
}

export function brushPath():string {return 'M 3 26 C 16 11 29 17 41 14 C 57 8 68 21 91 16 L 97 34 L 94 70 C 79 88 67 76 53 86 C 32 90 23 77 5 84 L 8 64 L 2 48 Z';}
/** One edge only; no contour walk and no frame-sized arrays. Distances are physical vp. */
export class CompositionSnap {box:ElementBox=new ElementBox();edge:string='';}
export function snapComposition(box:ElementBox,cardW:number,cardH:number,scale:number,blend:string,previousEdge:string='',boundary:number[]=[0,1,0,1]):CompositionSnap {
 const out=new CompositionSnap();out.box.x=box.x;out.box.y=box.y;out.box.w=box.w;out.box.h=box.h;out.box.rot=box.rot;out.box.opacity=box.opacity;
 if(!['space','sticker'].includes(blend)||Math.abs(box.rot)>3)return out;
 let best=6;
 const candidates:number[]=[boundary[0],boundary[1]-box.w,boundary[0]-box.w,boundary[1],boundary[2],boundary[3]-box.h,boundary[2]-box.h,boundary[3]];
 const edges:string[]=['left','right','right','left','top','bottom','bottom','top'];
 if(previousEdge){let held=-1,heldDistance=10;for(let i=0;i<8;i++){const d=Math.abs((i<4?box.x:box.y)-candidates[i])*(i<4?cardW:cardH)*scale;if(edges[i]===previousEdge&&d<heldDistance){held=i;heldDistance=d;}}if(held>=0){out.edge=previousEdge;if(held<4)out.box.x=candidates[held];else out.box.y=candidates[held];return out;}}
 for(let i=0;i<8;i++){const distance=Math.abs((i<4?box.x:box.y)-candidates[i])*(i<4?cardW:cardH)*scale;if(distance<best){best=distance;out.edge=edges[i];if(i<4){out.box.x=candidates[i];out.box.y=box.y;}else{out.box.x=box.x;out.box.y=candidates[i];}}}
 return out;
}
/** Hook can be placed anywhere on the upper semicircle, with tiny lift adjustment. */
export function hookPoint(position:number):number[] {const a=Math.PI+Math.max(0,Math.min(1,position))*Math.PI;const x=Math.cos(a),y=Math.sin(a);return [.5+.5*Math.sign(x)*Math.sqrt(Math.abs(x)),.5-.5*Math.sqrt(Math.abs(y))];}
export function hookPosition(x:number,y:number):number {return Math.max(0,Math.min(1,(Math.atan2(-Math.pow(Math.max(.0001,.5-y)*2,2),Math.sign(x-.5)*Math.pow(Math.abs(x-.5)*2,2))+Math.PI)/Math.PI));}
