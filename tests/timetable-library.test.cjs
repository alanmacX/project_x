const assert=require('node:assert/strict'),fs=require('node:fs'),path=require('node:path'),vm=require('node:vm');
const ts=require('/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript'),root=path.resolve(__dirname,'../entry/src/main/ets/model'),cache=new Map();
function load(name){const file=path.resolve(root,name+'.ets');if(cache.has(file))return cache.get(file).exports;const mod={exports:{}};cache.set(file,mod);const code=ts.transpileModule(fs.readFileSync(file,'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText;vm.runInThisContext('(function(require,module,exports){'+code+'\n})',{filename:file})(s=>load(path.relative(root,path.resolve(path.dirname(file),s))),mod,mod.exports);return mod.exports;}
const {TimetableLibrary,useSavedTimetable,sameTimetable}=load('TimetableLibrary');
const course={id:'math',name:'数学',room:'A101',day:2,start:'08:00',end:'09:40',firstWeek:1,lastWeek:18,parity:1};
const cap={k:'timetable',semester:'2026-09-07',courses:[course],skipHolidays:false,holidayDates:[{date:'2026-10-01',name:'校庆'}],teachingDays:[{date:'2026-10-10',sourceDate:'2026-10-09'}],courseChanges:[{id:'x',courseId:'math',date:'2026-10-06',targetDate:'2026-10-08',start:'14:00',end:'15:40',room:'B101'}],readingBlend:'tag',timetableMode:'day'};
(async()=>{
 let disk='',writes=0,fail=false;
 const io={read:async()=>disk,write:async(json)=>{if(fail)throw Error('disk full');await new Promise(r=>setTimeout(r,5));disk=json;writes++;}};
 const first=new TimetableLibrary(io);assert.equal(await first.read(),null);await first.save(cap);
 cap.courses[0].room='mutated after save';assert.equal((await first.read()).courses[0].room,'A101');
 const restart=new TimetableLibrary(io),saved=await restart.read();assert.equal(saved.semester,'2026-09-07');assert.equal(saved.courses[0].parity,1);assert.equal(saved.holidayDates[0].name,'校庆');assert.equal(saved.courseChanges[0].room,'B101');
 assert(!disk.includes('readingBlend')&&!disk.includes('timetableMode'),'storage owns course data, not card presentation');
 const a=useSavedTimetable({k:'timetable',readingBlend:'cloud',timetableMode:'next'},saved),b=useSavedTimetable({k:'timetable',readingBlend:'bare',timetableMode:'day'},saved);
 assert.equal(a.readingBlend,'cloud');assert.equal(b.timetableMode,'day');assert(sameTimetable(a,b));a.courses[0].name='改名';assert.equal(b.courses[0].name,'数学');assert.equal((await restart.read()).courses[0].name,'数学','card edit/deletion does not mutate retained course data');
 const latest={...b,courses:[{...course,name:'物理',room:'C101'}]};await restart.save(latest);
 await restart.save(b,true);assert.equal((await restart.read()).courses[0].name,'物理','deleting old card does not replace latest saved timetable');
 fail=true;await assert.rejects(restart.save({...latest,semester:'2027-02-22'}),/disk full/);assert.equal((await restart.read()).semester,'2026-09-07','failed flush preserves acknowledged data');
 fail=false;const p=restart.save({...latest,semester:'2027-02-22'}),q=restart.save({...latest,semester:'2027-03-01'});await Promise.all([p,q]);assert.equal((await new TimetableLibrary(io).read()).semester,'2027-03-01','ordered rapid edits survive restart');
 await restart.save({...latest,courses:[]});assert.deepEqual((await new TimetableLibrary(io).read()).courses,[],'intentional empty timetable is durable, not an invitation to remigrate an old card');
 const bad=new TimetableLibrary({read:async()=>'{broken',write:async()=>assert.fail('must not overwrite corrupt source')});await assert.rejects(bad.read());await assert.rejects(bad.save(b));
 assert(writes>=5);
 console.log('PASS reusable offline timetable: restart, calendar exceptions, independent cards/modes, deletion retention, ordered writes, flush failure, explicit empty data and corruption preservation');
})().catch(e=>{console.error(e);process.exitCode=1;});
