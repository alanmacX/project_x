const assert=require('node:assert/strict'),fs=require('node:fs'),path=require('node:path'),vm=require('node:vm');
const ts=require('/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript');
const root=path.resolve(__dirname,'../entry/src/main/ets/model'),cache=new Map();let jobs=0;
const pool={Task:class{constructor(fn,...args){this.fn=fn;this.args=args;}},execute:async task=>{jobs++;return task.fn(...task.args);}};
function load(name){const file=path.resolve(root,name+'.ets');if(cache.has(file))return cache.get(file).exports;const mod={exports:{}};cache.set(file,mod);const code=ts.transpileModule(fs.readFileSync(file,'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText;vm.runInThisContext('(function(require,module,exports){'+code+'\n})',{filename:file})(s=>s==='@kit.ArkTS'?{taskpool:pool}:load(path.relative(root,path.resolve(path.dirname(file),s))),mod,mod.exports);return mod.exports;}
(async()=>{
const r=load('RenderContours'),s=load('CardSchema');
const source=new s.FridgeCard();source.id='photo';source.cutout='file://local.png';source.subjectVersion=2;source.shape='subject';source.outline=[[{x:.1,y:.1},{x:.9,y:.1},{x:.9,y:.9},{x:.1,y:.9}]];
const state=new s.FridgeState();state.cards=[source];await r.primeRenderContours([source],JSON.stringify(state));assert.equal(jobs,1);
const encoded=r.serializeContourCache([source]);assert.ok(encoded);assert.equal(r.serializeContourCache([]),'');
const fresh=()=>Object.assign(new s.FridgeCard(),JSON.parse(JSON.stringify(source)));
const restored=fresh();restored.id='duplicate';restored.w=70;restored.rot=40;assert.equal(r.restoreContourCache([restored],encoded),1,'same immutable asset survives duplication, resizing and rotation');
await r.primeRenderContours([restored],'');assert.equal(jobs,1,'cold cache hit dispatches no topology worker');
restored.renderContourKey=r.registerRenderContour(restored);restored.outline=[];assert.deepEqual(r.cardOutline(restored),source.outline);
const changed=fresh();changed.outline[0][1].x=.85;assert.equal(r.restoreContourCache([changed],encoded),0,'edited master geometry invalidates cache');
const newVersion=fresh();newVersion.subjectVersion++;assert.equal(r.restoreContourCache([newVersion],encoded),0);
for(const raw of ['broken','{}',JSON.stringify({...JSON.parse(encoded),version:99})])assert.equal(r.restoreContourCache([fresh()],raw),0,'disposable cache cannot prevent local scene loading');
const corrupt=JSON.parse(encoded);Object.values(corrupt.entries)[0].outline[0][0].x=null;assert.equal(r.restoreContourCache([fresh()],JSON.stringify(corrupt)),0);
state.cards=[changed];await r.primeRenderContours([changed],JSON.stringify(state));assert.equal(jobs,2,'changed artwork is reprocessed off the UI thread');
console.log('PASS cold contour cache: exact-source/asset matching, worker avoidance, geometry reuse, corruption/version fallback and edit invalidation');
})().catch(e=>{console.error(e);process.exitCode=1;});
