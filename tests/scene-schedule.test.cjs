const assert=require('node:assert/strict'),fs=require('node:fs'),path=require('node:path'),vm=require('node:vm');
const ts=require('/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript');
const root=path.resolve(__dirname,'../entry/src/main/ets/model'),cache=new Map();
function load(name){const file=path.resolve(root,name+'.ets');if(cache.has(file))return cache.get(file).exports;const mod={exports:{}};cache.set(file,mod);const code=ts.transpileModule(fs.readFileSync(file,'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText;vm.runInThisContext('(function(require,module,exports){'+code+'\n})',{filename:file})(s=>s==='@kit.ArkTS'?{taskpool:{}}:load(path.relative(root,path.resolve(path.dirname(file),s))),mod,mod.exports);return mod.exports;}
const schema=load('CardSchema'),rules=load('SceneScheduleSchema'),engine=load('SceneSchedule'),storage=load('StorageSnapshot');
const at=s=>new Date(s).getTime();
const state=new schema.FridgeState();state.cards=Array.from({length:32},(_,i)=>{const c=new schema.FridgeCard();c.id='c'+i;c.x=i%4*70;c.y=Math.floor(i/4)*40;c.w=90;c.h=110;c.rot=i%2?25:-12;c.z=i;return c;});
const raw=JSON.stringify(state),layout=engine.captureSceneLayout(state,'layout','夜间');layout.placements.forEach(p=>{p.x+=10;p.rot=15;});state.sceneLayouts=[layout];
const rule=new rules.SceneRule();rule.id='rule';rule.kind='layout';rule.targetId='layout';rule.weekdays=[1];rule.start=23*60;rule.end=60;state.sceneRules=[rule];
assert.equal(engine.activeSceneRule(state,at('2026-10-05T22:59:59')),null);
const active=engine.activeSceneRule(state,at('2026-10-06T00:30:00'));assert.equal(active.token,'2026-10-05');
assert.equal(engine.activeSceneRule(state,at('2026-10-06T01:00:00')),null,'end is exclusive');
assert.equal(engine.nextSceneBoundary(state,at('2026-10-06T00:30:00')),at('2026-10-06T01:00:00'));
let display=engine.projectScheduledScene(state,active);assert.equal(display.state.cards[0].x,state.cards[0].x+10);assert.equal(display.state.cards[0].rot,15);assert.equal(state.cards[0].rot,-12);
const encoded=storage.storageSnapshot(state),restored=schema.normalizeState(JSON.parse(encoded));assert.equal(restored.sceneRules.length,1);assert.equal(restored.sceneLayouts[0].placements.length,32);
const original=JSON.stringify(state);rule.kind='focus';rule.targetId='c0';rule.repeat='once';rule.date='2026-10-05';rule.start=18*60;rule.end=19*60;rule.untilDismissed=true;
const focus=engine.activeSceneRule(state,at('2026-10-07T09:00:00'));assert.ok(focus,'one-off focus survives its end and app restart until acknowledged');
display=engine.projectScheduledScene(state,focus);assert.equal(display.focusId,'c0');assert.equal(display.state.cards[0].rot,0);assert.equal(display.state.cards[0].x,(schema.BOARD_W-display.state.cards[0].w)/2);
assert.equal(state.cards[0].x,0);assert.equal(state.cards[0].rot,-12,'projection never edits source artwork');
for(const c of display.state.cards.slice(1)) {
 const h=schema.BOARD_W/state.canvasAspect,y=c.y*h/schema.BOARD_H,r=c.rot*Math.PI/180;
 const xs=[c.x,c.x+c.w*Math.cos(r),c.x+c.h*Math.sin(r),c.x+c.w*Math.cos(r)+c.h*Math.sin(r)];
 const ys=[y+c.h,y+c.h+c.w*Math.sin(r),y+c.h-c.h*Math.cos(r),y+c.h+c.w*Math.sin(r)-c.h*Math.cos(r)];
 const overlapX=Math.min(schema.BOARD_W,Math.max(...xs))-Math.max(0,Math.min(...xs));
 const overlapY=Math.min(h,Math.max(...ys))-Math.max(0,Math.min(...ys));
 assert.ok(overlapX<=14.000001||overlapY<=14.000001,'swept cards leave only a bounded sliver at the edge');
}
assert.equal(engine.dismissScene(state,'wrong',focus.token,at('2026-10-07T09:00:00')),false);
assert.equal(engine.dismissScene(state,'rule','2026-10-04',at('2026-10-07T09:00:00')),false,'stale widget occurrence cannot dismiss a newer rule');
assert.equal(engine.dismissScene(state,'rule',focus.token,at('2026-10-07T09:00:00')),true);assert.equal(engine.activeSceneRule(state,at('2026-10-07T09:00:00')),null);
rule.createdAt=at('2026-10-06T00:00:00');rule.dismissed='';assert.equal(engine.activeSceneRule(state,at('2026-10-07T09:00:00')),null,'new rule does not replay finished occurrences');
rule.kind='canvas';rule.targetId='other';rule.createdAt=0;rule.untilDismissed=false;rule.repeat='daily';rule.weekdays=[0,1,2,3,4,5,6];rule.start=8*60;rule.end=10*60;
const target=new schema.FridgeState();target.canvasId='other';target.cards=[new schema.FridgeCard()];target.cards[0].id='other-card';
const o=engine.activeSceneRule(state,at('2026-10-05T09:00:00'));display=engine.projectScheduledScene(state,o,target);assert.equal(display.state,target);assert.equal(display.baseId,state.canvasId);
assert.equal(engine.projectScheduledScene(state,o,null).key,'base','removed target falls back to original');
const newer=new rules.SceneRule();Object.assign(newer,rule,{id:'newer',kind:'focus',targetId:'c1',start:9*60,end:11*60});state.sceneRules.push(newer);
assert.equal(engine.activeSceneRule(state,at('2026-10-05T09:30:00')).rule.id,'newer');assert.ok(engine.dismissScene(state,'newer','2026-10-05',at('2026-10-05T09:30:00')));assert.equal(engine.activeSceneRule(state,at('2026-10-05T09:30:00')),null,'restore clears overlapping occurrences and returns original');
const invalid=rules.normalizeSceneRules([{...rule,id:'bad',repeat:'once',date:'2026-02-30',start:NaN,weekdays:[-1,8,2,2]}])[0];assert.equal(invalid.enabled,false);assert.deepEqual(invalid.weekdays,[2]);
assert.equal(rules.normalizeSceneRules(Array.from({length:30},(_,i)=>({...rule,id:'r'+i}))).length,12);
rule.enabled=true;rule.dismissed='';rule.repeat='daily';rule.start=9*60;rule.end=9*60;state.sceneRules=[rule];assert.ok(engine.activeSceneRule(state,at('2026-10-05T18:00:00')),'equal times define a full-day interval');
// Acknowledged repeats are eligible again on their next occurrence.
newer.repeat='daily';newer.weekdays=[0,1,2,3,4,5,6];newer.start=9*60;newer.end=10*60;newer.untilDismissed=true;newer.dismissed='2026-10-05';newer.createdAt=0;state.sceneRules=[newer];
assert.equal(engine.activeSceneRule(state,at('2026-10-05T12:00:00')),null);assert.equal(engine.activeSceneRule(state,at('2026-10-06T09:00:00')).token,'2026-10-06');
const absent=new rules.SceneRule();Object.assign(absent,newer,{id:'absent',kind:'layout',targetId:'layout',dismissed:''});
const withNewCard=new schema.FridgeState();withNewCard.cards=[...state.cards.slice(0,2),new schema.FridgeCard()];withNewCard.cards[2].id='added-later';withNewCard.sceneLayouts=[layout];
const projected=engine.projectScheduledScene(withNewCard,{rule:absent,token:'day',start:0,end:1});assert.equal(projected.state.cards[2].x,withNewCard.cards[2].x,'cards added after capture keep their base geometry');
const originalTimezone=process.env.TZ;process.env.TZ='America/New_York';
const dstState=new schema.FridgeState(),dstRule=new rules.SceneRule();Object.assign(dstRule,{id:'dst',targetId:'layout',start:150,end:180});dstState.sceneRules=[dstRule];
assert.equal(engine.activeSceneRule(dstState,new Date('2026-03-08T03:45:00').getTime()),null,'spring-forward normalization never creates a negative active interval');
assert.ok(engine.nextSceneBoundary(dstState,new Date('2026-03-08T01:00:00').getTime())>new Date('2026-03-08T03:45:00').getTime());
if(originalTimezone===undefined)delete process.env.TZ;else process.env.TZ=originalTimezone;
state.sceneRules=[rule];
const focusArtwork=new schema.FridgeCard();focusArtwork.id='artwork';focusArtwork.capability=null;focusArtwork.x=50;focusArtwork.y=100;focusArtwork.w=100;focusArtwork.h=100;
const {widgetHit}=load('WidgetHitTest');assert.equal(widgetHit([focusArtwork],100,150,schema.BOARD_W,schema.BOARD_H,0).id,'','decorative artwork has no ordinary capability route');
assert.equal(widgetHit([focusArtwork],100,150,schema.BOARD_W,schema.BOARD_H,0,'artwork').id,'artwork','central text-only artwork can acknowledge a scene');
assert.equal(widgetHit([focusArtwork],10,10,schema.BOARD_W,schema.BOARD_H,0,'artwork').id,'','blank canvas never acknowledges central artwork');
const t=performance.now();for(let i=0;i<500;i++)engine.projectScheduledScene(state,{rule:newer,token:'2026-10-05',start:0,end:1});console.log('500 focus projections × 32 cards:',(performance.now()-t).toFixed(2),'ms (host CPU only)');
console.log('PASS timed scenes: weekly/one-off/overnight, exact boundaries, latched focus, stale acknowledgement, overlap restore, source isolation, rotated edge slivers, missing targets, limits and persisted geometry');
(async()=>{const resolved=await engine.resolveScheduledScene(state,at('2026-10-05T18:00:00'),async id=>id==='other'?target:null);assert.equal(resolved.state,target);assert.equal(JSON.parse(engine.sceneWidgetContext(resolved)).baseId,state.canvasId);console.log('PASS async one-level canvas resolution and base-owned widget acknowledgement context');})().catch(e=>{console.error(e);process.exitCode=1;});

// Explicit normal layout is editable base; temporary scenes must always return to it.
const normalState=new schema.FridgeState();const normalCard=new schema.FridgeCard();normalCard.id='normal-card';normalCard.x=12;normalState.cards=[normalCard];
const normalLayout=engine.captureSceneLayout(normalState,'normal','日常');normalCard.x=180;const triggeredLayout=engine.captureSceneLayout(normalState,'triggered','晚间');normalState.sceneLayouts=[normalLayout,triggeredLayout];
assert.ok(engine.setNormalSceneLayout(normalState,'normal'));assert.equal(normalCard.x,12);assert.equal(normalState.sceneBaseLayoutId,'normal');
const interval={...new rules.SceneRule(),id:'interval',targetId:'triggered',start:20*60,end:22*60,createdAt:0};normalState.sceneRules=[interval];
assert.equal(engine.projectScheduledScene(normalState,engine.activeSceneRule(normalState,at('2026-10-05T20:00:00'))).state.cards[0].x,180);
assert.equal(engine.projectScheduledScene(normalState,engine.activeSceneRule(normalState,at('2026-10-05T22:00:00'))).state.cards[0].x,12,'end restores explicitly chosen normal layout');
assert.equal(schema.normalizeState(JSON.parse(storage.storageSnapshot(normalState))).sceneBaseLayoutId,'normal','normal selection survives storage');
assert.equal(engine.setNormalSceneLayout(normalState,'missing'),false);assert.equal(normalState.sceneBaseLayoutId,'normal');
normalCard.x=30;engine.refreshNormalSceneLayout(normalState);assert.equal(normalState.sceneBaseLayoutId,'');assert.equal(normalLayout.placements[0].x,12,'editing base never overwrites saved normal/target states');
console.log('PASS explicit normal layout selection, restoration, persistence, missing-target protection and immutable saved layouts');

const templates=load('TemplatePackage');engine.setNormalSceneLayout(normalState,'normal');const shared=templates.packageScene(storage.storageSnapshot(normalState),'');let serial=0;const sharedCards=templates.importedCards(shared.state,()=> 'shared_'+(++serial));templates.remapSceneSchedules(shared.state,sharedCards,()=> 'shared_'+(++serial),shared.state.canvasAspect);assert.ok(shared.state.sceneLayouts.some(l=>l.id===shared.state.sceneBaseLayoutId),'canvas import remaps the normal-state reference');assert.equal(templates.packageScene(storage.storageSnapshot(normalState),'normal-card').state.sceneBaseLayoutId,'','single-card export has no canvas normal-state reference');
