// Executes the real model/service sources with only the Harmony platform APIs mocked.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const ts = require(process.env.FRIDGE_TYPESCRIPT || '/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript');
const root = path.resolve(__dirname, '../entry/src/main/ets/model');
const disk = new Map();
const writes = [], updates = [], closed = [], opened = [], schedules = [];
let failWrite = false, failForm = false, removedForm = '';
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
    formProvider: { setFormNextRefreshTime: async(id,minutes)=>schedules.push({id,minutes}), updateForm: async (id, data) => {
      if (id === removedForm) { const e=Error('removed form'); e.code=16501001; throw e; }
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
kits['@kit.ImageKit']={image:{}};
kits['@ohos.net.http']={default:{}};
const jobs = [];
kits['@kit.BasicServicesKit'].batteryInfo={batterySOC:72,chargingStatus:1,BatteryChargeState:{ENABLE:1}};
kits['@kit.NetworkKit'].http={RequestMethod:{GET:0},HttpDataType:{STRING:0},createHttp:()=>({destroy:()=>{},request:async()=>({responseCode:200,result:'{"data":{"value":42}}'})})};
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
(async()=>{
 const {FridgeStore,FridgeCard,CanvasElement,defaultState}=load('FridgeModel');
 const {readCatalog,boundCanvas,canvasKey}=load('CanvasLibrary');
 const {backgroundSignature}=load('BackgroundInputs');
 const data=load('CapabilityData'),{readCapability,systemAgenda}=load('CapabilityService'),{refreshMinutes}=load('WidgetRefreshPolicy');
 const original=defaultState(),card=new FridgeCard();card.id='original';card.capability={k:'clock'};original.cards=[card];
 disk.set('fridge_state_json',JSON.stringify(original));disk.set('fridge_form_dims_json',JSON.stringify({home:'4*4'}));
 const store=new FridgeStore();await store.init({});await store.save();
 assert.equal(store.state.cards[0].id,'original','legacy artwork is migrated intact');
 assert.equal(JSON.parse(disk.get('fridge_form_bindings_json')).home,'canvas_main');
 const old=store.state,second=store.createCanvas('第二张');await store.save();
 const other=new FridgeCard();other.id='other';other.capability={k:'battery'};store.addCard(other);await store.save();
 assert.equal(JSON.parse(disk.get(canvasKey('canvas_main'))).cards[0].id,'original','new canvas never overwrites original');
 assert.equal(updates.at(-1).data.canvasId,'canvas_main','switching app does not replace original desktop form');
 const inactive=await store.canvasSnapshot('canvas_main');assert.equal(inactive.cards[0].id,'original');assert.equal(store.state.canvasId,second,'sharing inactive canvas never activates it');inactive.cards[0].x=999;assert.notEqual(JSON.parse(disk.get(canvasKey('canvas_main'))).cards[0].x,999);
 const active=await store.canvasSnapshot(second);active.cards[0].paper='#000000';assert.notEqual(store.state.cards[0].paper,'#000000','sharing snapshot is detached from live editor');
 disk.set('fridge_form_dims_json',JSON.stringify({home:'4*4',second:'4*4'}));disk.set('fridge_form_bindings_json',JSON.stringify({home:'canvas_main',second}));
 store.state.cards[0].paper='#ABCDEF';await store.save();assert.equal(updates.at(-1).id,'second');
 const reloaded=new FridgeStore();await reloaded.init({});assert.equal(reloaded.state.canvasId,second);assert.equal(reloaded.documents.length,1,'cold start loads only active artwork');
 await reloaded.openCanvas('canvas_main');assert.equal(reloaded.state.cards[0].id,'original');
 reloaded.renameCanvas('旧画布');await reloaded.save(false);assert.equal(readCatalog(disk.get('fridge_canvases_json')).canvases[0].name,'旧画布');
 const external=JSON.parse(disk.get(canvasKey('canvas_main')));external.cards[0].capability.title='Widget-side change';disk.set(canvasKey('canvas_main'),JSON.stringify(external));await reloaded.openCanvas('canvas_main');assert.equal(reloaded.state.cards[0].capability.title,'Widget-side change','switching reloads cached artwork after a FormExtension update');
 const duplicate=reloaded.createCanvas('副本',reloaded.state);reloaded.state.cards[0].x=145;await reloaded.save();await reloaded.openCanvas('canvas_main');assert.notEqual(reloaded.state.cards[0].x,145,'duplicate is independently editable');
 // The fallback canvas has already been delivered: unchanged scene bytes must
 // still be republished when another form is rebound to it after deletion.
 await reloaded.save();const beforeRebind=updates.length;
 await reloaded.openCanvas(second);await reloaded.deleteCanvas(second);
 assert.ok(updates.slice(beforeRebind).some(u=>u.id==='second'&&u.data.canvasId==='canvas_main'),'deletion immediately delivers the fallback to its newly rebound form');
 await reloaded.save();assert.equal(JSON.parse(disk.get('fridge_form_bindings_json')).second,'canvas_main','deleted source is explicitly rebound');assert.ok(!disk.has(canvasKey(second)));
 assert.equal(boundCanvas({a:'canvas_main'},'a',reloaded.catalog),'canvas_main');assert.throws(()=>readCatalog('{"version":1,"canvases":[]}'));
 const corrupt=JSON.stringify({version:1,activeId:'missing',canvases:[{id:'missing',name:'Missing'}]});disk.set('fridge_canvases_json',corrupt);await assert.rejects(new FridgeStore().init({}),/已保留原始记录/);assert.equal(disk.get('fridge_canvases_json'),corrupt);disk.clear();
 // Each canvas retains its own disposable geometry cache across cold starts.
 const contours=load('RenderContours'),outline=[[{x:.1,y:.1},{x:.9,y:.1},{x:.9,y:.9},{x:.1,y:.9}]];
 const cachedStore=new FridgeStore();await cachedStore.init({});
 const subject=new FridgeCard();subject.id='cached-subject';subject.shape='subject';subject.cutout='file://cache-test.png';subject.outline=outline;cachedStore.addCard(subject);
 await contours.primeRenderContours(cachedStore.state.cards,JSON.stringify(cachedStore.state));await cachedStore.save(false);
 const cacheMain='fridge_render_contours_v1_'+cachedStore.state.canvasId;assert.ok(disk.get(cacheMain));const mainCache=disk.get(cacheMain);
 const cachedSecond=cachedStore.createCanvas('Cache second',cachedStore.state);await contours.primeRenderContours(cachedStore.state.cards,JSON.stringify(cachedStore.state));await cachedStore.save(false);
 assert.equal(disk.get(cacheMain),mainCache,'saving another canvas preserves the first geometry cache');assert.ok(disk.get('fridge_render_contours_v1_'+cachedSecond));
 const jobsBefore=jobs.length,cold=new FridgeStore();await cold.init({});await cold.openCanvas('canvas_main');await contours.primeRenderContours(cold.state.cards,JSON.stringify(cold.state));assert.equal(jobs.length,jobsBefore,'both cold load and switching reuse derived geometry');
 const getPrefs=prefs.get;prefs.get=async(key,fallback)=>{if(key.startsWith('fridge_render_contours_v1_'))throw Error('cache unavailable');return getPrefs(key,fallback);};await new FridgeStore().init({});prefs.get=getPrefs;
 await cold.deleteCanvas(cachedSecond);assert.ok(!disk.has('fridge_render_contours_v1_'+cachedSecond),'canvas deletion removes its derived cache');disk.clear();
 const bg=defaultState();bg.background.mode='blend';bg.cards=[card];const before=backgroundSignature(bg);card.x+=90;card.y-=80;card.w+=10;card.rot+=15;card.z+=10;assert.equal(backgroundSignature(bg),before,'drag/resize/rotate/layer order never triggers palette extraction');card.paper='#FF4422';assert.notEqual(backgroundSignature(bg),before,'artwork colour triggers re-extraction');
 const ctx={applicationInfo:{accessTokenId:1}},battery=await readCapability({k:'battery'},ctx);assert.equal(battery.percent,72);assert.equal(battery.charging,true);
 assert.equal(data.needsDataRefresh({k:'fetch',url:'https://example.org',sourceConfigured:true},Date.now()),false,'retired URL capabilities never schedule a request');
 const merged=data.mergeCapabilityResult({...battery,title:'My battery'},{...battery,percent:15});assert.equal(merged.percent,15);assert.equal(merged.title,'My battery');
 await assert.rejects(systemAgenda(ctx),/受限权限/);
 const candidates=data.pickupCandidates('登录验证码 123456；菜鸟驿站取件码：２－１２３４；订单号 12345678901；提货码 88-99');assert.equal(candidates.length,2);assert.equal(candidates[0].code,'2-1234');assert.equal(data.pickupCandidates('验证码123456，订单号888999000').length,0);assert.equal(data.pendingParcels({k:'parcel',parcels:[{id:'a',code:'12',place:'',picked:true}]}).length,0);
 const semester='2026-09-07',course={id:'math',name:'数学',room:'A101',day:1,start:'08:00',end:'10:00',firstWeek:1,lastWeek:16,parity:1},timetable={k:'timetable',semester,courses:[course]};
 const monday=new Date('2026-09-07T09:00:00').getTime();assert.equal(data.semesterWeek(semester,monday),1);assert.equal(data.courseInstances(timetable,monday)[0].start,new Date('2026-09-07T08:00:00').getTime(),'ongoing course stays visible');assert.equal(data.courseInstances(timetable,new Date('2026-09-14T07:00:00').getTime())[0].start,new Date('2026-09-21T08:00:00').getTime(),'odd/even week skips the wrong week');assert.equal(data.courseInstances({...timetable,courses:[{...course,lastWeek:1}]},new Date('2026-09-14').getTime()).length,0);
 const state=defaultState();const lesson=new FridgeCard();lesson.capability=timetable;state.cards=[lesson];assert.equal(refreshMinutes(state,new Date('2026-09-07T07:58:00').getTime()),5,'system one-shot minimum is respected');assert.equal(refreshMinutes(state,new Date('2026-09-07T07:45:00').getTime()),15,'nearest lesson boundary schedules an update');
 const {importAgenda,importCourses}=load('ScheduleImport'),ics='BEGIN:VCALENDAR\r\nBEGIN:VEVENT\r\nDTSTART:20261004T100000Z\r\nDTEND:20261004T110000Z\r\nSUMMARY:Discuss\\, tomorrow\r\nLOCATION:Room A\r\nEND:VEVENT\r\nEND:VCALENDAR';const events=importAgenda(ics,new Date('2026-10-03').getTime());assert.equal(events[0].start,Date.UTC(2026,9,4,10));assert.equal(events[0].title,'Discuss, tomorrow');assert.ok(importAgenda(ics.replace('SUMMARY:','RRULE:FREQ=WEEKLY;COUNT=4\r\nSUMMARY:'),new Date('2026-10-03').getTime()).length===4,'weekly recurrence expands into actual instances');assert.throws(()=>importAgenda(ics.replace('SUMMARY:','RRULE:FREQ=MONTHLY\r\nSUMMARY:')),/复杂重复/);assert.throws(()=>importAgenda(ics.replace('DTSTART:20261004T100000Z','DTSTART;TZID=Asia/Shanghai:20261004T100000')),/时区/);assert.equal(importCourses(JSON.stringify([course])).length,1);assert.throws(()=>importCourses(JSON.stringify([{...course,day:9}])));
 const modelPath=path.resolve(root,'../form/FridgeFormAbility.ets');kits['@kit.FormKit'].FormExtensionAbility=class{constructor(){this.context=ctx;}};const Form=load('../form/FridgeFormAbility').default;
 const a=defaultState(),b=defaultState();a.canvasId='canvas_main';a.cards=[card];b.canvasId='canvas_second';other.capability={k:'battery',percent:1};b.cards=[other];disk.set('fridge_canvases_json',JSON.stringify({version:1,activeId:'canvas_second',canvases:[{id:'canvas_main',name:'A'},{id:'canvas_second',name:'B'}]}));disk.set(canvasKey(a.canvasId),JSON.stringify(a));disk.set(canvasKey(b.canvasId),JSON.stringify(b));disk.set('fridge_form_dims_json',JSON.stringify({fa:'4*4',fb:'4*4'}));disk.set('fridge_form_bindings_json',JSON.stringify({fa:'canvas_main',fb:'canvas_second'}));const form=new Form();form.onUpdateForm('fb');await form.actionQueue;assert.equal(JSON.parse(disk.get(canvasKey(b.canvasId))).cards[0].capability.percent,72,'background Form refresh reads live battery');assert.equal(JSON.parse(disk.get(canvasKey(a.canvasId))).cards[0].id,'original','another canvas is untouched');assert.equal(updates.at(-1).data.canvasId,'canvas_second');
 // Slow registration/flush must never gate the first visible artwork.
 const added=new Form();let releaseRegistration,finishAdd,firstDelivery;
 const registration=new Promise(resolve=>releaseRegistration=resolve),completedAdd=new Promise(resolve=>finishAdd=resolve),delivered=new Promise(resolve=>firstDelivery=resolve);
 added.register=()=>registration;added.refreshDueData=async()=>{};added.scheduleForm=async()=>finishAdd();
 const originalUpdate=kits['@kit.FormKit'].formProvider.updateForm;
 kits['@kit.FormKit'].formProvider.updateForm=async(id,payload)=>{await originalUpdate(id,payload);if(id==='instant')firstDelivery();};
 added.onAddForm({parameters:{'ohos.extra.param.key.form_identity':'instant','ohos.extra.param.key.form_dimension':4}});
 let timeout;try {await Promise.race([delivered,new Promise((_,reject)=>{timeout=setTimeout(()=>reject(Error('initial delivery waited for registration')),2000);})]);}
 finally {clearTimeout(timeout);releaseRegistration();await completedAdd;kits['@kit.FormKit'].formProvider.updateForm=originalUpdate;}
 assert.ok(updates.find(u=>u.id==='instant').data.scenePacket,'initial artwork is sent while registration is still pending');
 const {pushWidgets}=load('WidgetSync');removedForm='fb';await pushWidgets(ctx,JSON.stringify(b));assert.ok(!JSON.parse(disk.get('fridge_form_dims_json')).fb,'removed form is pruned without retrying indefinitely');assert.equal(JSON.parse(disk.get('fridge_form_dims_json')).fa,'4*4','another live canvas binding is preserved');assert.equal(JSON.parse(disk.get('fridge_form_bindings_json')).fa,'canvas_main');removedForm='';
 assert.equal(schedules.length,0,'ordinary saves and battery updates never spend one-shot refresh quota');
 // Use midday: a real run near midnight has a nearer calendar refresh boundary.
 const actualNow=Date.now;Date.now=()=>new Date('2026-10-04T12:00:00').getTime();
 try { const event=new FridgeCard(),now=Date.now();event.capability={k:'agenda',agendaSource:'imported',events:[{id:'e',title:'即将开始',start:now+10*60000,end:now+70*60000,location:'',allDay:false}]};a.cards.push(event);disk.set(canvasKey(a.canvasId),JSON.stringify(a));form.onUpdateForm('fa');await form.actionQueue;assert.equal(schedules.length,1);assert.equal(schedules[0].id,'fa');assert.equal(schedules[0].minutes,10,'a nearer calendar boundary uses one system scheduling request');
 } finally {Date.now=actualNow;}
 const recurring=ics.replace('SUMMARY:','RRULE:FREQ=WEEKLY;COUNT=4\r\nEXDATE:20261011T100000Z\r\nSUMMARY:');const exceptions=importAgenda(recurring,new Date('2026-10-03').getTime());assert.equal(exceptions.length,3);assert.ok(!exceptions.some(e=>e.start===Date.UTC(2026,9,11,10)),'excluded occurrence never appears in the widget agenda');
 const {parseWakeUp,resolveWakeUp,mondayDate}=load('WakeUpImport'),wp=[{node:1,startTime:'8:00',endTime:'08:45'},{node:2,startTime:'08:50',endTime:'09:35'}],wb=[{id:7,courseName:'高等数学'}],wd=[{id:7,day:2,startNode:1,step:2,startWeek:2,endWeek:16,type:2,room:'A101'}];
 const backup=[JSON.stringify({id:1,name:'学校作息'}),JSON.stringify(wp),JSON.stringify({tableName:'秋季学期',startDate:'2026-09-08'}),JSON.stringify(wb),JSON.stringify(wd)].join('\r\n');
 const wake=parseWakeUp(backup);assert.equal(wake.semester,'2026-09-07');assert.equal(wake.name,'秋季学期');assert.equal(wake.courses[0].name,'高等数学');const resolved=resolveWakeUp(wake,wake.semester,wake.slots);assert.equal(resolved[0].start,'08:00');assert.equal(resolved[0].end,'09:35');assert.equal(resolved[0].parity,2);assert.equal(resolved[0].firstWeek,2);assert.equal(resolved[0].lastWeek,16);assert.equal(resolved[0].day,2);
 assert.throws(()=>parseWakeUp('[]'),/没有课程/);
 const encoded='【来自WakeUp课程表】\n课程分享：\n'+JSON.stringify({name:'分享课表',startDate:'2026-09-07',courseDetailJson:encodeURIComponent(JSON.stringify([{...wd[0],name:'C++ 数据结构',startNode:11,step:3}])).replace(/%20/g,'+')});
 const missing=parseWakeUp(encoded);assert.equal(missing.courses[0].name,'C++ 数据结构');assert.deepEqual(missing.slots.map(s=>s.node),[11,12,13],'late periods are preserved instead of clamped or fabricated');assert.throws(()=>resolveWakeUp(missing,missing.semester,missing.slots),/补全第 11 节/);assert.throws(()=>parseWakeUp('分享口令 abc123'),/导出/);
 assert.equal(mondayDate('2026-02-30'),'');assert.throws(()=>resolveWakeUp(wake,'',wake.slots),/学期/);assert.throws(()=>parseWakeUp(backup.replace('"step":2','"step":25')),/节次/);assert.throws(()=>parseWakeUp(backup.replace('"type":2','"type":9')),/周次/);assert.throws(()=>parseWakeUp(backup.replace('08:50','08:30'))&&resolveWakeUp(parseWakeUp(backup.replace('08:50','08:30')),wake.semester,parseWakeUp(backup.replace('08:50','08:30')).slots),/重叠/);
 const bp=load('BatteryPresentation');assert.equal(bp.batteryLevel({k:'battery',percent:0}),0);assert.equal(bp.batteryStatus({k:'battery',percent:-1}),'等待电量');assert.equal(bp.batteryStatus({k:'battery',percent:100,chargeState:'full'}),'已充满');assert.equal(bp.batteryStatus({k:'battery',percent:12,refreshState:'failed'}),'上次读数');assert.equal(bp.batteryTint({k:'battery',percent:12,charging:true},'#000000'),'#3B8868');
 // Timed scenes use the same delivery path as ordinary edits, never persist projected geometry.
 disk.clear();updates.length=0;schedules.length=0;
 const {SceneRule,sceneDay}=load('SceneScheduleSchema'),sceneEngine=load('SceneSchedule');
 const source=defaultState(),destination=defaultState();destination.canvasId='canvas_target';
 const center=new FridgeCard();center.id='center';center.x=30;center.y=80;center.rot=18;center.capability={k:'battery',percent:1};
 const edge=new FridgeCard();edge.id='edge';edge.x=140;edge.y=190;source.cards=[center,edge];
 const sceneRule=new SceneRule();sceneRule.id='focus-rule';sceneRule.kind='focus';sceneRule.targetId='center';sceneRule.start=0;sceneRule.end=0;source.sceneRules=[sceneRule];
 const targetCard=new FridgeCard();targetCard.id='destination';targetCard.x=55;targetCard.capability={k:'battery',percent:1};destination.cards=[targetCard];
 const putScene=()=>{disk.set(canvasKey(source.canvasId),JSON.stringify(source));disk.set(canvasKey(destination.canvasId),JSON.stringify(destination));};
 disk.set('fridge_canvases_json',JSON.stringify({version:1,activeId:source.canvasId,canvases:[{id:source.canvasId,name:'Source'},{id:destination.canvasId,name:'Target'}]}));
 disk.set('fridge_form_dims_json',JSON.stringify({scene:'4*4'}));disk.set('fridge_form_bindings_json',JSON.stringify({scene:source.canvasId}));putScene();
 const liveStore=new FridgeStore();await liveStore.init({});const sceneForm=new Form();sceneForm.onUpdateForm('scene');await sceneForm.actionQueue;
 let storedScene=JSON.parse(disk.get(canvasKey(source.canvasId))),packet=JSON.parse(updates.at(-1).data.scenePacket);
 assert.equal(storedScene.cards[0].rot,18);assert.equal(storedScene.cards[1].x,140,'battery updates never save swept positions');
 assert.equal(storedScene.cards[0].capability.percent,72);assert.equal(JSON.parse(packet.cards)[0].rot,0);assert.equal(JSON.parse(packet.context).baseId,source.canvasId);
 const sourceGeometry=liveStore.state.cards.map(c=>[c.x,c.y,c.w,c.h,c.rot]);
 sceneForm.onFormEvent('scene',JSON.stringify({operation:'dismissScene',ruleId:'focus-rule',occurrence:'2000-01-01'}));await sceneForm.actionQueue;assert.ok(JSON.parse(updates.at(-1).data.scenePacket).context,'stale acknowledgement ignored');
 sceneForm.onFormEvent('scene',JSON.stringify({operation:'dismissScene',ruleId:'focus-rule',occurrence:sceneDay(new Date())}));await sceneForm.actionQueue;
 assert.equal(JSON.parse(updates.at(-1).data.scenePacket).context,'');await liveStore.reloadSceneAcknowledgements();
 assert.equal(liveStore.state.sceneRules[0].dismissed,sceneDay(new Date()));assert.deepEqual(liveStore.state.cards.map(c=>[c.x,c.y,c.w,c.h,c.rot]),sourceGeometry,'foreground merges only acknowledgement');
 source.sceneRules[0].kind='canvas';source.sceneRules[0].targetId=destination.canvasId;source.sceneRules[0].untilDismissed=false;source.sceneRules[0].dismissed='';putScene();
 sceneForm.onUpdateForm('scene');await sceneForm.actionQueue;packet=JSON.parse(updates.at(-1).data.scenePacket);
 assert.equal(packet.canvasId,destination.canvasId);assert.equal(JSON.parse(disk.get('fridge_form_bindings_json')).scene,source.canvasId,'display switching never rebinds source');
 assert.equal(JSON.parse(disk.get(canvasKey(destination.canvasId))).cards[0].capability.percent,72);assert.equal(JSON.parse(disk.get(canvasKey(source.canvasId))).cards[0].id,'center');
 destination.cards[0].paper='#B9C6A2';putScene();const updateCount=updates.length;await pushWidgets(ctx,JSON.stringify(destination));assert.ok(updates.length>updateCount,'target edits fan out to source-bound forms while switching');
 assert.equal(JSON.parse(JSON.parse(updates.at(-1).data.scenePacket).cards)[0].paper,'#B9C6A2');
 const boundaryState=defaultState(),boundaryRule=new SceneRule();boundaryRule.id='upcoming';boundaryRule.targetId='layout';boundaryRule.start=9*60;boundaryRule.end=10*60;boundaryState.sceneRules=[boundaryRule];
 assert.equal(refreshMinutes(boundaryState,new Date('2026-10-05T08:58:00').getTime()),5);assert.equal(refreshMinutes(boundaryState,new Date('2026-10-05T08:45:00').getTime()),15);
 const nextMinute=(new Date().getHours()*60+new Date().getMinutes()+10)%1440;source.sceneRules[0].start=nextMinute;source.sceneRules[0].end=(nextMinute+60)%1440;putScene();
 await pushWidgets(ctx,JSON.stringify(source));const scheduleCount=schedules.length;await pushWidgets(ctx,JSON.stringify(source));assert.equal(schedules.length,scheduleCount,'repeated edits do not spend additional scene scheduling quota');
 const imported=JSON.parse(JSON.stringify(source));imported.sceneLayouts=[sceneEngine.captureSceneLayout(source,'layout-import','Arrangement')];imported.sceneRules.push({...sceneRule,id:'import-layout',kind:'layout',targetId:'layout-import'});
 imported.sceneRules.push({...sceneRule,id:'import-focus',kind:'focus',targetId:'center'});const importedCards=imported.cards.map((c,i)=>({...c,id:'new-'+i}));let sequence=0;
 load('TemplatePackage').remapSceneSchedules(imported,importedCards,()=> 'import-'+(++sequence),.8);
 assert.equal(imported.sceneRules.length,2,'external canvas links are excluded from a single shared document');assert.ok(imported.sceneRules.every(r=>!r.enabled&&!r.dismissed));assert.equal(imported.sceneLayouts[0].placements[0].id,'new-0');assert.equal(imported.sceneRules.find(r=>r.kind==='focus').targetId,'new-0');
 console.log('PASS timed delivery: atomic packet, bound-source ownership, target fanout, original geometry during battery updates, persisted acknowledgement and foreground merge, refresh minimum/quota, imported schedule remapping and opt-in.');
 console.log('PASS: legacy migration, lazy multi-canvas storage, independent duplication, widget bindings/deletion and removed-form cleanup, preserved corruption, movement-stable palette, offline refresh guard, live battery/Form refresh, conservative pickup OCR, course week/parity/boundaries, bounded ICS/JSON imports with recurrence exceptions and calendar ACL gate.');
})().catch(e=>{console.error(e);process.exitCode=1;});
