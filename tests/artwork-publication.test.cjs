const assert=require('node:assert/strict'),fs=require('node:fs'),vm=require('node:vm');
const ts=require('/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript');
const src=fs.readFileSync('entry/src/main/ets/pages/Index.ets','utf8');
const relief=src.slice(src.indexOf('  private reliefTimer:'),src.indexOf('  private readingTintKey('));
const background=src.slice(src.indexOf('  private async refreshBackground('),src.indexOf('  private chooseBackgroundMode('));
let resolveTask;const jobs=[];const mod={exports:{}};
vm.runInNewContext(ts.transpileModule(`class Harness {${relief}${background}}module.exports=Harness`,{compilerOptions:{target:ts.ScriptTarget.ES2020}}).outputText,{
 module:mod,taskpool:{Task:class{},execute:()=>new Promise(resolve=>resolveTask=resolve)},prepareSceneRelief(){},createSmartBackground(){},FridgeState:class{},cardRenderSnapshot:c=>c,backgroundSignature:s=>s.signature,normalizeBackground:x=>x,setTimeout:fn=>(jobs.push(fn),jobs.length),clearTimeout(){}});
function fixture(){const h=new mod.exports();Object.assign(h,{alive:true,ready:true,pageVisible:true,appWindowFocused:true,appBackgrounded:false,context:{filesDir:'/local'},backgroundGeneration:0,canvasBackground:{mode:'blend',signature:'old'},store:{state:{canvasId:'one',signature:'new',cards:[{id:'card',shape:'subject',cutout:'file://subject',w:1,h:1,reliefSrc:'old'}]}},renders:0,published:0,retries:0,render(){this.renders++},applyBackground(){this.published++},scheduleBackground(){this.retries++}});return h;}
(async()=>{
 for(const field of ['activeBoardId','gestureGroup','heroActive','layerDrag','arriving','canvasChanging','scheduleTransition','deletionId']){
  const h=fixture(),p=h.prepareRelief();h[field]=true;resolveTask(JSON.stringify({card:'new'}));await p;assert.equal(h.store.state.cards[0].reliefSrc,'old',field);assert.equal(h.renders,0);assert.equal(h.reliefBusy,false);assert(h.reliefTimer>=0,'retry after worker finishes');h[field]=false;const retry=h.prepareRelief();resolveTask(JSON.stringify({card:'new'}));await retry;assert.equal(h.renders,1,'publish when idle');
  const b=fixture(),q=b.refreshBackground();b[field]=true;resolveTask('{}');await q;assert.equal(b.published,0,field);assert.equal(b.retries,1);assert.equal(b.backgroundBusy,false);
 }
 for(const method of ['prepareRelief','refreshBackground']){
  for(const interruption of ['hidden','canvas','destroyed']){const h=fixture(),p=h[method]();if(interruption==='hidden')h.pageVisible=false;else if(interruption==='canvas')h.store.state.canvasId='two';else h.alive=false;resolveTask(method==='prepareRelief'?'{"card":"new"}':'{}');await p;assert.equal(h.renders+h.published,0,method+':'+interruption);}
 }
 console.log('PASS asynchronous artwork publication: eight interaction races, idle retry, canvas switch, hidden page and teardown.');
})().catch(e=>{console.error(e);process.exitCode=1});
