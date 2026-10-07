const assert=require('node:assert/strict'),fs=require('node:fs'),path=require('node:path'),vm=require('node:vm');
const ts=require('/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript');
const root=path.resolve(__dirname,'../entry/src/main/ets/model'),cache=new Map();
function load(name){const file=path.resolve(root,name+'.ets');if(cache.has(file))return cache.get(file).exports;const mod={exports:{}};cache.set(file,mod);const code=ts.transpileModule(fs.readFileSync(file,'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText;vm.runInThisContext('(function(require,module,exports){'+code+'\n})',{filename:file})(s=>s==='@kit.ArkTS'?{taskpool:{}}:s==='@kit.BasicServicesKit'?{deviceInfo:{sdkApiVersion:24}}:load(path.relative(root,path.resolve(path.dirname(file),s))),mod,mod.exports);return mod.exports;}
const {alignToCanvas}=load('AlignmentGuide'),{groupBox}=load('GroupGeometry'),{FridgeCard}=load('CardSchema');
const bounds={minX:-300,maxX:400,minY:-300,maxY:800},origin={x:10,y:20},anchor={x:100,y:120};
for(const height of [344,470,620])for(const scale of [.6,1,2.5]){
 const x=origin.x+172-anchor.x,y=origin.y+(height/2-anchor.y)*470/height;
 const near=alignToCanvas(x+3/scale,y+3/scale*470/height,origin,anchor,height,scale,bounds);
 assert.equal(near.vertical,true);assert.equal(near.horizontal,true);assert.ok(Math.abs(near.x-x)<1e-8);assert.ok(Math.abs(near.y-y)<1e-8);
 const far=alignToCanvas(x+6/scale,y+6/scale*470/height,origin,anchor,height,scale,bounds);assert.equal(far.vertical,false);assert.equal(far.horizontal,false);
 const blocked=alignToCanvas(x,y,origin,anchor,height,scale,{...bounds,minX:x+1,minY:y+1});assert.equal(blocked.vertical,false);assert.equal(blocked.horizontal,false);
}
const a=new FridgeCard(),b=new FridgeCard();a.x=10;a.y=20;a.w=80;a.h=100;a.rot=37;b.x=170;b.y=200;b.w=90;b.h=70;b.rot=-24;
const box=groupBox([a,b],344),centre={x:box.x+box.w/2,y:box.y+box.h/2};
const dx=172-centre.x,dy=(172-centre.y)*470/344;
const aligned=alignToCanvas(a.x+dx,a.y+dy,{x:a.x,y:a.y},centre,344,1,bounds);assert.equal(aligned.vertical,true);assert.equal(aligned.horizontal,true);
console.log('PASS central guides: physical 4vp tolerance, responsive aspect/density, constrained snap and rotated group centre.');
