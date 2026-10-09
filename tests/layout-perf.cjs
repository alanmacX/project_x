// Executes the real model/service sources with only the Harmony platform APIs mocked.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const ts = require(process.env.FRIDGE_TYPESCRIPT || '/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript');
const root = path.resolve(__dirname, '../entry/src/main/ets/model');
const disk = new Map();
const writes = [], updates = [], closed = [], opened = [];
let failWrite = false, failForm = false;
const prefs = {
  get: async (key, fallback) => disk.has(key) ? disk.get(key) : fallback,
  put: async (key, value) => {
    if (failWrite) { failWrite = false; throw Error('disk failure'); }
    await new Promise(resolve => setTimeout(resolve, 2));
    disk.set(key, value); writes.push([key, value]);
  },
  flush: async () => {},
};
const kits = {
  '@ohos.data.preferences': { default: { getPreferences: async () => prefs, removePreferencesFromCache: async () => {} } },
  '@kit.FormKit': {
    formBindingData: { createFormBindingData: data => data },
    formProvider: { updateForm: async (id, data) => {
      if (failForm) { failForm = false; throw Error('removed form'); }
      updates.push({id, data});
    } },
  },
  '@kit.CoreFileKit': { fileIo: {
    OpenMode: { READ_ONLY: 0 },
    open: async name => { opened.push(name); if (name.includes('missing')) throw Error('missing photo'); return {fd: 11}; },
    closeSync: fd => closed.push(fd),
  } },
  '@kit.PerformanceAnalysisKit': { hilog: {warn: () => {}, error: () => {}} },
};
const jobs = [];
kits['@kit.ArkTS'] = { taskpool: { Task: class { constructor(fn,...args){this.fn=fn;this.args=args;} setTransferList(list){this.transfer=list;} }, execute: async task => { jobs.push(task.fn.name); await new Promise(resolve=>setImmediate(resolve)); return task.fn(...task.args); } } };
kits['@kit.ArkGraphics2D']={drawing:{}};
kits['@kit.ImageKit']={image:{}};
const cache = new Map();
function load(name) {
  const file = path.resolve(root, name + '.ets');
  if (cache.has(file)) return cache.get(file).exports;
  const module = {exports: {}}; cache.set(file, module);
  const code = ts.transpileModule(fs.readFileSync(file, 'utf8').replace(/^@Concurrent\s*$/gm, '').replace(/import lazy /g,'import '), {
    compilerOptions: {module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2020},
  }).outputText;
  const requireMock = spec => kits[spec] || load(path.relative(root, path.resolve(path.dirname(file), spec)));
  vm.runInThisContext('(function(require,module,exports){' + code + '\n})', {filename:file})(requireMock, module, module.exports);
  return module.exports;
}

const {FridgeCard}=load('CardSchema');
const {safeContentBox,subjectInterior,subjectSurfaceFactor}=load('CanvasLayout');
const card=new FridgeCard();card.shape='subject';card.subjectBorder=true;card.capability={k:'weather'};
card.outline=[Array.from({length:512},(_,i)=>{const a=i*2*Math.PI/512;return {x:.5+.46*Math.cos(a),y:.5+.46*Math.sin(a)};})];
const baseW=300,baseH=360,count=100;
function run(fn){const start=performance.now();for(let i=0;i<count;i++){const f=1-i*.004;card.w=baseW*f;card.h=baseH*f;fn(card);}return performance.now()-start;}
// v8 rescanned the interior whenever the 6vp border factor changed during resizing.
const before=run(c=>{const b=subjectInterior(c.outline,72*c.h/(56*c.w));const f=subjectSurfaceFactor(c);b.w*=f;b.h*=f;return b;});
const after=run(safeContentBox);
console.log(JSON.stringify({scenario:'100 proportional subject resizes, 512 contour points, white edge, weather',beforeMs:before,afterMs:after,speedup:before/after},null,2));

// Compare the previous cache-key path with the current production source.
const legacySource = fs.readFileSync(path.join(root,'CanvasLayout.ets'),'utf8')
  .replaceAll('outlineIdentity(card)', 'JSON.stringify(card.outline)');
const legacyModule = {exports:{}};
const legacyCode = ts.transpileModule(legacySource,{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText;
vm.runInThisContext('(function(require,module,exports){'+legacyCode+'\n})')(
  spec=>load(path.relative(root,path.resolve(root,spec))),legacyModule,legacyModule.exports);
const currentLayout=load('CanvasLayout');
card.w=300;card.h=360;
legacyModule.exports.safeContentBox(card); currentLayout.safeContentBox(card);
const keyIterations=2000;
function keyRun(layout) { const start=performance.now(); for(let i=0;i<keyIterations;i++) { layout.safeContentBox(card); layout.capabilityBox(card); } return performance.now()-start; }
const oldKeyMs=keyRun(legacyModule.exports), newKeyMs=keyRun(currentLayout);
assert.deepEqual(JSON.parse(JSON.stringify(currentLayout.capabilityBox(card))),JSON.parse(JSON.stringify(legacyModule.exports.capabilityBox(card))));
console.log(JSON.stringify({scenario:'2000 warm-cache safe/obstacle layout lookups, 512 contour points; cache-key CPU work only',beforeMs:oldKeyMs,afterMs:newKeyMs,speedup:oldKeyMs/newKeyMs},null,2));
