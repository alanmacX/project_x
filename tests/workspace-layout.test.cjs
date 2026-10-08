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
  else {assert.equal(l.previewW,w);assert.ok(body-l.previewH-l.layersH>=120,'small phone retains room for contextual tools; detail controls live in the sheet');}
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
for(const [w,h] of [[390,844],[844,390],[520,800]]){const l=workspaceLayout(w,h,28,24,1);assert.equal(l.floating,true);assert.equal(l.panelH,52);assert.ok(l.expandedBoardY<=l.boardY);assert.ok(l.expandedBoardY>=28);assert.ok(l.expandedBoardY+l.boardH<=h-24,'lift remains within safe bounds');}
for(const [w,h] of [[768,1024],[1024,768]])assert.equal(workspaceLayout(w,h,28,24,1).floating,false);
console.log('PASS responsive workspace: 16 phone/tablet/split-window sizes, four canvas ratios, safe areas, portrait artwork priority and settings budget');

// Actual emulator windows in vp (native densities: Pura X Max 440, Mate X7 500).
const foldWindows=[[2584/2.75,1828/2.75],[1828/2.75,2584/2.75],[1264/2.75,1848/2.75],[1848/2.75,1264/2.75],
 [2210/3.125,2416/3.125],[2416/3.125,2210/3.125],[1080/3.125,2444/3.125],[2444/3.125,1080/3.125]];
for(const [w,h] of foldWindows) for(const [top,bottom] of [[0,24],[36,24],[48,32]]) for(const ratio of [.3,.73,1,1.5,3]) {
 const l=workspaceLayout(w,h,top,bottom,ratio);
 assert.ok(l.boardX>=0&&l.boardX+l.boardW<=w+.001);
 assert.ok(l.boardY>=top&&l.boardY+l.boardH<=h-bottom+.001);
 assert.ok(l.panelX>=0&&l.panelX+l.panelW<=w+.001);
 assert.ok(l.panelY+l.panelH<=h-bottom+.001);
 const body=h-top-bottom-76;
 assert.ok(l.previewH+l.layersH+(l.wide?12:56)<=body,'folded screen retains room for inspector');
 assert.ok(l.previewW>=300&&l.inspectorW>=300);
}
console.log('PASS Pura X Max / Mate X7: both screens, both orientations, three safe-area configurations, five ratios');
