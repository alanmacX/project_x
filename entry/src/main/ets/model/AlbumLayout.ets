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

/** Approved metadata layouts. Shared by ArkUI and the offline previewer. */
export interface AlbumInfoGeometry {coverX:number;coverY:number;coverSize:number;textX:number;textY:number;textWidth:number;titleSize:number;artistSize:number;artistGap:number;titleLines:number;artistLines:number;centerText:boolean;}
export function albumInfoGeometry(width:number,height:number,style:string):AlbumInfoGeometry {
  const w=Math.max(0,width),h=Math.max(0,height),row=style==='row',s=Math.min(w/(row?300:180),h/(row?150:180)),pad=13.5*s,gap=(row?15:8)*s;
  const cover=row?Math.max(0,Math.min(h-2*pad,w-2*pad-gap-60*s)):97.5*s;
  return {coverX:pad,coverY:pad,coverSize:cover,textX:row?pad+cover+gap:pad,textY:row?h/2:pad+cover+gap,textWidth:Math.max(0,row?w-2*pad-cover-gap:w-2*pad),titleSize:(row?17:15.3)*s,artistSize:(row?14:12.24)*s,artistGap:(row?6:3)*s,titleLines:2,artistLines:row?2:1,centerText:row};
}
