import { BackgroundAnchor } from './CardSchema';
export interface WeightedColor { color: string; weight: number; }
export interface LabColor { l: number; a: number; b: number; }
function linear(c: number): number { return c <= .04045 ? c / 12.92 : ((c + .055) / 1.055) ** 2.4; }
function encoded(c: number): number { return Math.max(0, Math.min(255, Math.round(255 * (c <= .0031308 ? 12.92*c : 1.055*Math.max(0,c)**(1/2.4)-.055)))); }
export function colorLab(hex: string): LabColor {
  const r=linear(parseInt(hex.slice(1,3),16)/255),g=linear(parseInt(hex.slice(3,5),16)/255),b=linear(parseInt(hex.slice(5,7),16)/255);
  const f=(v:number):number => v>.008856 ? Math.cbrt(v) : 7.787*v+16/116;
  const x=f((r*.4124564+g*.3575761+b*.1804375)/.95047),y=f(r*.2126729+g*.7151522+b*.072175),z=f((r*.0193339+g*.119192+b*.9503041)/1.08883);
  return {l:116*y-16,a:500*(x-y),b:200*(y-z)};
}
function labRGB(lab: LabColor): number[] {
  const y=(lab.l+16)/116,x=y+lab.a/500,z=y-lab.b/200;
  const f=(v:number):number => v**3>.008856 ? v**3 : (v-16/116)/7.787;
  const X=f(x)*.95047,Y=f(y),Z=f(z)*1.08883;
  return [encoded(X*3.2404542-Y*1.5371385-Z*.4985314),encoded(-X*.969266+Y*1.8760108+Z*.041556),encoded(X*.0556434-Y*.2040259+Z*1.0572252)];
}
export function labColor(lab: LabColor): string { return '#'+labRGB(lab).map((v:number)=>v.toString(16).padStart(2,'0')).join('').toUpperCase(); }
function distance(a: LabColor,b: LabColor): number { return (a.l-b.l)**2+(a.a-b.a)**2+(a.b-b.b)**2; }
/** Alpha-weighted perceptual clusters: transparent padding and white margins do not vote. */
export function representativeColor(rgba: Uint8Array, premultiplied: boolean = false): string {
  const bins=new Map<number,WeightedColor>();
  for(let i=0;i<rgba.length;i+=4){
    const alpha=rgba[i+3]/255;if(alpha<.35)continue;
    const scale=premultiplied?1/alpha:1;
    const r=Math.min(255,rgba[i]*scale),g=Math.min(255,rgba[i+1]*scale),b=Math.min(255,rgba[i+2]*scale);
    const chroma=(Math.max(r,g,b)-Math.min(r,g,b))/255,light=(r+g+b)/765;
    if(light>.97||light<.035)continue;
    const key=(Math.round(r/24)<<10)|(Math.round(g/24)<<5)|Math.round(b/24);
    const weight=alpha*(.2+chroma)*(.45+Math.min(light,1-light));
    const previous=bins.get(key);
    if(previous!==undefined)previous.weight+=weight;
    else bins.set(key,{color:'#'+[r,g,b].map((v:number)=>Math.round(v).toString(16).padStart(2,'0')).join(''),weight:weight});
  }
  const points=Array.from(bins.values()).sort((a:WeightedColor,b:WeightedColor)=>b.weight-a.weight).slice(0,96);
  if(points.length===0)return '#C5C1B8';
  const labs=points.map((p:WeightedColor)=>colorLab(p.color)),centres:LabColor[]=[labs[0]];
  for(let c=1;c<Math.min(3,labs.length);c++){
    let best=0,score=-1;
    for(let i=0;i<labs.length;i++){const d=Math.min(...centres.map((p:LabColor)=>distance(p,labs[i])))*Math.sqrt(points[i].weight);if(d>score){score=d;best=i;}}
    centres.push(labs[best]);
  }
  let weights:number[]=[];
  for(let pass=0;pass<5;pass++){
    weights=centres.map(()=>0);const sums=centres.map(()=>({l:0,a:0,b:0} as LabColor));
    for(let i=0;i<labs.length;i++){
      let at=0,best=Infinity;for(let c=0;c<centres.length;c++){const d=distance(labs[i],centres[c]);if(d<best){best=d;at=c;}}
      const w=points[i].weight;weights[at]+=w;sums[at].l+=labs[i].l*w;sums[at].a+=labs[i].a*w;sums[at].b+=labs[i].b*w;
    }
    for(let c=0;c<centres.length;c++)if(weights[c]>0)centres[c]={l:sums[c].l/weights[c],a:sums[c].a/weights[c],b:sums[c].b/weights[c]};
  }
  let at=0,score=-1;for(let c=0;c<centres.length;c++){const v=weights[c]*(.7+Math.min(40,Math.hypot(centres[c].a,centres[c].b))/40);if(v>score){score=v;at=c;}}
  return labColor(centres[at]);
}
/** Quiet colour wash, not a saturated average or a harsh complementary colour. */
export function backgroundTone(color: string): string {
  const lab=colorLab(color),c=Math.hypot(lab.a,lab.b),scale=c>0?Math.min(14,c*.28)/c:0;
  return labColor({l:91,a:lab.a*scale,b:lab.b*scale+.8});
}
export function combineColors(colors: WeightedColor[]): string {
  let total=0,l=0,a=0,b=0;
  for(const p of colors){const lab=colorLab(p.color),c=Math.hypot(lab.a,lab.b),w=p.weight*(.15+Math.min(c,50)/50);l+=lab.l*w;a+=lab.a*w;b+=lab.b*w;total+=w;}
  return total>0?labColor({l:l/total,a:a/total,b:b/total}):'#C5C1B8';
}
export function smartTone(colors: WeightedColor[]): string {
  if(colors.length===0)return '#F2F1EE';
  let total=0,a=0,b=0;
  for(const p of colors){const lab=colorLab(p.color),c=Math.hypot(lab.a,lab.b),w=p.weight*(.25+Math.min(c,50)/50);a+=lab.a*w;b+=lab.b*w;total+=w;}
  return backgroundTone(labColor({l:65,a:a/Math.max(total,.001),b:b/Math.max(total,.001)}));
}
/** Smooth Lab mixture tied to card centres; cached as one bitmap for App and FormKit. */
export function blendPixels(anchors: BackgroundAnchor[], base: string, width: number, height: number): Uint8Array {
  const bytes=new Uint8Array(width*height*4);
  const labs=anchors.map((anchor:BackgroundAnchor)=>{ const tone=colorLab(anchor.color),chroma=Math.hypot(tone.a,tone.b),scale=chroma>0?Math.min(30,chroma*.6)/chroma:0;
    return {l:Math.max(40,Math.min(64,30+tone.l*.4)),a:tone.a*scale,b:tone.b*scale} as LabColor;
  });
  const neutral=colorLab(base);neutral.l=50;neutral.a*=.55;neutral.b*=.55;
  // Broad overlapping colour clouds with subtle luminance variation, never small radial spots.
  const horizontal=anchors.map((p:BackgroundAnchor)=>{const row:number[]=[];for(let x=0;x<width;x++){const dx=x/Math.max(1,width-1)-p.x;row.push(Math.exp(-dx*dx/.28));}return row;});
  const vertical=anchors.map((p:BackgroundAnchor)=>{const column:number[]=[];for(let y=0;y<height;y++){const dy=y/Math.max(1,height-1)-p.y;column.push(Math.exp(-dy*dy/.2));}return column;});
  for(let y=0;y<height;y++)for(let x=0;x<width;x++){
    const nx=x/Math.max(1,width-1),ny=y/Math.max(1,height-1);let sum=.22,l=neutral.l*.22,a=neutral.a*.22,b=neutral.b*.22;
    for(let k=0;k<anchors.length;k++){
      const p=anchors[k],w=horizontal[k][x]*vertical[k][y]*Math.sqrt(p.weight);
      sum+=w;l+=labs[k].l*w;a+=labs[k].a*w;b+=labs[k].b*w;
    }
    const atmosphere=4.8*Math.sin(nx*3.1+ny*1.7)-3.2*ny;
    const color=labRGB({l:l/sum+atmosphere,a:a/sum,b:b/sum}),i=(y*width+x)*4;
    const noise=(((x*73+y*151)%17)/16-.5)*.65;
    bytes[i]=Math.max(0,Math.min(255,Math.round(color[0]+noise)));
    bytes[i+1]=Math.max(0,Math.min(255,Math.round(color[1]+noise)));
    bytes[i+2]=Math.max(0,Math.min(255,Math.round(color[2]+noise)));bytes[i+3]=255;
  }
  return bytes;
}
