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

const {FridgeCard,CanvasElement}=load('CardSchema');
const {cardViewSnapshot}=load('CardViewSnapshot');
const cards=Array.from({length:8},(_,n)=>{const c=new FridgeCard();c.id='p'+n;c.shape='subject';c.outline=[Array.from({length:1024},(_,i)=>({x:(Math.sin(i)+1)/2,y:(Math.cos(i)+1)/2}))];const e=new CanvasElement();e.text='draft';c.elements=[e];return c;});
let board=cards.map(c=>JSON.parse(JSON.stringify(c)));
let start=performance.now();for(let i=0;i<100;i++){cards[0].elements[0].text='value '+i;board=cards.map((c,n)=>JSON.stringify(board[n])===JSON.stringify(c)?board[n]:JSON.parse(JSON.stringify(c)));const preview=JSON.parse(JSON.stringify(cards[0]));}
const beforeMs=performance.now()-start;
start=performance.now();for(let i=0;i<100;i++){cards[0].elements[0].text='value '+i;const preview=cardViewSnapshot(cards[0]);}
const afterMs=performance.now()-start;
console.log(JSON.stringify({scenario:'100 editor changes, 8 cards with 1024-point contours; snapshot work only',beforeMs,afterMs,speedup:beforeMs/afterMs},null,2));
