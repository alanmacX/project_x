import { compositionPadding } from './ReadingComposition';
export function hookReserve(blend:string):number {return blend==='tag'||blend==='dock'?20:0;}
export function hookCenter(position:number,w:number,scale:number):number {const margin=Math.min(w/2,14*scale);return margin+Math.max(0,Math.min(1,position))*(w-2*margin);}
/** Every curve is outside the content rectangle. Edge amplitude is in vp, never a percentage of label height. */
export function micaPath(blend:string,w:number,h:number,scale:number,edge:string=''):string {
 if(w<=0||h<=0)return '';
 const p=Math.min(compositionPadding(blend)*scale,w/4,h/4),a=p*.42,r=Math.min(p*2,w/4,h/4),l=a,t=a,b=h-a,x=w-a;
 if(blend==='bare')return `M ${p} ${p*.3} C ${w*.25} 0 ${w*.66} ${p*.7} ${w-p} ${p*.2} L ${w-p*.35} ${p*.5} L ${w-p*.5} ${h*.18} L ${w-p*.12} ${h*.2} L ${w-p*.4} ${h*.35} L ${w-p*.05} ${h*.4} L ${w-p*.35} ${h*.55} L ${w-p*.1} ${h*.68} L ${w-p*.55} ${h-p*.35} L ${w-p} ${h-p*.2} C ${w*.66} ${h} ${w*.3} ${h-p*.65} ${p} ${h-p*.25} L ${p*.25} ${h-p*.6} L ${p*.48} ${h*.75} L ${p*.12} ${h*.7} L ${p*.4} ${h*.5} L ${p*.06} ${h*.4} L ${p*.45} ${h*.25} L ${p*.2} ${p*.6} Z`;
 if(blend==='badge')return `M ${w/2} 0 A ${w/2} ${h/2} 0 1 1 ${w/2-.001} 0 Z`;
 if(blend==='tag'||blend==='dock')return `M ${r} 0 L ${w-r} 0 Q ${w} 0 ${w} ${r} L ${w} ${h-r} Q ${w} ${h} ${w-r} ${h} L ${r} ${h} Q 0 ${h} 0 ${h-r} L 0 ${r} Q 0 0 ${r} 0 Z`;
 // Tangents and controls stay in the outer padding band. The straight safe rectangle is contained even at very wide/tall aspect ratios.
 const path=`M ${p} ${t} C ${w*.28} ${edge==='top'?0:0} ${w*.34} ${t+a} ${w*.5} ${t} C ${w*.68} 0 ${w*.8} ${t+a} ${w-p} ${t} Q ${x} ${t} ${x} ${p} C ${edge==='right'?w:w-a*2} ${h*.35} ${w} ${h*.65} ${x} ${h-p} Q ${x} ${b} ${w-p} ${b} C ${w*.72} ${h} ${w*.63} ${b-a} ${w*.5} ${b} C ${w*.3} ${h} ${w*.2} ${b-a} ${p} ${b} Q ${l} ${b} ${l} ${h-p} C 0 ${h*.65} ${edge==='left'?0:a*2} ${h*.35} ${l} ${p} Q ${l} ${t} ${p} ${t} Z`;
 if(!edge)return path;
 let index=0;return path.replace(/-?\d+(?:\.\d+)?(?:e[+-]?\d+)?/gi,(raw:string)=>{const value=Number(raw),isX=index++%2===0;if(isX&&edge==='left'&&value<=p)return '0';if(isX&&edge==='right'&&value>=w-p)return String(w);if(!isX&&edge==='top'&&value<=p)return '0';if(!isX&&edge==='bottom'&&value>=h-p)return String(h);return raw;});
}
