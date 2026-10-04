/** Native ECMA-402/ICU rules: no network, annual tables or permission prompts. */
export interface ClockCity { value: string; zone: string; }
export const CLOCK_CITIES: ClockCity[] = [
  {value:'北京',zone:'Asia/Shanghai'}, {value:'东京',zone:'Asia/Tokyo'},
  {value:'首尔',zone:'Asia/Seoul'}, {value:'新加坡',zone:'Asia/Singapore'},
  {value:'曼谷',zone:'Asia/Bangkok'}, {value:'迪拜',zone:'Asia/Dubai'},
  {value:'新德里',zone:'Asia/Kolkata'}, {value:'加德满都',zone:'Asia/Kathmandu'},
  {value:'伦敦',zone:'Europe/London'}, {value:'巴黎',zone:'Europe/Paris'},
  {value:'柏林',zone:'Europe/Berlin'}, {value:'纽约',zone:'America/New_York'},
  {value:'洛杉矶',zone:'America/Los_Angeles'}, {value:'温哥华',zone:'America/Vancouver'},
  {value:'悉尼',zone:'Australia/Sydney'}, {value:'阿德莱德',zone:'Australia/Adelaide'},
  {value:'奥克兰',zone:'Pacific/Auckland'}, {value:'檀香山',zone:'Pacific/Honolulu'}
];
export function clockZone(zone:string=''):string { return CLOCK_CITIES.some((city)=>city.zone===zone)?zone:'Asia/Shanghai'; }
export function clockCity(zone:string=''):string { return CLOCK_CITIES.find((city)=>city.zone===clockZone(zone))!.value; }
const formatters:Map<string,Intl.DateTimeFormat>=new Map();
interface OffsetReading { minute:number; offset:number; }
const offsets:Map<string,OffsetReading>=new Map();
function formatter(zone:string):Intl.DateTimeFormat {
  let value=formatters.get(zone);
  if(!value) {value=new Intl.DateTimeFormat('en-US',{timeZone:zone,year:'numeric',month:'2-digit',day:'2-digit',hour:'2-digit',minute:'2-digit',second:'2-digit',hourCycle:'h23'});formatters.set(zone,value);}
  return value;
}
/** TextClock uses the opposite sign to UTC offsets, including supported half/quarter-hour zones. */
export function clockOffset(zone:string,now:number):number {
  zone=clockZone(zone);const minute=Math.floor(now/60000),cached=offsets.get(zone);
  if(cached?.minute===minute)return cached.offset;
  const parts=formatter(zone).formatToParts(new Date(now));
  const field=(key:string):number=>Number(parts.find((part)=>part.type===key)?.value??0);
  const offset=-(Date.UTC(field('year'),field('month')-1,field('day'),field('hour'),field('minute'),field('second'))-Math.floor(now/1000)*1000)/3600000 || 0;
  offsets.set(zone,{minute:minute,offset:offset});return offset;
}
export class CityReading { city:string=''; date:string=''; difference:string=''; }
export function cityReading(zone:string,now:number):CityReading {
  const result=new CityReading(),offset=clockOffset(zone,now),date=new Date(now-offset*3600000),local=new Date(now);
  const localOffset=local.getTimezoneOffset()/60,difference=localOffset-offset;
  result.city=clockCity(zone);
  result.date=(date.getUTCMonth()+1)+'月'+date.getUTCDate()+'日 · '+['周日','周一','周二','周三','周四','周五','周六'][date.getUTCDay()];
  result.difference=Math.abs(difference)<.01?'与本地同一时区':(difference>0?'比本地快 ':'比本地慢 ')+Math.abs(difference)+' 小时';
  return result;
}
export function nextCityMidnight(zone:string,now:number):number {
  const offset=clockOffset(zone,now),date=new Date(now-offset*3600000);
  const midnight=Date.UTC(date.getUTCFullYear(),date.getUTCMonth(),date.getUTCDate()+1);
  let result=midnight+offset*3600000;
  for(let i=0;i<3;i++)result=midnight+clockOffset(zone,result)*3600000;
  return result;
}
/** Prioritize a nearby DST transition; the FormKit caller still honors its 5-minute quota. */
export function nextCityBoundary(zone:string,now:number):number {
  let result=nextCityMidnight(zone,now),end=now+30*60000;
  const offset=clockOffset(zone,now);
  if(clockOffset(zone,end)!==offset) {
    let lo=Math.floor(now/60000),hi=Math.ceil(end/60000);
    while(hi-lo>1) {const mid=Math.floor((lo+hi)/2);if(clockOffset(zone,mid*60000)===offset)lo=mid;else hi=mid;}
    result=Math.min(result,hi*60000);
  }
  return result;
}
export class LunarReading { date:string=''; year:string=''; }
let lunarFormatter:Intl.DateTimeFormat|undefined=undefined;
let lunarKey:string='',lunarValue:LunarReading=new LunarReading();
export function lunarReading(now:number):LunarReading {
  const date=new Date(now),key=date.getFullYear()+':'+date.getMonth()+':'+date.getDate()+':'+date.getTimezoneOffset();
  if(key===lunarKey)return lunarValue;
  lunarFormatter=new Intl.DateTimeFormat('zh-CN-u-ca-chinese',{year:'numeric',month:'long',day:'numeric'});
  const parts=lunarFormatter.formatToParts(date),day=Number(parts.find((part)=>part.type==='day')?.value??0);
  const names:string[]=['','初一','初二','初三','初四','初五','初六','初七','初八','初九','初十','十一','十二','十三','十四','十五','十六','十七','十八','十九','二十','廿一','廿二','廿三','廿四','廿五','廿六','廿七','廿八','廿九','三十'];
  const result=new LunarReading();result.date=(parts.find((part)=>part.type==='month')?.value??'')+' '+(names[day]??'');
  result.year=parts.filter((part)=>String(part.type)==='yearName').map((part)=>part.value).join('')+'年';
  lunarKey=key;lunarValue=result;return result;
}
