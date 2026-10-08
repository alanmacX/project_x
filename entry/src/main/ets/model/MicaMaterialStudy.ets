/** Read-only study presets. No runtime blur, image decoding, or time-dependent noise. */
export const MICA_STUDY_LABELS:string[]=['现有材质','A · 轻染色','B · 云白混色','C · 浓采色'];
export const MICA_STUDY_NOTES:string[]=['当前正式效果','基底不透明度 70% · 采色混合 32%','基底不透明度 82% · 采色混合 50%','基底不透明度 90% · 采色混合 66%'];
export function micaStudyFill(tint:string,variant:number):string {
 const source=/^#[0-9a-fA-F]{6}$/.test(tint)?tint:'#E8D6B0';
 const index=Math.max(0,Math.min(2,Math.floor(variant)-1)),ratio=[.32,.5,.66][index],alpha=[.70,.82,.90][index];
 const white='#FAF8EF';
 const cloud=[250,248,239],rgb=[1,3,5].map((i:number)=>parseInt(source.slice(i,i+2),16)*ratio+parseInt(white.slice(i,i+2),16)*(1-ratio));
 // Dark photographs must not turn the sampled mica into a dark unreadable label.
 // Test the worst-case black underlay and lift toward cloud white, preserving hue.
 for(let pass=0;pass<12;pass++) {
  const linear=rgb.map((v:number)=>{const c=v*alpha/255;return c<=.04045?c/12.92:Math.pow((c+.055)/1.055,2.4);});
  const luminance=linear[0]*.2126+linear[1]*.7152+linear[2]*.0722;
  if((luminance+.05)/.055>=4.5)break;
  for(let i=0;i<3;i++)rgb[i]=rgb[i]*.85+cloud[i]*.15;
 }
 return '#'+Math.round(alpha*255).toString(16).padStart(2,'0')+rgb.map((v:number)=>Math.round(v).toString(16).padStart(2,'0')).join('');
}

export interface MicaStudySwatch {color:string;weight:number;}
/** Neutral shadows do not drown out a photograph's coloured subject. */
export function micaStudyTint(swatches:MicaStudySwatch[]):string {
 let best='',score=-1;
 for(const swatch of swatches) {
  const rgb=[1,3,5].map((i:number)=>parseInt(swatch.color.slice(i,i+2),16)/255),chroma=Math.max(...rgb)-Math.min(...rgb);
  if(chroma<.16||Math.max(...rgb)<.35)continue;
  const value=swatch.weight*Math.sqrt(chroma);if(value>score){best=swatch.color;score=value;}
 }
 return best||swatches[0]?.color||'#E8D6B0';
}
