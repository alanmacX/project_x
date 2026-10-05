// Execute the real Form scene controller, with the native animation clock stepped explicitly.
const assert=require('node:assert/strict'),fs=require('node:fs'),vm=require('node:vm');
const ts=require('/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript');
const source=fs.readFileSync('entry/src/main/ets/widget/pages/FridgeWidgetCard.ets','utf8');
const controller=source.slice(source.indexOf('  private syncPacket()'),source.indexOf('  private sceneOffset('));
const disappear=source.match(/  aboutToDisappear\(\):void \{[^\n]+/)[0];
const jobs=[];const env={exports:{},Curve:{EaseIn:0,Friction:1},cardRenderSnapshot:c=>c,normalizeBackground:b=>b,animateTo:(o,update)=>{update();jobs.push(o);}};
const code=ts.transpileModule('export class Harness {parse(json:string){return JSON.parse(json);}'+controller+disappear+'}',{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText;
vm.runInNewContext(code,env);const scene=new env.exports.Harness();Object.assign(scene,{alive:true,sceneGeneration:0,appliedPacket:'',sceneAnimating:false,scenePhase:0});
const packet=(canvasId,id,colour,rev)=>JSON.stringify({canvasId,cards:JSON.stringify([{id,z:1}]),background:JSON.stringify({color:colour}),context:'',rev});
scene.packetJson=packet('a','a1','red',1);scene.syncPacket();assert.equal(scene.cardIds[0],'a1');assert.equal(scene.canvasBackground.color,'red');assert.equal(jobs.length,0);
scene.packetJson=packet('b','b1','blue',2);scene.syncPacket();assert.equal(scene.cardIds[0],'a1','outgoing artwork remains intact during exit');assert.equal(scene.canvasBackground.color,'red');
const interrupted=jobs.shift();scene.packetJson=packet('c','c1','green',3);scene.syncPacket();interrupted.onFinish();assert.equal(scene.cardIds[0],'a1','an older completion cannot apply a stale canvas');
jobs.shift().onFinish();assert.equal(scene.cardIds[0],'c1');assert.equal(scene.canvasBackground.color,'green','geometry and background switch together');
jobs.shift().onFinish();jobs.shift().onFinish();assert.equal(scene.scenePhase,0);assert.equal(scene.sceneAnimating,false);
scene.packetJson=packet('d','d1','white',4);scene.syncPacket();const hidden=jobs.shift();scene.aboutToDisappear();assert.equal(scene.scenePhase,0);assert.equal(scene.appliedPacket,'');hidden.onFinish();assert.equal(scene.cardIds[0],'c1');
scene.alive=true;scene.syncPacket();assert.equal(scene.cardIds[0],'d1','a resumed renderer starts directly at the latest packet');assert.equal(scene.sceneAnimating,false);
scene.packetJson=packet('d','d2','cream',5);scene.syncPacket();assert.equal(scene.cardIds[0],'d2');assert.equal(scene.canvasBackground.color,'cream');const edited=jobs.shift();assert.equal(edited.duration,180);edited.onFinish();
scene.packetJson=packet('d','d2','cream',6);scene.syncPacket();assert.equal(jobs.length,0,'unchanged visibility/tick refresh does not rebuild or animate artwork');
// A newer packet returning to the outgoing canvas must cancel an in-flight switch.
scene.sceneAnimating=false;scene.packetJson=packet('e','e1','pink',7);scene.syncPacket();const pending=jobs.shift();
scene.packetJson=packet('d','d2','cream',8);scene.syncPacket();pending.onFinish();assert.equal(scene.displayCanvasId,'d','stale target cannot survive a return to the visible scene');
jobs.shift().onFinish();assert.equal(scene.sceneAnimating,false);
console.log('PASS Form transition controller: atomic scene/background, newer packet interruption, stale callbacks, hidden/reappearing host and same-canvas animation.');
