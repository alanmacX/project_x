/** Retained gallery refreshes behind the workspace before returning to it. */
export class GalleryAnchor { id:string='';preview:string='';x:number=0;y:number=0;w:number=0;h:number=0; }
export class GalleryController {
  resumePreviews: () => void = () => {};
  pausePreviews: () => void = () => {};
  aspect: (dimension:string,fallback:number) => number = (_dimension:string,fallback:number) => fallback;
  dismiss: () => boolean = () => false;
  cancelWarmPreviews: () => void = () => {};
  warmPreview: (id:string) => void = () => {};
  prepare: (id:string) => Promise<void> = async () => {};
  anchor: (id:string,requireFresh?:boolean) => GalleryAnchor|null = () => null;
  previewReady: (id:string) => boolean = () => false;
}
/** Gallery metadata is detached from the editor and never selects a canvas. */
export class GalleryItem {
  id: string = '';
  name: string = '';
  dimension: string = '';
  aspect: number = 1;
  preview: string = '';
  previewSource: string = '';
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
    JSON.stringify([item.id, item.name, item.dimension, item.aspect, item.preview ? false : item.loaded, item.preview ? false : item.failed, item.preview]))]);
}
export function galleryColumns(width: number): number {
  return width < 360 ? 1 : width >= 1100 ? 4 : width >= 720 ? 3 : 2;
}
export function galleryRows(items: GalleryItem[], filter: string, columns: number): GalleryRow[] {
  const rows: GalleryRow[] = [];
  let pending = new GalleryRow();
  for (const item of items) {
    if (filter && item.dimension !== filter) continue;
    if (item.dimension !== '2*2' && (item.dimension || item.aspect > 1.45) && columns > 1) {
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

/** Use measured launcher rectangles; before a host exists use its usual 4-column grid. */
export function galleryPreviewSize(dimension:string,aspect:number,available:number,rects:Record<string,number[]>):number[]{
  const full=Math.min(available,rects['4*4']?.[0]??344),small=(full-16)/2;
  const measured=rects[dimension];
  const width=Math.min(available,measured?.[0]??(dimension==='2*2'?small:full));
  const ratio=measured&&measured[1]>0?measured[0]/measured[1]:Math.max(.3,aspect);
  return [width,width/ratio];
}
