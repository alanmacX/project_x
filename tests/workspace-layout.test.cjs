const assert=require('node:assert/strict'),fs=require('node:fs'),vm=require('node:vm');
const ts=require('/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript');
const moduleObject={exports:{}};
const src=fs.readFileSync(__dirname+'/../entry/src/main/ets/model/WorkspaceLayout.ets','utf8');
vm.runInNewContext(ts.transpileModule(src,{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,{exports:moduleObject.exports,module:moduleObject});
const {workspaceLayout}=moduleObject.exports;
for(const [w,h] of [[320,568],[360,640],[390,844],[424,900],[600,960],[768,1024],[1024,768],[844,390],[720,360]]) {
 for(const ratio of [.6,1,1.5,2]) {
  const l=workspaceLayout(w,h,28,24,ratio);
  assert.ok(Math.abs(l.boardW/l.boardH-ratio)<.001);
  assert.ok(l.boardX>=0&&l.boardX+l.boardW<=w);
  assert.ok(l.boardY>=28&&l.boardY+l.boardH<=h-24);
  assert.ok(l.panelX>=0&&l.panelX+l.panelW<=w);
  assert.ok(l.panelY+l.panelH<=h-24+.001);
  assert.ok(l.panelY>=l.boardY+l.boardH || l.panelX>=l.boardX+l.boardW,'home canvas and tools never intersect');
  assert.equal(l.previewW+l.inspectorW,l.wide?w:w*2,'compact inspector is below, wide inspector beside');
  const body=h-28-24-76;
  if(l.wide)assert.ok(l.previewH+l.layersH+24<=body,'landscape artwork and native layer targets fit vertically');
  else {assert.equal(l.previewW,w);assert.ok(body-l.previewH-l.layersH-12-56>=140,'small phone retains a usable settings viewport');}
 }
}
assert.equal(workspaceLayout(600,960,28,24,1).wide,false);
assert.equal(workspaceLayout(844,390,28,24,1).wide,true);
console.log('PASS workspace layout: nine phone/tablet sizes, four canvas ratios, safe areas, independent content panes and compact settings budget');
