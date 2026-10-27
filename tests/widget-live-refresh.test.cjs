const fs=require('node:fs'),vm=require('node:vm'),assert=require('node:assert/strict'),path=require('node:path');
const ts=require(process.env.FRIDGE_TYPESCRIPT||'/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript');
const root=path.resolve('entry/src/main/ets'),cache=new Map();let now=new Date('2026-10-21T10:00:00').getTime();
class Clock extends Date {constructor(...args){super(...(args.length?args:[now]));}static now(){return now;}}
function execute(source,globals={}){const out={exports:{},Date:Clock,...globals};vm.runInNewContext(ts.transpileModule(source,{compilerOptions:{target:ts.ScriptTarget.ES2020,module:ts.ModuleKind.CommonJS}}).outputText,out);return out.exports;}
const kits={'@kit.FormKit':{formProvider:{}},'@ohos.data.preferences':{}};
function load(name){if(cache.has(name))return cache.get(name);const out={};cache.set(name,out);execute(fs.readFileSync(path.join(root,'model',name+'.ets'),'utf8'),{exports:out,require:s=>s in kits?kits[s]:load(s.slice(2))});return out;}
const settle=()=>new Promise(resolve=>setImmediate(resolve));
(async()=>{
 const {defaultState,FridgeCard}=load('CardSchema'),{widgetBoundary}=load('WidgetSchedule'),{refreshMinutes}=load('WidgetRefreshPolicy');
 const state=defaultState();state.cards=[];assert.equal(widgetBoundary(state,now),Infinity);
 const card=new FridgeCard();state.cards=[card];card.capability={k:'battery'};
 assert.equal(widgetBoundary(state,now),now+5*60000);assert.equal(refreshMinutes(state,now),5);
 card.hidden=true;assert.equal(widgetBoundary(state,now),Infinity,'hidden data does not spend refresh quota');card.hidden=false;
 card.capability={k:'agenda',agendaSource:'system',attemptedAt:now};assert.equal(widgetBoundary(state,now),now+15*60000);assert.equal(refreshMinutes(state,now),15);
 for(const k of ['date','calendar','lunar','countdown','anniversary']){card.capability={k};assert.equal(widgetBoundary(state,now),new Date('2026-10-22T00:00:00').getTime());}
 const {capabilityRenderTick}=load('CapabilityClock');for(const k of ['clock','worldclock','timetable','agenda','dayprogress','yearprogress']){assert.equal(capabilityRenderTick({k},now),now);assert.equal(capabilityRenderTick({k},now+60000),now+60000);}
 const entry=fs.readFileSync(path.join(root,'entryability/EntryAbility.ets'),'utf8'),refresh=entry.slice(entry.indexOf('  private refreshBackgroundWidgets():'),entry.indexOf('  private launchPage:'));
 const bg=entry.slice(entry.indexOf('  onBackground():'),entry.lastIndexOf('\n}')),storage=new Map(),deliveries=[];let callback,invalidations=0,hold=null;
 const service={invalidateCapabilityRead:()=>invalidations++},widgets={refreshStoredWidgets:async context=>{deliveries.push(context);if(hold)await hold;}};
 const {Host}=execute('export class Host {context={id:7};backgroundRefresh=null;backgroundRefreshPending=false;backgroundBattery={start(fn){callback(fn);}};'+refresh+bg+'}',{callback:fn=>callback=fn,AppStorage:{get:k=>storage.get(k),setOrCreate:(k,v)=>storage.set(k,v)},hilog:{warn(){},info(){}},require:s=>s.endsWith('CapabilityService')?service:widgets,TAG:'test'});
 const host=new Host();host.onBackground();await settle();assert.equal(deliveries.length,1,'leaving the editor immediately refreshes saved desktop bindings');assert.equal(storage.get('appBackgrounded'),true);
 callback();await settle();assert.equal(deliveries.length,2,'battery event updates desktop while the app is backgrounded');assert.equal(invalidations,2,'background event bypasses cached battery read');
 let release;hold=new Promise(r=>release=r);callback();await settle();callback();callback();assert.equal(deliveries.length,3);hold=null;release();await settle();await settle();assert.equal(deliveries.length,4,'overlapping broadcasts produce one trailing refresh');storage.set('appBackgrounded',false);callback();await settle();assert.equal(deliveries.length,4,'late background work cannot publish after foreground resume');
 const battery={batterySOC:42,chargingStatus:0};const created=[],subscribed=[],unsubscribed=[];const events={createSubscriber:()=>new Promise(resolve=>created.push(resolve)),subscribe:(s,cb)=>subscribed.push({s,cb}),unsubscribe:s=>unsubscribed.push(s)};
 const {BatteryObserver}=execute(fs.readFileSync(path.join(root,'model/BatteryObserver.ets'),'utf8'),{require:s=>s==='@kit.BasicServicesKit'?{commonEventManager:events,batteryInfo:battery}:{hilog:{info(){},warn(){}}}});const observer=new BatteryObserver();let changes=0;
 const old=observer.start(()=>changes++);observer.stop();const fresh=observer.start(()=>changes++);created[0]({id:'old'});await old;assert.equal(subscribed.length,0,'old subscriber cannot attach after restart');created[1]({id:'new'});await fresh;subscribed[0].cb(null,{});assert.equal(changes,1);subscribed[0].cb(null,{});assert.equal(changes,1,'temperature-only events and thawed duplicates are ignored');subscribed[0].cb({code:1},{});assert.equal(changes,1,'subscription errors are not battery changes');observer.stop();subscribed[0].cb(null,{});assert.equal(changes,1);assert.equal(unsubscribed[0].id,'new');
 console.log('PASS desktop refresh: background power events, provider invalidation, broadcast coalescing, lifecycle races, five-minute battery fallback, agenda polling and local time boundaries.');
})().catch(e=>{console.error(e);process.exitCode=1;});
