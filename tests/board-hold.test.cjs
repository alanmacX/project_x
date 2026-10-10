const fs=require('node:fs'),vm=require('node:vm'),assert=require('node:assert/strict');
const ts=require('/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript');
const source=fs.readFileSync('entry/src/main/ets/pages/Index.ets','utf8');
const cache=new Map();
function load(name){if(cache.has(name))return cache.get(name);const mod={exports:{}};cache.set(name,mod.exports);const text=fs.readFileSync('entry/src/main/ets/model/'+name+'.ets','utf8');vm.runInThisContext('(function(require,module,exports){'+ts.transpileModule(text,{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText+'})')(s=>load(s.slice(2)),mod,mod.exports);cache.set(name,mod.exports);return mod.exports;}
const methods=source.slice(source.indexOf('  private raiseBoardStack('),source.indexOf('  private moveCardLayer('));
const commit=source.slice(source.indexOf('  private commitGeometry('),source.indexOf('  private async pickImage('));
const ctx={exports:{},groupMembers:load('CardGroups').groupMembers};
vm.runInNewContext(ts.transpileModule(`class Fixture{editing=false;viewing=false;groupSelecting=false;scheduledName='';scheduleTransition=false;selectedId='';saveTimer=-1;renders=0;saves=0;boardMotion={offset:{x:0,y:0}};store;renderBoard(){this.renders++;}render(){this.renders++;}persist(){this.saves++;}clamp(){}${methods}${commit}}exports.Fixture=Fixture;`,{compilerOptions:{target:ts.ScriptTarget.ES2020}}).outputText,ctx);
const f=new ctx.exports.Fixture(),a={id:'a',groupId:'g',z:1,x:0,y:0,w:100,h:100,rot:0},b={...a,id:'b',z:3,x:120},c={...a,id:'c',groupId:'',z:5};
f.store={state:{cards:[a,b,c],maxZ:5},findCard:id=>f.store.state.cards.find(c=>c.id===id)||null,bringToFront(card){card.z=++this.state.maxZ;}};
f.holdBoardCard('a');assert.equal(a.z,6);assert.equal(b.z,7);assert.equal(c.z,5);assert.equal(f.selectedId,'a');assert.equal(f.saves,1);assert.equal(a.x,0);assert.equal(b.x,120);
f.holdBoardCard('a');assert.equal(f.saves,1,'already front does not publish redundant changes');assert.equal(f.store.state.maxZ,7);
for(const key of ['editing','viewing','groupSelecting','scheduledName','scheduleTransition']){f[key]=true;f.holdBoardCard('c');assert.equal(c.z,5);f[key]=false;}
c.hidden=true;assert.equal(f.raiseBoardStack('c'),false);c.hidden=false;
f.commitGeometry({...c,w:110});assert.equal(c.z,5,'resizing preserves permanent stacking');f.commitGeometry({...c,rot:15});assert.equal(c.z,5,'rotation preserves stacking');
f.commitGeometry({...c,x:20});assert.equal(c.z,8,'finished drag restores historic promotion');
f.commitGeometry({...a,x:10});assert.equal(b.x,130,'group translates rigidly');assert.ok(a.z>c.z&&b.z>a.z,'group raises together preserving internal order');
assert.equal(f.raiseBoardStack('missing'),false);
console.log('PASS hold/drag promotion: actual group model, internal order, no-op, scene/edit guards, geometry and resize/rotation isolation');
