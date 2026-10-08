import { edgeStudyPath } from './ReadingEdgeStudy';
/** Cloud decoration grows outside the existing 8vp reading gutter, not into the text core. */
export const CLOUD_READING_PADDING:number=8;
export const CLOUD_READING_OUTSET:number=16;
// Renderers cap content scale at 2; include stroke + offset thickness in all export/cache bounds.
export const CLOUD_READING_FRINGE:number=CLOUD_READING_OUTSET*2+4;
export function cloudReadingPath(w:number,h:number,scale:number):string {
 return edgeStudyPath(0,w+2*CLOUD_READING_OUTSET*scale,h+2*CLOUD_READING_OUTSET*scale,scale);
}
