const assert=require('node:assert/strict'),fs=require('node:fs'),path=require('node:path'),vm=require('node:vm');
const ts=require('/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript');
const root=path.resolve(__dirname,'../entry/src/main/ets/model'),cache=new Map();
function load(name){const file=path.resolve(root,name+'.ets');if(cache.has(file))return cache.get(file).exports;const mod={exports:{}};cache.set(file,mod);const code=ts.transpileModule(fs.readFileSync(file,'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText;vm.runInThisContext('(function(require,module,exports){'+code+'\n})',{filename:file})(s=>s==='@kit.ArkTS'?{taskpool:{}}:s==='@kit.BasicServicesKit'?{deviceInfo:{sdkApiVersion:24}}:load(path.relative(root,path.resolve(path.dirname(file),s))),mod,mod.exports);return mod.exports;}
const s=load('CardSchema'),c=load('CapabilityCatalog'),p=load('CapabilityPresentation'),g=load('CanvasLayout'),m=load('CapabilityMetrics'),intake=load('ParcelIntake'),actions=load('WidgetActions'),hit=load('WidgetHitTest'),templates=load('TemplatePackage');
assert.deepEqual(c.CAPABILITY_CATALOG.map(x=>x.key).sort(),s.CAPABILITIES.slice().sort(),'every shipped capability has a source/purpose/detail contract');
for(const cap of c.CAPABILITY_CATALOG){assert.ok(cap.source&&cap.summary&&cap.detail);assert.ok(c.CAPABILITY_GROUPS.includes(cap.group));const min=m.capabilityMinimum({k:cap.key},true);assert.ok(min.w>=64&&min.h>=32);}
const parcels=Array.from({length:5},(_,i)=>({id:'parcel'+i,code:'2-'+i+'234',place:'东门菜鸟驿站',picked:false}));
assert.ok(m.capabilityMinimum({k:'countdown',date:'9999-12-31'},true).w>=100,'long countdowns gain width instead of unreadable type');
const now=new Date('2026-10-04T09:00:00').getTime();const events=[{id:'a',title:'设计评审',location:'会议室203',start:now+3600000,end:now+7200000},{id:'b',title:'买菜',start:now+10800000,end:now+14400000},{id:'c',title:'过期',start:0,end:1}];assert.equal(p.summaryPresentation({k:'agenda',events},136,now).events.length,2);assert.equal(p.summaryPresentation({k:'agenda',events},82,now).events[0].id,'a');
assert.equal(p.summaryPresentation({k:'agenda',events:events.concat(Array.from({length:7},(_,i)=>({id:'next'+i,title:'后续',start:now+(i+5)*3600000,end:now+(i+6)*3600000})))},82,now).remaining,8,'remaining count includes the whole upcoming list');
assert.equal(p.readingSurface({k:'parcel'},true,false),true);assert.equal(p.readingSurface({k:'parcel',readingStyle:'plain'},true,false),false);assert.equal(p.readingSurface({k:'parcel',readingStyle:'plain'},false,true),true,'overlap fallback remains readable');
for(const shape of ['rect','round','pill','blob','subject']){
 const card=new s.FridgeCard();card.id=shape;card.w=240;card.h=280;card.shape=shape;card.capability={k:'parcel',readingStyle:'surface'};card.outline=[[{x:.1,y:.1},{x:.9,y:.1},{x:.9,y:.9},{x:.1,y:.9}]];
 assert.ok(g.ensureCapabilitySize(card));const safe=g.safeContentBox(card);for(const anchor of ['top','center','bottom']){const box=g.capabilityPreset(card,anchor);assert.ok(box.x>=safe.x-.001&&box.y>=safe.y-.001&&box.x+box.w<=safe.x+safe.w+.001&&box.y+box.h<=safe.y+safe.h+.001);assert.ok(m.capabilityFits(card.capability,box.w*card.w-16,box.h*card.h-16));}
}
const notices=intake.parsePickupNotice('登录验证码123456；请到东门菜鸟驿站，取件码【２－１２３４】。请至西门丰巢快递柜，取件码 9-4567。');assert.equal(notices.length,2);assert.equal(notices[0].place,'东门菜鸟驿站');assert.equal(notices[1].place,'西门丰巢快递柜');assert.equal(notices[0].code,'2-1234');
for(const raw of ['验证码123456，订单号888999000','取件码：13812345678','取件码：123456789012345678','取件码：abcdef'])assert.equal(intake.parsePickupNotice(raw).length,0);
assert.equal(intake.parsePickupNotice('取件码 2-1234 please collect')[0].code,'2-1234');
const missing=intake.parsePickupNotice('取件码:88-99');assert.equal(missing[0].place,'');let merged=intake.mergePickupParcels([],missing,'学校驿站',now);assert.equal(merged[0].place,'学校驿站');assert.equal(intake.mergePickupParcels(merged,missing,'学校驿站',now).length,1);merged[0].picked=true;assert.equal(intake.mergePickupParcels(merged,missing,'学校驿站',now).length,2,'a code can be reused after pickup');
assert.throws(()=>intake.mergePickupParcels(Array.from({length:64},(_,i)=>({id:''+i,code:''+i,place:'old',picked:false})),missing,'new',now),/记录已满/);
const cal=new s.FridgeCard();cal.id='calendar';cal.w=260;cal.h=320;cal.x=30;cal.y=50;cal.rot=27;cal.capability={k:'calendar'};cal.capBox=g.capabilityPreset(cal,'center');const scale=1.4,width=344*scale,height=344*scale;
const rects=actions.widgetActionRects(cal,scale,now);assert.equal(rects.length,2);for(const rect of rects){assert.equal(rect.w*scale,44);assert.equal(rect.h*scale,44);const at=hit.widgetCanvasPoint(cal,(rect.x+rect.w/2)*scale,(rect.y+rect.h/2)*scale,width,height);const result=hit.widgetHit([cal],at.x,at.y,width,height,now);assert.equal(result.id,cal.id);assert.equal(result.operation,rect.operation);}
cal.w=140;cal.h=100;cal.capBox=g.safeContentBox(cal);assert.equal(actions.widgetActionRects(cal,scale,now).length,0,'compact calendar has no invisible/tiny month controls');
const state=s.defaultState();state.cards=[new s.FridgeCard()];state.cards[0].id='private';state.cards[0].capability={k:'parcel',readingStyle:'surface',parcelPlace:'家门口',parcels};const pkg=templates.packageScene(JSON.stringify(state),'private');assert.equal(pkg.state.cards[0].capability,null,'retired pickup capability cannot be reintroduced by a shared package');assert.equal(state.cards[0].capability.parcels.length,5,'export does not mutate original data');
for(const ink of ['#262824','#FFFFFF','#777777','#AA4455','#FFDD00','#000000','#234567'])assert.ok(p.textContrast(ink,p.readingSurfaceColor(ink))>=4.5,'reading backing is chosen by actual text contrast');
const normalized=s.normalizeState({...s.defaultState(),cards:[{...new s.FridgeCard(),id:'bounded',capability:{k:'calendar',calendarOffset:999}}]});assert.equal(normalized.cards[0].capability.calendarOffset,120);
console.log('PASS capability framework: complete catalog; adaptive list budgets; protected photo reading insets; shape-safe presets; local labelled pickup parsing/merge/capacity; 44vp rendered/hit geometry; compact deep links; template locality; month migration');

const viewport=load('EditorViewport');for(const body of [220,260,300]){const pane=viewport.editorPreviewPaneHeight(body,true);assert.ok(pane>body-164,'short landscape gives usable height back to artwork');assert.ok(body-pane-16>=92,'one-line layers retain 44vp targets, heading and padding');const v=viewport.editorViewport(240,280,15,400,body+100,0,24,true,pane);assert.ok(v.scale*280>40,'rotated preview remains useful for placement');}

const grouping=load('CardGroups');
const grouped=['a','b','c','d'].map((id,i)=>({...new s.FridgeCard(),id,z:4-i,groupId:['a','c'].includes(id)?'same':''}));
const order=grouped.map(x=>x.id);const sections=grouping.layerSections(grouped);assert.deepEqual(sections[0].ids,['a','c']);assert.equal(sections[0].title,'组合 1');assert.deepEqual(grouped.map(x=>x.id),order,'layer grouping does not rewrite canvas stacking');
for(const ink of ['#262824','#FFFFFF','#777777','#AA4455','#FFDD00','#000000','#234567']) {
 for(const strength of [-1,0,.1,.3,.42,1]) {
  const tint=p.readingVeilColor(ink,strength),alpha=parseInt(tint.slice(1,3),16)/255;
  assert.ok(alpha<=.421,'reading field preserves at least 58% of the photograph');
  if(strength===0)assert.equal(alpha,0,'feather ends fully transparent');
 }
 assert.ok(p.textContrast(ink,p.readingSurfaceColor(ink))>=4.5,'glyph halo chooses the contrasting luminance');
 assert.equal(p.readingHalo(ink,1,false).length,0,'plain solid cards need no extra text effects');
}
for(const blend of ['feather','scrim','halo']) {
 const input=new s.FridgeState(),card=new s.FridgeCard();card.capability={k:'clock',readingBlend:blend,readingStyle:'surface'};input.cards=[card];
 const restored=s.normalizeState(JSON.parse(JSON.stringify(input)));
 assert.equal(restored.cards[0].capability.readingBlend,'bare','legacy material migrates to neutral mica without changing artwork');
 const maxAlpha=parseInt(p.readingVeilColor('#FFFFFF',1,blend).slice(1,3),16)/255;
 assert.ok(maxAlpha<=(blend==='scrim'?.722:.421));assert.equal(p.readingVeilColor('#FFFFFF',0,blend).slice(1,3),'00');
}
const shape=new s.FridgeCard();shape.shape='subject';shape.subjectBorder=false;shape.w=300;shape.h=300;shape.capability={k:'clock'};
shape.outline=[[{x:0,y:0},{x:1,y:0},{x:1,y:.4},{x:.4,y:.4},{x:.4,y:1},{x:0,y:1}]];
shape.capBox={x:.08,y:.7,w:.28,h:.14,rot:0,opacity:1};const placed=g.capabilityPlacement(shape);assert.ok(Math.abs(placed.y-.7)<.001,'requested lower arm remains outside the largest upper rectangle');
shape.elements=[{...new s.CanvasElement(),kind:'text',x:0,y:0,w:1,h:1}];assert.ok(g.capabilityObstructed(shape));assert.ok(g.capabilityPlacement(shape).y>.5,'intentional overlap never automatically relocates a capability');
const previous={...placed},requested={...placed,x:.65,y:.65};const constrained=g.constrainCapabilityDrag(shape,requested,previous);assert.ok(constrained.x+constrained.w<=.4+.001 || constrained.y+constrained.h<=.4+.001,'gesture never enters transparent cutout');
console.log('PASS grouped layer ordering; detached canvas snapshots; transparent reading veil and contrasting glyph halos; whole-silhouette placement and bounded drag');

const hollow={...shape,cutout:'',outline:[[{x:0,y:0},{x:1,y:0},{x:1,y:1},{x:0,y:1}],[{x:.4,y:.4},{x:.6,y:.4},{x:.6,y:.6},{x:.4,y:.6}]],elements:[],capBox:{x:.3,y:.3,w:.28,h:.14,rot:0,opacity:1}};
const holeFit=g.capabilityPlacement(hollow);assert.ok(holeFit.x+holeFit.w<=.4 || holeFit.x>=.6 || holeFit.y+holeFit.h<=.4 || holeFit.y>=.6,'capability never covers a transparent hole');
let travel={...placed};const started=performance.now();for(let i=0;i<5000;i++){travel=g.constrainCapabilityDrag(shape,{...travel,x:.08+(i%10)*.002,y:.7+(i%7)*.002},travel);}console.log('5000 cached capability drag queries: '+(performance.now()-started).toFixed(2)+' ms (model CPU, not device FPS)');

global.BlurStyle={COMPONENT_THIN:0};
const material=load('ChromeMaterial');
material.prepareChromeMaterial().then(()=>{const old={backgroundColor(){return this;},backgroundBlurStyle(){return this;},border(){return this;},shadow(){return this;},systemMaterial:()=>{throw Error('API26 method called on API24');}};material.immersiveChrome().applyNormalAttribute(old);material.immersiveReading('#E0FFFFFF').applyNormalAttribute(old);assert.equal(material.chromeMaterial(),undefined);console.log('PASS API24 material module and method guards');}).catch(e=>{console.error(e);process.exitCode=1;});

const gg=load('GroupGeometry');
for(const height of [s.BOARD_H,280,740]) {
 const members=[{...new s.FridgeCard(),id:'ga',x:-12,y:31,w:120,h:180,rot:23},{...new s.FridgeCard(),id:'gb',x:190,y:180,w:100,h:90,rot:-40}];
 const before=members.map(c=>({...c})),box=gg.groupBox(members,height),cx=box.x+box.w/2,cy=box.y+box.h/2;
 const origin=c=>({x:c.x,y:c.y*height/s.BOARD_H+c.h});
 const centre=c=>{const a=c.rot*Math.PI/180,o=origin(c);return {x:o.x+c.w/2*Math.cos(a)+c.h/2*Math.sin(a),y:o.y+c.w/2*Math.sin(a)-c.h/2*Math.cos(a)};};
 gg.transformGroup(members,box,height,1.35,67);
 members.forEach((c,i)=>{const b=centre(before[i]),v=centre(c),a=67*Math.PI/180;assert.ok(Math.abs(v.x-(cx+1.35*((b.x-cx)*Math.cos(a)-(b.y-cy)*Math.sin(a))))<1e-8);assert.ok(Math.abs(v.y-(cy+1.35*((b.x-cx)*Math.sin(a)+(b.y-cy)*Math.cos(a))))<1e-8);});
 gg.transformGroup(members,box,height,1/1.35,-67);
 members.forEach((c,i)=>{for(const key of ['x','y','w','h','rot'])assert.ok(Math.abs(c[key]-before[i][key])<1e-8,'group pose roundtrip '+height+' '+key);});
 assert.ok(gg.groupMinimumScale(members)>0);
 grouping.ungroupCards(members,'');assert.equal(members.length,2);
}
const snap=load('CardViewSnapshot'),ungrouped=new s.FridgeCard();ungrouped.id='reactive-group';ungrouped.groupId='group';const oldSnap=snap.cardRenderSnapshot(ungrouped);grouping.ungroupCards([ungrouped],'group');const newSnap=snap.cardRenderSnapshot(ungrouped);assert.notEqual(oldSnap,newSnap);assert.equal(newSnap.groupId,'','ungroup publishes a new reactive render snapshot');
console.log('PASS group centre/pivot, scale/rotation roundtrip across widget aspects; reactive ungroup snapshot');

const mutable=new s.FridgeCard();mutable.id='snapshot-cache-contract';mutable.capability={k:'weather',temp:'18'};mutable.elements=[{...new s.CanvasElement(),id:'caption',text:'before'}];
const stable=snap.cardRenderSnapshot(mutable);assert.equal(snap.cardRenderSnapshot(mutable),stable,'unchanged cards reuse their render parameter');
mutable.capability.temp='19';mutable.elements[0].text='after';mutable.rot=23;mutable.capBox.x=.3;
const changed=snap.cardRenderSnapshot(mutable);assert.notEqual(changed,stable);assert.equal(stable.capability.temp,'18');assert.equal(stable.elements[0].text,'before');assert.equal(changed.rot,23);assert.equal(changed.capBox.x,.3);
console.log('PASS render-cache reuse and isolated nested content/geometry updates');

// Bounds and commit must use the same display-space displacement on phone/tablet hosts.
const dg=load('DragGeometry');
for(const height of [280,s.BOARD_H,740]) {
 const members=[{...new s.FridgeCard(),id:'pan-a',groupId:'pan',x:35,y:100,w:92,h:130,rot:27},
  {...new s.FridgeCard(),id:'pan-b',groupId:'pan',x:170,y:180,w:100,h:78,rot:-31}];
 const anchor=members[0],bounds=grouping.groupDragBounds(members,anchor,height);
 for(const target of [{x:bounds.minX,y:bounds.minY},{x:bounds.maxX,y:bounds.maxY}]) {
  const dx=target.x-anchor.x,dy=target.y-anchor.y;
  for(const member of members) {
   const b=dg.dragBounds(member,height),x=member.x+dx,y=member.y+dy;
   assert.ok(x>=b.minX-1e-8&&x<=b.maxX+1e-8&&y>=b.minY-1e-8&&y<=b.maxY+1e-8,'every member stays recoverable at shared bounds '+height);
  }
 }
 const boxBefore=gg.groupBox(members,height),dx=17,dy=-11;
 members.forEach(c=>{c.x+=dx;c.y+=dy;});
 const boxAfter=gg.groupBox(members,height);
 assert.ok(Math.abs(boxAfter.x-boxBefore.x-dx)<1e-8);
 assert.ok(Math.abs(boxAfter.y-boxBefore.y-dy*height/s.BOARD_H)<1e-8);
 assert.ok(Math.abs(boxAfter.w-boxBefore.w)<1e-8&&Math.abs(boxAfter.h-boxBefore.h)<1e-8,'pan preserves group box and member relationship');
}
for(const k of s.CAPABILITIES) {
 const cap={k},floor=m.capabilityReadableMinimum(cap);
 assert.equal(m.capabilityFits(cap,floor.w,floor.h),true,'readable floor '+k);
 assert.ok(m.capabilityContentScale(cap,floor.w,floor.h)>=.8-1e-8,'typography cannot become microscopic '+k);
 assert.equal(m.capabilityFits(cap,floor.w-1,floor.h),false,'hard floor '+k);
}
const photo=new s.FridgeCard();photo.shape='subject';photo.w=300;photo.h=360;photo.subjectPhoto=true;photo.capability={k:'battery'};
photo.outline=[[{x:.3,y:.15},{x:.7,y:.15},{x:.7,y:.85},{x:.3,y:.85}]];
const compactMin=g.minimumCardSize(photo),shrink=Math.max(compactMin.w/photo.w,compactMin.h/photo.h);
photo.w*=shrink;photo.h*=shrink;
const slot=g.capabilityPlacement(photo),pad=g.capabilityInset(photo);
assert.equal(m.capabilityFits(photo.capability,slot.w*photo.w-2*pad,slot.h*photo.h-2*pad),true,'fixed sticker edge and transparent reading gutter stay readable after proportional shrink');
assert.ok(photo.w<230,'battery on a narrow photo no longer locks the card near the maximum');
console.log('PASS host-aware group bounds, rigid pan geometry and responsive typography floors including subject border');

for(const height of [280,470,740]) {
 const members=[{...new s.FridgeCard(),id:'persist-a',groupId:'persist',x:450,y:360,w:90,h:120,rot:40},
  {...new s.FridgeCard(),id:'persist-b',groupId:'persist',x:360,y:310,w:110,h:90,rot:-20}];
 const dx=members[1].x-members[0].x,dy=members[1].y-members[0].y;
 const state=s.normalizeState({schemaVersion:2,cards:members});
 assert.equal(state.cards[0].x,450,'normalization retains valid rotated/group positions until host recovery');
 grouping.clampCanvasGroups(state.cards,height);
 assert.ok(Math.abs(state.cards[1].x-state.cards[0].x-dx)<1e-8);
 assert.ok(Math.abs(state.cards[1].y-state.cards[0].y-dy)<1e-8,'reload preserves rigid group relationship');
 const copy=state.cards.map(c=>({...c}));grouping.clampCanvasGroups(state.cards,height);
 state.cards.forEach((c,i)=>{assert.equal(c.x,copy[i].x);assert.equal(c.y,copy[i].y);});
}
console.log('PASS group recovery preserves composition and is idempotent across host aspects');

// Artwork minima must survive storage and group scaling; readability is a separate contract.
for(const shape of ['rect','round','pill','blob']) {
 const tiny=new s.FridgeCard();tiny.id='tiny-'+shape;tiny.shape=shape;tiny.w=32;tiny.h=40;
 assert.deepEqual(g.minimumCardSize(tiny),Object.assign(new m.CapabilitySize(),{w:32,h:32}));
 const restored=s.normalizeState({schemaVersion:2,cards:[tiny]}).cards[0];assert.equal(restored.w,32);assert.equal(restored.h,40,'reload must not expand artwork to the retired 80-unit floor');
 assert.equal(gg.groupMinimumScale([restored]),1,'a pure-artwork group can reach the same floor as a single card');
}
const smallClock=new s.FridgeCard();smallClock.capability={k:'clock'};smallClock.w=120;smallClock.h=120;
const clockFloor=g.minimumCardSize(smallClock);assert.ok(clockFloor.w<80&&clockFloor.h<80,'clock is governed by its compact typography, not an unrelated 80-unit paper floor');
const smallLesson=new s.FridgeCard();smallLesson.shape='subject';smallLesson.w=300;smallLesson.h=360;smallLesson.subjectPhoto=true;smallLesson.capability={k:'timetable',timetableMode:'next'};smallLesson.outline=[[{x:.3,y:.15},{x:.7,y:.15},{x:.7,y:.85},{x:.3,y:.85}]];
const lessonFloor=g.minimumCardSize(smallLesson),lessonScale=Math.max(lessonFloor.w/smallLesson.w,lessonFloor.h/smallLesson.h);assert.ok(smallLesson.w*lessonScale<250,'a single lesson no longer requires a nearly maximum-size narrow subject');smallLesson.w*=lessonScale;smallLesson.h*=lessonScale;
const lessonSlot=g.capabilityPlacement(smallLesson),lessonInset=g.capabilityInset(smallLesson);assert.ok(m.capabilityFits(smallLesson.capability,lessonSlot.w*smallLesson.w-2*lessonInset,lessonSlot.h*smallLesson.h-2*lessonInset));
assert.ok(g.ensureCapabilitySize(smallLesson));const beforeLesson=smallLesson.w;assert.ok(g.ensureCapabilitySize(smallLesson));assert.ok(Math.abs(smallLesson.w-beforeLesson)<.001,'reopening cannot progressively inflate compact lesson artwork');
console.log('PASS small artwork persistence/group floor; compact clock and upcoming lesson keep readable content inside a narrow photo');

const depth=load("CardDepth");
for(const factor of [.25,.5,1,2,3]) {assert.equal(depth.cardDepthScale(factor)/factor,1,"desktop relief follows the same normalized artwork proportions as app");assert.equal(s.shapeRadius("rect",factor)/factor,16,"rounded substrate corners scale with the same scene");}

// Manual capability placement is a separate foreground, free of silhouette snapping.
const free={...shape,capFree:true,capBox:{x:.65,y:.65,w:.28,h:.14,rot:0,opacity:.7}};
const freeBox=g.capabilityPlacement(free);assert.equal(freeBox.x,.65);assert.equal(freeBox.y,.65);assert.equal(freeBox.opacity,.7);
const freeDrag=g.constrainCapabilityDrag(free,{...freeBox,x:.6,y:.5},freeBox);assert.equal(freeDrag.x,.6);assert.equal(freeDrag.y,.5);
const freeEdge=g.constrainCapabilityDrag(free,{...freeBox,x:2,y:-1},freeBox);assert.equal(freeEdge.x,1-freeBox.w);assert.equal(freeEdge.y,0);
assert.ok(g.minimumCardSize(free).w<g.minimumCardSize(shape).w,'free foreground does not require a large interior rectangle');
const freeState=new s.FridgeState();freeState.cards=[free];assert.equal(s.normalizeState(JSON.parse(JSON.stringify(freeState))).cards[0].capFree,true);assert.equal(snap.cardViewSnapshot(free).capFree,true);
for(const k of ['clock','date','battery','agenda','timetable']){const cap={k};const full=m.capabilityMinimum(cap,false);assert.ok(m.capabilityContentScale(cap,full.w*1.5,full.h*1.5)>1,'larger boxes enlarge content '+k);assert.ok(m.capabilityContentScale(cap,full.w*10,full.h*10)<=2,'readout enlargement stays bounded '+k);}
console.log('PASS free foreground placement, edge recovery, readable size, storage/snapshot roundtrip and enlarged content');

const cardHit=load('CardHitTest');assert.equal(cardHit.cardContainsPoint(free,.7*free.w,.7*free.h,1),true,'foreground over a transparent silhouette is selectable');assert.equal(cardHit.cardContainsPoint(free,.98*free.w,.98*free.h,1),false,'remaining transparent space stays inert');

for(const ink of ['#FFFFFF','#F8F8F8','#323232','#D0A050','#000000'])assert.ok(p.textContrast(p.paperReadingInk(ink),p.READING_PAPER_COLOR)>=4.5);
assert.equal(p.paperReadingInk('#101010'),'#101010');assert.equal(p.paperReadingRadius(180,100),10);assert.equal(p.paperReadingRadius(20,20),3.2);
const paperState=new s.FridgeState();paperState.cards=[new s.FridgeCard()];paperState.cards[0].capability={k:'clock',readingStyle:'surface',readingBlend:'paper'};assert.equal(s.normalizeState(JSON.parse(JSON.stringify(paperState))).cards[0].capability.readingBlend,'bare');
console.log('PASS thin-paper contrast, compact corner geometry and persisted material choice');

for(const ink of ['#FFFFFF','#323232','#6D6D6D','#000000'])for(const background of ['#000000','#FFFFFF'])assert.ok(p.textContrast(p.paperReadingInk(ink),p.paperReadingBackground(background))>=4.5,'translucent paper keeps ink readable over darkest/lightest photographs');
assert.equal(p.READING_PAPER_FILL.slice(1,3),'80');

const textWidth=load('PaperTextWidth');
assert.ok(textWidth.paperTextWidth('88:88',42,500)>100);
assert.ok(textWidth.paperTextWidth('课程表',14)>=42);
assert.equal(textWidth.paperTextWidth('88:88',42,500),textWidth.paperTextWidth('88:88',42,500));
assert.ok(!fs.readFileSync(path.join(root,'PaperTextWidth.ets'),'utf8').includes('getMeasureUtils'), 'Form metrics never require an app UIContext');
assert.ok(textWidth.paperTextWidth('更长的文字',14)>textWidth.paperTextWidth('文字',14),'changed content gets a new width');
const batteryPaper=load('BatteryPresentation');assert.equal(batteryPaper.batteryPaperMask(0,10),'');assert.equal(batteryPaper.batteryPaperMask(100,NaN),'');
const ringMask=batteryPaper.batteryPaperMask(100,30);assert.ok(ringMask.includes('0 1 1')&&ringMask.includes('0 1 0'),'opposite circle winding leaves the photo visible at the centre');
console.log('PASS content-sized paper shared font advances and hollow battery masking');

assert.equal(batteryPaper.batteryPaperArcMask(100,40,126,0),'');assert.ok(batteryPaper.batteryPaperArcMask(100,40,126,288).includes('0 1 1'));assert.ok(batteryPaper.batteryPaperArcMask(100,30,70,40).includes('0 0 0'),'number backing uses only its local arc');
const compositions=load('ReadingComposition');
assert.equal(compositions.READING_COMPOSITIONS.length,5);
for(const kind of s.CAPABILITIES.filter(k=>k!=='album')) for(const blend of compositions.readingStyles(kind)){
 const card=new s.FridgeCard();card.id=kind+'-'+blend;card.capability={k:kind,readingBlend:blend,readingTint:'#F8CF32'};card.capFree=true;card.capBox.x=-.35;card.capBox.y=.6;card.capBox.w=.65;card.capBox.h=.5;card.capBox.rot=-12;
 const restored=s.normalizeState({...s.defaultState(),cards:[card]}).cards[0];assert.equal(restored.capability.readingBlend,blend);assert.equal(restored.capability.readingTint,'#F8CF32');assert.equal(restored.capBox.x,-.35);assert.equal(restored.capBox.rot,-12);
 const drag=g.constrainCapabilityDrag(restored,{...restored.capBox,x:-100,y:100},restored.capBox);assert.equal(drag.x,-2);assert.equal(drag.y,2);assert.equal(drag.rot,-12);
 assert.equal(p.readingSurface(restored.capability,true,false),true);
}
for(const blend of ['space','sticker'])for(const [w,h] of [[1,1],[100,40],[40,150]]){const path=compositions.compositionPath(blend,w,h);assert.ok(path.endsWith('Z'));assert.ok(!/NaN|Infinity/.test(path));assert.equal((path.match(/ C /g)||[]).length,6);}
assert.equal(compositions.compositionPath('sticker',0,20),'');
console.log('PASS simplified compositions: compatible capability/style pairs, material/position/rotation persistence, bounded external drag, finite fixed-complexity silhouettes and bare-text contract');
const external=new s.FridgeCard();external.capFree=true;external.capability={k:'worldclock',readingBlend:'sticker'};external.capBox={x:-.35,y:.6,w:.65,h:.5,rot:25,opacity:1};
const fringe=compositions.compositionOverflow(external,2);assert.ok(fringe.left>0&&fringe.bottom>0);assert.equal(compositions.compositionOverflow({...external,capFree:false},2).left,0);
console.log('PASS external composition cache includes rotated attachment overflow without changing artwork bounds');

const policy=load('ReadingStylePolicy');
for(const k of s.CAPABILITIES.filter(k=>k!=='album'&&k!=='battery'))assert.deepEqual(policy.readingStyles(k),['cloud','bare','tag','sticker']);
assert.deepEqual(policy.readingStyles('battery'),['badge','cloud','bare','tag','sticker']);assert.deepEqual(policy.readingStyles('album'),[]);
assert.equal(policy.validReadingStyle('clock','dock'),'tag');assert.equal(policy.validReadingStyle('calendar','space'),'sticker');
for(const k of s.CAPABILITIES.filter(k=>k!=='album'))for(const style of compositions.READING_COMPOSITIONS)assert.ok(policy.readingStyles(k).includes(s.normalizeState({...s.defaultState(),cards:[{...new s.FridgeCard(),capability:{k,readingBlend:style}}]}).cards[0].capability.readingBlend));
for(const scale of [.5,1,2]){
 const box={x:4/(200*scale),y:.4,w:.3,h:.3,rot:0,opacity:1};const snapped=compositions.snapComposition(box,200,240,scale,'sticker');assert.equal(snapped.edge,'left');assert.equal(snapped.box.x,0);assert.equal(snapped.box.y,.4);
 assert.equal(compositions.snapComposition({...box,x:8/(200*scale)},200,240,scale,'space').edge,'');
 const outside=compositions.snapComposition({...box,x:-.3+2/(200*scale)},200,240,scale,'space');assert.equal(outside.edge,'right');assert.equal(outside.box.x,-.3);
 assert.equal(compositions.snapComposition({...box,x:8/(200*scale)},200,240,scale,'space','left').edge,'left');
 assert.equal(compositions.snapComposition({...box,rot:12},200,240,scale,'space').edge,'');
}
for(const edge of ['left','right','top','bottom']){const path=compositions.compositionPath('sticker',180,80,edge);assert.ok(!/NaN|Infinity|@/.test(path));assert.equal((path.match(/ C /g)||[]).length,5);assert.ok(path.endsWith('Z'));}
for(let u=0;u<=1;u+=.01){const p=compositions.hookPoint(u);assert.ok(p[1]<=.5+1e-12);assert.ok(Math.abs(compositions.hookPosition(...p)-u)<.002);}
const backing=fs.readFileSync(path.resolve(root,'../views/ReadingBacking.ets'),'utf8');assert.ok(!backing.includes('Canvas(this.context)'),'moving materials cannot clear and repaint a Canvas');assert.ok(backing.includes('Counter-clockwise subpath'),'punched hole uses real transparent winding');assert.ok(backing.includes('onSizeChange'),'material follows native layout without a bitmap resize callback');

const mica=load('MicaGeometry');
for(const style of ['tag','dock']){assert.equal(mica.hookReserve(style),20);for(const u of [0,.5,1]){const x=mica.hookCenter(u,100,1);assert.ok(x>=14&&x<=86);assert.ok(10+3.3<20+compositions.compositionPadding(style),'hole stays above content');}}
for(const style of ['bare','space','sticker'])assert.equal(mica.hookReserve(style),0);
// Sample every Bezier segment, then check a grid spanning the entire safe content rectangle.
function polygon(path){const tokens=path.match(/[MCQLZ]|-?\d+(?:\.\d+)?(?:e[+-]?\d+)?/gi);let i=0,x=0,y=0,out=[];while(i<tokens.length){const op=tokens[i++];if(op==='Z')break;if(op==='M'||op==='L'){x=+tokens[i++];y=+tokens[i++];out.push([x,y]);}else{const start=[x,y],a=[+tokens[i++],+tokens[i++]],b=op==='C'?[+tokens[i++],+tokens[i++]]:a,end=[+tokens[i++],+tokens[i++]];for(let j=1;j<=32;j++){const t=j/32,v=1-t;out.push(op==='C'?[v**3*start[0]+3*v*v*t*a[0]+3*v*t*t*b[0]+t**3*end[0],v**3*start[1]+3*v*v*t*a[1]+3*v*t*t*b[1]+t**3*end[1]]:[v*v*start[0]+2*v*t*a[0]+t*t*end[0],v*v*start[1]+2*v*t*a[1]+t*t*end[1]]);} [x,y]=end;}}return out;}
function inside(poly,x,y){let yes=false;for(let i=0,j=poly.length-1;i<poly.length;j=i++){const a=poly[i],b=poly[j];if((a[1]>y)!==(b[1]>y)&&x<(b[0]-a[0])*(y-a[1])/(b[1]-a[1])+a[0])yes=!yes;}return yes;}
for(const style of ['bare','space','sticker','tag','dock'])for(const edge of ['', 'left','right','top','bottom'])for(const scale of [.25,.5,1,2])for(const [rw,rh] of [[32,32],[80,50],[300,40],[40,300],[240,180]]){
 const w=rw*scale,h=rh*scale,poly=polygon(mica.micaPath(style,w,h,scale,edge)),p=compositions.compositionPadding(style)*scale,top=p+mica.hookReserve(style)*scale;
 for(let ix=0;ix<=10;ix++)for(let iy=0;iy<=10;iy++){const x=p+(w-2*p)*ix/10,y=top+Math.max(0,h-top-p)*iy/10;assert.ok(inside(poly,x,y),`${style}/${edge}/${scale}/${rw}x${rh}: content ${x},${y} outside material`);}
}
console.log('PASS mica geometry: 60,500 safe-area samples; transparent holes remain in reserved header; no observed measurement feedback');
console.log('PASS explicit style policy, legacy migration, one-edge physical snapping, finite attached shapes, freely placed hooks and feedback-free native backing');

const boundaryCard=new s.FridgeCard();boundaryCard.shape='subject';boundaryCard.capability={k:'calendar',readingBlend:'sticker'};boundaryCard.outline=[[{x:.25,y:.15},{x:.75,y:.15},{x:.75,y:.85},{x:.25,y:.85}]];
const edgeBox={x:.253,y:.35,w:.2,h:.2,rot:0,opacity:1},boundary=g.capabilityAttachmentEdges(boundaryCard,edgeBox);
assert.ok(Math.abs(boundary[0]-.25)<.02&&Math.abs(boundary[1]-.75)<.02);assert.equal(compositions.snapComposition(edgeBox,240,240,1,'sticker','',boundary).box.x,boundary[0]);
let edgeTime=performance.now();for(let i=0;i<5000;i++){const b=g.capabilityAttachmentEdges(boundaryCard,edgeBox);compositions.snapComposition(edgeBox,240,240,1,'sticker','',b);}console.log('5000 warm silhouette-edge snaps: '+(performance.now()-edgeTime).toFixed(2)+' ms (host CPU, not device FPS)');

const attachments=load('EdgeAttachment');
for(const shape of ['round','rect','pill','blob','subject'])for(const side of ['left','right'])for(const outer of [false,true]){
 const card=new s.FridgeCard();card.shape=shape;card.w=240;card.h=280;card.capability={k:'date',readingBlend:'sticker'};card.outline=[[{x:.25,y:0},{x:.65,y:0},{x:.95,y:.5},{x:.65,y:1},{x:.25,y:1},{x:.05,y:.5}]];
 for(let step=0;step<=30;step++){const b={x:0,y:step/50,w:.6,h:.35,rot:0,opacity:1},contact=attachments.edgeAttachment(card,b,side,outer);assert.equal(contact.profile.length,25);for(let i=0;i<=24;i++)assert.ok(contact.profile[i]>=-.001&&contact.profile[i]<=1.001);assert.ok(Number.isFinite(contact.gutter));assert.ok(contact.box.w*card.w-contact.gutter>=m.capabilityReadableMinimum(card.capability).w+11.99,'contour cannot invade the readable content budget');}
}
console.log('PASS 620 side attachments: continuous inner/outer contact, finite sampled profiles and protected content budgets');

// Contact excursions add material, never steal the user's content width, even beyond artwork bounds.
for(const side of ['left','right'])for(const outer of [false,true]){const c=new s.FridgeCard();c.w=90;c.h=160;c.shape='round';c.capability={k:'clock'};const b=new s.ElementBox();b.w=1.6;b.h=.3;let width;for(let i=0;i<50;i++){b.y=i/70;const a=attachments.edgeAttachment(c,b,side,outer);const core=a.box.w*c.w-a.gutter;assert.ok(Math.abs(core-144)<1e-8);assert.ok(a.box.w>1);if(width!==undefined)assert.ok(Math.abs(core-width)<1e-8);width=core;}}

const readingNative=fs.readFileSync(path.join(root,'../views/ReadingBacking.ets'),'utf8');assert.ok(readingNative.includes('Path().commands(this.path())'),'live contour is a native Path rather than a resized and cleared Canvas');const layerSource=fs.readFileSync(path.join(root,'../views/CardCanvas.ets'),'utf8');assert.ok(layerSource.includes("this.card.capFree || isReadingComposition(this.card.capability?.readingBlend??'')"),'starting a material drag cannot replace its rendering branch');
