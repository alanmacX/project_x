const fs=require('node:fs'),vm=require('node:vm'),assert=require('node:assert/strict');
const ts=require('/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript');
const view=fs.readFileSync('entry/src/main/ets/views/CanvasGallery.ets','utf8');
const page=fs.readFileSync('entry/src/main/ets/pages/Index.ets','utf8');
function between(text,a,b){return text.slice(text.indexOf(a),text.indexOf(b,text.indexOf(a)));}
function execute(source,globals={}){const env={exports:{},...globals};vm.runInNewContext(ts.transpileModule(source,{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,env);return env.exports;}
let primeGate=null,packGate=null,snapshotCount=0;const committed=[],deleted=[];
const {Fixture}=execute(`export class Fixture {
 alive=true;pageVisible=true;busy=false;previewsPaused=false;generation=0;pendingIds=new Set();previewQueue=Promise.resolve();previewFileSequence=0;warmAllowed=false;warmingIds=new Set();warmRequests=new Map();widgetRects={};documentRequests=new Map();previewTick=0;
 items=[{id:'a',name:'A',loaded:true,dimension:'4*4',aspect:1,preview:'old.png',previewSource:'previous'}];documents=new Map([['a',{signature:'old',cards:[],canvasDimension:'4*4',canvasAspect:1}]]);visibleIds=new Set(['a']);
 previewSource(state){return state.signature;}artwork(){}loadItems(){}onLoad=async()=>this.documents.get('a');
 getUIContext(){return {getHostContext:()=>({cacheDir:'/cache'}),getComponentSnapshot:()=>({createFromBuilder:async()=>{snapshotCount();return {release:async()=>{}};}})};}
 ${between(view,'  private async warmPreview(', '  private previewWorkAllowed(')}
 ${between(view,'  private previewWorkAllowed(', '  private reload(')}
 ${between(view,'  private async prepareReturn(', '  private async loadItems(')}
 ${between(view,'  private requestPreview(', '  private previewUnavailable(')}
}`,{
 GalleryItem:class{},GalleryThumbnail:class{},GALLERY_MEASUREMENT_DELAY_MS:300,storageSnapshot:JSON.stringify,
 primeRenderContours:async()=>{if(primeGate){const gate=primeGate;primeGate=null;await gate;}},snapshotCount:()=>snapshotCount++,
 image:{createImagePacker:()=>({packToFile:async()=>{if(packGate){const gate=packGate;packGate=null;await gate;}},release:async()=>{}})},
 fileIo:{OpenMode:{CREATE:1,READ_WRITE:2},open:async()=>({fd:1}),closeSync(){},unlink:async path=>deleted.push(path)},
 saveGalleryPreview:async(dir,id,item)=>committed.push(item),Date:class extends Date{static now(){return 123456;}},
});
async function drain(f){let previous;do{previous=f.previewQueue;await previous;}while(f.previewQueue!==previous);}
const nextState=signature=>({signature,cards:[],canvasDimension:'4*4',canvasAspect:1});
(async()=>{
 const f=new Fixture();let release;primeGate=new Promise(r=>release=r);f.requestPreview('a');await new Promise(r=>setImmediate(r));
 f.documents.set('a',nextState('new'));release();await drain(f);
 assert.equal(snapshotCount,1,'obsolete contour preparation skips capture and retries latest document');assert.deepEqual(committed.map(x=>x.source),['new']);assert.equal(f.items[0].previewSource,'new');
 committed.length=0;deleted.length=0;const packing=new Fixture();packGate=new Promise(r=>release=r);packing.requestPreview('a');await new Promise(r=>setImmediate(r));
 packing.documents.set('a',nextState('newer'));release();await drain(packing);
 assert.deepEqual(committed.map(x=>x.source),['newer'],'old encoded pixels never replace the new preview');assert.equal(deleted.length,1);assert.notEqual(deleted[0],committed[0].path.slice(7),'captures in one clock tick cannot share a file name');
 committed.length=0;const warm=new Fixture();warm.pageVisible=false;warm.previewsPaused=true;
 await warm.requestPreview('a',true);assert.equal(committed.length,0,'ordinary force cannot bypass hidden-gallery suspension');
 warm.warmAllowed=true;await warm.warmPreview('a');assert.equal(warm.items[0].previewSource,'old','idle workspace can prepare its next homepage image before returning');assert.equal(warm.warmingIds.size,0);
 committed.length=0;const gesture=new Fixture();gesture.pageVisible=false;gesture.warmAllowed=true;primeGate=new Promise(r=>release=r);const warming=gesture.warmPreview('a');await new Promise(r=>setImmediate(r));gesture.warmAllowed=false;release();await warming;
 assert.equal(committed.length,0,'a new gesture/navigation cancels pending warm publication');assert.equal(gesture.warmingIds.size,0);
 const metadata=new Fixture(),oldRows=metadata.items;const resolvers=[];metadata.onLoad=()=>new Promise(r=>resolvers.push(r));
 const old=metadata.prepareReturn('a'),fresh=metadata.prepareReturn('a');resolvers[1](nextState('latest'));await fresh;resolvers[0](nextState('late-old'));await old;
 assert.equal(metadata.documents.get('a').signature,'latest','late metadata read cannot overwrite a more recent document');assert.equal(metadata.items,oldRows);assert.equal(metadata.previewTick,120000,'clock refresh uses stable minute buckets');
 const clock=new Fixture();clock.previewTimeChanged();await new Promise(r=>setImmediate(r));await drain(clock);assert.equal(clock.items[0].previewSource,'old','minute refresh first rereads the document and then captures');
 const helpers=between(page,'  private galleryDocumentRefresh:', '  private reliefTimer:');
 const {Host}=execute(`export class Host {alive=true;galleryMounted=true;galleryVisible=true;canvasChanging=false;galleryTransitioning=false;store={state:{canvasId:'a'}};galleryController;${helpers}}`);
 const host=new Host(),loads=[];let resumed=0;host.galleryController={prepare:id=>new Promise(r=>loads.push(r)),resumePreviews:()=>resumed++};
 host.refreshGalleryDocument();host.refreshGalleryDocument();loads[0]();await Promise.resolve();assert.equal(resumed,0);loads[1]();await Promise.resolve();assert.equal(resumed,1,'visible saved data refreshes the gallery without navigating away');
 host.refreshGalleryDocument();host.galleryVisible=false;loads[2]();await Promise.resolve();assert.equal(resumed,1,'navigation prevents a late save callback restarting preview work');
 const timers=new Map();let timerId=0,warmCalls=0;
 const {WarmHost}=execute(`export class WarmHost {alive=true;galleryMounted=true;galleryVisible=false;pageVisible=true;appWindowFocused=true;appBackgrounded=false;editing=false;viewing=false;busy=false;sharing=false;artworkInteractionBusy(){return false;}store={state:{canvasId:'a'}};galleryController={cancelWarmPreviews(){},warmPreview:()=>warmCalls++};galleryWarmAllowed(){return !this.galleryVisible;} ${between(page,'  private galleryWarmTimer:', '  private galleryDocumentRefresh:')}}`,{setTimeout:fn=>{timers.set(++timerId,fn);return timerId;},clearTimeout:id=>timers.delete(id),warmCalls:0});
 const warmHost=new WarmHost();warmHost.galleryController={cancelWarmPreviews(){},warmPreview:()=>warmCalls++};warmHost.scheduleGalleryWarm();warmHost.scheduleGalleryWarm();assert.equal(timers.size,1,'repeated edits coalesce to one background warm-up');const [timerKey,fireWarm]=[...timers.entries()][0];timers.delete(timerKey);fireWarm();assert.equal(warmCalls,1);
 warmHost.scheduleGalleryWarm();warmHost.galleryVisible=true;warmHost.cancelGalleryWarm();assert.equal(timers.size,0,'return cancels the pending warm timer');
 assert(between(page,'  private async showGallery(', '  private async createGalleryCanvas(').includes('this.cancelGalleryWarm()'),'return cancels unsent work instead of creating a scene on its critical path');
 assert(between(page,'  private persist(', '  private galleryDocumentRefresh:').includes('this.refreshGalleryDocument()'),'foreground saves notify the retained preview gallery');
 console.log('PASS preview refresh: live-save notification, stale metadata/contour/encode rejection, automatic latest retry, unique filenames and minute reconciliation.');
})().catch(e=>{console.error(e);process.exitCode=1;});
