const fs=require('node:fs'),vm=require('node:vm'),assert=require('node:assert/strict');
const ts=require('/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript');
const source=fs.readFileSync('entry/src/main/ets/pages/Index.ets','utf8');
function method(a,b){return source.slice(source.indexOf(a),source.indexOf(b,source.indexOf(a)));}
const timers=new Map();let timer=0;const routes=[];
const env={exports:{},storageSnapshot:JSON.stringify,primeRenderContours:async()=>{},prepareSceneImages:async()=>{},setTimeout:fn=>{timers.set(++timer,fn);return timer;},clearTimeout:id=>timers.delete(id),AppStorage:{setOrCreate:(key,value)=>routes.push([key,value])}};
const fixture=`export class Fixture {
 context={};alive=true;ready=true;widgetRouteTimer=-1;widgetRouteRunning=false;widgetRoutePending=false;widgetRouteRequest=0;
 galleryVisible=true;workspaceMounted=false;galleryArtworkOpacity=0;canvasChanging=false;galleryTransitioning=false;heroActive=false;activeBoardId='';routedId='';viewRouteId='';routeCanvasId='a';
 galleryController={pausePreviews(){}};foregrounds=0;renders=[];loads=[];saves=0;editorMountGeneration=0;editing=false;
 store={state:{canvasId:'a',cards:[],background:{}},catalog:{scenes:[],activeId:'a'},switchCanvas:id=>{this.store.state={canvasId:id,cards:[],background:{}};return true;},init(){throw Error('warm route must not initialize storage');},openCanvas:async id=>{this.loads.push(id);this.store.state={canvasId:id,cards:[],background:{}};return true;},findCard:()=>null,save:async()=>{this.saves++;}};
 cancelGalleryTransition(){this.galleryArtworkOpacity=this.galleryVisible?0:1;this.galleryTransitioning=false;}
 cancelGalleryWarm(){}cancelForegroundRefresh(){}flushPendingEdits(){}cancelScheduledTransition(){}syncSchedules(){}refreshCanvasList(){}syncHostCanvasGeometry(){}layoutBoard(){}scheduleBackground(){}routeChanged(){}select(){}
 retainCanvasImages(){}scheduleForegroundRefresh(){this.foregrounds++;}render(){this.renders.push(this.store.state.canvasId);}
 ${method('  private scheduleWidgetRoute():','  private retainCanvasImages(')}
}`;
vm.runInNewContext(ts.transpileModule(fixture,{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,env);
async function flushTimers(){for(let i=0;timers.size&&i<10;i++){const tasks=[...timers.values()];timers.clear();tasks.forEach(fn=>fn());await new Promise(setImmediate);}}
(async()=>{
 const f=new env.exports.Fixture();f.editing=true;await f.reloadWidgetRoute();
 assert.equal(f.galleryVisible,false);assert.equal(f.workspaceMounted,true);assert.equal(f.galleryArtworkOpacity,1,'gallery opacity must be restored on widget entrance');assert.equal(f.editing,true,'same-canvas route preserves an existing edit');assert.equal(f.loads.length,0);assert.equal(f.saves,0);
 const cross=new env.exports.Fixture();cross.routeCanvasId='b';await cross.reloadWidgetRoute();
 assert.deepEqual(Array.from(cross.loads),['b']);assert.equal(cross.galleryArtworkOpacity,1);assert.equal(cross.saves,1);assert.equal(cross.canvasChanging,false);
 const racing=new env.exports.Fixture(),pending=[];let inFlight=0,maxInFlight=0;
 racing.store.openCanvas=id=>new Promise(resolve=>{inFlight++;maxInFlight=Math.max(maxInFlight,inFlight);pending.push(()=>{inFlight--;racing.store.state={canvasId:id,cards:[],background:{}};resolve(true);});});
 racing.routeCanvasId='b';const first=racing.reloadWidgetRoute();await new Promise(setImmediate);
 racing.routeCanvasId='c';racing.scheduleWidgetRoute();await flushTimers();assert.equal(pending.length,1,'second route cannot overlap the first read');
 pending.shift()();await first;assert.equal(racing.store.state.canvasId,'a','discarded read restores the visible document before processing the next route');await flushTimers();assert.equal(pending.length,1);assert.deepEqual(Array.from(racing.renders),[],'obsolete target never replaces visible artwork');
 pending.shift()();await new Promise(setImmediate);await flushTimers();assert.equal(maxInFlight,1);assert.deepEqual(Array.from(racing.renders),['c']);assert.equal(racing.store.state.canvasId,'c');assert.equal(racing.galleryArtworkOpacity,1);
 const rejected=new env.exports.Fixture();let finishOld;rejected.routeCanvasId='b';rejected.store.openCanvas=id=>id==='b'?new Promise(resolve=>finishOld=()=>{rejected.store.state={canvasId:'b',cards:[],background:{}};resolve(true);}):Promise.resolve(false);
 const obsolete=rejected.reloadWidgetRoute();await new Promise(setImmediate);rejected.routeCanvasId='deleted';rejected.scheduleWidgetRoute();await flushTimers();finishOld();await obsolete;await flushTimers();
 assert.equal(rejected.store.state.canvasId,'a','a newer failed route cannot leave the previous hidden target selected');assert.equal(rejected.galleryVisible,true);assert.deepEqual(Array.from(rejected.renders),[]);
 const missing=new env.exports.Fixture();missing.routeCanvasId='deleted';missing.store.openCanvas=async()=>false;await missing.reloadWidgetRoute();assert.equal(missing.galleryVisible,true,'failed navigation retains the complete previous page');assert.equal(missing.canvasChanging,false);assert.equal(missing.saves,0);
 console.log('PASS widget routes: gallery opacity restoration, same-canvas reuse, target-only reads, serialized latest-wins navigation and failure recovery.');
})().catch(e=>{console.error(e);process.exitCode=1;});
