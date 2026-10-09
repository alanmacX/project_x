const assert=require('node:assert/strict'),fs=require('node:fs'),path=require('node:path'),vm=require('node:vm');
const ts=require('/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript');
const root=path.resolve(__dirname,'../entry/src/main/ets/model'),cache=new Map();
function load(name){const file=path.resolve(root,name+'.ets');if(cache.has(file))return cache.get(file).exports;const mod={exports:{}};cache.set(file,mod);const code=ts.transpileModule(fs.readFileSync(file,'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText;vm.runInThisContext('(function(require,module,exports){'+code+'\n})',{filename:file})(s=>s==='@kit.ArkTS'?{taskpool:{}}:load(path.relative(root,path.resolve(path.dirname(file),s))),mod,mod.exports);return mod.exports;}
const p=load('CapabilityPresentation'),m=load('CapabilityMetrics'),l=load('TimetableLayout'),c=load('CapabilityCalendar');
const now=new Date('2026-09-07T08:00:00').getTime();
const events=Array.from({length:20},(_,i)=>({id:String(i),title:'项目评审 '+i,location:'会议室 '+i,start:now+(i+1)*3600000,end:now+(i+2)*3600000,allDay:false}));
const cap={k:'agenda',events};
const small=p.summaryPresentation(cap,82,now,164),tall=p.summaryPresentation(cap,280,now,164),wide=p.summaryPresentation(cap,280,now,352);
assert.equal(small.events.length,1);assert.equal(tall.events.length,5);assert.equal(wide.events.length,10);assert.equal(wide.columns,2);assert.equal(wide.remaining,10);
assert.equal(p.summaryPresentation(cap,1000,now,1000).events.length,12,'bound native node count for oversized cards');
assert.equal(p.summaryPresentation(cap,280,now,351.99).columns,1,'avoid almost-fit two-column layout');
for(const w of [120,164,240,352,600]){let before=0;for(const h of [82,136,184,280,500]){const result=p.summaryPresentation(cap,h,now,w);assert.ok(result.events.length>=before,'more height never loses information');before=result.events.length;const rows=Math.ceil(result.events.length/result.columns);assert.ok(24+rows*48-8<=h,'every selected row fits the available content height');}}
assert.equal(events.length,20);assert.equal(events[0].id,'0','reading does not reorder or modify personal source');
for(const k of ['agenda','calendar','timetable']){assert.equal(m.capabilityContentScale({k},1000,1000),1);}
assert.ok(m.capabilityContentScale({k:'agenda'},96,65.6)>=.7999,'retain existing compact readable floor');
assert.equal(l.lessonRowHeight(114,3,1),32);assert.equal(l.lessonRowHeight(162,3,1),48);assert.equal(l.lessonRowHeight(198,3,1),60);assert.equal(l.lessonRowHeight(78,3,3),60);
assert.equal(l.lessonContext(events[0],now+30*60000),'距上课 30 分钟');assert.equal(l.lessonContext(events[0],now+70*60000),'剩余 50 分钟');assert.equal(l.lessonContext(events[0],now+130*60000),'');
assert.equal(c.detailedCalendar(223,300,6,true),false);assert.equal(c.detailedCalendar(224,247.99,6,true),false);assert.equal(c.detailedCalendar(224,248,6,true),true);assert.equal(c.detailedCalendar(224,272,6,false),true);
const month=new Date('2026-10-01T12:00:00'),labels=c.calendarDetails(month),cells=c.calendarCells(month);assert.equal(labels.length,cells.length);assert.ok(labels[cells.indexOf(1)].includes('国庆'));assert.equal(c.calendarDetails(new Date('2026-10-20T12:00:00')),labels,'one cached month avoids Intl work during repaint');assert.equal(labels[0],'');assert.ok(labels[cells.indexOf(15)].length>0);
console.log('PASS dense readouts: height/width content budgets, bounded nodes, compact floor, complete lesson lines, local cached calendar enrichment');
