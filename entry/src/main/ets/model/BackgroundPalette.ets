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
export function representativePalette(rgba: Uint8Array, premultiplied: boolean = false): string[] {
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
  if(points.length===0)return ['#C5C1B8'];
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
  const ordered = centres.map((c: LabColor, i: number): WeightedColor => ({ color: labColor(c), weight: weights[i] })).filter((p: WeightedColor) => p.weight > 0).sort((a: WeightedColor, b: WeightedColor) => b.weight - a.weight);
  return [labColor(centres[at]), ...ordered.filter((p: WeightedColor) => p.color !== labColor(centres[at])).map((p: WeightedColor) => p.color)].slice(0, 3);
}
export function representativeColor(rgba: Uint8Array, premultiplied: boolean = false): string { return representativePalette(rgba, premultiplied)[0]; }
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
/** FluidGradient port: solid radial cores, source-over base, Overlay highlights, final blur.
 * Cindori/FluidGradient (MIT); see THIRD_PARTY_NOTICES.md. A deterministic pose is
 * rendered off-thread so FormKit, preview and exported artwork share identical pixels.
 */
export function blendPixels(anchors: BackgroundAnchor[], base: string, width: number, height: number): Uint8Array {
  const bytes=new Uint8Array(width*height*4);
  const rgb=(hex:string):number[]=>[parseInt(hex.slice(1,3),16)/255,parseInt(hex.slice(3,5),16)/255,parseInt(hex.slice(5,7),16)/255];
  const neutral=rgb(anchors.length>0?anchors[0].color:base);
  const colors=anchors.map((p:BackgroundAnchor)=>rgb(p.color));
  const core=(r:number):number=>r<=.9?1:r>=1?0:1-(r-.9)/.1;
  const overlay=(b:number,h:number):number=>b<.5?2*b*h:1-2*(1-b)*(1-h);
  // Spatial influences remain attached to card centres. Sizes match the source's
  // .15–.75 range; a second independently displaced layer supplies luminous folds.
  for(let y=0;y<height;y++)for(let x=0;x<width;x++){
    const nx=x/Math.max(1,width-1),ny=y/Math.max(1,height-1);
    const out=neutral.slice(),high:number[]=[0,0,0];let alpha=0;
    for(let k=0;k<anchors.length;k++){
      const p=anchors[k],radius=.3+.45*((k*7+3)%11)/10;
      const ry=radius*Math.max(width/height,1)*(.65+.9*((k*5+1)%7)/6);
      const opacity=.55+.4*Math.min(1,Math.sqrt(p.weight));
      const a=core(Math.hypot((nx-p.x)/radius,(ny-p.y)/ry))*opacity;
      for(let c=0;c<3;c++)out[c]=colors[k][c]*a+out[c]*(1-a);
      const hx=Math.max(0,Math.min(1,p.x+.28*Math.sin(k*2.4+1))),hy=Math.max(0,Math.min(1,p.y+.24*Math.cos(k*1.7+1)));
      const ha=core(Math.hypot((nx-hx)/(radius*.85),(ny-hy)/(ry*.85)))*opacity;
      for(let c=0;c<3;c++)high[c]=colors[k][c]*ha+high[c]*(1-ha);
      alpha=ha+alpha*(1-ha);
    }
    const i=(y*width+x)*4;
    for(let c=0;c<3;c++)bytes[i+c]=Math.round(255*(alpha>0?out[c]*(1-alpha)+overlay(out[c],high[c]/alpha)*alpha:out[c]));
    bytes[i+3]=255;
  }
  // Separable blur on the generated colour field, not on card artwork. O(pixels), off UI thread.
  const radius=Math.max(2,Math.round(Math.pow(Math.min(width,height),.75))),span=radius*2+1;
  let input=bytes;
  for(let pass=0;pass<3;pass++){
    const horizontalBytes=new Uint8Array(bytes.length),output=new Uint8Array(bytes.length);
    for(let y=0;y<height;y++)for(let c=0;c<3;c++){
      let sum=0;for(let k=-radius;k<=radius;k++)sum+=input[(y*width+Math.max(0,Math.min(width-1,k)))*4+c];
      for(let x=0;x<width;x++){horizontalBytes[(y*width+x)*4+c]=Math.round(sum/span);sum+=input[(y*width+Math.min(width-1,x+radius+1))*4+c]-input[(y*width+Math.max(0,x-radius))*4+c];}
    }
    for(let x=0;x<width;x++)for(let c=0;c<3;c++){
      let sum=0;for(let k=-radius;k<=radius;k++)sum+=horizontalBytes[(Math.max(0,Math.min(height-1,k))*width+x)*4+c];
      for(let y=0;y<height;y++){output[(y*width+x)*4+c]=Math.round(sum/span);sum+=horizontalBytes[(Math.min(height-1,y+radius+1)*width+x)*4+c]-horizontalBytes[(Math.max(0,y-radius)*width+x)*4+c];}
    }
    for(let i=3;i<output.length;i+=4)output[i]=255;input=output;
  }
  return input;
}
