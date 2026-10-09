import { compositionOverflow } from './ReadingComposition';
import { rotatedCanvas, nextCanvasBoundary } from './CanvasRotation';
import { FridgeState, FridgeCard, BOARD_W, BOARD_H } from './CardSchema';
import { SceneRule, SavedSceneLayout, ScenePlacement, sceneDay, normalizeSceneRules } from './SceneScheduleSchema';
import { cardViewSnapshot } from './CardViewSnapshot';
export class SceneOccurrence { rule:SceneRule=new SceneRule(); token:string=''; start:number=0; end:number=0; }
export class ScheduledScene { state:FridgeState=new FridgeState(); ruleId:string=''; occurrence:string=''; key:string='base'; name:string=''; focusId:string=''; baseId:string=''; normalState:FridgeState=new FridgeState(); focusSourceId:string=''; }
function occurrence(rule:SceneRule,day:Date):SceneOccurrence {
  const result=new SceneOccurrence();result.rule=rule;result.token=sceneDay(day);
  const start=new Date(day.getFullYear(),day.getMonth(),day.getDate(),Math.floor(rule.start/60),rule.start%60);
  const end=new Date(day.getFullYear(),day.getMonth(),day.getDate()+(rule.end<=rule.start?1:0),Math.floor(rule.end/60),rule.end%60);
  result.start=start.getTime();result.end=rule.centralOnly?result.start+rule.timeoutMinutes*60000:end.getTime();return result;
}
/** Recent starts win. A focus occurrence remains latched until the user acknowledges it. */
export function activeSceneRule(state:FridgeState,now:number):SceneOccurrence|null {
  if(state.scenePolicyV2){
    let latest:SceneOccurrence|null=null;
    for(const rule of state.sceneRules){
      if(!rule.enabled||!rule.centralOnly||!rule.targetId)continue;
      let current:SceneOccurrence|null=null;
      if(rule.repeat==='once'){const p=rule.date.split('-').map(Number);if(p.length===3)current=occurrence(rule,new Date(p[0],p[1]-1,p[2]));}
      else for(let back=0;back<8;back++){const d=new Date(now);d.setDate(d.getDate()-back);if(!rule.weekdays.includes(d.getDay()))continue;const o=occurrence(rule,d);if(o.start<=now){current=o;break;}}
      // Include expired and acknowledged starts in priority: an older scene must never resume.
      if(current&&current.start<=now&&current.start>=Math.floor(rule.createdAt/60000)*60000&&(!latest||current.start>=latest.start))latest=current;
    }
    return latest&&latest.end>now&&latest.token!==latest.rule.dismissed?latest:null;
  }
  let chosen:SceneOccurrence|null=null;
  for(const rule of state.sceneRules) {
    if(!rule.enabled||!rule.targetId)continue;
    let current:SceneOccurrence|null=null;
    if(rule.repeat==='once') {const p=rule.date.split('-').map(Number);if(p.length===3)current=occurrence(rule,new Date(p[0],p[1]-1,p[2]));}
    else for(let back=0;back<8;back++) {
      const day=new Date(now);day.setDate(day.getDate()-back);if(!rule.weekdays.includes(day.getDay()))continue;
      const candidate=occurrence(rule,day);if(candidate.start<=now){current=candidate;break;}
    }
    if(!current||current.end<=current.start||current.start>now||current.end<=rule.createdAt||current.token===rule.dismissed)continue;
    if(!(rule.kind==='focus'&&rule.untilDismissed&&!rule.centralOnly)&&now>=current.end)continue;
    if(chosen===null||current.start>=chosen.start)chosen=current;
  }
  return chosen;
}
export function nextSceneBoundary(state:FridgeState,now:number):number {
  let next=nextCanvasBoundary(state.canvasRotation,now);
  if(state.scenePolicyV2){
    const active=activeSceneRule(state,now);if(active)next=Math.min(next,active.end);
    for(const rule of state.sceneRules){
      if(!rule.enabled||!rule.centralOnly||!rule.targetId)continue;
      if(rule.repeat==='once'){const p=rule.date.split('-').map(Number);if(p.length!==3)continue;const o=occurrence(rule,new Date(p[0],p[1]-1,p[2]));if(o.start>now&&o.start>=rule.createdAt)next=Math.min(next,o.start);}
      else for(let delta=0;delta<=7;delta++){const d=new Date(now);d.setDate(d.getDate()+delta);if(!rule.weekdays.includes(d.getDay()))continue;const o=occurrence(rule,d);if(o.start>now&&o.start>=rule.createdAt)next=Math.min(next,o.start);}
    }
    return next;
  }
  for(const rule of state.sceneRules) {
    if(!rule.enabled||!rule.targetId)continue;
    if(rule.repeat==='once') {
      const p=rule.date.split('-').map(Number);if(p.length!==3)continue;const o=occurrence(rule,new Date(p[0],p[1]-1,p[2]));
      if(o.end<=o.start)continue;if(o.start>now)next=Math.min(next,o.start);if(o.end>now&&!(rule.kind==='focus'&&rule.untilDismissed&&!rule.centralOnly))next=Math.min(next,o.end);
    } else for(let delta=-1;delta<=8;delta++) {
      const d=new Date(now);d.setDate(d.getDate()+delta);if(!rule.weekdays.includes(d.getDay()))continue;const o=occurrence(rule,d);
      if(o.end<=o.start)continue;if(o.start>now)next=Math.min(next,o.start);if(o.end>now&&!(rule.kind==='focus'&&rule.untilDismissed&&!rule.centralOnly))next=Math.min(next,o.end);
    }
  }
  return next;
}
export function captureSceneLayout(state:FridgeState,id:string,name:string):SavedSceneLayout {
  const layout=new SavedSceneLayout();layout.id=id;layout.name=name;
  layout.placements=state.cards.map((c:FridgeCard):ScenePlacement=>({id:c.id,x:c.x,y:c.y,w:c.w,h:c.h,rot:c.rot,z:c.z}));return layout;
}
/** A named normal layout becomes the editable base, never a temporary scheduled projection. */
export function setNormalSceneLayout(state:FridgeState,id:string):boolean {
  const layout=state.sceneLayouts.find(s=>s.id===id);
  if(id.length>0&&!layout)return false;
  if(layout)state.cards.forEach((card)=>{const p=layout.placements.find(item=>item.id===card.id);if(p){card.x=p.x;card.y=p.y;card.w=p.w;card.h=p.h;card.rot=p.rot;card.z=p.z;}});
  state.sceneBaseLayoutId=id;return true;
}
export function refreshNormalSceneLayout(state:FridgeState):void {
  const layout=state.sceneLayouts.find(s=>s.id===state.sceneBaseLayoutId);
  if(!layout || layout.placements.length!==state.cards.length || state.cards.some(c=>{const p=layout.placements.find(item=>item.id===c.id);return !p || p.x!==c.x || p.y!==c.y || p.w!==c.w || p.h!==c.h || p.rot!==c.rot || p.z!==c.z;}))state.sceneBaseLayoutId='';
}
/** Rotation pivot matches app/widget: bottom left, in physical board units. */
function bounds(card:FridgeCard,height:number,includeAttachments:boolean=false):ScenePlacement {
  const r=card.rot*Math.PI/180,s=Math.sin(r),c=Math.cos(r),ys=height/BOARD_H;
  const fringe=includeAttachments?compositionOverflow(card,1):null;
  const left=-(fringe?.left??0),right=card.w+(fringe?.right??0),top=-(fringe?.top??0),bottom=card.h+(fringe?.bottom??0);
  const us=[left,right,left,right],vs=[top,top,bottom,bottom];
  const xs=us.map((u:number,i:number)=>u*c-(vs[i]-card.h)*s),ysLocal=us.map((u:number,i:number)=>card.h+u*s+(vs[i]-card.h)*c);
  const result=new ScenePlacement();result.x=card.x+Math.min(...xs);result.y=card.y*ys+Math.min(...ysLocal);result.w=Math.max(...xs)-Math.min(...xs);result.h=Math.max(...ysLocal)-Math.min(...ysLocal);return result;
}
export function projectScheduledScene(base:FridgeState,current:SceneOccurrence|null,target:FridgeState|null=null):ScheduledScene {
  const out=new ScheduledScene();out.state=base;out.normalState=base;out.baseId=base.canvasId;if(current===null)return out;
  const rule=current.rule;
  if(rule.kind==='layout'&&!base.sceneLayouts.some(s=>s.id===rule.targetId))return out;
  if(rule.kind==='canvas'&&(target===null||target.canvasId===base.canvasId))return out;
  if(rule.kind==='focus'&&(rule.centralOnly?(!target||target.cards.length!==1):!base.cards.some(c=>c.id===rule.targetId)))return out;
  out.ruleId=rule.id;out.occurrence=current.token;out.key=rule.id+':'+current.token;out.name=rule.name;
  if(rule.kind==='canvas'){out.state=target!;return out;}
  const state=new FridgeState();state.canvasId=base.canvasId;state.background=base.background;state.canvasAspect=base.canvasAspect;state.canvasDimension=base.canvasDimension;state.maxZ=base.maxZ;
  state.cards=base.cards.map(cardViewSnapshot);if(rule.centralOnly&&target){state.cards.push(cardViewSnapshot(target.cards[0]));out.focusSourceId=target.canvasId;}out.state=state;
  if(rule.kind==='layout') {
    const layout=base.sceneLayouts.find(s=>s.id===rule.targetId)!;
    state.cards.forEach((card)=>{const p=layout.placements.find(item=>item.id===card.id);if(p){card.x=p.x;card.y=p.y;card.w=p.w;card.h=p.h;card.rot=p.rot;card.z=p.z;}});return out;
  }
  const height=BOARD_W/base.canvasAspect,ys=height/BOARD_H,focus=rule.centralOnly?state.cards[state.cards.length-1]:state.cards.find(c=>c.id===rule.targetId)!;
  for(const card of state.cards) {
    if(card.id===focus.id)continue;
    const b=bounds(card,height,rule.centralOnly),cx=b.x+b.w/2,cy=b.y+b.h/2;
    const dx=cx-BOARD_W/2,dy=cy-height/2,peek=rule.centralOnly?-Math.max(16,Math.min(b.w,b.h)*.1):Math.min(14,Math.max(5,Math.min(b.w,b.h)*.12));
    if(Math.abs(dx)/(BOARD_W/2)>=Math.abs(dy)/(height/2))card.x+=dx<0?peek-b.x-b.w:BOARD_W-peek-b.x;
    else card.y+=(dy<0?peek-b.y-b.h:height-peek-b.y)/ys;
  }
  focus.rot=0;
  const footprint=bounds(focus,height,rule.centralOnly),factor=Math.min(1,BOARD_W*.72/footprint.w,height*.75/footprint.h);focus.w*=factor;focus.h*=factor;
  const fitted=bounds(focus,height,rule.centralOnly);focus.x+=(BOARD_W/2-fitted.x-fitted.w/2);focus.y+=(height/2-fitted.y-fitted.h/2)/ys;
  focus.z=Math.max(...state.cards.map(c=>c.z))+1;out.focusId=focus.id;return out;
}
export function dismissScene(state:FridgeState,ruleId:string,token:string,now:number):boolean {
  const current=activeSceneRule(state,now);if(!current||current.rule.id!==ruleId||current.token!==token)return false;
  current.rule.dismissed=token;
  // One restore returns the original canvas rather than revealing another overlapping rule.
  for(let i=0;i<state.sceneRules.length;i++){const other=activeSceneRule(state,now);if(!other)break;other.rule.dismissed=other.token;}
  return true;
}
export async function resolveScheduledScene(base:FridgeState,now:number,loadTarget:(id:string)=>Promise<FridgeState|null>):Promise<ScheduledScene> {
  const rules=normalizeSceneRules(base.sceneRules);
  const id=rotatedCanvas(base.canvasRotation,now,base.systemDark===true,base.canvasId);
  const normal=id===base.canvasId?base:await loadTarget(id)??base;
  const policy=new FridgeState();policy.canvasId=normal.canvasId;policy.cards=normal.cards;policy.background=normal.background;policy.canvasAspect=normal.canvasAspect;policy.canvasDimension=normal.canvasDimension;policy.maxZ=normal.maxZ;policy.sceneLayouts=normal.sceneLayouts;policy.sceneRules=rules;policy.canvasRotation=base.canvasRotation;policy.scenePolicyV2=base.scenePolicyV2;policy.systemDark=base.systemDark;
  const current=activeSceneRule(policy,now);
  const target=current&&(current.rule.kind==='canvas'||current.rule.centralOnly)?await loadTarget(current.rule.targetId):null;
  const out=projectScheduledScene(policy,current,target);out.normalState=normal;return out;
}
export function sceneWidgetContext(scene:ScheduledScene):string {
  return scene.ruleId?JSON.stringify({ruleId:scene.ruleId,occurrence:scene.occurrence,baseId:scene.baseId,focusId:scene.focusId}):'';
}
