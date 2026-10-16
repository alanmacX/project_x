/** Gallery metadata is detached from the editor and never selects a canvas. */
export class GalleryItem {
  id: string = '';
  name: string = '';
  dimension: string = '';
  aspect: number = 1;
  preview: string = '';
  loaded: boolean = false;
  failed: boolean = false;
}
export class GalleryRow {
  id: string = '';
  wide: boolean = false;
  items: GalleryItem[] = [];
}
/** ArkUI retains keyed builder arguments; replace a row when its async preview data settles. */
export function galleryRowKey(row: GalleryRow): string {
  return JSON.stringify([row.id, row.wide, row.items.map((item: GalleryItem): string =>
    JSON.stringify([item.id, item.name, item.dimension, item.aspect, item.loaded, item.failed, item.preview]))]);
}
export function galleryColumns(width: number): number {
  return width < 360 ? 1 : width >= 1100 ? 4 : width >= 720 ? 3 : 2;
}
export function galleryRows(items: GalleryItem[], filter: string, columns: number): GalleryRow[] {
  const rows: GalleryRow[] = [];
  let pending = new GalleryRow();
  for (const item of items) {
    if (filter && item.dimension !== filter) continue;
    if (item.aspect > 1.45 && columns > 1) {
      if (pending.items.length) { rows.push(pending); pending = new GalleryRow(); }
      const row = new GalleryRow(); row.id = item.id; row.wide = true; row.items = [item]; rows.push(row);
    } else {
      if (!pending.items.length) pending.id = item.id;
      pending.items.push(item);
      if (pending.items.length === columns) { rows.push(pending); pending = new GalleryRow(); }
    }
  }
  if (pending.items.length) rows.push(pending);
  return rows;
}
