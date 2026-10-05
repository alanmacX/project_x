import { FridgeState, FridgeCard, normalizeState, defaultState, BOARD_W, BOARD_H } from './CardSchema';
import { assertCanvasCapacity } from './CanvasCapacity';
export interface TemplateSummary { kind: string; count: number; images: number; }
export interface TemplateAsset { key: string; extension: string; data: string; }
export interface TemplatePackage { format: string; version: number; kind: string; state: FridgeState; assets: TemplateAsset[]; }
export function packageScene(json: string, cardId: string): TemplatePackage {
  const state=normalizeState(JSON.parse(json) as FridgeState);
  if(cardId.length>0){state.cards=state.cards.filter((c:FridgeCard)=>c.id===cardId);if(state.cards.length!==1)throw new Error('卡片不存在');state.cards[0].groupId='';state.background=defaultState().background;}
  state.canvasId='canvas_main';
  for(const card of state.cards){const cap=card.capability;if(cap?.k==='battery'){cap.percent=-1;cap.charging=false;cap.chargeState='';cap.updatedAt=0;cap.attemptedAt=0;}if(cap?.k==='parcel'){cap.parcels=[];cap.parcelPlace='';}if(cap?.k==='agenda'&&cap.agendaSource==='system'){cap.events=[];cap.updatedAt=0;cap.attemptedAt=0;}}
  return {format:'fridgememo-template',version:1,kind:cardId.length>0?'card':'canvas',state:state,assets:[]};
}
export function readPackage(json: string): TemplatePackage {
  if(json.length>90*1024*1024)throw new Error('作品包超过大小限制');
  const raw=JSON.parse(json) as TemplatePackage;
  if(raw.format!=='fridgememo-template'||raw.version!==1||!['card','canvas'].includes(raw.kind)||raw.state?.schemaVersion!==2||!Array.isArray(raw.state?.cards)||raw.state.cards.length>128||!Array.isArray(raw.assets)||raw.assets.length>256)throw new Error('不是支持的作品包');
  assertCanvasCapacity(0, raw.state.cards.length);
  if(raw.kind==='card'&&raw.state.cards.length!==1)throw new Error('卡片包内容不完整');
  const keys:string[]=[];for(const a of raw.assets){if(typeof a.key!=='string'||keys.includes(a.key)||!/^asset:\/\/\d+$/.test(a.key)||!/^\.(png|jpg|jpeg|gif|webp)$/.test(a.extension)||typeof a.data!=='string'||a.data.length>32*1024*1024)throw new Error('作品图片无效');keys.push(a.key);}
  const refs:string[]=[raw.state.background?.src??'',raw.state.background?.photo??''];
  for(const c of raw.state.cards){refs.push(c.cutout??'',c.capability?.albumCover??'',c.capability?.albumBackground??'');for(const el of c.elements??[])refs.push(el.src??'');}
  if(refs.some((src:string)=>src.length>0&&!keys.includes(src)))throw new Error('作品图片引用不完整');
  // Normal runtime schemas intentionally reject package-local asset URIs.
  // Normalize their temporary file representation, then restore the validated keys.
  const swap=(from:string,to:string):void=>{
    const bg=raw.state.background;if(bg!==undefined){if(bg.src===from)bg.src=to;if(bg.photo===from)bg.photo=to;}
    for(const c of raw.state.cards){if(c.cutout===from)c.cutout=to;if(c.capability){if(c.capability.albumCover===from)c.capability.albumCover=to;if(c.capability.albumBackground===from)c.capability.albumBackground=to;}for(const el of c.elements??[])if(el.src===from)el.src=to;}
  };
  for(const c of raw.state.cards){if(typeof c.id!=='string'||(c.elements??[]).length>128||(c.outline??[]).length>128||(c.outline??[]).reduce((sum:number,row)=>sum+row.length,0)>16384)throw new Error('作品图层或轮廓过多');}
  for(const key of keys)swap(key,'file:///template/'+key.slice(8));
  raw.state=normalizeState(raw.state);
  for(const key of keys)swap('file:///template/'+key.slice(8),key);
  return raw;
}
/** Remap every identifier; importing twice never aliases a card, element or group. */
export function importedCards(state:FridgeState,newId:()=>string):FridgeCard[]{
  const cards=normalizeState(JSON.parse(JSON.stringify(state)) as FridgeState).cards,groups=new Map<string,string>();
  for(const c of cards){c.id=newId();if(c.groupId.length>0){if(!groups.has(c.groupId))groups.set(c.groupId,newId());c.groupId=groups.get(c.groupId)??'';}c.elements.forEach(el=>{el.id=newId();});c.renderContourKey='';}
  return cards;
}

/** Fit a shared composition as one scene; do not stretch its relative card positions. */
export function fitImportedCanvas(cards:FridgeCard[],sourceAspect:number,targetAspect:number):void {
  const sourceH=BOARD_W/sourceAspect,targetH=BOARD_W/targetAspect;
  const scale=Math.min(1,targetH/sourceH),left=BOARD_W*(1-scale)/2,top=(targetH-sourceH*scale)/2;
  for(const c of cards){c.x=c.x*scale+left;c.y=(c.y/BOARD_H*sourceH*scale+top)/targetH*BOARD_H;c.w*=scale;c.h*=scale;}
}
