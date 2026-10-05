// Execute the ability lifecycle against a window that rejects updates before load.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const ts = require(process.env.FRIDGE_TYPESCRIPT || '/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript');
const values = new Map(), backgrounds = [], bars = [];
let ready = false, callback;
const removed=[],jobs=[];
class UIAbility { context = {config: {colorMode: 1},cacheDir:'/cache'}; }
const nativeWindow = {
  setWindowBackgroundColor(color) { if (!ready) throw Error('window state abnormal'); backgrounds.push(color); },
  setWindowSystemBarProperties(props) { bars.push(props); return Promise.resolve(); },
  setPreferredOrientation() { return Promise.resolve(); }, setImmersiveModeEnabledState() {},
  getUIContext() { return {px2vp: x => x}; }, getWindowAvoidArea() { return {topRect: {height: 32}, bottomRect: {height: 24}}; }, on() {},
};
const moduleMock = {exports:{}};
const source = fs.readFileSync('entry/src/main/ets/entryability/EntryAbility.ets','utf8');
const code = ts.transpileModule(source, {compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText;
const kits = {
 '../model/StartupTrace':{startStartupTrace(){},startupMark(){}},
 '../model/IncomingTemplate':{incomingTemplateUri:u=>u?.startsWith('file://')?u:'',stageIncomingTemplate:async()=>'',removeStagedTemplate:(u)=>{if(u)removed.push(u);}},
 '@kit.ArkTS':{taskpool:{Task:class{constructor(fn,...args){this.fn=fn;this.args=args;}},execute:task=>new Promise(resolve=>jobs.push({task,resolve}))}},
 '@kit.AbilityKit': {UIAbility, ConfigurationConstant:{ColorMode:{COLOR_MODE_DARK:0,COLOR_MODE_LIGHT:1}}},
 '@kit.ArkUI': {window:{Orientation:{AUTO_ROTATION_UNSPECIFIED:0},AvoidAreaType:{TYPE_SYSTEM:0,TYPE_NAVIGATION_INDICATOR:1}}},
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
ready=false;assert.doesNotThrow(()=>ability.onForeground(),'hidden/closing windows must not crash the ability');
ability.onWindowStageDestroy();const count=backgrounds.length;
ability.onConfigurationUpdate({colorMode:1});assert.equal(values.get('appDark'),false);assert.equal(backgrounds.length,count);
console.log('PASS: appearance follows system; no window calls before content load or after destruction; abnormal native window cannot crash foreground.');

(async()=>{
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
