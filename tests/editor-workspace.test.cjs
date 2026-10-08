const assert=require('node:assert/strict'),fs=require('node:fs'),vm=require('node:vm');
const ts=require('/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript');
const env={exports:{}};vm.runInNewContext(ts.transpileModule(fs.readFileSync('entry/src/main/ets/model/EditorWorkspace.ets','utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS}}).outputText,env);
for(const [w,h] of [[320,568],[360,640],[390,844],[460,672],[768,1024],[940,665],[780,360],[300,260]]) {
 const v=env.exports.editorWorkspace(w,h,38,24);
 assert.ok(v.previewW>=96&&v.layersW>=92,'usable preview and layers');
 assert.equal(v.previewW+v.layersW+12,v.stageW,'layers share preview stage without stealing another row');
 assert.ok(v.panelH>0&&v.stageH>0);
 if(v.wide){assert.equal(v.stageW+v.panelW,w);assert.equal(v.panelH,v.body);assert.equal(v.stageH,v.body);}
 else {assert.equal(v.stageW,w);assert.equal(v.stageH+v.panelH,v.body);assert.ok(v.stageH<=260);assert.ok(v.panelH>=Math.min(148,v.body-48));}
}
console.log('PASS embedded editor: preview + layers share height, inspector fills remaining phone/wide space, short-window budgets.');
