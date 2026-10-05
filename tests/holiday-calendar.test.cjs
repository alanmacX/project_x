const assert=require('node:assert/strict'),fs=require('node:fs'),path=require('node:path'),vm=require('node:vm');
const ts=require('/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript');
const root=path.resolve(__dirname,'../entry/src/main/ets/model'),cache=new Map();
function load(name){const file=path.resolve(root,name+'.ets');if(cache.has(file))return cache.get(file).exports;const mod={exports:{}};cache.set(file,mod);const code=ts.transpileModule(fs.readFileSync(file,'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText;vm.runInThisContext('(function(require,module,exports){'+code+'\n})',{filename:file})(s=>load(path.relative(root,path.resolve(path.dirname(file),s))),mod,mod.exports);return mod.exports;}
const h=load('HolidayCalendar'),d=load('CapabilityData'),schema=load('CardSchema');
const at=s=>new Date(s+'T07:00:00').getTime(), dates=cap=>d.courseInstances(cap,at('2026-10-01')).map(e=>h.dateKey(new Date(e.start)));
const c={id:'math',name:'数学',room:'101',day:4,start:'09:00',end:'10:00',firstWeek:1,lastWeek:20,parity:0};
const cap={k:'timetable',semester:'2026-08-31',courses:[c]};
assert.equal(h.holidayName(new Date(at('2026-10-07'))),'国庆节');assert.equal(h.holidayMarker(new Date(at('2026-10-10'))),'班');assert.equal(h.holidayName(new Date(at('2027-10-01'))),'');assert.equal(h.holidayKnown(2027),false);
assert.deepEqual(dates(cap),['2026-10-08']);assert.deepEqual(dates({...cap,skipHolidays:false}),['2026-10-01','2026-10-08']);
assert.deepEqual(dates({...cap,teachingDays:[{date:'2026-10-01',sourceDate:'2026-10-01'}]}),['2026-10-01','2026-10-08']);
assert.deepEqual(dates({...cap,teachingDays:[{date:'2026-10-10',sourceDate:'2026-10-08'}]}),['2026-10-10']);
assert.deepEqual(dates({...cap,holidayDates:[{date:'2026-10-08',name:'校庆'}]}),[]);
const change={id:'move',courseId:'math',date:'2026-10-08',targetDate:'2026-10-03',start:'11:00',end:'12:00',room:'202'};
assert.deepEqual(dates({...cap,courseChanges:[change]}),['2026-10-03']);assert.equal(d.teachingDayLabel({...cap,courseChanges:[change]},at('2026-10-03')),'单次调课');
assert.deepEqual(dates({...cap,courseChanges:[{...change,targetDate:''}]}),[]);
assert.deepEqual(dates({...cap,courseChanges:[change],teachingDays:[{date:'2026-10-03',sourceDate:''}]}),[]);
assert.deepEqual(dates({...cap,courses:[{...c,parity:2}],teachingDays:[{date:'2026-10-10',sourceDate:'2026-10-08'}]}),['2026-10-10']);
const two={...cap,courses:[c,{...c,id:'art',name:'美术'}],courseChanges:[{...change,targetDate:''}]};assert.equal(d.courseInstances(two,at('2026-10-01'))[0].title,'美术');
assert.equal(h.validDay('2026-02-30'),false);assert.equal(h.validDay('2028-02-29'),true);assert.throws(()=>h.daysBetween('2026-10-08','2026-10-01'));
const ics='BEGIN:VCALENDAR\r\nBEGIN:VEVENT\r\nDTSTART;VALUE=DATE:20261001\r\nDTEND;VALUE=DATE:20261008\r\nSUMMARY:学校\r\n 假期\r\nEND:VEVENT\r\nEND:VCALENDAR\r\n';const imported=h.holidayFileDates(ics);assert.equal(imported.length,7);assert.equal(imported[6].date,'2026-10-07');assert.equal(imported[0].name,'学校假期');
assert.throws(()=>h.holidayFileDates(ics.replace('SUMMARY:','RRULE:FREQ=YEARLY\r\nSUMMARY:')));assert.throws(()=>h.holidayFileDates(ics.replace('20261001','20261001T090000')));
const n=schema.normalizeCapability({...cap,courseChanges:[change,{...change,id:'bad',date:'2026-02-30'}],teachingDays:[{date:'bad',sourceDate:''}]});assert.equal(n.skipHolidays,true);assert.equal(n.courseChanges.length,1);assert.equal(n.teachingDays.length,0);
assert.deepEqual(h.missingHolidayYears('2026-08-31',16),[]);assert.deepEqual(h.missingHolidayYears('2026-08-31',24),[2027]);assert.ok(h.holidayDataLabel().includes('随应用版本更新'));
for(const period of h.HOLIDAY_PERIODS){assert.ok(h.validDay(period.start)&&h.validDay(period.end));assert.ok(period.end>=period.start);for(const day of h.daysBetween(period.start,period.end))assert.equal(h.holidayMarker(new Date(day+'T12:00:00')),'休');}
const midnight=new Date('2026-10-02T00:00:00').getTime();assert.equal(d.nextDataBoundary(cap,new Date('2026-10-01T23:59:00').getTime()),midnight);
console.log('PASS: holidays, unpublished years, school overrides, whole-day transfer/parity, cancellation, single-lesson moves, midnight boundary, normalization, all-day ICS and recurrence rejection');
