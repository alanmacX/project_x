const fs=require('node:fs'),vm=require('node:vm'),assert=require('node:assert/strict');
const ctx=vm.createContext({});vm.runInContext(fs.readFileSync('previewer/shared-models.js','utf8'),ctx);
const core=ctx.FridgeCore,{sharedCapability}=core.load('SharedCapability'),schema=core.load('CardSchema'),templates=core.load('TemplatePackage');
const privateData={title:'PRIVATE target',date:'2028-07-02',semester:'2026-09-01',courses:[{id:'secret',name:'PRIVATE course',room:'PRIVATE room',day:1,start:'08:00',end:'09:00',firstWeek:1,lastWeek:16,parity:0}],events:[{id:'secret',title:'PRIVATE meeting',location:'PRIVATE address',start:1,end:2}],agendaSource:'imported',holidayDates:[{date:'2026-10-01',name:'PRIVATE school'}],teachingDays:[{date:'2026-10-01',sourceDate:'2026-10-02'}],courseChanges:[],percent:67,charging:true,chargeState:'charging',updatedAt:123,attemptedAt:123,refreshState:'ready',seed:'secret',value:'PRIVATE cached data',parcels:[{id:'p',code:'PRIVATE code'}],unknownFuturePrivateField:'PRIVATE future'};
const state=schema.defaultState();state.cards=['battery','agenda','timetable','countdown','anniversary','clock'].map((k,i)=>{const c=new schema.FridgeCard();c.id='c'+i;c.capability={...privateData,k,readingBlend:'cloud',readingTint:'#abccdd'};return c;});
const original=JSON.stringify(state),out=templates.packageScene(original,'');
assert.equal(JSON.stringify(state),original,'export never mutates the sender');
assert.ok(!JSON.stringify(out).includes('PRIVATE'),'no sender records or unknown provider fields in exported design');
for(const c of out.state.cards){assert.equal(c.capability.readingBlend,'cloud');assert.equal(c.capability.readingTint,'#abccdd');}
assert.equal(out.state.cards[0].capability.percent,-1);assert.equal(out.state.cards[1].capability.agendaSource,'system');assert.equal(out.state.cards[2].capability.courses.length,0);assert.equal(out.state.cards[3].capability.date,undefined);
let id=0;const imported=templates.importedCards(state,()=>String(++id));assert.ok(!JSON.stringify(imported).includes('PRIVATE'),'legacy files cannot inject sender data on import');
// Recipient timetable is bound after template sanitization, retaining the shared visual design.
const libSource=fs.readFileSync('entry/src/main/ets/model/TimetableLibrary.ets','utf8');
const ts=require('/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript');const mod={exports:{}};
vm.runInThisContext('(function(require,module,exports){'+ts.transpileModule(libSource,{compilerOptions:{module:ts.ModuleKind.CommonJS}}).outputText+'})')(s=>core.load(s.slice(2)),mod,mod.exports);
const recipient={semester:'2026-09-07',courses:[{name:'My own class'}],skipHolidays:true,holidayDates:[],teachingDays:[],courseChanges:[]};
const bound=mod.exports.useSavedTimetable(imported[2].capability,recipient);assert.equal(bound.courses[0].name,'My own class');assert.equal(bound.readingTint,'#abccdd');
const album=sharedCapability({k:'album',title:'Artwork album',artist:'Artwork artist',albumCover:'file:///cover.png',albumRotationStart:123,albumId:'sender-id'});assert.equal(album.title,'Artwork album');assert.equal(album.albumCover,'file:///cover.png');assert.equal(album.albumRotationStart,0);assert.equal(album.albumId,'sender-id','album selection is an artwork reference');
const world=sharedCapability({k:'worldclock',zone:'Asia/Tokyo',city:'东京',value:'PRIVATE'});assert.equal(world.zone,'Asia/Tokyo');assert.equal(world.value,undefined);
const html=JSON.parse(fs.readFileSync('skills/fridge-create/examples/html-clock.fridge','utf8'));html.state.cards[0].capability={...privateData,k:'agenda'};const htmlCards=templates.importedCards(templates.readPackage(JSON.stringify(html)).state,()=>String(++id));assert.equal(htmlCards[0].html.source,html.state.cards[0].html.source);assert.equal(htmlCards[0].capability.events.length,0,'HTML uses the same recipient provider binding');
console.log('PASS design-only share, legacy import privacy, recipient library binding, retained artwork and HTML provider privacy.');
