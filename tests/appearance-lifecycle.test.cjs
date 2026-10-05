// Execute the ability lifecycle against a window that rejects updates before load.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const ts = require(process.env.FRIDGE_TYPESCRIPT || '/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript');
const values = new Map(), backgrounds = [], bars = [];
let ready = false, callback;
class UIAbility { context = {config: {colorMode: 1}}; }
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
 '../model/IncomingTemplate':{incomingTemplateUri:()=>'',stageIncomingTemplate:async()=>''},
 '@kit.ArkTS':{},
 '@kit.AbilityKit': {UIAbility, ConfigurationConstant:{ColorMode:{COLOR_MODE_DARK:0,COLOR_MODE_LIGHT:1}}},
 '@kit.ArkUI': {window:{Orientation:{AUTO_ROTATION_UNSPECIFIED:0},AvoidAreaType:{TYPE_SYSTEM:0,TYPE_NAVIGATION_INDICATOR:1}}},
 '@kit.PerformanceAnalysisKit': {hilog:{info(){},warn(){},error(){}}},
};
vm.runInNewContext(code, {require:s=>kits[s],exports:moduleMock.exports, AppStorage:{setOrCreate:(k,v)=>values.set(k,v)}});
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
