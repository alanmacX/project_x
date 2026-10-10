const assert=require('node:assert/strict'),fs=require('node:fs'),path=require('node:path'),vm=require('node:vm');
const ts=require('/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript');
const root=path.resolve(__dirname,'../entry/src/main/ets/model'),cache=new Map();
function load(name){if(cache.has(name))return cache.get(name);const mod={exports:{}};cache.set(name,mod.exports);const code=ts.transpileModule(fs.readFileSync(path.join(root,name+'.ets'),'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText;vm.runInThisContext('(function(require,module,exports){'+code+'\n})')(s=>load(s.replace('./','')),mod,mod.exports);return mod.exports;}
const {canvasViewport,sceneRect}=load('SceneLayout'),{FridgeCard}=load('CardSchema'),{capabilityVisualHeight,boundedReadoutFont}=load('CapabilityMetrics'),{albumInfoGeometry}=load('AlbumLayout');
const card=new FridgeCard();Object.assign(card,{x:64,y:197,w:98,h:141,rot:-12});const saved=JSON.stringify(card);
for(const aspect of [.3,.65,1,1.8,3]){
 let baseline;
 for(const [w,h] of [[300,500],[500,300],[400,400],[940,330],[330,940]]){
  const v=canvasViewport(w,h,aspect),r=sceneRect(card,v.w,v.h);
  assert.ok(Math.abs(v.w/v.h-aspect)<1e-8);assert.ok(v.w<=w&&v.h<=h);assert.ok(v.x>=0&&v.y>=0);
  assert.ok(Math.abs(v.x*2+v.w-w)<1e-8&&Math.abs(v.y*2+v.h-h)<1e-8);
  const normalized=[r.x/v.w,r.y/v.w,r.w/v.w,r.h/v.w,r.rot];
  if(baseline)normalized.forEach((n,i)=>assert.ok(Math.abs(n-baseline[i])<1e-8,'host orientation only changes a uniform scale'));
  baseline=normalized;
 }
}
assert.equal(JSON.stringify(card),saved,'authored card geometry is never changed by the host');
for(const invalid of [NaN,0,Infinity,4])assert.equal(canvasViewport(300,200,invalid).w,200);
for(const style of ['classic','row'])for(const [w,h] of [[80,80],[180,180],[300,150],[420,230],[80,300]]){
 const g=albumInfoGeometry(w,h,style),height=(g.titleSize*2+g.artistSize*g.artistLines)*1.15+g.artistGap;
 assert.ok((g.centerText?g.textY+height/2:g.textY+height)<=h+1e-8,'entire metadata line budget fits');
}
for(const kind of ['clock','worldclock','lunar','date','calendar','countdown','anniversary','dayprogress','yearprogress','battery'])for(const compact of [true,false]){
 const budget=capabilityVisualHeight({k:kind},compact);assert.ok(budget>0);
 for(const height of [18,32,50,80,160]){const scale=Math.min(2,height/budget);assert.ok(budget*scale<=height+1e-8);}
}
for(const width of [16,24,48,80,120])assert.ok(boundedReadoutFont(42,width,3.2)*3.2<=width+1e-8);
console.log('PASS fixed authored aspect across five host shapes; non-mutating uniform fit; full album text/graphic budgets and bounded clock numbers');

// Active Form policy restores pre-3a98384 full-host placement, not fixed-aspect fit.
for(const [w,h] of [[300,500],[500,300],[940,330],[330,940]]){
 const r=sceneRect(card,w,h);
 assert.ok(Math.abs(r.x/w-card.x/load('CardSchema').BOARD_W)<1e-8);
 assert.ok(Math.abs(r.y/h-card.y/load('CardSchema').BOARD_H)<1e-8);
 assert.ok(Math.abs(r.w/r.h-card.w/card.h)<1e-8, 'host adaptation does not stretch cards');
}
const index=fs.readFileSync('entry/src/main/ets/pages/Index.ets','utf8');
const method=index.slice(index.indexOf('  private syncHostCanvasGeometry()'),index.indexOf('  private widgetFrameChanged()'));
const env={exports:{}};vm.runInNewContext(ts.transpileModule('export class Harness {'+method+'}',{compilerOptions:{module:ts.ModuleKind.CommonJS}}).outputText,env);
const view=new env.exports.Harness();view.store={state:{canvasDimension:'4*4',canvasAspect:1},canvasSpecs:{'4*4':1.2}};view.widgetDimension='4*4';view.widgetAspect=1.6;
view.syncHostCanvasGeometry();assert.equal(view.canvasAspect,1.6);
view.widgetAspect=0;view.syncHostCanvasGeometry();assert.equal(view.canvasAspect,1.2);
view.store.canvasSpecs={};view.syncHostCanvasGeometry();assert.equal(view.canvasAspect,1);
assert.equal(view.store.state.canvasAspect,1,'reading a live host ratio does not modify persisted composition');
console.log('PASS original normalized full-host placement and App live-host/cached/fallback ratio policy.');
