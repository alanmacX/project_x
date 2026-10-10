const assert=require('node:assert/strict'),fs=require('node:fs'),path=require('node:path'),vm=require('node:vm');
const ts=require('/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript');
const root=path.resolve(__dirname,'../entry/src/main/ets/model'),cache=new Map();
function load(name){const file=path.resolve(root,name+'.ets');if(cache.has(file))return cache.get(file).exports;const mod={exports:{}};cache.set(file,mod);const code=ts.transpileModule(fs.readFileSync(file,'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText;vm.runInThisContext('(function(require,module,exports){'+code+'\n})',{filename:file})(s=>s==='@kit.ArkTS'?{taskpool:{}}:load(path.relative(root,path.resolve(path.dirname(file),s))),mod,mod.exports);return mod.exports;}
const d=load('CapabilityData'),l=load('TimetableLayout'),m=load('CapabilityMetrics'),g=load('CanvasLayout'),s=load('CardSchema');
const at=t=>new Date(t).getTime();
const course=(id,day,start='09:00',end='10:00',extra={})=>({id,name:'课程'+id,room:'教室101',day,start,end,firstWeek:1,lastWeek:20,parity:0,...extra});
const base={k:'timetable',semester:'2026-08-31',courses:[course('one',1),course('two',1,'11:00','12:00'),course('tomorrow',2)]};
const view=(cap,t)=>d.timetableDisplay(cap,at(t));
assert.equal(view(base,'2026-09-07T09:49:59').lessons[0].courseId,'one');
assert.equal(view(base,'2026-09-07T09:50:00').lessons[0].courseId,'two');
assert.equal(view(base,'2026-09-07T08:59:00').heading,'下一课');
assert.equal(view(base,'2026-09-07T09:10:00').heading,'正在上课');
assert.equal(view(base,'2026-09-07T19:59:59').lessons.length,0);
assert.equal(view(base,'2026-09-07T20:00:00').lessons[0].courseId,'tomorrow');
assert.equal(view(base,'2026-09-07T20:00:00').heading,'明日第一课');
assert.equal(view({...base,courses:[course('thu',4)]},'2026-10-01T07:00:00').lessons.length,0,'never reach over holiday to next week');
const holiday={...base,courses:[course('thu',4)],teachingDays:[{date:'2026-10-02',sourceDate:'2026-10-08'}]};
assert.equal(view(holiday,'2026-10-01T19:59:59').lessons.length,0);
assert.equal(view(holiday,'2026-10-01T20:00:00').lessons[0].courseId,'thu','school override tomorrow is announced on preceding evening');
assert.equal(view({...holiday,teachingDays:[{date:'2026-10-01',sourceDate:'2026-10-01'}]},'2026-10-01T08:00:00').lessons.length,1);
const daily={...base,timetableMode:'day'};
assert.equal(view(daily,'2026-09-07T11:50:00').lessons.length,2,'brief retains finished morning course');
assert.equal(view(daily,'2026-09-07T11:59:59').heading,'今日课程');
assert.equal(view(daily,'2026-09-07T12:00:00').heading,'明日课程');
assert.equal(view(daily,'2026-09-07T12:00:00').lessons.length,1);
assert.equal(view({...daily,courses:base.courses.slice(0,2)},'2026-09-07T12:00:00').empty,'明日无课');
assert.equal(view({...daily,courses:[course('fri',5)]},'2026-10-01T08:00:00').lessons.length,0);
assert.equal(view({...base,courses:[course('short',1,'09:00','09:05')]},'2026-09-07T08:59:00').lessons.length,1,'short class visible before start');
const change={id:'move',courseId:'one',date:'2026-09-07',targetDate:'2026-09-08',start:'14:00',end:'15:00',room:'202'};
const changed={...daily,courseChanges:[change]};
assert.equal(d.coursesOnDay(changed,at('2026-09-07T08:00:00')).length,1);
assert.equal(d.coursesOnDay(changed,at('2026-09-08T08:00:00')).length,2);
assert.equal(l.timetableCapacity(changed),2,'moved lesson included in minimum');
const dense={...daily,courses:Array.from({length:8},(_,i)=>course(String(i),1,`${String(i+8).padStart(2,'0')}:00`,`${String(i+9).padStart(2,'0')}:00`))};
assert.equal(view(dense,'2026-09-07T14:00:00').lessons.length,8,'no three-item truncation');
assert.equal(m.capabilityMinimum(dense,true).h,50);
assert.equal(l.briefColumns(191),1);assert.equal(l.briefColumns(207),1);assert.equal(l.briefColumns(208),2);assert.equal(l.briefColumns(312),3);
const card=new s.FridgeCard();card.id='day';card.w=320;card.h=260;card.capability=dense;card.shape='rect';
assert.ok(g.ensureCapabilitySize(card));const box=g.capabilityPlacement(card);
assert.ok(box.w*card.w>=104*m.MIN_CAPABILITY_SCALE-.1);assert.ok(m.capabilityFits(dense,box.w*card.w,box.h*card.h),'all eight lessons fit at the supported typography floor');
const first=g.capabilityPlacement(card);card.capability={...base};const next=g.capabilityPlacement(card);assert.notEqual(next,first,'mode switch invalidates cached layout even when the requested box already fits both modes');
const thin=new s.FridgeCard();thin.shape='subject';thin.outline=[[{x:.4,y:0},{x:.6,y:0},{x:.6,y:1},{x:.4,y:1}]];thin.capability=dense;assert.equal(g.ensureCapabilitySize(thin),false,'do not crush content into narrow cutout');
assert.equal(d.nextDataBoundary(base,at('2026-09-07T09:49:00')),at('2026-09-07T09:50:00'));
assert.equal(d.nextDataBoundary(base,at('2026-09-07T19:59:00')),at('2026-09-07T20:00:00'));
assert.equal(d.nextDataBoundary(daily,at('2026-09-07T11:59:00')),at('2026-09-07T12:00:00'));
const overlap={...base,courses:[course('a',1,'09:00','10:00'),course('b',1,'09:30','11:00'),course('c',1,'11:00','12:00')]};
assert.deepEqual(l.weekLessons(overlap,2).map(i=>[i.lane,i.lanes]),[[0,2],[1,2],[0,1]]);
assert.equal(l.weekLessons({...base,courses:[course('odd',1,'09:00','10:00',{parity:1})]},2).length,0);
assert.equal(s.normalizeCapability({...base,timetableMode:'other'}).timetableMode,'next');assert.equal(s.normalizeCapability(daily).timetableMode,'day');

const twelve={...dense,courses:Array.from({length:12},(_,i)=>course('busy'+i,1,'09:00','10:00'))};assert.equal(m.capabilityMinimum(twelve,true).w,104);assert.equal(m.capabilityMinimum(twelve,true).h,50);
const oldMinimum=l.timetableCapacity(twelve);twelve.courses=twelve.courses.slice(0,4);assert.equal(l.timetableCapacity(twelve),4,'replacement invalidates reference cache');
const begin=performance.now();for(let i=0;i<10000;i++){m.capabilityMinimum(dense,true);g.capabilityPlacement(card);}const elapsed=performance.now()-begin;
console.log(JSON.stringify({scenario:'10,000 warm timetable minimum + card placement lookups (model CPU only, not device FPS)',milliseconds:Number(elapsed.toFixed(2))}));

assert.equal(m.capabilityFits(dense,400,210),true,'wide brief preserves all rows using adaptive columns');assert.equal(m.capabilityFits(dense,192,205),true,'compact two-column brief is now allowed');assert.equal(m.capabilityFits(dense,166.4,116),true,'small brief drops whole secondary lessons rather than forcing a giant card');

const changingHolidays={...daily,courses:[course('original',1),course('first',2),course('second',2)],holidayDates:[{date:'2026-09-08',name:'校假'}],courseChanges:[{...change,courseId:'original',targetDate:'2026-09-08'}]};assert.equal(l.timetableCapacity(changingHolidays),2);changingHolidays.holidayDates=[];assert.equal(l.timetableCapacity(changingHolidays),3,'holiday changes invalidate transferred-day capacity');
console.log('PASS timetable: 10-minute handoff, evening/holiday gating, whole-day brief, tomorrow empty, short classes, transfers, dense adaptive sizing/cache, narrow cutout rejection, update boundaries, week overlaps/parity and migration');

const smallDaily={...daily,courses:[course('compact-a',1),course('compact-b',1,'11:00','12:00')]};
const compactMin=m.capabilityReadableMinimum(smallDaily);
assert.equal(compactMin.w,83.2);assert.equal(compactMin.h,40);
assert.ok(m.capabilityFits(smallDaily,83.2,40),'a complete first row fits the minimum; more rows appear as space grows');
assert.ok(!m.capabilityFits(smallDaily,82,40),'keep the readable width floor');
const hookCard=new s.FridgeCard();hookCard.capability={...smallDaily,readingBlend:'tag',readingStyle:'surface'};
const hookMin=g.cardCapabilityMinimum(hookCard,true);
assert.equal(hookMin.w,91.2);assert.equal(hookMin.h,68,'small timetable still reserves a separate punched-hook band');
console.log('PASS compact timetable: one complete row at 83.2x40, hook padding and 208/312 vp multi-column thresholds');

const nextMin=m.capabilityReadableMinimum(base);
assert.equal(nextMin.w,64);assert.equal(nextMin.h,40);
assert.ok(m.capabilityFits(base,64,40),'next lesson fits the same single-row geometry');
const source=require('node:fs').readFileSync('entry/src/main/ets/views/TimetableCapability.ets','utf8');
assert.ok(source.includes('this.lessonRow(e)')&&source.includes('this.lessonRow(this.display.lessons[0])'),'both modes share exactly the same course row');
assert.ok(source.includes('Text(timeText(e.end))'),'complete end time remains visible in a dedicated row');
const width=load('PaperTextWidth');for(const time of ['08:00','09:45','10:10','12:00','23:59'])assert.ok(width.paperTextWidth(time,9.5)<=30,'time column fits every representative start/end time');
console.log('PASS unified compact course rows: next lesson 64x40, matching brief typography and complete start/end times');

assert.equal(m.capabilityMinimum(dense,false).h,274,'full presentation still budgets the complete imported day');
for(const [height,cols,count] of [[49,1,0],[50,1,1],[81,1,1],[82,1,2],[82,2,4],[114,3,8]]){
 assert.equal(l.visibleLessonCount(height,8,cols),count);
 assert.ok(18+Math.ceil(count/cols)*32<=Math.max(18,height));
}
assert.equal(dense.courses.length,8,'presentation never removes saved lessons');
