const assert=require('node:assert/strict'),fs=require('node:fs'),vm=require('node:vm');
const ts=require('/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript'),m={exports:{}};
vm.runInNewContext(ts.transpileModule(fs.readFileSync(__dirname+'/../entry/src/main/ets/model/EditorScrollDetent.ets','utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS}}).outputText,{exports:m.exports,module:m});
const snap=new m.exports.EditorScrollDetent();
snap.begin(0,100);assert.equal(snap.move(0,65,false,0),undefined);assert.equal(snap.move(0,50,false,10),true);assert.equal(snap.move(0,180,true,0),undefined,'one snap per touch prevents layout changes from reversing it');
snap.begin(0,100);assert.equal(snap.move(0,180,true,50),undefined,'downward content scrolling must not collapse');assert.equal(snap.move(0,200,true,0),undefined);assert.equal(snap.move(0,240,true,0),false,'pull continues after reaching the start');
snap.begin(0,100);assert.equal(snap.move(150,30,false,0),undefined,'horizontal swipes do not expand');snap.end();assert.equal(snap.move(0,0,false,0),undefined,'inertia and cancelled touch cannot snap');
console.log('PASS editor content detents: thresholds, scroll boundary, horizontal/multitouch cancellation and one transition per gesture');
