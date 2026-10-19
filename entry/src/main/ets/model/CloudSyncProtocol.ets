/** Private same-account journal. Never contains device-local Form IDs or account credentials. */
export interface CloudRevision {
  version:number;entity:string;kind:string;name:string;revision:string;
  clock:Record<string,number>;deleted:boolean;data:string;assets:string[];digest:string;
}
export interface CloudResolution {primary:CloudRevision;copies:CloudRevision[];clock:Record<string,number>;}
export function cloudDominates(a:Record<string,number>,b:Record<string,number>):boolean{
  let greater=false;for(const key of Array.from(new Set(Object.keys(a).concat(Object.keys(b))))){if((a[key]??0)<(b[key]??0))return false;if((a[key]??0)>(b[key]??0))greater=true;}return greater;
}
export function cloudClock(records:CloudRevision[]):Record<string,number>{
  const result:Record<string,number>={};for(const record of records)for(const key of Object.keys(record.clock))result[key]=Math.max(result[key]??0,record.clock[key]);return result;
}
export function cloudResolution(records:CloudRevision[]):CloudResolution{
  if(!records.length)throw new Error('同步记录为空');
  const heads=records.filter(record=>!records.some(other=>other!==record&&cloudDominates(other.clock,record.clock)));
  // Concurrent deletion must never erase an offline edit. Stable revision order
  // makes two devices choose the same primary; every distinct live loser is retained.
  heads.sort((a,b)=>Number(a.deleted)-Number(b.deleted)||a.revision.localeCompare(b.revision));
  const primary=heads[0],copies:CloudRevision[]=[];
  for(const head of heads.slice(1))if(!head.deleted&&head.digest!==primary.digest&&!copies.some(copy=>copy.digest===head.digest))copies.push(head);
  return {primary,copies,clock:cloudClock(heads)};
}
export function validateCloudRevision(raw:CloudRevision):CloudRevision{
  if(!raw||raw.version!==1||!/^[-a-zA-Z0-9_]{1,96}$/.test(raw.entity)||!/^[-a-zA-Z0-9_]{1,96}$/.test(raw.revision)||
    !['canvas','scene','timetable','policy','archive'].includes(raw.kind)||typeof raw.name!=='string'||raw.name.length>100||typeof raw.deleted!=='boolean'||
    typeof raw.data!=='string'||raw.data.length>16*1024*1024||!Array.isArray(raw.assets)||raw.assets.length>512||
    raw.assets.some(key=>typeof key!=='string'||! /^[a-f0-9]{64}\.(png|jpg|jpeg|webp|gif)$/.test(key))||
    typeof raw.digest!=='string'||!/^[a-f0-9]{64}$/.test(raw.digest)||!raw.clock||typeof raw.clock!=='object'||Array.isArray(raw.clock)||
    !Object.keys(raw.clock).length||Object.keys(raw.clock).length>128||Object.keys(raw.clock).some(key=>!/^[-a-zA-Z0-9_]{1,96}$/.test(key)||!Number.isSafeInteger(raw.clock[key])||raw.clock[key]<1))throw new Error('云端同步记录损坏，保留本机作品');
  if(raw.deleted&&(raw.data!==''||raw.assets.length))throw new Error('删除记录不应包含作品');return raw;
}
