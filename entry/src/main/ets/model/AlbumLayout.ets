import { BackgroundAnchor, ALBUM_CORNER_RADIUS, ALBUM_INSET } from './CardSchema';
/** Stable, square cover centred in every card aspect ratio; no runtime animation. */
export function albumCoverSize(width:number,height:number,inset:number=ALBUM_INSET):number { return Math.max(0,Math.min(width,height)*(1-2*Math.max(0,Math.min(20,inset))/100)); }
/** Original subtle artwork corner; clamp for very small artwork. */
export function albumCoverRadius(width:number,height:number,inset:number=ALBUM_INSET):number {return Math.min(ALBUM_CORNER_RADIUS,albumCoverSize(width,height,inset)/2);}
export function albumAnchors(palette:string[]):BackgroundAnchor[] {
  const positions:number[][]=[[.18,.24],[.82,.32],[.48,.84]];
  return palette.slice(0,3).map((color:string,i:number):BackgroundAnchor=>({color:color,x:positions[i][0],y:positions[i][1],weight:1}));
}

/** Album artwork is square; reject other ratios before decoding or creating assets. */
export function isSquareAlbumCover(width:number,height:number):boolean {return Number.isInteger(width)&&width>0&&width===height;}

/** Study layouts are not persisted until a design is chosen. All cover geometry remains square. */
export interface AlbumInfoGeometry {coverX:number;coverY:number;coverSize:number;textX:number;textY:number;textWidth:number;titleSize:number;artistSize:number;}
export function albumInfoGeometry(width:number,height:number,style:string):AlbumInfoGeometry {
  const w=Math.max(0,width),h=Math.max(0,height),pad=Math.min(16,w*.075,h*.075);
  if(style==='row') {
    const cover=Math.max(0,Math.min(h-2*pad,w*.43));
    return {coverX:pad,coverY:(h-cover)/2,coverSize:cover,textX:pad+cover+12,textY:h*.36,textWidth:Math.max(0,w-2*pad-cover-12),titleSize:Math.min(17,w*.072),artistSize:Math.min(14,w*.06)};
  }
  const large=style==='portrait',size=Math.max(0,Math.min(w-2*pad,h*(large?.66:.49)));
  return {coverX:pad,coverY:pad,coverSize:size,textX:pad,textY:pad+size+(large?10:16),textWidth:Math.max(0,w-2*pad),titleSize:Math.min(18,w*.085),artistSize:Math.min(15,w*.068)};
}
