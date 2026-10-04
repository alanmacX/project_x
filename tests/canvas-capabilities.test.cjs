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
 await reloaded.openCanvas(second);await reloaded.deleteCanvas(second);await reloaded.save();assert.equal(JSON.parse(disk.get('fridge_form_bindings_json')).second,'canvas_main','deleted source is explicitly rebound');assert.ok(!disk.has(canvasKey(second)));
 assert.equal(boundCanvas({a:'canvas_main'},'a',reloaded.catalog),'canvas_main');assert.throws(()=>readCatalog('{"version":1,"canvases":[]}'));
 const corrupt=JSON.stringify({version:1,activeId:'missing',canvases:[{id:'missing',name:'Missing'}]});disk.set('fridge_canvases_json',corrupt);await assert.rejects(new FridgeStore().init({}),/已保留原始记录/);assert.equal(disk.get('fridge_canvases_json'),corrupt);disk.clear();
 const bg=defaultState();bg.background.mode='blend';bg.cards=[card];const before=backgroundSignature(bg);card.x+=90;card.y-=80;card.w+=10;card.rot+=15;card.z+=10;assert.equal(backgroundSignature(bg),before,'drag/resize/rotate/layer order never triggers palette extraction');card.paper='#FF4422';assert.notEqual(backgroundSignature(bg),before,'artwork colour triggers re-extraction');
 const fields=data.valueFields('{"items":[{"name":"今天","number":0}],"ok":false}');assert.deepEqual(fields.map(v=>v.path),['items.0.name','items.0.number','ok']);assert.equal(data.selectValue('{"value":0}','value'),'0');assert.equal(data.selectValue('晴朗',''),'晴朗');assert.throws(()=>data.valueFields('<html>login</html>'));assert.throws(()=>data.selectValue('{"v":2}','missing'));assert.ok(!data.validSourceURL('file:///private'));assert.ok(!data.validSourceURL('https://name:password@example.org/'));
 const ctx={applicationInfo:{accessTokenId:1}},battery=await readCapability({k:'battery'},ctx);assert.equal(battery.percent,72);assert.equal(battery.charging,true);
 const fetched=await readCapability({k:'fetch',url:'https://example.org/data',field:'data.value',sourceConfigured:true,title:'配额'},ctx);assert.equal(fetched.value,'42');assert.ok(jobs.includes('readURLValue'),'network parsing stays off UI thread');
 kits['@kit.NetworkKit'].http.createHttp=()=>({destroy:()=>{},request:async()=>({responseCode:503,result:'bad'})});const failed=await readCapability(fetched,ctx);assert.equal(failed.value,'42');assert.equal(failed.refreshState,'failed');
 const concurrent={...fetched,title:'Changed while fetching',unit:' 次'},merged=data.mergeCapabilityResult(concurrent,failed);assert.equal(merged.title,concurrent.title);assert.equal(merged.unit,' 次');
 assert.equal(data.needsDataRefresh({...fetched,attemptedAt:1000},1000+29*60000),false);assert.equal(data.needsDataRefresh({...fetched,attemptedAt:1000,interval:30},1000+30*60000),true);assert.equal(data.needsDataRefresh({...fetched,sourceConfigured:false},Date.now()),false);
 await assert.rejects(systemAgenda(ctx),/受限权限/);
 const candidates=data.pickupCandidates('登录验证码 123456；菜鸟驿站取件码：２－１２３４；订单号 12345678901；提货码 88-99');assert.equal(candidates.length,2);assert.equal(candidates[0].code,'2-1234');assert.equal(data.pickupCandidates('验证码123456，订单号888999000').length,0);assert.equal(data.pendingParcels({k:'parcel',parcels:[{id:'a',code:'12',place:'',picked:true}]}).length,0);
 const semester='2026-09-07',course={id:'math',name:'数学',room:'A101',day:1,start:'08:00',end:'10:00',firstWeek:1,lastWeek:16,parity:1},timetable={k:'timetable',semester,courses:[course]};
 const monday=new Date('2026-09-07T09:00:00').getTime();assert.equal(data.semesterWeek(semester,monday),1);assert.equal(data.courseInstances(timetable,monday)[0].start,new Date('2026-09-07T08:00:00').getTime(),'ongoing course stays visible');assert.equal(data.courseInstances(timetable,new Date('2026-09-14T07:00:00').getTime())[0].start,new Date('2026-09-21T08:00:00').getTime(),'odd/even week skips the wrong week');assert.equal(data.courseInstances({...timetable,courses:[{...course,lastWeek:1}]},new Date('2026-09-14').getTime()).length,0);
 const state=defaultState();const lesson=new FridgeCard();lesson.capability=timetable;state.cards=[lesson];assert.equal(refreshMinutes(state,new Date('2026-09-07T07:58:00').getTime()),5,'system one-shot minimum is respected');assert.equal(refreshMinutes(state,new Date('2026-09-07T07:45:00').getTime()),15,'nearest lesson boundary schedules an update');
 const {importAgenda,importCourses}=load('ScheduleImport'),ics='BEGIN:VCALENDAR\r\nBEGIN:VEVENT\r\nDTSTART:20261004T100000Z\r\nDTEND:20261004T110000Z\r\nSUMMARY:Discuss\\, tomorrow\r\nLOCATION:Room A\r\nEND:VEVENT\r\nEND:VCALENDAR';const events=importAgenda(ics,new Date('2026-10-03').getTime());assert.equal(events[0].start,Date.UTC(2026,9,4,10));assert.equal(events[0].title,'Discuss, tomorrow');assert.ok(importAgenda(ics.replace('SUMMARY:','RRULE:FREQ=WEEKLY;COUNT=4\r\nSUMMARY:'),new Date('2026-10-03').getTime()).length===4,'weekly recurrence expands into actual instances');assert.throws(()=>importAgenda(ics.replace('SUMMARY:','RRULE:FREQ=MONTHLY\r\nSUMMARY:')),/复杂重复/);assert.throws(()=>importAgenda(ics.replace('DTSTART:20261004T100000Z','DTSTART;TZID=Asia/Shanghai:20261004T100000')),/时区/);assert.equal(importCourses(JSON.stringify([course])).length,1);assert.throws(()=>importCourses(JSON.stringify([{...course,day:9}])));
 const modelPath=path.resolve(root,'../form/FridgeFormAbility.ets');kits['@kit.FormKit'].FormExtensionAbility=class{constructor(){this.context=ctx;}};const Form=load('../form/FridgeFormAbility').default;
 const a=defaultState(),b=defaultState();a.canvasId='canvas_main';a.cards=[card];b.canvasId='canvas_second';other.capability={k:'battery',percent:1};b.cards=[other];disk.set('fridge_canvases_json',JSON.stringify({version:1,activeId:'canvas_second',canvases:[{id:'canvas_main',name:'A'},{id:'canvas_second',name:'B'}]}));disk.set(canvasKey(a.canvasId),JSON.stringify(a));disk.set(canvasKey(b.canvasId),JSON.stringify(b));disk.set('fridge_form_dims_json',JSON.stringify({fa:'4*4',fb:'4*4'}));disk.set('fridge_form_bindings_json',JSON.stringify({fa:'canvas_main',fb:'canvas_second'}));const form=new Form();form.onUpdateForm('fb');await form.actionQueue;assert.equal(JSON.parse(disk.get(canvasKey(b.canvasId))).cards[0].capability.percent,72,'background Form refresh reads live battery');assert.equal(JSON.parse(disk.get(canvasKey(a.canvasId))).cards[0].id,'original','another canvas is untouched');assert.equal(updates.at(-1).data.canvasId,'canvas_second');
 const {pushWidgets}=load('WidgetSync');removedForm='fb';await pushWidgets(ctx,JSON.stringify(b));assert.ok(!JSON.parse(disk.get('fridge_form_dims_json')).fb,'removed form is pruned without retrying indefinitely');assert.equal(JSON.parse(disk.get('fridge_form_dims_json')).fa,'4*4','another live canvas binding is preserved');assert.equal(JSON.parse(disk.get('fridge_form_bindings_json')).fa,'canvas_main');removedForm='';
 assert.equal(schedules.length,0,'ordinary saves and battery updates never spend one-shot refresh quota');
 const event=new FridgeCard(),now=Date.now();event.capability={k:'agenda',agendaSource:'imported',events:[{id:'e',title:'即将开始',start:now+10*60000,end:now+70*60000,location:'',allDay:false}]};a.cards.push(event);disk.set(canvasKey(a.canvasId),JSON.stringify(a));form.onUpdateForm('fa');await form.actionQueue;assert.equal(schedules.length,1);assert.equal(schedules[0].id,'fa');assert.equal(schedules[0].minutes,10,'a nearer calendar boundary uses one system scheduling request');
 const recurring=ics.replace('SUMMARY:','RRULE:FREQ=WEEKLY;COUNT=4\r\nEXDATE:20261011T100000Z\r\nSUMMARY:');const exceptions=importAgenda(recurring,new Date('2026-10-03').getTime());assert.equal(exceptions.length,3);assert.ok(!exceptions.some(e=>e.start===Date.UTC(2026,9,11,10)),'excluded occurrence never appears in the widget agenda');
 const {parseWakeUp,resolveWakeUp,mondayDate}=load('WakeUpImport'),wp=[{node:1,startTime:'8:00',endTime:'08:45'},{node:2,startTime:'08:50',endTime:'09:35'}],wb=[{id:7,courseName:'高等数学'}],wd=[{id:7,day:2,startNode:1,step:2,startWeek:2,endWeek:16,type:2,room:'A101'}];
 const backup=[JSON.stringify({id:1,name:'学校作息'}),JSON.stringify(wp),JSON.stringify({tableName:'秋季学期',startDate:'2026-09-08'}),JSON.stringify(wb),JSON.stringify(wd)].join('\r\n');
 const wake=parseWakeUp(backup);assert.equal(wake.semester,'2026-09-07');assert.equal(wake.name,'秋季学期');assert.equal(wake.courses[0].name,'高等数学');const resolved=resolveWakeUp(wake,wake.semester,wake.slots);assert.equal(resolved[0].start,'08:00');assert.equal(resolved[0].end,'09:35');assert.equal(resolved[0].parity,2);assert.equal(resolved[0].firstWeek,2);assert.equal(resolved[0].lastWeek,16);assert.equal(resolved[0].day,2);
 assert.throws(()=>parseWakeUp('[]'),/没有课程/);
 const encoded='【来自WakeUp课程表】\n课程分享：\n'+JSON.stringify({name:'分享课表',startDate:'2026-09-07',courseDetailJson:encodeURIComponent(JSON.stringify([{...wd[0],name:'C++ 数据结构',startNode:11,step:3}])).replace(/%20/g,'+')});
 const missing=parseWakeUp(encoded);assert.equal(missing.courses[0].name,'C++ 数据结构');assert.deepEqual(missing.slots.map(s=>s.node),[11,12,13],'late periods are preserved instead of clamped or fabricated');assert.throws(()=>resolveWakeUp(missing,missing.semester,missing.slots),/补全第 11 节/);assert.throws(()=>parseWakeUp('分享口令 abc123'),/导出/);
 assert.equal(mondayDate('2026-02-30'),'');assert.throws(()=>resolveWakeUp(wake,'',wake.slots),/学期/);assert.throws(()=>parseWakeUp(backup.replace('"step":2','"step":25')),/节次/);assert.throws(()=>parseWakeUp(backup.replace('"type":2','"type":9')),/周次/);assert.throws(()=>parseWakeUp(backup.replace('08:50','08:30'))&&resolveWakeUp(parseWakeUp(backup.replace('08:50','08:30')),wake.semester,parseWakeUp(backup.replace('08:50','08:30')).slots),/重叠/);
 const bp=load('BatteryPresentation');assert.equal(bp.batteryLevel({k:'battery',percent:0}),0);assert.equal(bp.batteryStatus({k:'battery',percent:-1}),'等待电量');assert.equal(bp.batteryStatus({k:'battery',percent:100,chargeState:'full'}),'已充满');assert.equal(bp.batteryStatus({k:'battery',percent:12,refreshState:'failed'}),'上次读数');assert.equal(bp.batteryTint({k:'battery',percent:12,charging:true},'#000000'),'#3B8868');
 console.log('PASS: legacy migration, lazy multi-canvas storage, independent duplication, widget bindings/deletion and removed-form cleanup, preserved corruption, movement-stable palette, URL selection/worker/failure/merge, live battery/Form refresh, conservative pickup OCR, course week/parity/boundaries, bounded ICS/JSON imports with recurrence exceptions and calendar ACL gate.');
})().catch(e=>{console.error(e);process.exitCode=1;});
