/** Per-canvas policy. Existing stored works are never truncated by this limit. */
export const CANVAS_CARD_TARGET: number = 12;
export const CANVAS_CARD_LIMIT: number = 16;

export function assertCanvasCapacity(current: number, incoming: number = 1): void {
  if (!Number.isInteger(current) || !Number.isInteger(incoming) || current < 0 || incoming < 0) {
    throw new Error('卡片数量无效');
  }
  if (current + incoming > CANVAS_CARD_LIMIT) {
    throw new Error('每张画布最多 16 张卡片，请新建画布后添加');
  }
}

export function canvasCapacityHint(count: number): string {
  if (count < CANVAS_CARD_TARGET) return '';
  return count >= CANVAS_CARD_LIMIT ? '已达上限，可新建画布继续创作' : '建议将新作品放到另一张画布';
}
