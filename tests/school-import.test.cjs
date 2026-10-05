const assert=require('node:assert/strict'),fs=require('node:fs'),path=require('node:path'),vm=require('node:vm');
const ts=require('/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript');
const root=path.resolve(__dirname,'../entry/src/main/ets/model'),raw=path.resolve(root,'../../resources/rawfile'),cache=new Map();
function load(name){if(cache.has(name))return cache.get(name).exports;const module={exports:{}};cache.set(name,module);const code=ts.transpileModule(fs.readFileSync(path.join(root,name+'.ets'),'utf8'),{compilerOptions:{target:ts.ScriptTarget.ES2020,module:ts.ModuleKind.CommonJS}}).outputText;vm.runInThisContext('(function(require,module,exports){'+code+'})')(s=>load(s.replace('./','')),module,module.exports);return module.exports;}
const {parseSchoolCourses,schoolSnapshot}=load('SchoolImport'),{resolveWakeUp}=load('WakeUpImport');
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
console.log('PASS: local course JSON conversion, interrupted teaching weeks, distinct school schedules and calendar replacement isolation.');
