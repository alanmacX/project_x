const assert=require('node:assert/strict'),fs=require('node:fs'),vm=require('node:vm');
const ts=require('/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript');
const context={exports:{}};
vm.runInNewContext(ts.transpileModule(fs.readFileSync('entry/src/main/ets/model/CardActionPlacement.ets','utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,context);
const anchor=context.exports.cardActionAnchor;
for(const width of [320,390,768])for(const rot of [-90,-12,0,45,180])for(const x of [-90,40,300]){
 const card={x,y:240,w:100,h:120,rot};const saved=JSON.stringify(card);
 const p=anchor(card,1,1,0,100,500,width,900,24,24);
 assert(p.x>=96&&p.x<=width-96,'capsule stays within horizontal safe edges');
 assert(p.above?p.y-60>=108:p.y+60<=592,'capsule stays above tools panel');
 assert.equal(JSON.stringify(card),saved);
}
let p=anchor({x:80,y:300,w:120,h:240,rot:0},1,1,0,100,500,390,1000,24,24);
assert.equal(p.above,true,'card crossing board bottom moves actions above');assert.equal(p.y,378);
p=anchor({x:80,y:100,w:120,h:120,rot:0},1,1,0,100,500,390,1000,24,24,[0,0,0,15]);
assert.equal(p.above,false);assert.equal(p.y,357,'artwork fringe is included in the gap');
console.log('PASS card actions: rotated artwork, narrow/wide screens, safe edges, fringe and board-bottom overflow.');
