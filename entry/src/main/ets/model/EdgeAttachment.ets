import { capabilityReadableMinimum } from './CapabilityMetrics';
import { FridgeCard, ElementBox } from './CardSchema';
import { capabilityAttachmentEdges, subjectSurfaceFactor } from './CanvasLayout';
export class EdgeAttachment {
 box:ElementBox=new ElementBox();side:string='left';outer:boolean=false;profile:number[]=[];gutter:number=0;
}
/** Fixed 25 samples; cached silhouette lookup + interpolation, never scans raw contours during a drag. */
export function edgeAttachment(card:FridgeCard,requested:ElementBox,side:string,outer:boolean):EdgeAttachment {
 const out=new EdgeAttachment();out.box.x=requested.x;out.box.y=Math.max(0,Math.min(1-requested.h,requested.y));out.box.w=requested.w;out.box.h=requested.h;out.box.opacity=requested.opacity;out.box.rot=0;out.side=side==='right'?'right':'left';out.outer=outer;
 const samples:number[]=[];
 for(let i=0;i<=24;i++) {const row=new ElementBox();row.x=.4;row.w=.2;row.h=0;row.y=out.box.y+out.box.h*i/24;const e=capabilityAttachmentEdges(card,row);samples.push(out.side==='left'?e[0]:e[1]);}
 const f=subjectSurfaceFactor(card);for(let i=0;i<samples.length;i++)samples[i]=(1-f)/2+samples[i]*f;
 const low=Math.min(...samples),high=Math.max(...samples);out.gutter=Math.max(0,(high-low)*card.w);out.box.w=(Math.max(requested.w*card.w,capabilityReadableMinimum(card.capability).w+12)+out.gutter)/card.w;
 const attachedLeft=(out.side==='left')!==outer;
 out.box.x=attachedLeft?low:high-out.box.w;
 out.profile=samples.map(x=>(x-out.box.x)/out.box.w);
 out.gutter=Math.max(0,(high-low)*card.w);
 return out;
}
/** Contact side follows the complete silhouette; the reading rectangle is inset by its entire excursion. */
export function attachedPath(w:number,h:number,profile:number[],left:boolean,p:number):string {
 if(profile.length<2)return '';
 const xs=profile.map(x=>Math.max(0,Math.min(w,x*w)));
 let path=`M ${left?w-p:p} 0 L ${xs[0]} 0`;
 for(let i=1;i<xs.length;i++)path+=` L ${xs[i]} ${h*i/(xs.length-1)}`;
 path+=` L ${left?w-p:p} ${h} Q ${left?w:0} ${h} ${left?w:0} ${h-p} L ${left?w:0} ${p} Q ${left?w:0} 0 ${left?w-p:p} 0 Z`;return path;
}
