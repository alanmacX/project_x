// Executes the real model/service sources with only the Harmony platform APIs mocked.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const ts = require(process.env.FRIDGE_TYPESCRIPT || '/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript');
const root = path.resolve(__dirname, '../entry/src/main/ets/model');
const disk = new Map();
const writes = [], updates = [], closed = [], opened = [];
let failWrite = false, failForm = false;
const prefs = {
  get: async (key, fallback) => disk.has(key) ? disk.get(key) : fallback,
  put: async (key, value) => {
    if (failWrite) { failWrite = false; throw Error('disk failure'); }
    await new Promise(resolve => setTimeout(resolve, 2));
    disk.set(key, value); writes.push([key, value]);
  },
  flush: async () => {},
  delete: async key => disk.delete(key),
};
const kits = {
  '@kit.BasicServicesKit':{batteryInfo:{batterySOC:60,chargingStatus:0,BatteryChargeState:{ENABLE:1}}},
  '@kit.CalendarKit':{calendarManager:{}},
  '@kit.AbilityKit':{abilityAccessCtrl:{GrantStatus:{PERMISSION_GRANTED:0},createAtManager:()=>({checkAccessToken:async()=>-1})}},
  '@kit.NetworkKit':{http:{}},
  '@ohos.data.preferences': { default: { getPreferences: async () => prefs, removePreferencesFromCache: async () => {} } },
  '@kit.FormKit': {
    formInfo: {VisibilityType:{FORM_VISIBLE:1}},
    formBindingData: { createFormBindingData: data => data },
    formProvider: { setFormNextRefreshTime: async()=>{}, updateForm: async (id, data) => {
      if (failForm) { failForm = false; throw Error('removed form'); }
      updates.push({id, data});
    } },
  },
  '@kit.CoreFileKit': { fileIo: {
    OpenMode: { READ_ONLY: 0 },
    open: async name => { opened.push(name); if (name.includes('missing')) throw Error('missing photo'); return {fd: 11}; },
    closeSync: fd => closed.push(fd),
  } },
  '@kit.PerformanceAnalysisKit': { hilog: {warn: () => {}, error: () => {}} },
};
const jobs = [];
kits['@kit.ArkTS'] = { taskpool: { Task: class { constructor(fn,...args){this.fn=fn;this.args=args;} setTransferList(list){this.transfer=list;} }, execute: async task => { jobs.push(task.fn.name); await new Promise(resolve=>setImmediate(resolve)); return task.fn(...task.args); } } };
const cache = new Map();
function load(name) {
  const file = path.resolve(root, name + '.ets');
  if (cache.has(file)) return cache.get(file).exports;
  const module = {exports: {}}; cache.set(file, module);
  const code = ts.transpileModule(fs.readFileSync(file, 'utf8').replace(/^@Concurrent\s*$/gm, ''), {
    compilerOptions: {module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2020},
  }).outputText;
  const requireMock = spec => kits[spec] || load(path.relative(root, path.resolve(path.dirname(file), spec)));
  vm.runInThisContext('(function(require,module,exports){' + code + '\n})', {filename:file})(requireMock, module, module.exports);
  return module.exports;
}
(async () => {
  const {FridgeStore, FridgeCard, CanvasElement, normalizeState, defaultState, materialColors} = load('FridgeModel');
  const {widgetHit, widgetCanvasPoint, widgetCardPoint} = load('WidgetHitTest');
  const {cardRenderSnapshot} = load('CardViewSnapshot');
  const {cardOutline} = load('RenderContours');
  const {BOARD_W: hitBoardWidth} = load('CardSchema');
  const low = new FridgeCard(); low.id='low'; low.x=40; low.y=70; low.w=180; low.h=180; low.z=1; low.capability={k:'date'};
  const high = new FridgeCard(); Object.assign(high,low,{id:'high',z:2,shape:'subject',capability:{k:'clock'},subjectBorder:false});
  high.outline=[[{x:0,y:0},{x:1,y:0},{x:1,y:1},{x:0,y:1}], [{x:.35,y:.35},{x:.65,y:.35},{x:.65,y:.65},{x:.35,y:.65}]];
  const thin=cardRenderSnapshot(high); assert.equal(thin.outline.length,0); assert.equal(cardOutline(thin),high.outline,'render contours stay outside reactive props without losing precision');
  assert.equal(cardRenderSnapshot(high),thin,'unchanged render snapshots reuse identity');
  assert.equal(load('CardViewSnapshot').cardViewSnapshot(thin).outline,high.outline,'render snapshots hydrate into complete storage/undo snapshots');
  high.paper='#ABCDEF'; assert.notEqual(cardRenderSnapshot(high),thin,'changed visual content invalidates the snapshot cache');
  for (const [width,height] of [[344,344],[380,400],[700,520],[520,700]]) {
    for (const angle of [-15,0,23]) {
      high.rot=angle;low.rot=angle;
      for (const [fx,fy,expected] of [[.5,.5,'low'],[.2,.2,'high']]) {
        const x=high.w*width/hitBoardWidth*fx,y=high.h*width/hitBoardWidth*fy;
        const p=widgetCanvasPoint(high,x,y,width,height),q=widgetCardPoint(high,p.x,p.y,width,height);
        assert.ok(Math.abs(q.x-x)<1e-8 && Math.abs(q.y-y)<1e-8,'rotation and independent canvas axes invert exactly');
        assert.equal(widgetHit([low,high],p.x,p.y,width,height).id,expected,'holes pass to visible lower card');
      }
      high.capability=null;
      const p=widgetCanvasPoint(high,high.w*width/hitBoardWidth*.2,high.h*width/hitBoardWidth*.2,width,height);
      assert.equal(widgetHit([low,high],p.x,p.y,width,height).id,'','opaque decorative card occludes underlying capability');
      high.capability={k:'clock'};
    }
    assert.equal(widgetHit([low,high],width-2,2,width,height).id,'','rounded canvas corner is inert');
    assert.equal(widgetHit([low,high],-1,100,width,height).id,'','off-canvas points are rejected');
  }
  const {CardEditHistory} = load('CardEditHistory');
  const historyCard = new FridgeCard(); historyCard.id='history'; historyCard.outline=[[{x:0,y:0},{x:1,y:1}]];
  const history = new CardEditHistory(); history.reset(historyCard);
  historyCard.paper='#112233'; history.record(historyCard);
  historyCard.rot=3; history.record(historyCard,'drag1'); historyCard.rot=8; history.record(historyCard,'drag1');
  const undone=history.undo(); assert.equal(undone.rot,0); assert.equal(undone.paper,'#112233','a whole gesture is one undo step');
  assert.equal(undone.outline,historyCard.outline,'history does not clone immutable contours');
  const redone=history.redo(); assert.equal(redone.rot,8); redone.paper='#abcdef';
  assert.equal(history.undo().paper,'#112233','returned snapshots cannot mutate stored history');
  const restored=history.undo(); assert.equal(restored.paper,''); assert.equal(history.canUndo(),false);
  restored.paper='#445566'; history.record(restored); assert.equal(history.canRedo(),false,'new edits discard redo');
  const cancelled = new CardEditHistory(); cancelled.reset(restored);
  restored.rot=15; cancelled.record(restored,'cancel'); restored.rot=0; cancelled.record(restored,'cancel');
  assert.equal(cancelled.canUndo(),false,'cancelled gesture creates no empty undo step');
  const other=new FridgeCard(); other.id='other'; history.record(other);assert.equal(history.canUndo(),false,'switching cards resets history');
  const {editorViewport} = load('EditorViewport');
  for (const [screenW, screenH] of [[390,844],[844,390],[1138,712],[712,1138]]) {
    const landscape = screenW > screenH, viewportW = landscape ? screenW * .56 : screenW;
    for (const [w,h] of [[320,420],[300,80],[80,400]]) for (const angle of [-15,0,15,85]) {
      const v = editorViewport(w,h,angle,viewportW,screenH,36,24,landscape);
      const rad = angle*Math.PI/180, cw = w*v.scale, ch = h*v.scale;
      const points = [[0,ch],[ch*Math.sin(rad),ch-ch*Math.cos(rad)],
        [cw*Math.cos(rad)+ch*Math.sin(rad),ch+cw*Math.sin(rad)-ch*Math.cos(rad)],
        [cw*Math.cos(rad),ch+cw*Math.sin(rad)]];
      for (const [x,y] of points) {
        assert.ok(v.left+x >= 47.99 && v.left+x <= viewportW-47.99, 'rotated preview stays within horizontal controls');
        assert.ok(v.top+y >= 23.99 && v.top+y <= v.height-23.99, 'rotated preview stays within vertical controls');
      }
      assert.ok(v.height+36+24+(landscape ? 76 : 192) <= screenH+.01, 'preview leaves room for controls and safe areas');
    }
  }
  const {selectionHandles}=load('SelectionHandles');
  const tinyBox={x:.3,y:.35,w:.12,h:.09,rot:25};
  const tinyHandles=selectionHandles(tinyBox,260,300,12,460,430);
  assert.ok(Math.hypot(tinyHandles.resize.x-tinyHandles.pivot.x,tinyHandles.resize.y-tinyHandles.pivot.y)>50,
    'resize handle does not cover the move region of a tiny element');

  for(const [vw,vh,w,h] of [[391,367,295,295],[600,402,330,330]]) {
    for(const x of [0,.45,.96]) for(const y of [0,.45,.96]) for(const rot of [0,25,90,175]) {
      const box={x,y,w:.04,h:.04,rot};const handles=selectionHandles(box,w,h,12,vw,vh);
      assert.ok(Math.hypot(handles.resize.x-handles.rotate.x,handles.resize.y-handles.rotate.y)>=52-1e-8,'tiny and edge elements retain separate 44vp controls');
      for(const p of [handles.resize,handles.rotate])assert.ok(p.x>=22&&p.x<=vw-22&&p.y>=22&&p.y<=vh-22,'full hit regions stay inside viewport');
    }
  }
  const {capabilityBox, safeContentBox, subjectInterior, resizeFactor, clampCardGeometry, capabilityPlacement, minimumCardSize, ensureCapabilitySize, cardHandlePoint} = load('CanvasLayout');
  const {sceneRect,scenePercent} = load('SceneLayout');
  const {cardContainsPoint} = load('CardHitTest');
  const {storageSnapshot}=load('StorageSnapshot');
  const {LatestWidgetQueue}=load('LatestWidgetQueue');
  const sent=[];let release;const queue=new LatestWidgetQueue(async json=>{sent.push(json);if(json==='A')await new Promise(r=>release=r);});
  const firstDelivery=queue.submit('A');queue.submit('B');queue.submit('C');release();await firstDelivery;assert.deepEqual(sent,['A','C'],'pending scenes coalesce to the newest without delivering stale intermediate scenes');
  await queue.submit('C');assert.equal(sent.length,2,'successful revisions are acknowledged');
  let attempts=0;const retryQueue=new LatestWidgetQueue(async()=>{if(++attempts===1)throw Error('IPC');});await assert.rejects(retryQueue.submit('same'));await retryQueue.submit('same');assert.equal(attempts,2,'a failed revision is never acknowledged');
  const {combineCards,ungroupCards,groupMembers,cleanGroups,groupDragBounds}=load('CardGroups');
  const members=[new FridgeCard(),new FridgeCard(),new FridgeCard()];members.forEach((c,i)=>{c.id='group'+i;c.x=.15+i*.1;c.y=.25;});
  combineCards(members,['group0','group1'],'first');combineCards(members,['group1','group2'],'merged');assert.equal(groupMembers(members,members[0]).length,3,'combining a member merges the entire existing group');
  const before=members.map(c=>[c.x,c.y,c.rot,c.w,c.h]);const limits=groupDragBounds(members,members[0]);assert.ok(limits.minX<=members[0].x&&limits.maxX>=members[0].x);ungroupCards(members,'merged');assert.deepEqual(members.map(c=>[c.x,c.y,c.rot,c.w,c.h]),before,'ungrouping never changes layout');members[0].groupId='orphan';cleanGroups(members);assert.equal(members[0].groupId,'');
  const {contourPath}=load('ContourPath');const square=[{x:0,y:0},{x:1,y:0},{x:1,y:1},{x:0,y:1}];const curve=contourPath([square,square.slice().reverse()],100,100,1);assert.equal((curve.match(/Z/g)||[]).length,2,'independent closed loops retain holes');assert.ok(curve.startsWith('M0,0 L100,0 L100,100 L0,100 L0,0 Z'),'deliberate large corners remain pinned without redundant curve commands');
  const {compactContours}=load('ContourGeometry');
  const denseLoop=Array.from({length:4000},(_,i)=>{const a=i*Math.PI*2/4000;return {x:.5+.4*Math.cos(a),y:.5+.4*Math.sin(a)};});
  const hole=Array.from({length:400},(_,i)=>{const a=-i*Math.PI*2/400;return {x:.5+.05*Math.cos(a),y:.5+.05*Math.sin(a)};});
  const reduced=compactContours([denseLoop,hole]);assert.equal(reduced.length,2,'holes remain independent closed loops');
  assert.ok(reduced[0].length<400,'smooth contours reduce substantially');
  const segDistance=(p,a,b)=>{const dx=b.x-a.x,dy=b.y-a.y,n=dx*dx+dy*dy,t=n?Math.max(0,Math.min(1,((p.x-a.x)*dx+(p.y-a.y)*dy)/n)):0;return Math.hypot(p.x-a.x-t*dx,p.y-a.y-t*dy);};
  for(let ring=0;ring<2;ring++)for(const point of [denseLoop,hole][ring])assert.ok(Math.min(...reduced[ring].map((a,i)=>segDistance(point,a,reduced[ring][(i+1)%reduced[ring].length])))<=.000350001,'every original boundary point stays inside the hard geometric tolerance');
  const thinOutline=[{x:0,y:0},{x:.9,y:0},{x:.9,y:.0001},{x:.1,y:.0001},{x:.1,y:1},{x:0,y:1}];
  const kept=compactContours([thinOutline],.001)[0];assert.ok(kept.some(p=>p.x===.9&&p.y===.0001),'thin protrusions retain their endpoints');

  const snapState=defaultState();let contourReads=0;
  const measured=new FridgeCard();measured.id='measured';measured.outline=[[{get x(){contourReads++;return .2;},get y(){contourReads++;return .3;}}]];
  const literal=new CanvasElement();literal.text='$& $` $\' $$';measured.elements=[literal];
  snapState.cards=[measured];const originalStorage=JSON.parse(storageSnapshot(snapState));const firstReads=contourReads;
  measured.x=123;const movedStorage=JSON.parse(storageSnapshot(snapState));
  assert.equal(contourReads,firstReads,'geometry saves never traverse immutable contour vertices again');
  assert.equal(originalStorage.cards[0].elements[0].text,literal.text,'template text is preserved literally during contour splicing');
  assert.equal(originalStorage.cards[0].x,24);assert.equal(movedStorage.cards[0].x,123);assert.deepEqual(movedStorage.cards[0].outline,[[{x:.2,y:.3}]]);
  measured.outline=[[{x:.9,y:.8}]];assert.deepEqual(JSON.parse(storageSnapshot(snapState)).cards[0].outline,measured.outline,'replacing the subject invalidates only its contour serialization');

  const {dragBounds}=load('DragGeometry');
  const {arrivalOffset}=load('ArrivalGeometry');
  for (const angle of [-175,-90,-15,0,15,85,175]) {
    const card=new FridgeCard();Object.assign(card,{w:119,h:239,rot:angle});
    const bounds=dragBounds(card);
    for (const x of [-2000,-12,120,2000]) for (const y of [-2000,-15,200,2000]) {
      card.x=x;card.y=y;const cx=Math.max(bounds.minX,Math.min(bounds.maxX,x)),cy=Math.max(bounds.minY,Math.min(bounds.maxY,y));
      clampCardGeometry(card);
      assert.ok(Math.abs(card.x-cx)<1e-8&&Math.abs(card.y-cy)<1e-8,'cached drag limits preserve recoverable rotated geometry');
    }
    for (const [width,height] of [[344,344],[700,520],[390,700]]) for (const [x,y] of [[-10,-20],[50,60],[200,220],[300,320]]) {
      card.x=x;card.y=y;const offset=arrivalOffset(card,width,height),r=sceneRect(card,width,height),a=angle*Math.PI/180;
      const xs=[r.x,r.x+r.h*Math.sin(a),r.x+r.w*Math.cos(a)+r.h*Math.sin(a),r.x+r.w*Math.cos(a)].map(v=>v+offset.x);
      const ys=[r.y+r.h,r.y+r.h-r.h*Math.cos(a),r.y+r.h+r.w*Math.sin(a)-r.h*Math.cos(a),r.y+r.h+r.w*Math.sin(a)].map(v=>v+offset.y);
      assert.ok(offset.x===0||offset.y===0,'arrival uses one edge without diagonal crossing');
      assert.ok(Math.max(...xs)<=-23.99||Math.min(...xs)>=width+23.99||Math.max(...ys)<=-23.99||Math.min(...ys)>=height+23.99,'entire rotated card begins beyond its chosen edge');
    }
  }
  for (const [vw,pane] of [[222,240],[550,300],[180,200]]) for (const angle of [-85,-15,0,35,85]) {
    const v=editorViewport(119,239,angle,vw,712,36,24,vw>300,pane),a=angle*Math.PI/180,w=119*v.scale,h=239*v.scale;
    const points=[[0,h],[h*Math.sin(a),h-h*Math.cos(a)],[w*Math.cos(a)+h*Math.sin(a),h+w*Math.sin(a)-h*Math.cos(a)],[w*Math.cos(a),h+w*Math.sin(a)]];
    for(const [x,y] of points)assert.ok(v.left+x>=27.99&&v.left+x<=vw-27.99&&v.top+y>=23.99&&v.top+y<=pane-23.99,'compact preview fits its own pane including rotated bounds');
  }

  const cacheCard = new FridgeCard(); cacheCard.shape='subject';
  cacheCard.outline=[[{x:.1,y:.1},{x:.9,y:.1},{x:.9,y:.9},{x:.1,y:.9}]];
  const cachedInterior = safeContentBox(cacheCard);
  const originalStringify = JSON.stringify;
  try {
    JSON.stringify = function(value, ...args) {
      assert.notEqual(value, cacheCard.outline, 'cache lookups must not serialize the contour');
      return originalStringify(value, ...args);
    };
    for (let i=0;i<100;i++) { safeContentBox(cacheCard); capabilityBox(cacheCard); }
  } finally { JSON.stringify = originalStringify; }
  const assetCard = new FridgeCard(); assetCard.shape='subject'; assetCard.cutout='file:///private/immutable-subject.png';
  assetCard.outline=cacheCard.outline;
  const assetBox=safeContentBox(assetCard);
  const propagated=JSON.parse(JSON.stringify(assetCard));
  Object.defineProperty(propagated.outline[0][0], 'x', {get() { throw Error('copied contour should hit existing cache'); }});
  assert.deepEqual(JSON.parse(JSON.stringify(safeContentBox(propagated))), JSON.parse(JSON.stringify(assetBox)), 'ArkUI copied contours keep the same layout');
  propagated.cutout='file:///private/replacement-subject.png';
  propagated.outline=[[{x:.4,y:.1},{x:.6,y:.1},{x:.6,y:.9},{x:.4,y:.9}]];
  assert.ok(safeContentBox(propagated).w < assetBox.w, 'a replacement asset invalidates copied-contour cache');
  cacheCard.outline=[[{x:.4,y:.1},{x:.6,y:.1},{x:.6,y:.9},{x:.4,y:.9}]];
  assert.ok(safeContentBox(cacheCard).w < cachedInterior.w, 're-extraction invalidates the interior cache');
  const hitCard = new FridgeCard(); hitCard.w = 200; hitCard.h = 100;
  assert.equal(cardContainsPoint(hitCard,100,50,1),true);
  assert.equal(cardContainsPoint(hitCard,1,1,1),false,'rounded transparent corner passes through');
  assert.equal(cardContainsPoint(hitCard,-1,50,1),false,'control padding is not the card face');
  hitCard.shape='round';assert.equal(cardContainsPoint(hitCard,10,10,1),false);assert.equal(cardContainsPoint(hitCard,100,50,1),true);
  hitCard.shape='subject'; hitCard.subjectBorder=false;
  hitCard.outline=[[{x:.1,y:.1},{x:.9,y:.1},{x:.9,y:.9},{x:.1,y:.9}], [{x:.4,y:.4},{x:.6,y:.4},{x:.6,y:.6},{x:.4,y:.6}]];
  assert.equal(cardContainsPoint(hitCard,40,50,1),true);
  assert.equal(cardContainsPoint(hitCard,5,50,1),false,'subject bounding box background passes through');
  assert.equal(cardContainsPoint(hitCard,100,50,1),false,'subject hole passes through');
  assert.equal(cardContainsPoint(hitCard,20,25,.5),true,'display scaling preserves hit location');
  hitCard.subjectBorder=true;assert.equal(cardContainsPoint(hitCard,22,50,1),true,'white outline is interactive');

  const cropCard=new FridgeCard();cropCard.id='crop';cropCard.x=-40;cropCard.y=-25;cropCard.w=180;cropCard.h=120;cropCard.rot=15;
  clampCardGeometry(cropCard);assert.equal(cropCard.x,-40);assert.equal(cropCard.y,-25,'intentional partial edge cropping is preserved');
  const cropReload=normalizeState({schemaVersion:2,cards:[cropCard]});assert.equal(cropReload.cards[0].x,-40);assert.equal(cropReload.cards[0].y,-25);
  for(const [width,height] of [[344,344],[344,172],[344,516],[560,492]]){
    const app=sceneRect(cropCard,width,height),form=scenePercent(cropCard,width/height);
    for(const [key,extent] of [['x',width],['y',height],['w',width],['h',height]])assert.ok(Math.abs(app[key]-form[key]/100*extent)<1e-7,'app and widget geometry agree');
    assert.ok(Math.abs(app.w/app.h-cropCard.w/cropCard.h)<1e-7,'changing widget ratio preserves card proportions');
    assert.equal(app.rot,15);
  }
  const previousRect=kits['@kit.FormKit'].formProvider.getFormRect;
  kits['@kit.FormKit'].formProvider.getFormRect=async()=>({width:560,height:492});
  const {normalizeBox, CAPABILITIES, contrastingInk} = load('CardSchema');
  const {updateWidget, pushWidgets, widgetImageKey} = load('WidgetSync');
  kits['@kit.CoreVisionKit'] = {subjectSegmentation:{}};
  kits['@kit.ImageKit'] = {image:{}};
  const {traceMask, extractSubject, repairSubject} = load('SubjectShape');
  await updateWidget('geometry-form',JSON.stringify({schemaVersion:2,cards:[]}), '4*4');
  assert.equal(updates.at(-1).data.canvasWidth,560);assert.equal(updates.at(-1).data.canvasHeight,492);updates.length=0;
  kits['@kit.FormKit'].formProvider.getFormRect=previousRect;
  assert.equal(contrastingInk('#FFFFFF'),'#262824'); assert.equal(contrastingInk('#262824'),'#FFFFFF');
  assert.equal(defaultState().cards.length, 0);
  assert.deepEqual(CAPABILITIES,['clock','date','calendar','countdown','anniversary','dayprogress','yearprogress','battery','agenda','timetable','worldclock','lunar','album']);
  assert.ok(!CAPABILITIES.includes('np'));
  const legacy = {id:'legacy',w:999,h:-1,x:800,y:-20,z:42,caps:[
    {k:'text',text:'自己的文字 ☕',fs:22}, {k:'clock'}, {k:'countdown',title:'生日',date:'2027-01-01'},
    {k:'np',title:'一首歌',artist:'艺术家'}, {k:'photo',seed:'file:///photo.jpg',label:'海边'}]};
  const migrated = normalizeState({cards:[legacy]});
  assert.equal(migrated.schemaVersion, 2);
  assert.equal(migrated.cards.length, 2, 'extra legacy capabilities get their own card');
  assert.equal(migrated.cards[0].capability.k, 'clock');
  assert.equal(migrated.cards[1].capability.title, '生日');
  assert.equal(migrated.cards[0].elements[0].text, '自己的文字 ☕');
  assert.equal(migrated.cards[0].elements[1].text, '一首歌\n艺术家');
  assert.equal(migrated.cards[0].elements[3].text, '海边');
  assert.ok(migrated.cards.every(c => !c.caps));
  assert.equal(migrated.cards[0].w, 320); assert.equal(migrated.cards[0].h, 32);
  assert.equal(migrated.cards[0].x, 312); assert.equal(migrated.cards[0].y, -20);
  assert.deepEqual(normalizeState(migrated), migrated, 'migration is idempotent');
  const box = normalizeBox({w:1,h:1}); assert.equal(box.x, 0); assert.equal(box.y, 0);
  assert.deepEqual(materialColors('dark', '#aabbcc', 'bad'), ['#aabbcc', '#F4F3EF']);
  const custom = new FridgeCard(); custom.id = 'custom';
  const element = new CanvasElement(); element.id = 'text'; element.text = 'first'; custom.elements.push(element);
  assert.equal(normalizeState({schemaVersion:2,cards:[custom]}).cards[0].capability, null);
  const store = new FridgeStore(); await store.init({});
  const {CANVAS_CARD_LIMIT,canvasCapacityHint}=load('CanvasCapacity');
  const boundedStore=new FridgeStore();
  const batch=Array.from({length:CANVAS_CARD_LIMIT},(_,i)=>Object.assign(new FridgeCard(),{id:'limit_'+i}));
  boundedStore.addCards(batch);const originalZ=boundedStore.state.maxZ;
  assert.throws(()=>boundedStore.addCard(new FridgeCard()),/最多 16/);
  assert.equal(boundedStore.state.cards.length,16);assert.equal(boundedStore.state.maxZ,originalZ,'rejected insertion never changes z-order');
  boundedStore.removeCard(batch[0].id);
  assert.throws(()=>boundedStore.addCards([new FridgeCard(),new FridgeCard()]),/最多 16/);
  assert.equal(boundedStore.state.cards.length,15,'over-budget batch is atomic');boundedStore.addCard(new FridgeCard());
  assert.equal(canvasCapacityHint(11),'');assert.match(canvasCapacityHint(12),/另一张画布/);assert.match(canvasCapacityHint(16),/已达上限/);
  const oversizedLegacy=defaultState();oversizedLegacy.cards=Array.from({length:17},(_,i)=>Object.assign(new FridgeCard(),{id:'legacy_'+i}));
  assert.equal(normalizeState(oversizedLegacy).cards.length,17,'stored legacy works are preserved, never truncated');
  const catalogBefore=JSON.stringify(boundedStore.catalog);assert.throws(()=>boundedStore.createCanvas('too large',oversizedLegacy),/最多 16/);
  assert.equal(JSON.stringify(boundedStore.catalog),catalogBefore,'oversized canvas creation leaves catalog intact');
  boundedStore.createCanvas('empty');assert.equal(boundedStore.state.cards.length,0,'capacity is per canvas');
  const ids = Array.from({length:1000}, () => store.newId()); assert.equal(new Set(ids).size,1000);
  store.addCard(custom); const first = store.save(); element.text = 'second'; const second = store.save();
  await Promise.all([first,second]);
  assert.equal(JSON.parse(writes.find(([key])=>key==='fridge_state_json')[1]).cards[0].elements[0].text, 'first');
  assert.equal(JSON.parse(disk.get('fridge_state_json')).cards[0].elements[0].text, 'second');
  const {cardViewSnapshot}=load('CardViewSnapshot');
  custom.outline=[[{x:.1,y:.2},{x:.8,y:.9}]];
  const view=cardViewSnapshot(custom);assert.equal(view.outline,custom.outline,'immutable contour is shared');
  view.elements[0].text='view-only';assert.equal(custom.elements[0].text,'second','editable element snapshot is isolated');
  const widgetUpdates=updates.length; element.text='local draft'; await store.save(false);
  assert.equal(updates.length,widgetUpdates,'editor draft saves locally without pushing desktop photos');
  await store.save(true);assert.ok(JSON.parse(disk.get('fridge_state_json')).cards[0].elements[0].text==='local draft');
  const savedWrites=writes.length, savedUpdates=updates.length; await store.save();
  assert.equal(writes.length,savedWrites,'unchanged snapshots do not flush preferences again');
  assert.equal(updates.length,savedUpdates,'unchanged snapshots do not resend photo descriptors');
  element.text = 'unsaved change'; failWrite = true; await assert.rejects(store.save(), /disk failure/);
  element.text = 'retry'; await store.save(); const reloaded = new FridgeStore(); await reloaded.init({});
  assert.equal(reloaded.state.cards[0].elements[0].text, 'retry');
  store.removeCard(custom.id); await store.save(); const empty = new FridgeStore(); await empty.init({});
  assert.equal(empty.state.cards.length, 0);
  disk.delete('fridge_canvases_json');disk.delete('fridge_canvas_canvas_main');
  disk.set('fridge_state_json','{broken'); await assert.rejects(new FridgeStore().init({}), /本地卡片数据无法读取/);
  assert.equal(disk.get('fridge_state_json'),'{broken');
  const photo = new FridgeCard(); photo.id='photo'; photo.paper='#234567'; photo.shape='subject'; photo.cutout='file:///private/subject.png';
  const img = new CanvasElement(); img.id='image'; img.kind='image'; img.src='file:///private/photo.gif'; img.animated=true; photo.elements.push(img);
  const snapshot=JSON.stringify({schemaVersion:2,cards:[photo]});
  await updateWidget('123',snapshot,'4*4'); assert.ok(jobs.includes('deliverWidget'),'large widget scene preparation runs through TaskPool'); const payload=updates.at(-1).data;
  assert.equal(payload.formImages[widgetImageKey('photo_image',img.src)],11); assert.equal(payload.formImages[widgetImageKey('photo_subject',photo.cutout)],11);
  const transfer=JSON.parse(payload.faceCards)[0];
  assert.equal(transfer.elements[0].animated,true,'GIF playback metadata survives form transfer'); assert.equal(transfer.elements[0].src,'memory://'+widgetImageKey('photo_image',img.src)); assert.equal(transfer.cutout,'memory://'+widgetImageKey('photo_subject',photo.cutout));
  assert.deepEqual(JSON.parse(payload.cards), JSON.parse(payload.faceCards), 'one atomic scene contains transferred images');
  assert.notEqual(widgetImageKey('photo_image',img.src),widgetImageKey('photo_image','file:///private/replacement.gif'),'replacing a photo refreshes its image resource');
  assert.equal(photo.elements[0].src,'file:///private/photo.gif'); assert.equal(transfer.paper,'#234567');
  assert.equal(closed.length,2); failForm=true;
  await assert.rejects(updateWidget('removed',snapshot,'4*4'),/removed form/); assert.equal(closed.length,4);
  photo.elements[0].src='file:///private/missing.jpg';
  await updateWidget('123',JSON.stringify({schemaVersion:2,cards:[photo]}),'4*4');
  assert.equal(JSON.parse(updates.at(-1).data.faceCards)[0].elements[0].src,'');
  disk.set('fridge_form_dims_json', JSON.stringify({removed:'4*4',working:'2*4'})); failForm=true; await pushWidgets({},snapshot);
  assert.ok(updates.some(u=>u.id==='working')); assert.equal(updates.at(-1).id,'removed','failed instance retries without blocking healthy instance');
  assert.throws(() => traceMask(new Int32Array(2),2,2),/尺寸/);
  assert.throws(() => traceMask(new Int32Array(4),2,2),/未检测/);
  assert.equal(traceMask(new Int32Array([255,255,255,255]),2,2)[0].length,4,'a square preserves four real corners without adding artificial smoothing vertices');
  const ring=traceMask(new Int32Array([255,255,255,255,0,255,255,255,255]),3,3);
  assert.equal(ring.length,2,'holes preserved');
  const area=loop => loop.reduce((sum,p,i) => {const n=loop[(i+1)%loop.length];return sum+p.x*n.y-n.x*p.y;},0);
  assert.ok(area(ring[0])*area(ring[1])<0,'holes have opposite winding');
  assert.equal(traceMask(new Int32Array([255,0,255]),3,1).length,2,'disconnected parts preserved');
  const released=[]; let unavailable=false, segmentationFailure=false, packFailure=false;
  const pixel={getImageInfo:async()=>({size:{width:3,height:3}}),readPixelsToBuffer:async bytes=>new Uint8Array(bytes).fill(255),release:async()=>released.push('pixel')};
  const foreground={release:async()=>released.push('foreground')};
  kits['@kit.ImageKit'].image.PixelMapFormat={RGBA_8888:3};
  kits['@kit.ImageKit'].image.AlphaType={UNPREMUL:3,PREMUL:2};
  kits['@kit.ImageKit'].image.createPixelMap=async()=>({release:async()=>released.push('processed')});
  kits['@kit.ImageKit'].image.createImageSource=()=>({getImageInfo:pixel.getImageInfo,createPixelMap:async()=>pixel,release:async()=>released.push('source')});
  kits['@kit.ImageKit'].image.createImagePacker=()=>({packToFile:async()=>{if(packFailure) throw Error('pack failure');},release:async()=>released.push('packer')});
  Object.assign(kits['@kit.CoreVisionKit'].subjectSegmentation,{
    init:async()=>!unavailable,release:async()=>released.push('service'),
    doSegmentation:async(input,options)=>{
      assert.equal(input.pixelMap,pixel); assert.equal(options.enableSubjectForegroundImage,true);
      if(segmentationFailure) throw Error('native error');
      return {subjectCount:1,subjectDetails:[{foregroundImage:foreground,mattingList:new Int32Array([0,255,0,255,255,255,0,255,0])}]};
    }
  });
  const unlinked=[]; kits['@kit.CoreFileKit'].fileIo.unlink=async path=>unlinked.push(path);
  const shape=await extractSubject('file:///input.jpg','/private');
  assert.ok(jobs.includes('prepareSubjectJob'),'new segmentation submits pixels to TaskPool');
  assert.ok(shape.src.startsWith('file:///private/subject_')); assert.equal(shape.outline.length,1);
  assert.deepEqual(released,['packer','processed','foreground','pixel','source','service']);
  await extractSubject('file://media/Photo/2/picker.jpeg','/private');
  assert.ok(opened.includes('file://media/Photo/2/picker.jpeg'), 'media URI must remain intact');
  const repaired=await repairSubject('file:///old.png','/private');assert.ok(repaired.src.includes('subject_smooth_'));assert.ok(jobs.includes('repairSubjectJob'),'old PNG processing runs as a TaskPool job');
  const originalSourceFactory = kits['@kit.ImageKit'].image.createImageSource;
  let decodeSize;
  kits['@kit.ImageKit'].image.createImageSource=()=>({getImageInfo:async()=>({size:{width:4096,height:3072}}),
    createPixelMap:async options=>{decodeSize=options.desiredSize;return pixel;},release:async()=>released.push('source')});
  await repairSubject('file:///large-old.png','/private');
  assert.deepEqual(decodeSize,{width:1024,height:768},'legacy PNG is bounded before reading pixel bytes');
  kits['@kit.ImageKit'].image.createImageSource=originalSourceFactory;
  packFailure=true; released.length=0;
  const removedBefore=unlinked.length;
  await assert.rejects(repairSubject('file:///old.png','/private'),/pack failure/);
  assert.equal(unlinked.length,removedBefore+1,'failed background packing removes its incomplete output');
  assert.deepEqual(released,['packer','processed','pixel','source']); packFailure=false;
  released.length=0; unavailable=true; await assert.rejects(extractSubject('file:///input.jpg','/private'),/不可用/);
  assert.deepEqual(released,['pixel','source','service']); unavailable=false;
  released.length=0; segmentationFailure=true; await assert.rejects(extractSubject('file:///input.jpg','/private'),/native error/);
  assert.deepEqual(released,['pixel','source','service']); segmentationFailure=false;
  released.length=0; packFailure=true; await assert.rejects(extractSubject('file:///input.jpg','/private'),/pack failure/);
  assert.deepEqual(released,['packer','processed','foreground','pixel','source','service']); assert.equal(unlinked.length,removedBefore+2);
  for (const shape of ['rect','round','pill','blob']) {
    const card = new FridgeCard(); card.id='fit_'+shape; card.shape=shape;
    card.capBox={x:0,y:0,w:1,h:1,rot:-110,opacity:1};
    const box=capabilityBox(card), safe=safeContentBox(card);
    assert.equal(box.rot,0); assert.ok(box.x>=safe.x && box.y>=safe.y);
    assert.ok(box.x+box.w<=safe.x+safe.w+1e-6 && box.y+box.h<=safe.y+safe.h+1e-6);
  }
  const layout = new FridgeCard(); layout.id='avoid'; layout.capability={k:'calendar'};
  const text = new CanvasElement(); text.id='obstacle'; text.x=.1; text.y=.1; text.w=.8; text.h=.45;
  layout.elements=[text]; const free=capabilityBox(layout);
  assert.ok(free.w > 0 && free.h*layout.h >= 62, 'overlapping composition retains a readable compact week');
  const interior=subjectInterior([[{x:.2,y:.1},{x:.8,y:.1},{x:.8,y:.9},{x:.2,y:.9}]]);
  assert.ok(interior.x>=.2 && interior.y>=.1 && interior.x+interior.w<=.8 && interior.y+interior.h<=.9);
  assert.equal(resizeFactor(180,180,18,-18,0),1.1);
  assert.ok(Math.abs(resizeFactor(180,180,18,18,90)-1.1)<1e-6,'resize respects rotation');
  for (const rot of [-15,0,15]) {
    const bounded = new FridgeCard(); bounded.rot=rot; bounded.w=320; bounded.h=420; bounded.x=-100; bounded.y=900;
    clampCardGeometry(bounded);
    const a=rot*Math.PI/180, c=Math.cos(a),s=Math.sin(a);
    const corners=[[0,0],[bounded.w,0],[0,bounded.h],[bounded.w,bounded.h]].map(([x,y])=>[bounded.x+x*c-(y-bounded.h)*s,bounded.y+bounded.h+x*s+(y-bounded.h)*c]);
    assert.ok(Math.max(...corners.map(p=>p[0]))>=32-1e-6 && Math.min(...corners.map(p=>p[0]))<=344-32+1e-6,'cropped cards retain a recoverable horizontal part');
    assert.ok(Math.max(...corners.map(p=>p[1]))>=32-1e-6 && Math.min(...corners.map(p=>p[1]))<=470-32+1e-6,'cropped cards retain a recoverable vertical part');
    assert.equal(bounded.w,320);assert.equal(bounded.h,420,'clamping does not shrink capability content');

  }
  text.x=0;text.y=0;text.w=1;text.h=1;const overlay=capabilityPlacement(layout);
  assert.ok(overlay.w>0 && overlay.h>0,'full foreground gets a readable capability overlay, not a blank card');
  const {prepareSubject, smoothAlpha, cropCardToSubject} = load('SubjectGeometry');
  const width=80,height=100,rgba=new Uint8Array(width*height*4).fill(255),mask=new Int32Array(width*height);
  for(let y=25;y<75;y++) for(let x=20;x<60;x++) mask[y*width+x]=255;
  const cropped=prepareSubject(rgba,mask,width,height);
  assert.ok(cropped.width<=52 && cropped.height<=62,'transparent photo margins are removed');
  assert.ok(cropped.rgba.some((a,i)=>i%4===3 && a>0 && a<255),'edge keeps fractional antialias alpha');
  assert.ok(cropped.outline.every(loop=>loop.every(p=>p.x>=0 && p.x<=1 && p.y>=0 && p.y<=1)));
  // Independent direct Gaussian reference: the constant-window shortcut must
  // produce exactly the same alpha values for binary and soft masks.
  function referenceAlpha(mask,w,h) {
    let l=w,t=h,r=0,b=0;
    for(let y=0;y<h;y++)for(let x=0;x<w;x++)if(mask[y*w+x]>=128){l=Math.min(l,x);t=Math.min(t,y);r=Math.max(r,x);b=Math.max(b,y);}
    const sigma=Math.min(w,h)<8?.55:Math.max(1.4,Math.min(2.6,Math.max(r-l+1,b-t+1)/240));
    const radius=Math.ceil(sigma*3),weights=[];let sum=0;
    for(let i=-radius;i<=radius;i++){const v=Math.exp(-i*i/(2*sigma*sigma));weights.push(v);sum+=v;}
    const tmp=new Float32Array(w*h),out=new Int32Array(w*h);
    for(let y=0;y<h;y++)for(let x=0;x<w;x++){let v=0;for(let i=-radius;i<=radius;i++)v+=mask[y*w+Math.max(0,Math.min(w-1,x+i))]*weights[i+radius];tmp[y*w+x]=v/sum;}
    for(let y=0;y<h;y++)for(let x=0;x<w;x++){let v=0;for(let i=-radius;i<=radius;i++)v+=tmp[Math.max(0,Math.min(h-1,y+i))*w+x]*weights[i+radius];out[y*w+x]=Math.max(0,Math.min(255,Math.round(v/sum)));}
    return out;
  }
  for(const [w,h] of [[3,3],[31,29],[80,70]])for(const soft of [false,true]){
    const mask=new Int32Array(w*h);
    for(let y=0;y<h;y++)for(let x=0;x<w;x++)mask[y*w+x]=soft?(x*97+y*53)%256:((x>w*.2&&x<w*.8&&y>h*.2&&y<h*.8)?255:0);
    assert.deepEqual(smoothAlpha(mask,w,h),referenceAlpha(mask,w,h),'optimized smoothing retains exact Gaussian output');
  }
  const {featherSubjectAlpha}=load('SubjectGeometry');
  const silhouette=new Int32Array(25*25);
  for(let y=3;y<22;y++)for(let x=3;x<22;x++)silhouette[y*25+x]=255;
  silhouette[12*25+12]=0;for(let x=0;x<3;x++)silhouette[12*25+x]=255;
  const feathered=featherSubjectAlpha(silhouette,25,25);
  for(let i=0;i<silhouette.length;i++)assert.equal(feathered[i]>=128,silhouette[i]>=128,'feathering preserves the entire 50% silhouette, including a one-pixel hole and thin bridge');
  const flat=smoothAlpha(new Int32Array(100).fill(255),10,10);assert.ok(flat.every(a=>a===255),'opaque interior is unchanged');
  const tight=new FridgeCard();tight.x=10;tight.y=20;tight.w=160;tight.h=200;
  cropCardToSubject(tight,{x:.25,y:.25,w:.5,h:.5});assert.deepEqual([tight.x,tight.y,tight.w,tight.h],[50,70,80,100]);
  for (const shape of ['rect','round','pill','blob']) for (const k of CAPABILITIES) {
    const card=new FridgeCard();card.shape=shape;card.capability={k};card.w=80;card.h=80;
    assert.equal(ensureCapabilitySize(card),true,shape+':'+k);
    const min=minimumCardSize(card);assert.ok(card.w>=min.w-.01 && card.h>=min.h-.01);
    const slot=capabilityPlacement(card), required=load('CapabilityMetrics').capabilityReadableMinimum(card.capability);
    assert.ok(slot.w*card.w>=required.w-.01 && slot.h*card.h>=required.h-.01,'slot remains legible '+shape+':'+k);
  }
  const handleCard=new FridgeCard();handleCard.shape='subject';handleCard.outline=[[{x:.5,y:0},{x:1,y:.5},{x:.5,y:1},{x:0,y:.5}]];
  const handle=cardHandlePoint(handleCard,true,true);assert.ok(handle.x<1 || handle.y<1,'irregular handle attaches to outline instead of an empty corner');
  const wide=new FridgeCard();wide.id='wide';wide.shape='subject';wide.cutout='file:///wide.png';wide.w=240;wide.h=40;
  assert.equal(ensureCapabilitySize(wide),true);assert.equal(wide.h,40,'a shape-only sticker may be thin without a capability');
  assert.equal(normalizeState({schemaVersion:2,cards:[wide]}).cards[0].h,40,'reload preserves thin subject aspect');
  const narrow=new FridgeCard();narrow.shape='subject';narrow.capability={k:'calendar'};
  narrow.outline=[[{x:.48,y:0},{x:.52,y:0},{x:.52,y:1},{x:.48,y:1}]];
  assert.equal(ensureCapabilitySize(narrow),false,'unsupported thin subjects refuse a capability');
  const {cleanSubjectMask}=load('SubjectGeometry');
  const noisy=new Int32Array(80*80);for(let y=20;y<60;y++)for(let x=20;x<60;x++)noisy[y*80+x]=255;
  noisy[5*80+5]=255;for(let x=60;x<66;x++)noisy[40*80+x]=255;
  const cleaned=cleanSubjectMask(noisy,80,80);assert.equal(cleaned[5*80+5],0,'isolated noise removed');
  assert.equal(cleaned[40*80+65],0,'single pixel spur removed');assert.equal(cleaned[40*80+40],255,'interior preserved');
  const thinMask=new Int32Array(80*80);for(let y=10;y<70;y++)thinMask[y*80+40]=255;
  assert.ok(cleanSubjectMask(thinMask,80,80).some(a=>a===255),'legitimate thin subject is not erased');
  const {compactCapability,capabilityMinimum}=load('CapabilityMetrics');
  for(const k of CAPABILITIES){const min=capabilityMinimum({k},true),full=capabilityMinimum({k});
    assert.ok(min.w<=full.w && min.h<=full.h);assert.equal(compactCapability({k},min.w,min.h),true,'each upcoming capability has a distinct compact presentation');
    assert.equal(compactCapability({k},full.w,full.h),false);}
  const bird=new FridgeCard();bird.shape='subject';bird.w=300;bird.h=360;bird.capability={k:'date'};
  bird.outline=[[{x:.25,y:.2},{x:.75,y:.2},{x:.75,y:.8},{x:.25,y:.8}]];
  const birdMin=minimumCardSize(bird);assert.ok(birdMin.w<170 && birdMin.h<120,'date on a half-width silhouette no longer requires a near-maximum card');
  bird.w=birdMin.w;bird.h=birdMin.h;assert.equal(ensureCapabilitySize(bird),true);
  const slot=capabilityPlacement(bird);assert.ok(slot.w*bird.w>=51.2-.01 && slot.h*bird.h>=38.4-.01);
  bird.subjectBorder=true;const bordered=safeContentBox(bird);assert.ok(bordered.w<safeContentBox({...bird,subjectBorder:false}).w,'white edge remains within measured box and reserves content space');
  assert.equal(normalizeState({schemaVersion:2,cards:[bird]}).cards[0].subjectBorder,true);
  assert.equal(new FridgeCard().subjectBorder,true,'new cutouts default to sticker border');
  assert.equal(normalizeState({schemaVersion:2,cards:[{...bird,subjectBorder:false}]}).cards[0].subjectBorder,true,'all extracted cards use a fixed sticker border');
  const {parseCapabilityAction,applyCalendarAction}=load('CapabilityActions');
  assert.equal(parseCapabilityAction('{bad'),null);assert.equal(parseCapabilityAction('{"cardId":"x","operation":"delete"}'),null);
  const cal=new FridgeCard();cal.capability={k:'calendar'};assert.equal(applyCalendarAction(cal,'nextMonth'),true);assert.equal(cal.capability.calendarOffset,1);
  applyCalendarAction(cal,'previousMonth');assert.equal(cal.capability.calendarOffset,0);
  cal.capability.calendarOffset=120;applyCalendarAction(cal,'nextMonth');assert.equal(cal.capability.calendarOffset,120);
  applyCalendarAction(cal,'currentMonth');assert.equal(cal.capability.calendarOffset,0);assert.equal(applyCalendarAction(bird,'nextMonth'),false);
  const formConfig=JSON.parse(fs.readFileSync(path.join(root,'../../resources/base/profile/form_config.json'),'utf8'));
  assert.deepEqual(formConfig.forms[0].supportDimensions,['4*4'],'one shared phone/tablet desktop size; 6*4 is device-dependent');
  assert.equal(formConfig.forms[0].defaultDimension,'4*4');
  assert.equal(normalizeState({cards:[]}).canvasDimension,'4*4');
  assert.equal(normalizeState({cards:[]}).canvasAspect,1);
  kits['@kit.FormKit'].FormExtensionAbility=class {context={};};
  kits['@kit.AbilityKit']={};
  const FormAbility=load('../form/FridgeFormAbility').default, formAbility=new FormAbility();
  cal.id='action-calendar';custom.id='untouched';custom.elements[0].text='preserved';
  disk.set('fridge_state_json',JSON.stringify({schemaVersion:2,cards:[cal,custom]}));disk.set('fridge_form_dims_json',JSON.stringify({native:'6*4'}));
  formAbility.onFormEvent('native','{"cardId":"action-calendar","operation":"nextMonth"}');
  formAbility.onFormEvent('native','{"cardId":"action-calendar","operation":"nextMonth"}');await formAbility.actionQueue;
  let actionState=JSON.parse(disk.get('fridge_state_json'));assert.equal(actionState.cards[0].capability.calendarOffset,2,'serialized native message actions do not lose increments');
  assert.equal(actionState.cards[1].elements[0].text,'preserved');
  for (const retired of ['parcel']) {
    const oldCard={...custom,capability:{k:retired,city:'杭州',parcels:[{id:'p',code:'1234'}]}};
    const migrated=normalizeState({schemaVersion:2,cards:[oldCard]});
    assert.equal(migrated.cards[0].capability,null);
    assert.equal(migrated.cards[0].elements[0].text,'preserved','retirement keeps artwork');
    assert.equal(migrated.cards[0].id,custom.id);
  }
  assert.equal(parseCapabilityAction('{"cardId":"action-calendar","operation":"refreshWeather"}'),null);
  const {photoFrame}=load('PhotoCropGeometry');
  for(const [sw,sh] of [[4000,3000],[3000,4000],[4000,700]]) for(const aspect of [.73,1,1.5,2]) for(const zoom of [1,2,5]) for(const [x,y] of [[0,0],[10000,-10000],[-10000,10000]]) {
    const fw=280,fh=280/aspect,f=photoFrame(sw,sh,fw,fh,zoom,x,y),scale=f.width/sw;
    assert.ok(f.left<=1e-9&&f.top<=1e-9&&f.left+f.width>=fw-1e-9&&f.top+f.height>=fh-1e-9,'crop always covers widget frame');
    assert.ok(-f.left/scale>=-1e-9&&(-f.left+fw)/scale<=sw+1e-7&&(-f.top+fh)/scale<=sh+1e-7,'native crop stays inside source pixels');
  }
  const palette=load('BackgroundPalette');
  for(const hex of ['#FF0000','#00FF00','#0000FF','#D8BE92','#262824']){
    const roundtrip=palette.labColor(palette.colorLab(hex));
    for(let i=1;i<7;i+=2)assert.ok(Math.abs(parseInt(roundtrip.slice(i,i+2),16)-parseInt(hex.slice(i,i+2),16))<=2,'Lab conversion preserves source colours');
    const tone=palette.colorLab(palette.backgroundTone(hex));assert.ok(tone.l>88&&tone.l<94&&Math.hypot(tone.a,tone.b)<17,'background tint stays light and restrained');
  }
  const samples=new Uint8Array(500*4);
  for(let i=0;i<500;i++)samples.set(i<300?[255,0,0,0]:i<450?[255,255,255,255]:[40,160,75,255],i*4);
  const rep=palette.colorLab(palette.representativeColor(samples));assert.ok(rep.a<-20,'transparent padding and white margins do not overwhelm green subject');
  const spectrum=new Uint8Array(90*4);for(let i=0;i<90;i++)spectrum.set(i<30?[220,55,45,255]:i<60?[45,170,65,255]:[45,85,215,255],i*4);assert.equal(new Set(palette.representativePalette(spectrum)).size,3,'multi-colour mode preserves three distinct image clusters rather than one muddy mean');
  const anchors=[{x:0,y:.5,color:'#E56953',weight:1},{x:1,y:.5,color:'#538CE5',weight:1}];
  const pixels=palette.blendPixels(anchors,'#EFECE5',128,64);
  const hexAt=(x,y)=>'#'+Array.from(pixels.slice((y*128+x)*4,(y*128+x)*4+3)).map(v=>v.toString(16).padStart(2,'0')).join('');
  const left=palette.colorLab(hexAt(0,32)),right=palette.colorLab(hexAt(127,32));assert.ok(left.b>right.b+4,'blend follows the cards spatial colour anchors');
  for(let x=1;x<128;x++)for(let c=0;c<3;c++)assert.ok(Math.abs(pixels[(32*128+x)*4+c]-pixels[(32*128+x-1)*4+c])<=3,'no hard boundary between blended regions');
  assert.ok(Array.from(pixels).filter((_,i)=>i%4===3).every(v=>v===255),'background bitmap is opaque');
  const bgState=normalizeState({schemaVersion:2,background:{mode:'photo',color:'#ABCDEF',src:'file:///private/canvas.jpg'},cards:[]});
  assert.equal(JSON.parse(load('StorageSnapshot').storageSnapshot(bgState)).background.src,'file:///private/canvas.jpg','background is retained across saves');
  await updateWidget('123',JSON.stringify(bgState),'4*4');
  const bgTransfer=JSON.parse(updates.at(-1).data.background);assert.ok(bgTransfer.src.startsWith('memory://canvas_background'),'background uses FormKit image transfer');
  assert.equal(bgState.background.src,'file:///private/canvas.jpg','form transfer does not overwrite source path');
  const rotatedState=normalizeState({schemaVersion:2,cards:[{...bird,rot:145,subjectBorder:false}]});assert.equal(rotatedState.cards[0].rot,145,'preview rotation survives reload outside the old 15 degree clamp');assert.equal(rotatedState.cards[0].subjectBorder,true);
  const albumCard=new FridgeCard();albumCard.id='album';albumCard.capability={k:'album',albumCover:'file:///private/album.jpg',albumBackground:'file:///private/album-fluid.png'};
  const closedBeforeAlbum=closed.length;
  await updateWidget('123',JSON.stringify({schemaVersion:2,cards:[albumCard]}),'4*4');
  const albumTransfer=JSON.parse(updates.at(-1).data.faceCards)[0].capability;
  assert.equal(albumTransfer.albumCover,'memory://'+widgetImageKey('album_albumCover',albumCard.capability.albumCover));assert.equal(albumTransfer.albumBackground,'memory://'+widgetImageKey('album_albumBackground',albumCard.capability.albumBackground));assert.equal(closed.length,closedBeforeAlbum+2,'album descriptors released');
  console.log('PASS: compact/full capability layouts and substantially smaller subject date minimum; isolated noise/spur cleanup with preserved interior/thin subject; subject white-edge safe bounds; serialized FormExtension calendar actions and retired-capability migration; one widget size; app/widget geometry parity across four viewports, preserved card aspect and off-canvas positions, actual FormKit dimensions; TaskPool dispatch and failure cleanup, 1024px decode limit, optimized/reference Gaussian equality; smoothing alpha, tight crop, coordinate preservation, 32 capability minima, thin-shape refusal; safe layout, non-overlap, cropped bounds, resize projection, full-foreground overlay; v2 zero/one capability, legacy migration, canvas content/captions, box constraints, save queue/retry/reload, corrupt-data preservation, image+subject form transfer/cleanup, mask contours/holes/disconnected parts, native segmentation cleanup/failures');
})().catch(error => { console.error(error); process.exitCode=1; });
