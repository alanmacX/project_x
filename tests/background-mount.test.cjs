const assert=require('node:assert/strict'),fs=require('node:fs'),vm=require('node:vm'),ts=require('/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript');
const page=fs.readFileSync('entry/src/main/ets/pages/Index.ets','utf8'),methods=page.slice(page.indexOf('  private openBackgroundEditor()'),page.indexOf('  @Builder\n  backgroundEditor()'));
const jobs=[],moduleExports={};vm.runInNewContext(ts.transpileModule('export class Harness {'+methods+'}',{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,{exports:moduleExports,PreparedTransition:class{constructor(fn){this.fn=fn;}}});
const h=new moduleExports.Harness();Object.assign(h,{alive:true,context:{},backgroundMountGeneration:0,scenePanelGeneration:0,getUIContext:()=>({postFrameCallback:job=>jobs.push(job)})});
h.openBackgroundEditor();assert.equal(h.backgroundOpen,true);assert.equal(h.backgroundContentStage,0);jobs.shift().fn();assert.equal(h.backgroundContentStage,1);jobs.shift().fn();assert.equal(h.backgroundContentStage,2);
h.openBackgroundEditor();const stale=jobs.shift();h.backgroundOpen=false;stale.fn();assert.equal(h.backgroundContentStage,0,'Closed panel is not resurrected');
h.openBackgroundEditor();const old=jobs.shift();h.openBackgroundEditor();old.fn();assert.equal(h.backgroundContentStage,0,'Old entrance cannot fill the new one');jobs.shift().fn();jobs.shift().fn();assert.equal(h.backgroundContentStage,2);
h.openBackgroundEditor();h.alive=false;jobs.shift().fn();assert.equal(h.backgroundContentStage,0,'Destroyed page is not repopulated');
console.log('PASS staged native background sections, close/reopen generation isolation and page teardown.');
