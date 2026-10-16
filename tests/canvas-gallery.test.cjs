const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const ts = require(process.env.FRIDGE_TYPESCRIPT || '/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript');
function execute(source, globals = {}) {
  const context = { exports: {}, ...globals };
  vm.runInNewContext(ts.transpileModule(source, { compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2020 } }).outputText, context);
  return context.exports;
}
const model = execute(fs.readFileSync('entry/src/main/ets/model/CanvasGallery.ets', 'utf8'));
const entries = [
  { id: 'square', dimension: '4*4', aspect: 1 },
  { id: 'small', dimension: '2*2', aspect: 1 },
  { id: 'strip', dimension: '2*4', aspect: 2 },
  { id: 'portrait', dimension: '4*4', aspect: .8 },
  { id: 'second-strip', dimension: '2*4', aspect: 2.1 }
];
for (const width of [320, 360, 390, 600, 720, 960, 1100, 1440]) {
  const columns = model.galleryColumns(width), rows = model.galleryRows(entries, '', columns);
  assert.deepEqual(Array.from(rows.flatMap(row => row.items).map(item => item.id)), entries.map(item => item.id), 'mixed sizes keep catalog order without duplicates');
  assert(rows.every(row => row.wide ? row.items.length === 1 : row.items.length <= columns));
  assert.deepEqual(Array.from(model.galleryRows(entries, '2*4', columns).flatMap(row => row.items).map(item => item.id)), ['strip', 'second-strip']);
  assert.equal(model.galleryRows(entries, 'unknown', columns).length, 0);
}
assert.equal(model.galleryColumns(320), 1, 'short narrow windows retain usable previews');
assert.equal(model.galleryRows([], '', 2).length, 0);

const page = fs.readFileSync('entry/src/main/ets/pages/Index.ets', 'utf8');
const methods = page.slice(page.indexOf('  private async openGalleryCanvas('), page.indexOf('  @Builder\n  canvasNavigation('));
const routeMethods = page.slice(page.indexOf('  private canvasRouteChanged('), page.indexOf('  private async foregroundSchedules('));
const calls = [];
const { Fixture } = execute(`class Fixture {
 alive=true;galleryVisible=true;galleryRevision=0;canvasChanging=false;busy=false;sharing=false;sceneNavigationBusy=false;
 heroActive=false;editing=false;viewing=false;deletionId='';activeBoardId='';sceneEditing=false;selectedId='';
 homeToolsOpen=true;scheduleOpen=true;backgroundOpen=true;groupSelecting=true;groupSelection=['card'];scheduleTimer=-1;scenePanelGeneration=0;
 boardOpacity=0;scatter=1;startupCardCount=4;ready=true;launchFromWidget=false;routeCanvasId='';
 store={save:async()=>calls.push('save'),state:{canvasId:'a'}};
 loadCanvas=async id=>calls.push('load:'+id);
 armScheduleTimer(){}updateScheduledScene(){}cancelScheduledTransition(){calls.push('cancel-scene');}
 flushPendingEdits(){calls.push('flush');}refreshCanvasList(){calls.push('list');}
 templateError(prefix,error){calls.push('error:'+prefix);}
 leaveTimedScene=async()=>calls.push('leave-scene');
 scheduleWidgetRoute(){calls.push('widget-route');}
 ${methods}
 ${routeMethods}
}exports.Fixture=Fixture;`, { calls, clearTimeout() {}, AppStorage: { setOrCreate: (key, value) => calls.push([key, value]) } });

(async () => {
  const f = new Fixture();
  let release; f.loadCanvas = async () => { await new Promise(resolve => release = resolve); };
  const opening = f.openGalleryCanvas('a');
  assert.equal(f.canvasChanging, true); assert.equal(f.galleryVisible, true, 'library stays visible while document loads');
  await f.openGalleryCanvas('b'); // rapid second tap must not replace pending intent
  release(); await opening;
  assert.equal(f.galleryVisible, false); assert.equal(f.canvasChanging, false);
  assert.equal(f.boardOpacity, 1); assert.equal(f.startupCardCount, -1, 'editor does not inherit partial cold-start surfaces');
  calls.length = 0;
  await f.showGallery();
  assert.equal(f.galleryVisible, true); assert.equal(f.galleryRevision, 1);
  assert(calls.indexOf('flush') < calls.indexOf('save')); assert(calls.indexOf('save') < calls.indexOf('list'), 'save completes before thumbnails are read');
  assert(calls.some(value => Array.isArray(value) && value[0] === 'launchFromWidget' && value[1] === false));
  assert.equal(f.homeToolsOpen, false); assert.equal(f.backgroundOpen, false);

  const failed = new Fixture(); failed.loadCanvas = async () => { throw Error('corrupt'); };
  await failed.openGalleryCanvas('broken'); assert.equal(failed.galleryVisible, true); assert.equal(failed.canvasChanging, false, 'failed load retains navigable library');
  const saveFailed = new Fixture(); saveFailed.galleryVisible = false; saveFailed.store.save = async () => { throw Error('disk full'); };
  await saveFailed.showGallery(); assert.equal(saveFailed.galleryVisible, false); assert.equal(saveFailed.canvasChanging, false, 'save failure leaves artwork open for recovery');

  const editing = new Fixture(); editing.galleryVisible = false; editing.editing = true;
  const revision = editing.galleryRevision; await editing.showGallery(); assert.equal(editing.galleryRevision, revision, 'nested card editor must finish first');
  const scene = new Fixture(); scene.galleryVisible = false; scene.sceneEditing = true;
  calls.length = 0; await scene.showGallery(); assert.deepEqual(calls, ['leave-scene'], 'scene back returns through its existing completion path');

  const stopped = new Fixture(); let finish; stopped.loadCanvas = async () => { await new Promise(resolve => finish = resolve); };
  const stale = stopped.openGalleryCanvas('a'); stopped.alive = false; finish(); await stale;
  assert.equal(stopped.galleryVisible, true, 'late load cannot open a destroyed page');
  const widget = new Fixture(); widget.launchFromWidget = true; calls.length = 0; widget.widgetLaunchChanged();
  assert.deepEqual(calls, ['widget-route'], 'warm widget launch bypasses the library too');
  const gallery = fs.readFileSync('entry/src/main/ets/views/CanvasGallery.ets', 'utf8');
  const loading = gallery.slice(gallery.indexOf('  private async loadItems('), gallery.indexOf('  private requestPreview('));
  const { Loader } = execute(`class Loader {
    alive=true;generation=0;items=[];entries=[{id:'a',name:'A'}];documents=new Map();visibleIds=new Set();
    requestPreview(){}onLoad=async()=>({cards:[],canvasDimension:'4*4',canvasAspect:1});
    ${loading}
  }exports.Loader=Loader;`, { GalleryItem: model.GalleryItem, thumbnails: new Map(), storageSnapshot: JSON.stringify, fileIo: { unlink: async () => {} } });
  let completeOld;
  const loader = new Loader(); loader.onLoad = async () => new Promise(resolve => completeOld = resolve);
  const old = loader.loadItems();
  loader.entries = [{ id: 'b', name: 'B' }]; loader.onLoad = async () => ({ cards: [], canvasDimension: '2*4', canvasAspect: 2 });
  await loader.loadItems(); completeOld({ cards: [], canvasDimension: '4*4', canvasAspect: 1 }); await old;
  assert.deepEqual(Array.from(loader.items.map(item => item.id)), ['b'], 'stale preview metadata cannot restore removed/replaced canvases');
  assert.equal(loader.items[0].aspect, 2); assert.equal(loader.documents.has('a'), false);
  const damaged = new Loader(); damaged.entries = [{ id: 'broken', name: 'Broken' }, { id: 'healthy', name: 'Healthy' }];
  damaged.onLoad = async id => { if (id === 'broken') throw Error('bad data'); return { cards: [], canvasDimension: '4*4', canvasAspect: 1 }; };
  await damaged.loadItems(); assert.equal(damaged.items[0].failed, true); assert.equal(damaged.items[1].loaded, true, 'one damaged preview cannot block the remaining library');
  console.log('PASS gallery: mixed-size responsive rows, filters, serialized opening, save-before-return, load/save recovery, nested/scene back, teardown and warm widget route');
})().catch(error => { console.error(error); process.exitCode = 1; });
