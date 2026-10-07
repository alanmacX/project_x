// Real Form packet controller: native animation completion can be dropped by a suspended host.
const assert=require('node:assert/strict'),fs=require('node:fs'),vm=require('node:vm');
const ts=require('/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript');
const source=fs.readFileSync('entry/src/main/ets/widget/pages/FridgeWidgetCard.ets','utf8');
const controller=source.slice(source.indexOf('  private syncPacket()'),source.indexOf('  private sceneOffset('));
const disappear=source.match(/  aboutToDisappear\(\):void \{[^\n]+/)[0];
const jobs=[],env={exports:{},Curve:{EaseOut:0},cardRenderSnapshot:c=>c,normalizeBackground:b=>b,animateTo:(o,update)=>{update();jobs.push(o);}};
vm.runInNewContext(ts.transpileModule('export class Harness {refresh(){}parse(json:string){return JSON.parse(json);}'+controller+disappear+'}',{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,env);
const scene=new env.exports.Harness();Object.assign(scene,{alive:true,sceneGeneration:0,appliedPacket:'',sceneAnimating:false,scenePhase:0});
const packet=(canvasId,id,color,rev)=>JSON.stringify({canvasId,cards:JSON.stringify([{id,z:1}]),background:JSON.stringify({color}),context:'',rev});
for(let i=0;i<100;i++){scene.packetJson=packet('canvas'+i,'card'+i,'color'+i,i);scene.syncPacket();assert.equal(scene.cardIds[0],'card'+i);assert.equal(scene.canvasBackground.color,'color'+i);assert.equal(scene.scenePhase,0);assert.equal(scene.sceneAnimating,false);}
// Deliberately never execute any animation callback. Latest cards must still be visible.
assert.ok(jobs.every(job=>!job.onFinish));scene.aboutToDisappear();assert.equal(scene.appliedPacket,'');scene.alive=true;scene.syncPacket();assert.equal(scene.cardIds[0],'card99');
const count=jobs.length;scene.packetJson=packet('canvas99','card99','color99',101);scene.syncPacket();assert.equal(jobs.length,count,'identical artwork does not animate again');
assert.ok(source.includes(".position({x:scenePercent"));assert.ok(!source.includes('.translate({x:scenePercent'),'normal positions use host percentages, not animation-sensitive measured absolute translation');
console.log('PASS Form packet controller: 100 interrupted switches, dropped animation callbacks, atomic latest artwork, resumed host and density-independent percent placement.');
