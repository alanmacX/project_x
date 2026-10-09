/** Local wall-clock rules. Geometry references artwork; it never duplicates image assets. */
export class ScenePlacement { id:string=''; x:number=0; y:number=0; w:number=180; h:number=180; rot:number=0; z:number=1; }
export class SavedSceneLayout { id:string=''; name:string=''; placements:ScenePlacement[]=[]; }
export class SceneRule {
  id:string=''; name:string=''; enabled:boolean=true;
  kind:string='layout'; targetId:string='';
  repeat:string='daily'; date:string=''; weekdays:number[]=[0,1,2,3,4,5,6];
  start:number=1200; end:number=1380; untilDismissed:boolean=true;
  createdAt:number=0; dismissed:string='';
  timeoutMinutes:number=15; centralOnly:boolean=false; migrationKey:string='';
}
export function sceneDay(date:Date):string {return date.getFullYear()+'-'+String(date.getMonth()+1).padStart(2,'0')+'-'+String(date.getDate()).padStart(2,'0');}
export function validSceneDate(value:string):boolean {
  if(!/^\d{4}-\d{2}-\d{2}$/.test(value))return false;
  const parts=value.split('-').map(Number),date=new Date(parts[0],parts[1]-1,parts[2]);return sceneDay(date)===value;
}
function number(value:number,min:number,max:number,fallback:number):number {return Number.isFinite(value)?Math.max(min,Math.min(max,value)):fallback;}
export function normalizeSceneLayouts(raw:SavedSceneLayout[]|undefined):SavedSceneLayout[] {
  const out:SavedSceneLayout[]=[];
  for(const source of (Array.isArray(raw)?raw:[]).slice(0,8)) {
    if(!source||typeof source.id!=='string'||!source.id||out.some(s=>s.id===source.id))continue;
    const next=new SavedSceneLayout();next.id=source.id.slice(0,96);next.name=(typeof source.name==='string'?source.name:'布局').slice(0,30);
    for(const p of (Array.isArray(source.placements)?source.placements:[]).slice(0,32)) {
      if(!p||typeof p.id!=='string'||next.placements.some(s=>s.id===p.id))continue;
      const item=new ScenePlacement();item.id=p.id.slice(0,96);item.x=number(p.x,-840,1184,0);item.y=number(p.y,-840,1310,0);
      item.w=number(p.w,16,320,180);item.h=number(p.h,16,420,180);item.rot=number(p.rot,-180,180,0);item.z=number(p.z,0,Number.MAX_SAFE_INTEGER,1);next.placements.push(item);
    }
    out.push(next);
  }
  return out;
}
export function normalizeSceneRules(raw:SceneRule[]|undefined):SceneRule[] {
  const out:SceneRule[]=[];
  for(const source of (Array.isArray(raw)?raw:[]).slice(0,12)) {
    if(!source||typeof source.id!=='string'||!source.id||out.some(s=>s.id===source.id)||!['layout','canvas','focus'].includes(source.kind))continue;
    const rule=new SceneRule();rule.id=source.id.slice(0,96);rule.name=(typeof source.name==='string'?source.name:'定时场景').slice(0,30);rule.enabled=source.enabled!==false;
    rule.kind=source.kind;rule.targetId=(typeof source.targetId==='string'?source.targetId:'').slice(0,96);
    rule.repeat=source.repeat==='once'?'once':'daily';rule.date=typeof source.date==='string'&&validSceneDate(source.date)?source.date:'';
    if(rule.repeat==='once'&&!rule.date)rule.enabled=false;
    rule.weekdays=Array.from(new Set((Array.isArray(source.weekdays)?source.weekdays:rule.weekdays).filter((n:number)=>Number.isInteger(n)&&n>=0&&n<7)));
    rule.start=Math.round(number(source.start,0,1439,1200));rule.end=Math.round(number(source.end,0,1439,1380));
    rule.untilDismissed=source.untilDismissed!==false;rule.createdAt=number(source.createdAt,0,Number.MAX_SAFE_INTEGER,0);
    rule.timeoutMinutes=Math.round(number(source.timeoutMinutes,1,120,15));rule.centralOnly=source.centralOnly===true;rule.migrationKey=typeof source.migrationKey==='string'?source.migrationKey.slice(0,200):'';
    rule.dismissed=typeof source.dismissed==='string'?source.dismissed.slice(0,24):'';out.push(rule);
  }
  return out;
}
export function sceneClock(minute:number):string {return String(Math.floor(minute/60)).padStart(2,'0')+':'+String(minute%60).padStart(2,'0');}
