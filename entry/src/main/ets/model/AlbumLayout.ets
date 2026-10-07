import { BackgroundAnchor } from './CardSchema';
/** Stable, square cover centred in every card aspect ratio; no runtime animation. */
export function albumCoverSize(width:number,height:number,inset:number=8):number { return Math.max(0,Math.min(width,height)*(1-2*Math.max(0,Math.min(20,inset))/100)); }
export function albumAnchors(palette:string[]):BackgroundAnchor[] {
  const positions:number[][]=[[.18,.24],[.82,.32],[.48,.84]];
  return palette.slice(0,3).map((color:string,i:number):BackgroundAnchor=>({color:color,x:positions[i][0],y:positions[i][1],weight:1}));
}
