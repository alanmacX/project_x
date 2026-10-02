import { BOARD_W, BOARD_H, FridgeCard, typeLabel } from './CardSchema';
export class SceneRect {
  x: number = 0; y: number = 0; w: number = 0; h: number = 0; rot: number = 0;
}
/** Percent geometry is also usable by the restricted FormKit renderer. */
export function scenePercent(card: FridgeCard, aspect: number): SceneRect {
  const rect = new SceneRect(); rect.x = card.x / BOARD_W * 100; rect.y = card.y / BOARD_H * 100;
  rect.w = card.w / BOARD_W * 100; rect.h = card.h / BOARD_W * aspect * 100; rect.rot = card.rot; return rect;
}
/** One normalized placement system for app and every FormKit size; card proportions stay intact. */
export function sceneRect(card: FridgeCard, width: number, height: number): SceneRect {
  const rect = new SceneRect(), scale = width / BOARD_W;
  rect.x = card.x * scale; rect.y = card.y * height / BOARD_H;
  rect.w = card.w * scale; rect.h = card.h * scale; rect.rot = card.rot; return rect;
}
export function layerLabel(card: FridgeCard): string {
  const text = card.elements.filter(el => el.kind === 'text').map(el => el.text.trim()).filter(value => value.length > 0).join(' ');
  return text.length > 0 ? text : (card.capability?.title || (card.capability !== null ? typeLabel(card.capability.k) : (card.shape === 'subject' ? '主体卡片' : '自定义卡片')));
}
