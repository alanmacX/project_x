import { isReadingComposition } from './ReadingComposition';
import { edgeAttachment } from './EdgeAttachment';
import { cardOutline } from './RenderContours';
import { FridgeCard } from './CardSchema';
import { subjectSurfaceFactor, capabilityPlacement } from './CanvasLayout';

/** Local face coordinates, after ArkUI has inverted the card's display transform. */
export function cardContainsPoint(card: FridgeCard, x: number, y: number, scale: number): boolean {
  const w = card.w * scale, h = card.h * scale;
  if(w<=0||h<=0||!Number.isFinite(x)||!Number.isFinite(y))return false;
  // Foreground is part of its card, including attachments outside the silhouette.
  if(card.capability!==null&&card.capability.k!=='album') {
    const original=capabilityPlacement(card),blend=card.capability.readingBlend??'';
    const box=blend==='sticker'?edgeAttachment(card,original,card.capability.readingEdge||'left',card.capability.readingOutside===true).box:original;
    const a=(blend==='sticker'?0:box.rot)*Math.PI/180,cx=(box.x+box.w/2)*w,cy=(box.y+box.h/2)*h;
    const dx=x-cx,dy=y-cy,px=dx*Math.cos(a)+dy*Math.sin(a),py=-dx*Math.sin(a)+dy*Math.cos(a);
    const padding=isReadingComposition(blend)?4*scale:0;
    if(box.opacity>0&&Math.abs(px)<=box.w*w/2+padding&&Math.abs(py)<=box.h*h/2+padding)return true;
  }
  if(x<0||y<0||x>w||y>h)return false;
  if (card.shape === 'subject' && cardOutline(card).length > 0) {
    const f = subjectSurfaceFactor(card), ox = (1 - f) * w / 2, oy = (1 - f) * h / 2;
    let inside = false;
    for (const loop of cardOutline(card)) {
      for (let i = 0, j = loop.length - 1; i < loop.length; j = i++) {
        const ax = ox + loop[j].x * w * f, ay = oy + loop[j].y * h * f;
        const bx = ox + loop[i].x * w * f, by = oy + loop[i].y * h * f;
        if ((ay > y) !== (by > y) && x < ax + (bx - ax) * (y - ay) / (by - ay)) inside = !inside;
        // Include the visible white outline, rather than its transparent bounding rectangle.
        if (card.subjectBorder) {
          const dx = bx - ax, dy = by - ay, length = dx * dx + dy * dy;
          const t = length > 0 ? Math.max(0, Math.min(1, ((x - ax) * dx + (y - ay) * dy) / length)) : 0;
          if ((x - ax - t * dx) ** 2 + (y - ay - t * dy) ** 2 <= (3 * scale) ** 2) return true;
        }
      }
    }
    return inside;
  }
  if (card.shape === 'round') return ((x - w / 2) / (w / 2)) ** 2 + ((y - h / 2) / (h / 2)) ** 2 <= 1;
  let rx = Math.min(16, w / 2), ry = Math.min(16, h / 2);
  if (card.shape === 'pill') { rx = Math.min(w, h) / 2; ry = rx; }
  if (card.shape === 'blob') {
    const fraction = y < h / 2 ? (x < w / 2 ? .28 : .12) : (x < w / 2 ? .18 : .26);
    rx = fraction * w; ry = fraction * h;
  }
  const cx = x < rx ? rx : (x > w - rx ? w - rx : x);
  const cy = y < ry ? ry : (y > h - ry ? h - ry : y);
  return rx <= 0 || ry <= 0 || ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1;
}
