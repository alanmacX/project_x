const fs=require('node:fs'),vm=require('node:vm'),assert=require('node:assert/strict');
const ts=require('/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript');
const page=fs.readFileSync('entry/src/main/ets/pages/Index.ets','utf8'),method=page.slice(page.indexOf('  private initialize():'),page.indexOf('  private cacheMaintained:'));
let decodes=0,widget=false;
const env={exports:{},AppStorage:{get:()=>widget,setOrCreate(){}},prepareChromeMaterial:async()=>{},prepareSceneImages:async()=>{decodes++;},startupMark(){},ensureCapabilitySize:()=>true,primeGalleryPreviews:async()=>{},PreparedTransition:class{constructor(start){this.start=start;}},revealStartup(){}};
const fixture=`export class Startup {
 context={cacheDir:'/cache'};alive=true;routeCanvasId='';routedId='';viewRouteId='';canvasEntries=[];cardIds=[];ready=false;
 store={state:{canvasId:'a',cards:[],background:{}},init:async()=>{},refreshCanvasSpecs:async()=>{}};
 refreshCanvasList(){}syncHostCanvasGeometry(){}layoutBoard(){}render(){}retainCanvasImages(){}queueReadingTints(){}queueRelief(){}scheduleBackground(){}routeChanged(){}viewRouteChanged(){}incomingTemplateChanged(){}scheduleMaintenance(){}scheduleWidgetRoute(){}
 getUIContext(){return {postFrameCallback:frame=>frame.start()};}
 ${method}
}`;
vm.runInNewContext(ts.transpileModule(fixture,{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,env);
(async()=>{
 const home=new env.exports.Startup();home.initialize();await new Promise(setImmediate);assert(home.ready);assert(home.galleryVisible);assert.equal(home.workspaceMounted,false);assert.equal(decodes,0,'icon-to-gallery startup never eagerly decodes full editor originals');
 widget=true;const route=new env.exports.Startup();route.initialize();await new Promise(setImmediate);assert(route.ready);assert.equal(route.galleryVisible,false);assert.equal(decodes,1,'widget startup retains predecoded artwork before revealing its workspace');
 widget=false;const card=new env.exports.Startup();card.routedId='card_a';card.initialize();await new Promise(setImmediate);assert.equal(card.galleryVisible,false);assert.equal(decodes,2,'direct card routes preserve their image readiness guarantee');
 console.log('PASS real startup flow: zero eager scene decodes for gallery; widget/card routes still predecode before reveal.');
})().catch(e=>{console.error(e);process.exitCode=1;});
