import { AlbumCover, CapBlock } from './CardSchema';
/** Elapsed wall time, not timer counts: app, widget and reopened app agree. */
export function albumLibrary(cap:CapBlock):AlbumCover[] {
  const items=(cap.albumItems??[]).slice();
  if(cap.albumCover&&!items.some(a=>a.cover===cap.albumCover))items.unshift({id:cap.albumId||cap.albumCover,cover:cap.albumCover,background:cap.albumBackground??'',title:cap.title??'',artist:cap.artist??''});
  return items.slice(0,12);
}
export function activeAlbum(cap:CapBlock,now:number=Date.now()):AlbumCover {
  const items=albumLibrary(cap);
  if(!items.length)return {id:'',cover:'',background:'',title:'',artist:''};
  const base=Math.max(0,items.findIndex(a=>a.id===cap.albumId));
  const period=(cap.albumRotationMinutes??0)*60000,start=cap.albumRotationStart??0;
  const steps=period>0&&start>0?Math.floor(Math.max(0,now-start)/period):0;
  return items[(base+steps)%items.length];
}
export function nextAlbumBoundary(cap:CapBlock,now:number):number {
  const period=(cap.albumRotationMinutes??0)*60000,start=cap.albumRotationStart??0;
  return period>0&&start>0&&albumLibrary(cap).length>1?start+(Math.floor(Math.max(0,now-start)/period)+1)*period:Infinity;
}
export function selectAlbum(cap:CapBlock,album:AlbumCover,now:number=Date.now()):CapBlock {
  const next=JSON.parse(JSON.stringify(cap)) as CapBlock;
  next.albumItems=albumLibrary(cap);next.albumId=album.id;next.albumCover=album.cover;next.albumBackground=album.background;next.title=album.title;next.artist=album.artist;next.albumRotationStart=now;
  return next;
}
