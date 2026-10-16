const assert=require('node:assert/strict'),fs=require('node:fs'),vm=require('node:vm'),ts=require('/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript');
const page=fs.readFileSync('entry/src/main/ets/pages/Index.ets','utf8'),methods=page.slice(page.indexOf('  private mountEditorSection('),page.indexOf('  private retireChrome()'));
const jobs=[],moduleExports={};vm.runInNewContext(ts.transpileModule('export class Harness {'+methods+'}',{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,{exports:moduleExports,PreparedTransition:class{constructor(fn){this.fn=fn;}}});
const h=new moduleExports.Harness();Object.assign(h,{alive:true,editing:true,heroActive:false,editorContentStage:0,editorMountGeneration:1,getUIContext:()=>({postFrameCallback:job=>jobs.push(job)})});
h.mountEditorSection(1,1);jobs.shift().fn();assert.equal(h.editorContentStage,1);jobs.shift().fn();assert.equal(h.editorContentStage,2);
for(const condition of [{editing:false},{heroActive:true},{alive:false},{editorMountGeneration:2}]){
 Object.assign(h,{alive:true,editing:true,heroActive:false,editorMountGeneration:1,editorContentStage:0},condition);h.mountEditorSection(1,1);jobs.shift().fn();assert.equal(h.editorContentStage,0);assert.equal(jobs.length,0);
}
console.log('PASS staged native editor controls, interrupted entrance, close/reopen and teardown isolation.');
