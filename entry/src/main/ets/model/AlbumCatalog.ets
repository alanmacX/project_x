export const ALBUM_USER_AGENT:string='FridgeMemo/1.0 (https://github.com/alanmacX/project_x)';
export interface AlbumResult { id:string; title:string; artist:string; year:string; }
interface ArtistCredit { name?:string; artist?:AlbumArtist; }
interface AlbumArtist { name?:string; }
export function albumSearchURL(term:string):string {
  const words=term.trim().slice(0,120).split(/\s+/).filter((s:string)=>s.length>0).map((s:string)=>'"'+s.replace(/["\\]/g,'')+'"');
  if(words.length===0)throw new Error('请输入专辑名或歌手');
  return 'https://musicbrainz.org/ws/2/release-group/?fmt=json&limit=20&query='+encodeURIComponent(words.map((word:string)=>'(releasegroup:'+word+' OR artist:'+word+')').join(' AND ')+' AND primarytype:album');
}
export function parseAlbums(json:string):AlbumResult[] {
  const raw=JSON.parse(json) as Record<string,Object>;
  if(!Array.isArray(raw['release-groups']))throw new Error('专辑目录返回异常');
  const ids=new Set<string>();const albums:AlbumResult[]=[];
  for(const r of raw['release-groups'] as Record<string,Object>[]) {
    if(typeof r['id']!=='string'||! /^[0-9a-f-]{36}$/.test(r['id'] as string)||typeof r['title']!=='string'||ids.has(r['id'] as string))continue;
    ids.add(r['id'] as string);albums.push({id:r['id'] as string,title:(r['title'] as string).slice(0,160),artist:((r['artist-credit']??[]) as ArtistCredit[]).map((a:ArtistCredit)=>a.name??a.artist?.name??'').join(' / ').slice(0,160),year:((r['first-release-date']??'') as string).slice(0,4)});
  }
  return albums.slice(0,20);
}
export function albumCoverURL(id:string):string {
  if(!/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/.test(id))throw new Error('专辑编号无效');
  return 'https://coverartarchive.org/release-group/'+id+'/front-500';
}
