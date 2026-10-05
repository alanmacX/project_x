const assert=require('node:assert/strict');
const fs=require('node:fs');
const vm=require('node:vm');
const ts=require(process.env.FRIDGE_TYPESCRIPT||'/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript');
class ElementBox {x=0;y=0;w=1;h=1;rot=0;opacity=1;}
const result={};
const source=fs.readFileSync('entry/src/main/ets/model/EditorLayerMotion.ets','utf8');
const code=ts.transpileModule(source,{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020,experimentalDecorators:true}}).outputText;
vm.runInNewContext(code,{exports:result,require:()=>({ElementBox}),Observed:x=>x,Track:()=>undefined});
const motion=new result.EditorLayerMotion(),sourceBox=new ElementBox();
sourceBox.x=.23;sourceBox.y=.17;sourceBox.w=.4;sourceBox.h=.2;sourceBox.rot=23;sourceBox.opacity=.6;
motion.update('text-1',sourceBox);
assert.equal(motion.id,'text-1');assert.notEqual(motion.box,sourceBox);
assert.equal(motion.box.x,.23);assert.equal(motion.box.rot,23);assert.equal(motion.box.opacity,.6);
sourceBox.x=.8;assert.equal(motion.box.x,.23,'live geometry must not alias stored artwork');
const previous=motion.box;motion.update('text-1',sourceBox);
assert.notEqual(motion.box,previous);assert.equal(previous.x,.23);assert.equal(motion.box.x,.8);
motion.clear();assert.equal(motion.id,'','completion/cancel returns rendering to persisted geometry');assert.equal(sourceBox.x,.8);
console.log('PASS editor gesture state: detached geometry, immutable frame snapshots, same-layer updates and explicit completion without artwork mutation');
