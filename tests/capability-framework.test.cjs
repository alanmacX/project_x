const assert=require('node:assert/strict'),fs=require('node:fs'),path=require('node:path'),vm=require('node:vm');
const ts=require('/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript');
const root=path.resolve(__dirname,'../entry/src/main/ets/model'),cache=new Map();
function load(name){const file=path.resolve(root,name+'.ets');if(cache.has(file))return cache.get(file).exports;const mod={exports:{}};cache.set(file,mod);const code=ts.transpileModule(fs.readFileSync(file,'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText;vm.runInThisContext('(function(require,module,exports){'+code+'\n})',{filename:file})(s=>s==='@kit.ArkTS'?{taskpool:{}}:s==='@kit.BasicServicesKit'?{deviceInfo:{sdkApiVersion:24}}:load(path.relative(root,path.resolve(path.dirname(file),s))),mod,mod.exports);return mod.exports;}
const s=load('CardSchema'),c=load('CapabilityCatalog'),p=load('CapabilityPresentation'),g=load('CanvasLayout'),m=load('CapabilityMetrics'),intake=load('ParcelIntake'),actions=load('WidgetActions'),hit=load('WidgetHitTest'),templates=load('TemplatePackage');
assert.deepEqual(c.CAPABILITY_CATALOG.map(x=>x.key).sort(),s.CAPABILITIES.slice().sort(),'every shipped capability has a source/purpose/detail contract');
for(const cap of c.CAPABILITY_CATALOG){assert.ok(cap.source&&cap.summary&&cap.detail);assert.ok(c.CAPABILITY_GROUPS.includes(cap.group));const min=m.capabilityMinimum({k:cap.key},true);assert.ok(min.w>=64&&min.h>=36);}
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
const shape=new s.FridgeCard();shape.shape='subject';shape.subjectBorder=false;shape.w=300;shape.h=300;shape.capability={k:'clock'};
shape.outline=[[{x:0,y:0},{x:1,y:0},{x:1,y:.4},{x:.4,y:.4},{x:.4,y:1},{x:0,y:1}]];
shape.capBox={x:.08,y:.7,w:.28,h:.14,rot:0,opacity:1};const placed=g.capabilityPlacement(shape);assert.ok(Math.abs(placed.y-.7)<.001,'requested lower arm remains outside the largest upper rectangle');
shape.elements=[{...new s.CanvasElement(),kind:'text',x:0,y:0,w:1,h:1}];assert.ok(g.capabilityObstructed(shape));assert.ok(g.capabilityPlacement(shape).y>.5,'intentional overlap never automatically relocates a capability');
const previous={...placed},requested={...placed,x:.65,y:.65};const constrained=g.constrainCapabilityDrag(shape,requested,previous);assert.ok(constrained.x+constrained.w<=.4+.001 || constrained.y+constrained.h<=.4+.001,'gesture never enters transparent cutout');
console.log('PASS grouped layer ordering; detached canvas snapshots; transparent reading veil and contrasting glyph halos; whole-silhouette placement and bounded drag');

const hollow={...shape,cutout:'',outline:[[{x:0,y:0},{x:1,y:0},{x:1,y:1},{x:0,y:1}],[{x:.4,y:.4},{x:.6,y:.4},{x:.6,y:.6},{x:.4,y:.6}]],elements:[],capBox:{x:.3,y:.3,w:.28,h:.14,rot:0,opacity:1}};
const holeFit=g.capabilityPlacement(hollow);assert.ok(holeFit.x+holeFit.w<=.4 || holeFit.x>=.6 || holeFit.y+holeFit.h<=.4 || holeFit.y>=.6,'capability never covers a transparent hole');
let travel={...placed};const started=performance.now();for(let i=0;i<5000;i++){travel=g.constrainCapabilityDrag(shape,{...travel,x:.08+(i%10)*.002,y:.7+(i%7)*.002},travel);}console.log('5000 cached capability drag queries: '+(performance.now()-started).toFixed(2)+' ms (model CPU, not device FPS)');

const material=load('ChromeMaterial');
material.prepareChromeMaterial().then(()=>{const old={systemMaterial:()=>{throw Error('API26 method called on API24');}};material.immersiveChrome().applyNormalAttribute(old);material.immersiveReading('#E0FFFFFF').applyNormalAttribute(old);assert.equal(material.chromeMaterial(),undefined);console.log('PASS API24 material module and method guards');}).catch(e=>{console.error(e);process.exitCode=1;});

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
