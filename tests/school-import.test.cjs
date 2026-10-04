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
// Different schools' numbering, actual times and explicit week sets must survive without borrowing defaults.
const cases=[
 {name:'早课校',position:'北校区1楼',day:1,weeks:[1,4,8,12],startSection:1,endSection:1},
 {name:'周末夜课校',position:'南校区实验室',day:7,weeks:[2,4,6,8],isCustomTime:true,customStartTime:'21:10',customEndTime:'23:05'},
 {name:'两节连堂校',position:'线上',day:6,weeks:[1,2,5,6,9],startSection:3,endSection:4}
];
const times=[{number:1,startTime:'06:50',endTime:'07:30'},{number:3,startTime:'13:20',endTime:'14:00'},{number:4,startTime:'14:15',endTime:'15:05'}];
for(const input of cases){const out=JSON.parse(parseSchoolCourses(JSON.stringify({...snapshot,courses:[input],slots:times}),'不同学校'));const resolved=resolveWakeUp(out,out.semester,out.slots),actual=[];for(let week=1;week<=60;week++)if(resolved.some(c=>load('CapabilityData').courseInWeek(c,week)))actual.push(week);assert.deepEqual(actual,input.weeks);assert.ok(resolved.every(c=>c.day===input.day&&c.room===input.position));const expected=input.name==='早课校'?['06:50','07:30']:input.name==='周末夜课校'?['21:10','23:05']:['13:20','15:05'];assert.ok(resolved.every(c=>c.start===expected[0]&&c.end===expected[1]));}
const {applyTimetableImport}=load('TimetableImport');
const old={k:'timetable',semester:'2026-09-07',courses,teachingDays:[{date:'2026-10-09',sourceDate:''}],holidayDates:[{date:'2026-10-10',name:'旧校历'}],courseChanges:[{id:'x',courseId:courses[0].id,date:'2026-10-14',targetDate:''}]};
const replaced=applyTimetableImport(old,'2027-02-22',[{...courses[0],id:'new'}],true);
assert.deepEqual(replaced.teachingDays,[]);assert.deepEqual(replaced.holidayDates,[]);assert.deepEqual(replaced.courseChanges,[]);assert.equal(old.teachingDays.length,1,'import does not mutate the existing timetable before save');
const kept=applyTimetableImport(old,old.semester,courses,true,true);assert.equal(kept.teachingDays.length,1);assert.equal(kept.holidayDates.length,1);assert.equal(kept.courseChanges.length,0,'old lesson IDs never carry exceptions across replacement');
const appended=applyTimetableImport(old,old.semester,courses,false);assert.equal(appended.courses.length,courses.length);assert.equal(appended.teachingDays.length,1);assert.throws(()=>applyTimetableImport(old,'2027-02-22',courses,false),/开学日期不同/);
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
 console.log('PASS: 249 adapter syntax, exact interrupted weeks, timetable validation, school-specific early/night/weekend times and weeks; replacement calendar isolation; local bridge choices and cancellation');
})().catch(e=>{console.error(e);process.exit(1);});
