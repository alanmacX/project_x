/** Decoration stays outside the existing reading gutter; resizing never cuts into text. */
export const CLOUD_READING_PADDING:number=8;
export const CLOUD_READING_OUTSET:number=16;
export const CLOUD_READING_FRINGE:number=CLOUD_READING_OUTSET*2+4;
/** Broad, asymmetric shoulders replace repeated scallops. Aspect-dependent curvature
 * varies continuously: no random seed, lobe-count switch or per-frame bitmap work. */
export function cloudReadingPath(w:number,h:number,scale:number):string {
 if(!Number.isFinite(w)||!Number.isFinite(h)||!Number.isFinite(scale)||w<=0||h<=0||scale<=0)return '';
 const W=w+2*CLOUD_READING_OUTSET*scale,H=h+2*CLOUD_READING_OUTSET*scale;
 const p=Math.min(10*scale,Math.min(W,H)*.1),l=p,r=W-p,t=p,b=H-p;
 const radius=Math.min(24*scale,Math.min(W,H)*.27);
 const rx=radius*(1+.12*(w-h)/(w+h)),ry=radius*(1-.12*(w-h)/(w+h));
 const spanX=r-l-2*rx,spanY=b-t-2*ry;
 const ax=Math.min(p*.65,spanX*.09),ay=Math.min(p*.58,spanY*.09);
 const x0=l+rx,x1=r-rx,y0=t+ry,y1=b-ry;
 const xm=x0+spanX*.57,ym=y0+spanY*.43;
 // Tangents are shared at every join, including the softened corner shoulders.
 return `M ${x0} ${t}
 C ${x0+spanX*.16} ${t} ${xm-spanX*.15} ${t-ax} ${xm} ${t-ax}
 C ${xm+spanX*.15} ${t-ax} ${x1-spanX*.13} ${t} ${x1} ${t}
 C ${x1+rx*.62} ${t} ${r} ${y0-ry*.58} ${r} ${y0}
 C ${r} ${y0+spanY*.13} ${r+ay} ${ym-spanY*.12} ${r+ay} ${ym}
 C ${r+ay} ${ym+spanY*.2} ${r} ${y1-spanY*.16} ${r} ${y1}
 C ${r} ${y1+ry*.6} ${x1+rx*.58} ${b} ${x1} ${b}
 C ${x1-spanX*.18} ${b} ${xm+spanX*.14} ${b+ax*.7} ${xm} ${b+ax*.7}
 C ${xm-spanX*.2} ${b+ax*.7} ${x0+spanX*.13} ${b} ${x0} ${b}
 C ${x0-rx*.62} ${b} ${l} ${y1+ry*.56} ${l} ${y1}
 C ${l} ${y1-spanY*.2} ${l-ay*.8} ${ym+spanY*.17} ${l-ay*.8} ${ym}
 C ${l-ay*.8} ${ym-spanY*.12} ${l} ${y0+spanY*.14} ${l} ${y0}
 C ${l} ${y0-ry*.6} ${x0-rx*.56} ${t} ${x0} ${t} Z`;
}
