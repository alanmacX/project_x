const assert=require('node:assert/strict'),fs=require('node:fs'),vm=require('node:vm');
const ctx=vm.createContext({});vm.runInContext(fs.readFileSync('previewer/shared-models.js','utf8'),ctx);const load=ctx.FridgeCore.load,s=load('CardSchema'),lib=load('CanvasLibrary'),engine=load('SceneSchedule'),rotation=load('CanvasRotation');
const at=text=>new Date(text).getTime();
const catalog=new lib.CanvasCatalog();catalog.canvases=[{id:'day',name:'白天'},{id:'night',name:'夜间'}];catalog.activeId='day';catalog.scenes=[{id:'scene_a',name:'休息'},{id:'scene_b',name:'喝水'}];
const main=new s.FridgeState();main.canvasId='day';main.cards=Array.from({length:16},(_,i)=>{const c=new s.FridgeCard();c.id='base'+i;c.x=i%4*70;c.y=Math.floor(i/4)*100;c.w=90;c.h=100;return c;});
const scene=new s.FridgeState();scene.canvasId='scene_a';scene.cards=[new s.FridgeCard()];scene.cards[0].id='central';scene.cards[0].w=160;scene.cards[0].h=120;
const r=new (load('SceneScheduleSchema').SceneRule)();Object.assign(r,{id:'first',kind:'focus',centralOnly:true,targetId:'scene_a',start:600,timeoutMinutes:60,createdAt:0});
const newer={...r,id:'second',targetId:'scene_b',start:610,timeoutMinutes:5};catalog.sceneRules=[r,newer];let policy=lib.withScenePolicy(main,catalog);
assert.equal(engine.activeSceneRule(policy,at('2026-10-09T10:09:59')).rule.id,'first');
assert.equal(engine.activeSceneRule(policy,at('2026-10-09T10:10:00')).rule.id,'second');
assert.equal(engine.activeSceneRule(policy,at('2026-10-09T10:15:00')),null,'expired new scene never reveals older active scene');assert.equal(engine.nextSceneBoundary(policy,at('2026-10-09T10:15:00')),at('2026-10-10T10:00:00'),'superseded timeout does not spend a desktop refresh');
assert(engine.dismissScene(policy,'second','2026-10-09',at('2026-10-09T10:12:00')));
assert.equal(engine.activeSceneRule(policy,at('2026-10-09T10:12:00')),null,'acknowledged new scene never resumes prior one');
catalog.sceneRules=[r];policy=lib.withScenePolicy(main,catalog);const original=JSON.stringify(main),sceneOriginal=JSON.stringify(scene);
const display=engine.projectScheduledScene(policy,engine.activeSceneRule(policy,at('2026-10-09T10:01:00')),scene);
assert.equal(display.state.cards.length,17,'16 main cards plus independently owned central card');assert.equal(display.focusSourceId,'scene_a');assert.equal(display.focusId,'central');assert.equal(display.state.cards.at(-1).rot,0);assert.equal(JSON.stringify(main),original);assert.equal(JSON.stringify(scene),sceneOriginal);
for(const card of display.state.cards.slice(0,-1)){const y=card.y*344/470;assert(card.x+card.w<0||card.x>344||y+card.h<0||y>344,'main cards leave fully beyond boundary');}
assert.equal(engine.nextSceneBoundary(policy,at('2026-10-09T10:01:00')),at('2026-10-09T11:00:00'));
const midnight={...r,start:1430,timeoutMinutes:30};catalog.sceneRules=[midnight];policy=lib.withScenePolicy(main,catalog);assert(engine.activeSceneRule(policy,at('2026-10-10T00:10:00')));assert.equal(engine.activeSceneRule(policy,at('2026-10-10T00:20:00')),null);
const ids=['day','night'];const rot=rotation.normalizeCanvasRotation({mode:'time',slots:[{start:600,canvasId:'day'},{start:1200,canvasId:'night'},{start:600,canvasId:'night'},{start:900,canvasId:'missing'}]},ids);assert.equal(rot.slots[0].start,0);assert.equal(rot.slots.length,3);assert.equal(rotation.rotatedCanvas(rot,at('2026-10-09T20:00:00'),false,'day'),'night');assert.equal(rotation.nextCanvasBoundary(rot,at('2026-10-09T20:00:00')),at('2026-10-10T00:00:00'));
rot.mode='theme';rot.lightId='day';rot.darkId='night';assert.equal(rotation.rotatedCanvas(rot,at('2026-10-09T12:00:00'),true,'day'),'night');assert.equal(rotation.nextCanvasBoundary(rot,at('2026-10-09T12:00:00')),Infinity,'theme does not run time schedule');
catalog.rotation=rot;catalog.sceneRules=[];
const night=new s.FridgeState();night.canvasId='night';night.cards=[];
(async()=>{const out=await engine.resolveScheduledScene(lib.withScenePolicy(main,catalog,true),at('2026-10-09T12:00:00'),async id=>id==='night'?night:null);assert.equal(out.state.canvasId,'night');assert.equal(out.normalState.canvasId,'night');assert.equal(out.ruleId,'');const restored=lib.readCatalog(JSON.stringify(catalog));assert.equal(restored.scenes.length,2);assert.equal(restored.rotation.mode,'theme');assert.equal(restored.activeId,'day');console.log('PASS central scene ownership, exclusive supersession, timeout/cross-midnight, immutable projections, 16-card canvas, complete day rotation and theme exclusion');})().catch(e=>{console.error(e);process.exitCode=1;});

// Attachments outside the silhouette must leave with the parent, including rotated hooks/cloud fringe.
const overflow=load('ReadingComposition').compositionOverflow;
main.cards[0].capability={k:'clock',readingBlend:'tag'};main.cards[0].capFree=true;main.cards[0].capBox.x=-.8;main.cards[0].capBox.y=.4;main.cards[0].capBox.w=1.2;main.cards[0].capBox.h=.6;main.cards[0].rot=25;
const attachmentCatalog=lib.readCatalog(JSON.stringify(catalog));attachmentCatalog.rotation.mode='off';attachmentCatalog.sceneRules=[r];const attached=engine.projectScheduledScene(lib.withScenePolicy(main,attachmentCatalog),engine.activeSceneRule(lib.withScenePolicy(main,attachmentCatalog),at('2026-10-09T10:01:00')),scene).state.cards[0],f=overflow(attached,1),angle=attached.rot*Math.PI/180;
const corners=[[-f.left,-f.top],[attached.w+f.right,-f.top],[-f.left,attached.h+f.bottom],[attached.w+f.right,attached.h+f.bottom]],xs=corners.map(([x,y])=>attached.x+x*Math.cos(angle)-(y-attached.h)*Math.sin(angle)),ys=corners.map(([x,y])=>attached.y*344/470+attached.h+x*Math.sin(angle)+(y-attached.h)*Math.cos(angle));
assert(Math.max(...xs)<0||Math.min(...xs)>344||Math.max(...ys)<0||Math.min(...ys)>344,'entire reading attachment is off-canvas after sweep');

const paused=rotation.normalizeCanvasRotation({...rot,enabled:false},ids);assert.equal(rotation.rotatedCanvas(paused,at('2026-10-09T12:00:00'),true,'day'),'day');assert.equal(rotation.nextCanvasBoundary(paused,at('2026-10-09T12:00:00')),Infinity);assert.equal(paused.darkId,'night');paused.enabled=true;assert.equal(rotation.rotatedCanvas(paused,at('2026-10-09T12:00:00'),true,'day'),'night');
const minutePolicy=lib.withScenePolicy(main,attachmentCatalog);minutePolicy.sceneRules=[{...r,createdAt:at('2026-10-09T10:00:30')}];assert(engine.activeSceneRule(minutePolicy,at('2026-10-09T10:00:31')),'enabling during scheduled minute triggers immediately');assert.equal(engine.activeSceneRule(minutePolicy,at('2026-10-09T09:59:59')),null,'no premature occurrence');minutePolicy.sceneRules[0].createdAt=at('2026-10-09T10:01:00');assert.equal(engine.activeSceneRule(minutePolicy,at('2026-10-09T10:01:30')),null,'past starts do not retroactively trigger');
console.log('PASS rotation pause/resume preserves configuration and same-minute activation');
