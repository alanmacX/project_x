/** Preview geometry uses the rotated bounds, including on short landscape screens. */
export class EditorViewport {
  scale: number = 1;
  left: number = 0;
  top: number = 24;
  height: number = 96;
}
export function editorViewport(cardWidth: number, cardHeight: number, angle: number,
  viewportWidth: number, screenHeight: number, safeTop: number, safeBottom: number, landscape: boolean, paneHeight: number = 0, fringe:number[]=[]): EditorViewport {
  const result = new EditorViewport(), a = angle * Math.PI / 180;
  const c = Math.cos(a), s = Math.sin(a);
  const l=-(fringe[0]??0),t=-(fringe[1]??0),r=cardWidth+(fringe[2]??0),b=cardHeight+(fringe[3]??0);
  const xs:number[]=[l*c-(t-cardHeight)*s,r*c-(t-cardHeight)*s,r*c-(b-cardHeight)*s,l*c-(b-cardHeight)*s];
  const ys:number[]=[cardHeight+l*s+(t-cardHeight)*c,cardHeight+r*s+(t-cardHeight)*c,cardHeight+r*s+(b-cardHeight)*c,cardHeight+l*s+(b-cardHeight)*c];
  const boundsW=Math.max(...xs)-Math.min(...xs),boundsH=Math.max(...ys)-Math.min(...ys);
  const available = Math.max(32, screenHeight - safeTop - safeBottom - (landscape ? 124 : 240));
  const maxHeight = paneHeight > 0 ? Math.max(24, paneHeight - 48) : Math.min(330, available * (landscape ? 1 : .5));
  result.scale = Math.min(maxHeight / boundsH, Math.max(32, viewportWidth - (paneHeight > 0 ? 56 : 96)) / boundsW);
  result.left = (viewportWidth - boundsW * result.scale) / 2 - Math.min(...xs)*result.scale;
  result.top = 24 - Math.min(...ys)*result.scale;
  result.top += paneHeight > 0 ? Math.max(0, (paneHeight - boundsH * result.scale - 48) / 2) : 0;
  result.height = paneHeight > 0 ? paneHeight : boundsH * result.scale + 48;
  return result;
}

/** Short landscape screens spend height on artwork; layer entries become one-line native controls. */
export function editorPreviewPaneHeight(bodyHeight:number,landscape:boolean):number {
  return landscape ? Math.min(300,Math.max(64,bodyHeight-(bodyHeight<320?114:164)),bodyHeight*.58) : Math.min(280,bodyHeight*.36);
}
