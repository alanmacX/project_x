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
const pendingRow = model.galleryRows([{id:'preview', name:'A', dimension:'', aspect:1, loaded:false, failed:false, preview:''}], '', 2)[0];
const pendingKey = model.galleryRowKey(pendingRow);
pendingRow.items[0].loaded = true; pendingRow.items[0].preview = 'file://preview.png';
assert.notEqual(model.galleryRowKey(pendingRow), pendingKey, 'settled async previews must replace ArkUI builders that captured a loading row');

const page = fs.readFileSync('entry/src/main/ets/pages/Index.ets', 'utf8');
const methods = page.slice(page.indexOf('  private async openGalleryCanvas('), page.indexOf('  @Builder\n  canvasNavigation('));
const routeMethods = page.slice(page.indexOf('  private canvasRouteChanged('), page.indexOf('  private async foregroundSchedules('));
const calls = [];
const motionTimers = new Map(); let motionTimerId = 0;
const { Fixture } = execute(`class Fixture {
 alive=true;galleryVisible=true;galleryMounted=true;galleryRevision=0;galleryController={pausePreviews(){},prepare:async()=>calls.push("prepare-gallery"),anchor:()=>null};galleryFrameResolve=null;workspaceMounted=false;galleryTransitioning=false;galleryTransitionGeneration=0;galleryTransitionTimer=-1;frameRate={};canvasChanging=false;busy=false;sharing=false;sceneNavigationBusy=false;
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
 getUIContext(){return {postFrameCallback:frame=>frame.start(),getComponentSnapshot:()=>({get:async()=>({release:async()=>{}})}),animateTo:(options,update)=>{update();options.onFinish();}};}
 ${methods}
 ${routeMethods}
}exports.Fixture=Fixture;`, { calls, rememberedGalleryPreview:()=>null,BOARD_W:344,PreparedTransition:class{constructor(start){this.start=start;}}, CANVAS_PAGE_DURATION:360, Curve:{Friction:0}, setTimeout:fn=>{motionTimers.set(++motionTimerId,fn);return motionTimerId;}, clearTimeout:id=>motionTimers.delete(id), AppStorage: { setOrCreate: (key, value) => calls.push([key, value]) } });

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
  assert.equal(f.galleryVisible, true); assert.equal(f.galleryRevision, 0);assert(calls.indexOf("save")<calls.indexOf("prepare-gallery"));
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
  const hiddenDuringLoad=new Fixture();let resolveHiddenLoad;
  hiddenDuringLoad.loadCanvas=()=>new Promise(resolve=>resolveHiddenLoad=resolve);
  const hiddenOpening=hiddenDuringLoad.openGalleryCanvas('a');hiddenDuringLoad.cancelGalleryTransition();resolveHiddenLoad();await hiddenOpening;
  assert.equal(hiddenDuringLoad.galleryVisible,true,'backgrounding invalidates a late open even when the page remains alive');
  const hiddenDuringPreview=new Fixture();hiddenDuringPreview.galleryVisible=false;let resolveHiddenPreview;
  hiddenDuringPreview.galleryController.prepare=()=>new Promise(resolve=>resolveHiddenPreview=resolve);
  const hiddenReturn=hiddenDuringPreview.showGallery();await new Promise(resolve=>setImmediate(resolve));hiddenDuringPreview.cancelGalleryTransition();resolveHiddenPreview();await hiddenReturn;
  assert.equal(hiddenDuringPreview.galleryVisible,false,'backgrounding cannot restart navigation after a slow preview refresh');
  const widget = new Fixture(); widget.launchFromWidget = true; calls.length = 0; widget.widgetLaunchChanged();
  assert.deepEqual(calls, ['widget-route'], 'warm widget launch bypasses the library too');
  const motion = new Fixture(), completions = [];
  motion.getUIContext = () => ({ postFrameCallback:frame=>frame.start(),getComponentSnapshot:()=>({get:async()=>({release:async()=>{}})}),animateTo: (options, update) => { update(); completions.push(options.onFinish); } });
  await motion.setGalleryPage(false);
  assert.equal(motion.galleryTransitioning, true); assert.equal(motion.galleryVisible, false);
  await motion.showGallery(); assert.equal(motion.galleryVisible, false, 'back cannot replace an active native transition');
  motion.cancelGalleryTransition(); await motion.setGalleryPage(true);
  completions.shift()(); assert.equal(motion.galleryTransitioning, true, 'old animation completion cannot release a newer transition');
  completions.shift()(); assert.equal(motion.galleryTransitioning, false); assert.equal(motionTimers.size, 0);
  await motion.setGalleryPage(false); motionTimers.values().next().value();
  assert.equal(motion.galleryTransitioning, false, 'deadline releases the interaction guard if native completion is omitted');
  await motion.setGalleryPage(true); motion.cancelGalleryTransition(); motion.alive = false;
  completions.forEach(finish => finish()); assert.equal(motion.galleryTransitioning, false, 'teardown remains cancelled after stale completions');
  const preparing = new Fixture(); let layoutFrame,snapshots=0;
  preparing.getUIContext=()=>({
    postFrameCallback:frame=>{layoutFrame=frame;},
    getComponentSnapshot:()=>{snapshots++;throw Error('GPU readback must not gate navigation');},
    animateTo:(options,update)=>{update();options.onFinish();}
  });
  const reveal=preparing.setGalleryPage(false);
  assert.equal(preparing.workspaceMounted,true);assert.equal(preparing.galleryVisible,true,'outgoing gallery covers destination construction');
  layoutFrame.start();await new Promise(resolve=>setImmediate(resolve));assert.equal(preparing.galleryVisible,true,'first frame measures the destination');
  layoutFrame.start();await reveal;assert.equal(preparing.galleryVisible,false);assert.equal(snapshots,0,'decoded artwork handoff does not block on a GPU snapshot');
  const cancelled = new Fixture();let staleFrame;
  cancelled.getUIContext=()=>({postFrameCallback:frame=>staleFrame=frame});
  const abandoned=cancelled.setGalleryPage(false);cancelled.cancelGalleryTransition();await abandoned;
  staleFrame.start();assert.equal(cancelled.galleryVisible,true,'background cancellation cannot reveal an unprepared workspace');
  const shared = new Fixture();const sharedCompletions=[];
  Object.assign(shared,{screenWidth:390,screenHeight:800,galleryAnchorWidth:390,galleryAnchorHeight:800,safeTop:36,safeBottom:24,boardLeft:23,boardTop:160,boardScale:1,boardHeight:344,
    galleryAnchor:{id:'a',preview:'file://canvas.png',x:16,y:120,w:344,h:344}});
  shared.getUIContext=()=>({postFrameCallback:frame=>frame.start(),getComponentSnapshot:()=>({get:async()=>({release:async()=>{}})}),animateTo:(options,update)=>{update();sharedCompletions.push(options.onFinish);}});
  await shared.setGalleryPage(false);
  assert.equal(shared.galleryHeroSource,'file://canvas.png');assert.equal(shared.galleryHeroX,23);assert.equal(shared.galleryHeroY,160,'shared preview lands on the measured board');
  sharedCompletions.shift()();assert.equal(shared.galleryArtworkOpacity,1,'decoded live surface is restored under the landing image');assert.equal(shared.galleryHeroSource,'file://canvas.png');
  sharedCompletions.shift()();assert.equal(shared.galleryHeroSource,'','dissolve completion releases the landing image');
  await shared.setGalleryPage(true);assert.equal(shared.galleryHeroX,16);assert.equal(shared.galleryHeroY,120,'return lands on the retained thumbnail');
  sharedCompletions.shift()();shared.screenWidth=600;await shared.setGalleryPage(false);
  assert.equal(shared.galleryHeroSource,'','resized windows cannot reuse stale thumbnail coordinates');sharedCompletions.shift()();
  const gallery = fs.readFileSync('entry/src/main/ets/views/CanvasGallery.ets', 'utf8');
  const loading = gallery.slice(gallery.indexOf('  private async loadItems('), gallery.indexOf('  private requestPreview('));
  const { Loader } = execute(`class Loader {
    alive=true;generation=0;items=[];entries=[{id:'a',name:'A'}];documents=new Map();visibleIds=new Set();
    getUIContext(){return {getHostContext:()=>undefined};}previewSource(state){return JSON.stringify(state);}requestPreview(){}onLoad=async()=>({cards:[],canvasDimension:'4*4',canvasAspect:1});
    ${loading}
  }exports.Loader=Loader;`, { GalleryItem: model.GalleryItem,rememberedGalleryPreview:()=>null,cachedGalleryPreview:async()=>null, storageSnapshot: JSON.stringify, fileIo: { unlink: async () => {} } });
  let completeOld;
  const loader = new Loader(); loader.onLoad = async () => new Promise(resolve => completeOld = resolve);
  const old = loader.loadItems();await new Promise(resolve=>setImmediate(resolve));
  loader.entries = [{ id: 'b', name: 'B' }]; loader.onLoad = async () => ({ cards: [], canvasDimension: '2*4', canvasAspect: 2 });
  await loader.loadItems(); completeOld({ cards: [], canvasDimension: '4*4', canvasAspect: 1 }); await old;
  assert.deepEqual(Array.from(loader.items.map(item => item.id)), ['b'], 'stale preview metadata cannot restore removed/replaced canvases');
  assert.equal(loader.items[0].aspect, 2); assert.equal(loader.documents.has('a'), false);
  const damaged = new Loader(); damaged.entries = [{ id: 'broken', name: 'Broken' }, { id: 'healthy', name: 'Healthy' }];
  damaged.onLoad = async id => { if (id === 'broken') throw Error('bad data'); return { cards: [], canvasDimension: '4*4', canvasAspect: 1 }; };
  await damaged.loadItems(); assert.equal(damaged.items[0].failed, true); assert.equal(damaged.items[1].loaded, true, 'one damaged preview cannot block the remaining library');
  const retained=new Loader();retained.items=[{id:'a',name:'A',dimension:'2*2',aspect:1,preview:'file://last-good.png',previewSource:'old',loaded:true}];
  let metadataReady;retained.onLoad=()=>new Promise(resolve=>metadataReady=resolve);
  const refreshing=retained.loadItems();await new Promise(resolve=>setImmediate(resolve));
  assert.equal(retained.items[0].preview,'file://last-good.png','reading new document bytes must not clear visible artwork');
  metadataReady({cards:[],canvasDimension:'2*2',canvasAspect:1});await refreshing;
  assert.equal(retained.items[0].preview,'file://last-good.png','stale image remains until a replacement is committed');
  retained.onLoad=async()=>{throw Error('temporarily unreadable');};await retained.loadItems();
  assert.equal(retained.items[0].preview,'file://last-good.png','read failure keeps last good preview');
  console.log('PASS gallery: mixed-size responsive rows, filters, serialized opening, save-before-return, load/save recovery, nested/scene back, teardown and warm widget route');
})().catch(error => { console.error(error); process.exitCode = 1; });

const sizes=execute(fs.readFileSync('entry/src/main/ets/model/CanvasSize.ets','utf8'));
const galleryView=fs.readFileSync('entry/src/main/ets/views/CanvasGallery.ets','utf8');
const creationMethods=galleryView.slice(galleryView.indexOf('  private startCreating('),galleryView.indexOf('  private splitWidth('));
const creationCalls=[];
const CreationFixture=execute('export class CreationFixture { '+creationMethods+' }',{CREATION_DIMENSIONS:sizes.CREATION_DIMENSIONS,curves:{springMotion:()=>0}}).CreationFixture;
for(const dimension of sizes.CREATION_DIMENSIONS){
 const f=new CreationFixture();Object.assign(f,{busy:false,filter:'4*4',splitOpen:true,sizeMenuOpen:true,onCreate:(...args)=>creationCalls.push(args),getUIContext:()=>({animateTo:(_,change)=>change()})});
 f.startCreating(dimension);assert.equal(f.draftDimension,dimension,'explicit size wins over active browsing filter');assert.equal(f.creating,true);assert.equal(f.splitOpen,false);assert.equal(f.sizeMenuOpen,false);
 f.createNamedCanvas();assert.equal(creationCalls.length,0,'empty names cannot create a canvas');
 f.draftName='  小画布  ';f.createNamedCanvas();assert.deepEqual(creationCalls.pop(),['小画布',dimension]);
 f.busy=true;f.startCreating('2*2');assert.equal(f.draftDimension,dimension,'pending save cannot replace creation intent');f.createNamedCanvas();assert.equal(creationCalls.length,0);
}
const invalid=new CreationFixture();invalid.startCreating('unsupported');assert.equal(invalid.creating,undefined);
assert.match(galleryView,/borderRadius\(widgetFrameMetrics\(this.tileWidth\(item\),this.previewHeight\(item,wide\)\).radius\)\.clip\(true\)/,'native pressed overlay follows the same measured frame mask');
assert(!galleryView.includes('this.scroller.scrollEdge(Edge.Top)'),'creation does not jump the gallery scroll position');
assert.match(page,/this.canvasChanging\|\|this.galleryTransitioning\|\|this.scheduleTransition/,'async derived surfaces must wait for the landing dissolve');
assert.match(fs.readFileSync('entry/src/main/ets/views/BoardCard.ets','utf8'),/CardFace\(\{ snapshot:true/,'local artwork is decoded before the gallery uncovers the board');

for(const available of [288,358,700]){
 const small=model.galleryPreviewSize('2*2',1,available,{}),large=model.galleryPreviewSize('4*4',1,available,{}),strip=model.galleryPreviewSize('2*4',2,available,{});
 assert(large[0]>small[0]*1.9,'large and small squares cannot have identical preview sizes');assert.equal(strip[0],large[0]);assert.equal(strip[1],strip[0]/2);
}
const measured=model.galleryPreviewSize('2*2',1,600,{'2*2':[190,170]});assert.equal(measured[0],190);assert.equal(measured[1],170,'native vp rectangle wins over nominal square ratio');

const visibilityStart=galleryView.indexOf('  private pageVisibilityChanged():');
const visibilityEnd=galleryView.indexOf('  private previewTimeChanged():',visibilityStart);
const VisibilityFixture=execute('export class VisibilityFixture { '+galleryView.slice(visibilityStart,visibilityEnd)+' }').VisibilityFixture;
const retainedForm=new VisibilityFixture();Object.assign(retainedForm,{pageVisible:false,creating:true,renameId:'a',toolsOpen:true,filter:'2*2'});
retainedForm.pageVisibilityChanged();assert.equal(retainedForm.creating,false);assert.equal(retainedForm.renameId,'');assert.equal(retainedForm.toolsOpen,false);assert.equal(retainedForm.filter,'2*2','transient form reset must retain gallery browsing intent');
