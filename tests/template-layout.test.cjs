process.env.TZ='Asia/Shanghai';
const fs=require('node:fs'),vm=require('node:vm'),assert=require('node:assert/strict');
const ctx=vm.createContext({});vm.runInContext(fs.readFileSync('previewer/shared-models.js','utf8'),ctx);const load=n=>ctx.FridgeCore.load(n),factory=load('TemplateFactory'),catalog=load('CardTemplate').CARD_TEMPLATES.filter(t=>t.kind!=='ensemble'),schema=load('CardSchema'),render=load('TemplateScene'),text=load('TemplateTextLayout');
const times=['2026-02-01T23:59:00+08:00','2024-02-29T00:00:00+08:00','2026-11-01T10:08:00+08:00','2026-12-31T23:59:00+08:00','2026-08-31T23:59:00+08:00'];
const long='跨学科研究方法与现代工程实践·👨‍👩‍👧‍👦Cafe\u0301🇨🇳 '.repeat(20);
function scenario(card,mode,tick){const cap=card.capability;cap.title=mode==='long'?long:'日程与课程';cap.city=mode==='long'?long:'加德满都';cap.zone='Asia/Kathmandu';cap.date=mode==='invalid'?'2026-02-31':mode==='long'?'1900-01-01':'2099-12-31';cap.percent=mode==='invalid'?NaN:mode==='empty'?-1:100;cap.semester='2026-08-31';
 if(mode!=='empty')cap.events=[0,1,2].map(i=>({id:'e'+i,title:long,start:tick+i*3600000,end:tick+(i+2)*3600000,location:long,allDay:i===0}));
 cap.courses=mode==='empty'?[]:Array.from({length:mode==='long'?64:7},(_,i)=>({id:'c'+i,name:long,room:long,day:i%7+1,start:mode==='long'?'00:00':'08:00',end:'23:59',firstWeek:1,lastWeek:60,parity:0}));cap.artist=long;
 if(mode==='photo'){const photo=new schema.CanvasElement();photo.kind='image';photo.src='file:///wide.webp';photo.depthForeground='file:///alpha.png';photo.depthEnabled=true;photo.depthSourceAspect=8;card.elements=[photo];card.template.zoom=1.5;card.template.offsetX=-.35;card.template.offsetY=.35;}
}
const measure=(value,size)=>text.templateClusters(value).reduce((sum,char)=>sum+size*(/[^\x00-\xff]/.test(char)?1:.62),0);
let scenes=0,labels=0;
for(const item of catalog)for(const mode of ['empty','long','invalid','photo'])for(const palette of ['','cream','cobalt','ink'])for(const date of times)for(const aspect of [0.3,1,2,3]){
 const tick=Date.parse(date),card=factory.makeTemplateCards(item.id,1,()=>item.id,tick)[0];card.w=300;card.h=300/aspect;card.template.palette=palette;scenario(card,mode,tick);const scene=render.cardTemplateScene(card,tick);scenes++;
 for(const mark of scene.marks){for(const key of ['x','y','w','h','r','size','angle','opacity','start','sweep'])assert.ok(Number.isFinite(mark[key]),item.id+' '+mode+' nonfinite '+key);
 if(mark.kind!=='text')continue;labels++;assert.ok(mark.x>=0&&mark.y>=0&&mark.x+mark.w<=300.001&&mark.y+mark.h<=300.001,item.id+' text slot outside face');assert.ok(!/NaN|Infinity|undefined/.test(mark.text),item.id+' invalid label');
 const fit=text.layoutTemplateText(mark,measure);assert.ok(fit.fontSize>0&&Number.isFinite(fit.fontSize));assert.ok(fit.lines.length<=mark.lines);assert.ok(fit.lineHeight*fit.lines.length<=mark.h+.001,item.id+' text height');for(const line of fit.lines){assert.ok(measure(line,fit.fontSize)<=mark.w+.01,item.id+' text width '+line);assert.ok(!/^[\udc00-\udfff]|[\ud800-\udbff]$/.test(line),'broken surrogate');}
 }
}
assert.deepEqual(Array.from(text.templateClusters('👨‍👩‍👧‍👦e\u0301🇨🇳')),['👨‍👩‍👧‍👦','e\u0301','🇨🇳']);
const longCard=factory.makeTemplateCards('course-next',1,()=> 'course')[0],tick=Date.parse('2026-11-01T10:08:00+08:00');scenario(longCard,'long',tick);assert.ok(render.cardTemplateScene(longCard,tick).marks.some(m=>m.kind==='text'&&m.lines===2));
const invalid=factory.makeTemplateCards('countdown-paper',1,()=> 'invalid')[0];scenario(invalid,'invalid',tick);assert.ok(render.cardTemplateScene(invalid,tick).marks.some(m=>m.text==='—'),'invalid dates stay unconfigured');
console.log(`PASS template layout: ${scenes} scenes / ${labels} text slots; 39 designs, 4 data extremes, 5 boundary dates, 4 aspect ratios, 4 palettes; measured fitting and Unicode clusters`);

const august=factory.makeTemplateCards('calendar-month',1,()=> 'six')[0],grid=render.cardTemplateScene(august,Date.parse('2026-08-31T12:00:00+08:00'));assert.ok(grid.marks.some(m=>m.kind==='text'&&m.text==='31'&&m.y===256),'six-row month shows the final date');
for(const zone of ['America/New_York','Europe/Berlin','Pacific/Auckland']){process.env.TZ=zone;const date=new Date(2026,5,1,0,0),card=factory.makeTemplateCards('year-dots',1,()=> zone)[0];assert.ok(render.cardTemplateScene(card,date.getTime()).marks.some(m=>m.text==='已过 151 天'),'civil day count must survive DST: '+zone);}process.env.TZ='Asia/Shanghai';
for(const raw of ['','2026-02-31','2100-02-29','nonsense']){const card=factory.makeTemplateCards('countdown-orbit',1,()=> 'date')[0];card.capability.date=raw;assert.ok(render.cardTemplateScene(card,tick).marks.some(m=>m.text==='—'));}
for(const phase of [['2020-01-01','天前'],['2099-01-01','天后']]){const card=factory.makeTemplateCards('countdown-poster',1,()=> 'phase')[0];card.capability.date=phase[0];assert.ok(render.cardTemplateScene(card,tick).marks.some(m=>m.text===phase[1]));}
const allDay=factory.makeTemplateCards('agenda-paper',1,()=> 'all-day')[0];scenario(allDay,'long',tick);assert.ok(render.cardTemplateScene(allDay,tick).marks.some(m=>m.text==='全天'));
console.log('PASS six-row months, DST civil-day counts, impossible dates, past/future countdown labels and all-day agenda');

assert.equal(render.templateContrastInk('#EABB65'),'#26312A');assert.equal(render.templateContrastInk('#26312A'),'#FFFFFF');
for(const palette of ['cobalt','ink']){const card=factory.makeTemplateCards('calendar-week',1,()=> palette)[0];card.template.palette=palette;const chosen=render.cardTemplateScene(card,tick).marks.filter(m=>m.kind==='text'&&m.y===199);assert.ok(chosen.some(m=>m.color==='#26312A'),'light accent pills need dark text');}
for(const pct of [0,1,9,10,25,50,99,100,101,-1,NaN,Infinity])for(const name of ['battery-ring','battery-cell','battery-segments'])for(const palette of ['','cream','cobalt','ink']){const card=factory.makeTemplateCards(name,1,()=> 'battery')[0];card.template.palette=palette;card.capability.percent=pct;const scene=render.cardTemplateScene(card,tick);assert.ok(scene.marks.every(m=>Number.isFinite(m.w)&&Number.isFinite(m.h)&&Number.isFinite(m.sweep)));const expected=Number.isFinite(pct)&&pct>=0?String(Math.min(100,pct)):'—';assert.ok(scene.marks.some(m=>m.text===expected));}
console.log('PASS 144 battery boundary/palette cases: 0/1/9/10/25/50/99/100/overflow/unknown/nonfinite');
