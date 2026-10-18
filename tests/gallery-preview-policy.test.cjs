const assert=require('node:assert/strict'),fs=require('node:fs'),vm=require('node:vm');
const ts=require('/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript');
function execute(source,globals={}){const env={exports:{},...globals};vm.runInNewContext(ts.transpileModule(source,{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,env);return env.exports;}
const view=fs.readFileSync('entry/src/main/ets/views/CanvasGallery.ets','utf8');
const clock=execute(fs.readFileSync('entry/src/main/ets/model/CapabilityClock.ets','utf8'),{require:()=>({})});
const gallery=execute(fs.readFileSync('entry/src/main/ets/model/CanvasGallery.ets','utf8'));
const loading=view.slice(view.indexOf('  private async loadItems('),view.indexOf('  private requestPreview('));
const source=view.slice(view.indexOf('  private previewSource('),view.indexOf('  private artworkCards('));
const policy=view.slice(view.indexOf('  private previewWorkAllowed('),view.indexOf('  private previewTimeChanged('));
const reads=[],snapshots=[];
const {Fixture}=execute(`export class Fixture {
 alive=true;pageVisible=true;busy=false;generation=0;previewTick=0;rectsLoaded=true;widgetRects={};sourceCache=new WeakMap();
 entries=[{id:'a',name:'A'},{id:'b',name:'B'},{id:'c',name:'C'}];items=[];documents=new Map([['b',{}],['c',{}]]);visibleIds=new Set(['a']);
 getUIContext(){return {getHostContext:()=>({cacheDir:'cache'})};}
 onLoad=async id=>{reads.push(id);return {canvasDimension:'2*4',canvasAspect:2,cards:[]};};
 requestPreview(id){snapshots.push(id);return new Promise(()=>{});}
 previewAspect(){return 2;}previewFrameCorner(){return 8;}
 ${loading}
 ${source}
 ${policy}
}`,{GalleryItem:gallery.GalleryItem,reads,snapshots,capabilityRenderTick:clock.capabilityRenderTick,storageSnapshot:JSON.stringify,rememberedGalleryPreview:()=>null,cachedGalleryPreview:async()=>null,widgetRectangles:()=>{throw Error('navigation must reuse measured geometry');}});
(async()=>{
 const f=new Fixture();await Promise.race([f.loadItems('a'),new Promise((_,reject)=>setTimeout(()=>reject(Error('return navigation blocked by snapshot queue')),200))]);
 assert.deepEqual(reads,['a'],'returning rereads the changed canvas, not the entire catalog');assert.deepEqual(snapshots,['a']);
 snapshots.length=0;f.busy=true;f.previewWorkChanged();assert.equal(snapshots.length,0);f.busy=false;f.previewWorkChanged();assert.deepEqual(snapshots,['a'],'only visible previews resume after landing');
 snapshots.length=0;f.pageVisible=false;f.previewWorkChanged();assert.equal(snapshots.length,0,'hidden gallery cannot compete with editor animation');
 const state={cards:[{capability:{k:'album',albumRotationMinutes:2,albumRotationStart:60000}}]};
 f.previewTick=60000;const a=f.previewSource(state);f.previewTick=119999;assert.equal(f.previewSource(state),a);f.previewTick=180000;assert.notEqual(f.previewSource(state),a,'album rollover invalidates its thumbnail');
 const staticState={cards:[{capability:null}]};const fixed=f.previewSource(staticState);f.previewTick+=60000;assert.equal(f.previewSource(staticState),fixed,'static geometry does not trigger minute-by-minute screenshots');
 assert.match(view,/const GALLERY_MEASUREMENT_DELAY_MS:number=300/,'capability paper/text measurement uses native offscreen settling rather than forcing the first frame');
 assert.equal((view.match(/this.artwork\(state\);\},layoutDelay,/g)||[]).length,2,'normal and missing-image fallback captures both wait for measured paper geometry');
 const split=view.slice(view.indexOf('  splitCreationButton()'),view.indexOf('  private async loadItems('));
 assert.equal((split.match(/sys.symbol.plus/g)||[]).length,1);assert(!split.includes("Text('+"),'plus must be the persistent rotating glyph, not part of fading text');assert(!split.includes('rotate({angle:this.splitOpen?45:0}).opacity'),'the same glyph remains visible in both directions');
 console.log('PASS preview policy: current-document refresh, nonblocking snapshots, transition suspension, album cache rollover and persistent plus glyph.');
})().catch(e=>{console.error(e);process.exitCode=1;});
