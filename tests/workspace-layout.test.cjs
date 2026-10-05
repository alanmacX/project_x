const assert=require('node:assert/strict'),fs=require('node:fs'),vm=require('node:vm');
const ts=require('/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript');
const moduleObject={exports:{}};
const src=fs.readFileSync(__dirname+'/../entry/src/main/ets/model/WorkspaceLayout.ets','utf8');
vm.runInNewContext(ts.transpileModule(src,{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,{exports:moduleObject.exports,module:moduleObject});
const {workspaceLayout}=moduleObject.exports;
for(const [w,h] of [[320,568],[360,640],[390,844],[424,900],[600,960],[768,1024],[1024,768],[844,390],[720,360],[834,1194],[1024,1366],[1366,1024],[960,540],[640,960],[600,720],[520,800]]) {
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
  if(l.wide){assert.ok(l.previewH+l.layersH+24<=body,'landscape artwork and native layer targets fit vertically');assert.ok(l.inspectorW>=300&&l.inspectorW<=400,'wide settings stay within a readable width');}
  else {assert.equal(l.previewW,w);assert.ok(body-l.previewH-l.layersH-12-56>=180,'small phone retains a usable settings viewport');}
 }
}
assert.equal(workspaceLayout(600,960,28,24,1).wide,false);
assert.equal(workspaceLayout(844,390,28,24,1).wide,true);
for(const [w,h] of [[768,1024],[834,1194],[1024,1366],[640,960]]) {
 const l=workspaceLayout(w,h,28,24,1);
 assert.equal(l.wide,false,'portrait tablet and tall split window must stack');
 assert.equal(l.previewW,w);
 assert.ok(l.boardW>=(w-2*l.margin)*.85,'portrait widget keeps at least 85% of available width');
 assert.ok(l.previewH>300,'tablet preview is not capped at phone height');
}
assert.equal(workspaceLayout(520,800,28,24,1).wide,false,'narrow tablet split window uses compact layout');
for(const [w,h] of [[390,844],[844,390],[520,800]]){const l=workspaceLayout(w,h,28,24,1);assert.equal(l.floating,true);assert.equal(l.panelH,52);}
for(const [w,h] of [[768,1024],[1024,768]])assert.equal(workspaceLayout(w,h,28,24,1).floating,false);
console.log('PASS responsive workspace: 16 phone/tablet/split-window sizes, four canvas ratios, safe areas, portrait artwork priority and settings budget');
