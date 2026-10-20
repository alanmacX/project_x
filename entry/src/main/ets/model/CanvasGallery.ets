/** Retained gallery refreshes behind the workspace before returning to it. */
export class GalleryAnchor { id:string='';preview:string='';x:number=0;y:number=0;w:number=0;h:number=0; }
/** Match the gallery's title/content inset and floating creation dock, in vp. */
export function galleryReturnTargetVisible(anchor:GalleryAnchor|null,width:number,height:number,safeTop:number,safeBottom:number):boolean{
  if(!anchor||![anchor.x,anchor.y,anchor.w,anchor.h,width,height,safeTop,safeBottom].every((value:number)=>Number.isFinite(value)))return false;
  return anchor.w>0&&anchor.h>0&&anchor.x>=0&&anchor.x+anchor.w<=width&&anchor.y>=safeTop+76&&anchor.y+anchor.h<=height-safeBottom-104;
}
export class GalleryController {
  refreshVisible: () => void = () => {};
  resumePreviews: () => void = () => {};
  pausePreviews: () => void = () => {};
  aspect: (dimension:string,fallback:number) => number = (_dimension:string,fallback:number) => fallback;
  dismiss: () => boolean = () => false;
  cancelWarmPreviews: () => void = () => {};
  warmPreview: (id:string) => void = () => {};
  prepare: (id:string) => Promise<void> = async () => {};
  anchor: (id:string,requireFresh?:boolean) => GalleryAnchor|null = () => null;
  previewReady: (id:string) => boolean = () => false;
  preview: (id:string) => string = () => '';
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
export class GalleryPlacement {
  item:GalleryItem=new GalleryItem();
  x:number=0;y:number=0;w:number=0;h:number=0;
}
/** Grid cells keep small canvases half the width of large ones, with a shared gutter. */
export function galleryColumns(width:number):number{return width>=1000?6:width>=600?4:width>=260?3:2;}
function galleryUnit(available:number,rects:Record<string,number[]>):number{
  const columns=galleryColumns(available),nativeFull=rects['4*4']?.[0]??344;
  return Math.max(1,Math.min((nativeFull-16)/2,(available-(columns-1)*16)/columns));
}
export function galleryPreviewSize(dimension:string,aspect:number,available:number,rects:Record<string,number[]>):number[]{
  const unit=galleryUnit(available,rects),width=dimension==='2*2'?unit:unit*2+16;
  const measured=rects[dimension],ratio=measured&&measured[0]>0&&measured[1]>0?measured[0]/measured[1]:Math.max(.3,aspect);
  return [width,width/ratio];
}
/** Lowest contiguous skyline slot: O(items × columns), stable ties read left to right. */
export function galleryLayout(items:GalleryItem[],filter:string,available:number,rects:Record<string,number[]>,renameId:string=''):GalleryPlacement[]{
  const columns=galleryColumns(available),unit=galleryUnit(available,rects),lanes:number[]=Array(columns).fill(0),out:GalleryPlacement[]=[];
  for(const item of items){
    if(filter&&item.dimension!==filter)continue;
    const span=item.dimension==='2*2'?1:2,size=galleryPreviewSize(item.dimension,item.aspect,available,rects);
    let best=0,y=Number.POSITIVE_INFINITY;
    for(let col=0;col<=columns-span;col++){
      let top=0;for(let slot=col;slot<col+span;slot++)top=Math.max(top,lanes[slot]);
      if(top<y){best=col;y=top;}
    }
    const placement=new GalleryPlacement();placement.item=item;placement.x=best*(unit+16);placement.y=y;placement.w=size[0];placement.h=size[1]+(item.id===renameId?108:60);out.push(placement);
    for(let col=best;col<best+span;col++)lanes[col]=y+placement.h+20;
  }
  const right=Math.max(0,...out.map((entry:GalleryPlacement)=>entry.x+entry.w)),inset=Math.max(0,(available-right)/2);
  for(const entry of out)entry.x+=inset;
  return out;
}
/** Refresh captured ArkUI builder inputs only when their pixels, label or geometry change. */
export function galleryPlacementKey(value:GalleryPlacement):string{
  const item=value.item;
  return JSON.stringify([item.id,item.name,item.dimension,item.aspect,item.preview,item.preview?false:item.loaded,item.preview?false:item.failed,value.x,value.y,value.w,value.h]);
}
