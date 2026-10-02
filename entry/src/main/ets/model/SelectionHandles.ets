import { ElementBox, ShapePoint } from './CardSchema';
export class SelectionHandles {
  pivot: ShapePoint = { x: 0, y: 0 };
  resize: ShapePoint = { x: 0, y: 0 };
  rotate: ShapePoint = { x: 0, y: 0 };
}
/** Controls live in the viewport, outside small element hit regions. */
export function selectionHandles(box: ElementBox, width: number, height: number, angle: number,
  viewportWidth: number, viewportHeight: number, left: number = (viewportWidth - width) / 2, top: number = 24): SelectionHandles {
  const result = new SelectionHandles(), a = box.rot * Math.PI / 180, b = angle * Math.PI / 180;
  const cx = (box.x + box.w / 2) * width, cy = (box.y + box.h / 2) * height;
  const transform = (dx: number, dy: number): ShapePoint => {
    const x = cx + dx * Math.cos(a) - dy * Math.sin(a), y = cy + dx * Math.sin(a) + dy * Math.cos(a);
    return { x: left + x * Math.cos(b) - (y - height) * Math.sin(b),
      y: top + height + x * Math.sin(b) + (y - height) * Math.cos(b) };
  };
  const clamp = (point: ShapePoint): ShapePoint => ({ x: Math.max(22, Math.min(viewportWidth - 22, point.x)),
    y: Math.max(22, Math.min(viewportHeight - 22, point.y)) });
  result.pivot = transform(0, 0);
  // Keep the 44vp control outside the element: tiny layers must retain a
  // body hit region for moving instead of being covered by the resize button.
  result.resize = clamp(transform(box.w * width / 2 + 26, box.h * height / 2 + 26));
  result.rotate = clamp(transform(0, -box.h * height / 2 - Math.max(24, 52 - box.h * height)));
  const dx = result.rotate.x - result.resize.x, dy = result.rotate.y - result.resize.y;
  if (dx * dx + dy * dy < 52 * 52) {
    result.rotate = { x: result.resize.x - 52 >= 22 ? result.resize.x - 52 : result.resize.x + 52, y: result.resize.y };
  }
  return result;
}
