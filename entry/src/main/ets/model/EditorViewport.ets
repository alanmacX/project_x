/** Preview geometry uses the rotated bounds, including on short landscape screens. */
export class EditorViewport {
  scale: number = 1;
  left: number = 0;
  top: number = 24;
  height: number = 96;
}
export function editorViewport(cardWidth: number, cardHeight: number, angle: number,
  viewportWidth: number, screenHeight: number, safeTop: number, safeBottom: number, landscape: boolean, paneHeight: number = 0): EditorViewport {
  const result = new EditorViewport(), a = angle * Math.PI / 180;
  const c = Math.cos(a), s = Math.sin(a);
  const boundsW = Math.abs(cardWidth * c) + Math.abs(cardHeight * s);
  const boundsH = Math.abs(cardHeight * c) + Math.abs(cardWidth * s);
  const available = Math.max(32, screenHeight - safeTop - safeBottom - (landscape ? 124 : 240));
  const maxHeight = paneHeight > 0 ? Math.max(24, paneHeight - 48) : Math.min(330, available * (landscape ? 1 : .5));
  result.scale = Math.min(440 / cardWidth, maxHeight / boundsH, Math.max(32, viewportWidth - (paneHeight > 0 ? 56 : 96)) / boundsW);
  const w = cardWidth * result.scale, h = cardHeight * result.scale;
  const xs: number[] = [0, h * s, w * c + h * s, w * c];
  const ys: number[] = [h, h - h * c, h + w * s - h * c, h + w * s];
  result.left = (viewportWidth - boundsW * result.scale) / 2 - Math.min(...xs);
  result.top = 24 - Math.min(...ys);
  result.top += paneHeight > 0 ? Math.max(0, (paneHeight - boundsH * result.scale - 48) / 2) : 0;
  result.height = paneHeight > 0 ? paneHeight : boundsH * result.scale + 48;
  return result;
}

/** Short landscape screens spend height on artwork; layer entries become one-line native controls. */
export function editorPreviewPaneHeight(bodyHeight:number,landscape:boolean):number {
  return landscape ? Math.min(300,Math.max(64,bodyHeight-(bodyHeight<320?114:164)),bodyHeight*.58) : Math.min(280,bodyHeight*.36);
}
