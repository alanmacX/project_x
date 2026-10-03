const assert=require('node:assert/strict'),fs=require('node:fs'),path=require('node:path'),vm=require('node:vm');
const ts=require('/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript');
const root=path.resolve(__dirname,'../entry/src/main/ets/model'),raw=path.resolve(root,'../../resources/rawfile'),cache=new Map();
function load(name){if(cache.has(name))return cache.get(name).exports;const module={exports:{}};cache.set(name,module);const code=ts.transpileModule(fs.readFileSync(path.join(root,name+'.ets'),'utf8'),{compilerOptions:{target:ts.ScriptTarget.ES2020,module:ts.ModuleKind.CommonJS}}).outputText;vm.runInThisContext('(function(require,module,exports){'+code+'})')(s=>load(s.replace('./','')),module,module.exports);return module.exports;}
const {parseSchoolCourses,schoolSnapshot,schoolUrl}=load('SchoolImport'),{resolveWakeUp}=load('WakeUpImport');
const course={name:'高等数学',position:'A101',day:3,weeks:[1,2,3,5,7,9,10,11,13],startSection:11,endSection:12};
const snapshot={token:'test',done:true,error:'',courses:[course],slots:[{number:11,startTime:'20:00',endTime:'20:45'},{number:12,startTime:'20:55',endTime:'21:40'}],config:{semesterStartDate:'2026-09-09'}};
const parsed=JSON.parse(parseSchoolCourses(JSON.stringify(snapshot),'学校'));assert.equal(parsed.semester,'2026-09-07');const courses=resolveWakeUp(parsed,parsed.semester,parsed.slots),weeks=[];
for(const c of courses)for(let w=c.firstWeek;w<=c.lastWeek;w++)if(!c.parity||w%2===c.parity%2)weeks.push(w);
assert.deepEqual(weeks,course.weeks,'interrupted teaching weeks stay exact');assert.ok(courses.every(c=>c.start==='20:00'&&c.end==='21:40'));
assert.equal(schoolSnapshot(JSON.stringify(JSON.stringify(snapshot))).token,'test');
assert.throws(()=>parseSchoolCourses(JSON.stringify({...snapshot,done:false}),'X'),/尚未完成/);
for(const c of [{...course,day:0},{...course,weeks:[]},{...course,weeks:[61]},{...course,startSection:25},{...course,isCustomTime:true,customStartTime:'09:00',customEndTime:'08:00'}])assert.throws(()=>parseSchoolCourses(JSON.stringify({...snapshot,courses:[c]}),'X'));
const custom=JSON.parse(parseSchoolCourses(JSON.stringify({...snapshot,courses:[{...course,isCustomTime:true,customStartTime:'8:30',customEndTime:'09:15'}],slots:[]}),'X'));assert.equal(custom.courses[0].start,'08:30');
const missing=JSON.parse(parseSchoolCourses(JSON.stringify({...snapshot,slots:[],config:{}}),'X'));assert.equal(missing.slots[0].start,'');assert.throws(()=>resolveWakeUp(missing,'2026-09-07',missing.slots),/真实作息/);
assert.equal(schoolUrl('jw.school.edu.cn/'),'https://jw.school.edu.cn/');for(const u of ['javascript:alert(1)','https://foo@school.edu.cn','https://foo\\bar','file:///tmp/test','https://'])assert.throws(()=>schoolUrl(u));
const catalogue=JSON.parse(fs.readFileSync(path.join(raw,'schools/catalog.json'))),ids=new Set();let count=0;
for(const s of catalogue)for(const a of s.adapters){const p=path.join(raw,a.script);assert.ok(p.startsWith(raw+'/'));assert.ok(!ids.has(a.id),'unique adapter IDs');ids.add(a.id);new vm.Script(fs.readFileSync(p,'utf8'));count++;}
assert.equal(count,249);assert.equal(catalogue.length,237);
(async()=>{
 const listeners=new Map(),window={addEventListener:(k,v)=>listeners.set(k,v),removeEventListener:k=>listeners.delete(k)};const ctx=vm.createContext({window,Map,JSON,Error,String,Array});
 const bridge=fs.readFileSync(path.join(raw,'school-bridge.js'),'utf8').replace('__TOKEN__','"test"');vm.runInContext(bridge,ctx);
 const b=window.AndroidBridgePromise;await b.saveImportedCourses(JSON.stringify([course]));assert.equal(JSON.parse(window.__fridgeSchool.snapshot()).courses.length,0,'no partial result before completion');
 window.__fridgeSchool.validators.validateYear=v=>/^20\d{2}$/.test(v)?false:'请输入学年';
 const prompt=b.showPrompt('学年','', '2026','validateYear');let request=window.__fridgeSchool.requests[0];assert.equal(window.__fridgeSchool.reply(request.id,'oops'),'请输入学年');assert.equal(window.__fridgeSchool.requests.length,1);window.__fridgeSchool.reply(request.id,'2026');assert.equal(await prompt,'2026');
 const selection=b.showSingleSelection('学期',JSON.stringify(['秋季','春季']),0),req=window.__fridgeSchool.requests[0];assert.equal(req.kind,'select');window.__fridgeSchool.reply(req.id,1);assert.equal(await selection,1);
 await b.savePresetTimeSlots(JSON.stringify(snapshot.slots));await b.saveCourseConfig(JSON.stringify(snapshot.config));window.AndroidBridge.notifyTaskCompletion();assert.equal(JSON.parse(window.__fridgeSchool.snapshot()).courses.length,1);
 await assert.rejects(b.saveImportedCourses(JSON.stringify(Array(129).fill(course))),/过多/);
 window.__fridgeSchool.cancel();assert.equal(listeners.size,0);await assert.rejects(b.saveImportedCourses('[]'),/结束/);
 console.log('PASS: 249 adapter syntax, exact interrupted weeks, timetable validation, local bridge choices and cancellation');
})().catch(e=>{console.error(e);process.exit(1);});
