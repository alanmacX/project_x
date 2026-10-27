// Execute the ability lifecycle against a window that rejects updates before load.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const ts = require(process.env.FRIDGE_TYPESCRIPT || '/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript');
const values = new Map(), backgrounds = [], bars = [], orientations = [];
let ready = false, callback;
const removed=[],jobs=[],displayListeners=new Map();
class UIAbility { context = {config: {colorMode: 1},cacheDir:'/cache',applicationInfo:{debug:false}}; }
const nativeWindow = {
  setWindowBackgroundColor(color) { if (!ready) throw Error('window state abnormal'); backgrounds.push(color); },
  setWindowSystemBarProperties(props) { bars.push(props); return Promise.resolve(); },
  setPreferredOrientation(value) { orientations.push(value); return Promise.resolve(); }, setImmersiveModeEnabledState() {},
  getUIContext() { return {px2vp: x => x}; }, getWindowAvoidArea() { return {topRect: {height: 32}, bottomRect: {height: 24}}; }, on() {},
};
const moduleMock = {exports:{}};
const source = fs.readFileSync('entry/src/main/ets/entryability/EntryAbility.ets','utf8');
const code = ts.transpileModule(source, {compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText;
const devicePolicy = {exports:{}};
vm.runInNewContext(ts.transpileModule(fs.readFileSync('entry/src/main/ets/model/DevicePolicy.ets','utf8'), {compilerOptions:{module:ts.ModuleKind.CommonJS}}).outputText,
  {exports:devicePolicy.exports,module:devicePolicy});
const kits = {
 '../model/BatteryObserver':{BatteryObserver:class {start(){}stop(){}}},
 '../model/StartupPresentation':{deferStartupReveal(){},revealStartup(){},cancelStartupReveal(){}},
 '../model/StartupTrace':{startStartupTrace(){},startupMark(){}},
 '../model/IncomingTemplate':{incomingTemplateUri:u=>u?.startsWith('file://')?u:'',stageIncomingTemplate:async()=>'',removeStagedTemplate:(u)=>{if(u)removed.push(u);}},
 '@kit.ArkTS':{taskpool:{Task:class{constructor(fn,...args){this.fn=fn;this.args=args;}},execute:task=>new Promise(resolve=>jobs.push({task,resolve}))}},
 '@kit.AbilityKit': {UIAbility, ConfigurationConstant:{ColorMode:{COLOR_MODE_DARK:0,COLOR_MODE_LIGHT:1}}},
 '../model/DevicePolicy':devicePolicy.exports,
 '@kit.BasicServicesKit':{deviceInfo:{deviceType:'tablet'}},
 '@kit.ArkUI': {display:{isFoldable:()=>false,getFoldStatus:()=>0,getFoldDisplayMode:()=>0,on:(name,cb)=>displayListeners.set(name,cb),off:(name,cb)=>{if(displayListeners.get(name)===cb)displayListeners.delete(name);}},window:{Orientation:{PORTRAIT:1,AUTO_ROTATION_UNSPECIFIED:12},AvoidAreaType:{TYPE_SYSTEM:0,TYPE_NAVIGATION_INDICATOR:1}}},
 '@kit.PerformanceAnalysisKit': {hilog:{info(){},warn(){},error(){}}},
};
vm.runInNewContext(code, {require:s=>kits[s],exports:moduleMock.exports, AppStorage:{get:k=>values.get(k),setOrCreate:(k,v)=>values.set(k,v)}});
const ability = new moduleMock.exports.default();
ability.onCreate({parameters:{}},{});
ability.onWindowStageCreate({getMainWindowSync:()=>nativeWindow,loadContent:(_,cb)=>callback=cb});
assert.doesNotThrow(()=>ability.onForeground());
assert.equal(backgrounds.length,0,'foreground before load must not touch the window');
ready=true; callback({code:0});
assert.equal(backgrounds.at(-1),'#FFFFFF');
ability.onConfigurationUpdate({colorMode:0});
assert.equal(values.get('appDark'),true);assert.equal(backgrounds.at(-1),'#101113');
assert.equal(bars.at(-1).statusBarContentColor,'#F1F2F3');
ability.context.config.colorMode=0;const repeated=bars.length;ability.onForeground();ability.onForeground();assert.equal(bars.length,repeated,'unchanged warm entrance must not send redundant system bar IPC');
ready=false;assert.doesNotThrow(()=>ability.onForeground(),'hidden/closing windows must not crash the ability');
ability.onWindowStageDestroy();const count=backgrounds.length;
ability.onConfigurationUpdate({colorMode:1});assert.equal(values.get('appDark'),false);assert.equal(backgrounds.length,count);
console.log('PASS: appearance follows system; no window calls before content load or after destruction; abnormal native window cannot crash foreground.');

// Execute the actual policy through EntryAbility for inner, outer and triple-fold forms.
for (const [name,type,foldable,status,mode,expected] of [
 ['ordinary phone','phone',false,0,0,1], ['ordinary fold outer','phone',true,2,2,1],
 ['ordinary fold inner','phone',true,1,1,12], ['wide fold outer','phone',true,2,3,1],
 ['wide fold inner','phone',true,1,1,12], ['triple single','phone',true,2,2,1],
 ['triple double','phone',true,12,1,12], ['triple full','phone',true,11,1,12],
 ['half folded outer','phone',true,3,3,1], ['half folded inner','phone',true,3,1,12],
 ['triple half outer','phone',true,22,2,1], ['triple half inner','phone',true,23,1,12],
 ['unknown phone form','phone',true,0,0,1], ['tablet','tablet',false,0,0,12],
]) {
 kits['@kit.BasicServicesKit'].deviceInfo.deviceType=type;
 Object.assign(kits['@kit.ArkUI'].display,{isFoldable:()=>foldable,getFoldStatus:()=>status,getFoldDisplayMode:()=>mode});
 const instance=new moduleMock.exports.default();ready=true;
 instance.onWindowStageCreate({getMainWindowSync:()=>nativeWindow,loadContent:(_,cb)=>cb({code:0})});
 assert.equal(orientations.at(-1),expected,name);
 instance.onWindowStageDestroy();assert.equal(displayListeners.size,0,'fold listeners removed with window');
}
console.log('PASS rotation policy: closed/single phones portrait; expanded double/triple and tablets auto; half-fold follows active display.');

(async()=>{
 const d=kits['@kit.ArkUI'].display;let status=11,mode=1;
 kits['@kit.BasicServicesKit'].deviceInfo.deviceType='phone';
 Object.assign(d,{isFoldable:()=>true,getFoldStatus:()=>status,getFoldDisplayMode:()=>mode});
 const instance=new moduleMock.exports.default();ready=true;
 const pending=[],original=nativeWindow.setPreferredOrientation;
 nativeWindow.setPreferredOrientation=value=>{orientations.push(value);return new Promise((resolve,reject)=>pending.push({value,resolve,reject}));};
 instance.onWindowStageCreate({getMainWindowSync:()=>nativeWindow,loadContent:(_,cb)=>cb({code:0})});
 assert.equal(pending.length,1);assert.equal(pending[0].value,12);
 status=2;displayListeners.get('foldStatusChange')(status); // display is still FULL during fold event
 assert.equal(pending.length,1,'orientation IPC serialized during rapid folding');
 pending[0].resolve();await new Promise(resolve=>setImmediate(resolve));
 assert.equal(pending[1].value,1,'latest single form wins after old expanded request');
 pending[1].resolve();await new Promise(resolve=>setImmediate(resolve));mode=2;
 displayListeners.get('foldDisplayModeChange')(mode);instance.onForeground();
 assert.equal(pending.length,2,'same policy avoids duplicate IPC');
 status=12;mode=1;displayListeners.get('foldStatusChange')(status);
 assert.equal(pending[2].value,12,'double screen unlocks without restart');
 pending[2].reject(Error('temporary native failure'));await new Promise(resolve=>setImmediate(resolve));instance.onForeground();
 assert.equal(pending[3].value,12,'failed orientation retries on foreground');
 instance.onWindowStageDestroy();assert.equal(displayListeners.size,0);pending[3].resolve();await new Promise(resolve=>setImmediate(resolve));
 assert.equal(instance.appliedOrientation,null,'late destroyed-window result discarded');
 nativeWindow.setPreferredOrientation=original;
 console.log('PASS runtime fold switching, request serialization, dedup, recovery, listener cleanup and stale native completion.');
 const want=uri=>({uri,action:'ohos.want.action.viewData',parameters:{}});
 const old=ability.routeTemplate(want('file:///sender/old.fridge'));
 const recent=ability.routeTemplate(want('file:///sender/recent.fridge'));
 jobs[1].resolve('file:///cache/received_2_2.fridge');await recent;
 jobs[0].resolve('file:///cache/received_1_1.fridge');await old;
 assert.equal(values.get('incomingTemplateUri'),'file:///cache/received_2_2.fridge','late old request cannot replace the latest incoming work');
 assert.ok(removed.includes('file:///cache/received_1_1.fridge'),'obsolete asynchronous copy is cleaned');
 await ability.routeTemplate({parameters:{incomingTemplatePath:'file:///cache/received_3_3.fridge'}});
 assert.ok(removed.includes('file:///cache/received_2_2.fridge'),'unreviewed replaced copy is cleaned');
 assert.equal(values.get('incomingTemplateUri'),'file:///cache/received_3_3.fridge');
 console.log('PASS receiving lifecycle: late stale delivery cleanup, latest request retained and replaced pending copy removed');
})().catch(e=>{console.error(e);process.exitCode=1;});
