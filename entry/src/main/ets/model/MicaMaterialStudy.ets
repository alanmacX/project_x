/** Read-only study presets. No runtime blur, image decoding, or time-dependent noise. */
export const MICA_STUDY_LABELS:string[]=['现有材质','A · 轻透云母','B · 云白采色','C · 奶油采色','D · 轻透磨砂','E · 暖白细纸'];
export const MICA_STUDY_NOTES:string[]=['当前正式效果','轻透基底 · 柔和色晕','云白透光 · 局部融色','较低透明度 · 更浓采色','温润透光 · 薄边与细颗粒','柔软暖白 · 纸面与接触厚度'];
export function micaStudyFill(tint:string,variant:number):string {
 const source=/^#[0-9a-fA-F]{6}$/.test(tint)?tint:'#E8D6B0';
 const index=Math.max(0,Math.min(2,Math.floor(variant)-1)),ratio=[.16,.42,.72][index],alpha=[.76,.88,.95][index];
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

/** Concentrated pigment is restricted to a soft corner pool, away from the white light. */
export function micaStudyPigment(tint:string,variant:number,strength:number=1):string {
 const source=/^#[0-9a-fA-F]{6}$/.test(tint)?tint:'#E8D6B0';
 const alpha=[.16,.28,.42][Math.max(0,Math.min(2,Math.floor(variant)-1))]*strength;
 const rgb=[1,3,5].map((i:number)=>parseInt(source.slice(i,i+2),16));
 for(let pass=0;pass<12;pass++) {
  const linear=rgb.map((v:number)=>{const c=v/255;return c<=.04045?c/12.92:Math.pow((c+.055)/1.055,2.4);});
  if(linear[0]*.2126+linear[1]*.7152+linear[2]*.0722>=.36)break;
  for(let i=0;i<3;i++)rgb[i]=rgb[i]*.85+[250,248,239][i]*.15;
 }
 return '#'+Math.round(alpha*255).toString(16).padStart(2,'0')+rgb.map((v:number)=>Math.round(v).toString(16).padStart(2,'0')).join('');
}

/** Preview-only tactile profiles: stable offline texture, no animated noise or backdrop blur. */
export function tactileFill(tint:string,variant:number):string {
 const source=/^#[0-9a-f]{6}$/i.test(tint)?tint:'#E8D6B0';
 const white=[250,248,239],ratio=variant===4?.12:.065;
 const rgb=[1,3,5].map((i:number,index:number)=>Math.round(parseInt(source.slice(i,i+2),16)*ratio+white[index]*(1-ratio)).toString(16).padStart(2,'0')).join('');
 return (variant===4?'#ED':'#FA')+rgb;
}
export function tactilePigment(tint:string,variant:number):string {return micaStudyPigment(tint,2,variant===4?.56:.32);}
export function tactileTextureOpacity(variant:number):number {return variant===4?.14:.32;}
export function tactileEdgeColor(variant:number):string {return variant===4?'#689B8967':'#809D8D70';}
export function tactileThickness(variant:number):number {return variant===4?1.1:1.8;}

/** Host-owned material: experimental IDs never become a portable package field. */
export function readingMaterialVariant(study:number|undefined,material:string|undefined):number {
 return study!==undefined?Math.max(0,Math.min(5,Math.floor(study))):material==='matte'?4:5;
}
