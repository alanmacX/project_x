/** Fixed-complexity silhouettes. A rectangular content core is never carved away by a lobe. */
export const EDGE_STUDY_NAMES:string[]=['柔软云朵','手工纸边','圆润卵石'];
export function edgeStudyInset(w:number,h:number,scale:number=1):number {
 return 2*Math.min(12*scale,Math.min(w,h)*.14);
}
export function edgeStudyPath(kind:number,w:number,h:number,scale:number=1):string {
 if(!Number.isFinite(w)||!Number.isFinite(h)||!Number.isFinite(scale)||w<=0||h<=0||scale<=0)return '';
 const p=edgeStudyInset(w,h,scale)/2,l=p,r=w-p,t=p,b=h-p,c=2*p;
 if(kind===2)return `M ${c} ${t} C ${w*.34} ${p*.12} ${w*.7} ${p*.45} ${w-c} ${t} Q ${r} ${t} ${r} ${c} C ${w-p*.1} ${h*.32} ${w-p*.35} ${h*.7} ${r} ${h-c} Q ${r} ${b} ${w-c} ${b} C ${w*.66} ${h-p*.1} ${w*.26} ${h-p*.55} ${c} ${b} Q ${l} ${b} ${l} ${h-c} C ${p*.2} ${h*.65} ${p*.65} ${h*.32} ${l} ${c} Q ${l} ${t} ${c} ${t} Z`;
 const horizontal=kind===0?3:5,vertical=kind===0?2:3;
 const amplitude=kind===0?p*.87:Math.min(2.2*scale,p*.38);
 let out=`M ${c} ${t}`;
 // Each lobe joins with a horizontal/vertical tangent; no pointed scallops.
 for(let i=0;i<horizontal;i++) {
  const x=c+(w-2*c)*i/horizontal,d=(w-2*c)/horizontal,a=amplitude*(kind===0?[.8,1,.7][i]:[.55,1,.7,.9,.6][i]);
  out+=` C ${x+d*.12} ${t} ${x+d*.18} ${t-a} ${x+d*.5} ${t-a} C ${x+d*.82} ${t-a} ${x+d*.88} ${t} ${x+d} ${t}`;
 }
 out+=` Q ${r} ${t} ${r} ${c}`;
 for(let i=0;i<vertical;i++) {
  const y=c+(h-2*c)*i/vertical,d=(h-2*c)/vertical,a=amplitude*(i%2?.7:1);
  out+=` C ${r} ${y+d*.12} ${r+a} ${y+d*.18} ${r+a} ${y+d*.5} C ${r+a} ${y+d*.82} ${r} ${y+d*.88} ${r} ${y+d}`;
 }
 out+=` Q ${r} ${b} ${w-c} ${b}`;
 for(let i=0;i<horizontal;i++) {
  const x=w-c-(w-2*c)*i/horizontal,d=(w-2*c)/horizontal,a=amplitude*(kind===0?[.7,.9,.8][i]:[.8,.55,1,.6,.9][i]);
  out+=` C ${x-d*.12} ${b} ${x-d*.18} ${b+a} ${x-d*.5} ${b+a} C ${x-d*.82} ${b+a} ${x-d*.88} ${b} ${x-d} ${b}`;
 }
 out+=` Q ${l} ${b} ${l} ${h-c}`;
 for(let i=0;i<vertical;i++) {
  const y=h-c-(h-2*c)*i/vertical,d=(h-2*c)/vertical,a=amplitude*(i%2?1:.7);
  out+=` C ${l} ${y-d*.12} ${l-a} ${y-d*.18} ${l-a} ${y-d*.5} C ${l-a} ${y-d*.82} ${l} ${y-d*.88} ${l} ${y-d}`;
 }
 return out+` Q ${l} ${t} ${c} ${t} Z`;
}
