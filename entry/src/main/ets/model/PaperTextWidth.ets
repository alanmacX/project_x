const widths=new Map<string,number>();
/** Shared conservative system-font advances in vp. FormKit has no UIContext;
 * measuring through getUIContext() aborts card construction in its renderer.
 * Both hosts use this same metric, including digits reserved for changing data. */
export function paperTextWidth(text:string,font:number,weight:number=400):number {
  const key=font+':'+weight+':'+text,cached=widths.get(key);if(cached!==undefined)return cached;
  let em=0;
  for(const char of text) {
    const cp=char.codePointAt(0)??0;
    if(cp>=0x2E80)em+=1;
    else if(/[0-9]/.test(char))em+=.63;
    else if(/[ilI.,:;'!|]/.test(char))em+=.3;
    else if(/[MW@%]/.test(char))em+=.92;
    else if(/\s/.test(char))em+=.32;
    else em+=.62;
  }
  const width=Math.ceil(em*font*(weight>=500?1.025:1));
  if(widths.size>=256)widths.clear();widths.set(key,width);return width;
}
