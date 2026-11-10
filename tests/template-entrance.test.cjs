const fs=require('node:fs'),vm=require('node:vm'),ts=require('typescript'),assert=require('node:assert/strict');
const core=vm.createContext({});vm.runInContext(fs.readFileSync('previewer/shared-models.js','utf8'),core);
const moduleEnv={exports:{},require:p=>core.FridgeCore.load(p.split('/').pop())};
vm.runInNewContext(ts.transpileModule(fs.readFileSync('entry/src/main/ets/model/CustomizerTransition.ets','utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,moduleEnv);
const {customizerEntrancePose,CUSTOMIZER_ENTER_DURATION}=moduleEnv.exports;assert.equal(CUSTOMIZER_ENTER_DURATION,380);
let cases=0;
for(const aspect of [.5,1,2])for(const size of [28,180,300])for(const angle of [-30,0,20]){
 const from={x:37,y:410,w:size,h:size/aspect,rot:angle},to={x:28,y:120,w:320,h:320/aspect,rot:0},p=customizerEntrancePose(from,to);
 assert.ok(Math.abs(to.x+to.w/2+p.x-(from.x+from.w/2))<1e-8);
 assert.ok(Math.abs(to.y+to.h/2+p.y-(from.y+from.h/2))<1e-8);
 assert.ok(Math.abs(to.w*p.scale-from.w)<1e-8);assert.ok(Math.abs(to.h*p.scale-from.h)<1e-8);assert.equal(p.angle,angle);cases++;
}
const source=fs.readFileSync('entry/src/main/ets/views/CardCustomizer.ets','utf8'),method=source.slice(source.indexOf('  private measureEntrance('),source.indexOf('  private toast('));
const sceneEnv={exports:{},require:p=>core.FridgeCore.load(p.split('/').pop())};vm.runInNewContext(ts.transpileModule(fs.readFileSync('entry/src/main/ets/model/SceneLayout.ets','utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,sceneEnv);
const env={exports:{},customizerEntrancePose,CUSTOMIZER_ENTER_DURATION,SceneRect:sceneEnv.exports.SceneRect,motionFrameRate:()=>({min:60,max:60,expected:60}),Curve:{Friction:'friction'},CustomizerFrame:class{constructor(action){this.action=action;}}};
vm.runInNewContext(ts.transpileModule(`export class Session {entranceRunning=true;entranceMeasured=false;entranceGeneration=0;alive=true;entranceVisible=false;entranceChrome=0;entranceOrigin={x:30,y:400,w:240,h:240,rot:15};queue=[];starts=0;ends=0;animation=null;onEntranceStart(){this.starts++;}onEntranceEnd(){this.ends++;}getUIContext(){return{postFrameCallback:f=>this.queue.push(f),animateTo:(options,change)=>{this.animation=options;change();}};} ${method}}`,{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,env);
const area={width:320,height:320,globalPosition:{x:28,y:120}},s=new env.exports.Session();s.measureEntrance(area);assert.equal(s.entranceVisible,false);assert.equal(s.queue.length,1);assert.equal(s.starts,0);
s.queue.shift().action();assert.equal(s.entranceVisible,true);assert.equal(s.starts,1);assert.equal(s.animation,null,'surface handoff is committed before motion');s.queue.shift().action();assert.equal(s.animation.duration,380);assert.equal(s.entranceScale,1);assert.equal(s.entranceX,0);assert.equal(s.entranceY,0);assert.equal(s.entranceChrome,1);s.animation.onFinish();assert.equal(s.entranceRunning,false);assert.equal(s.ends,1);
const cancelled=new env.exports.Session();cancelled.measureEntrance(area);cancelled.alive=false;cancelled.entranceGeneration++;cancelled.queue.shift().action();assert.equal(cancelled.starts,0);assert.equal(cancelled.animation,null);
const material=new env.exports.Session();material.entranceRunning=false;material.measureEntrance(area);assert.equal(material.queue.length,0);
console.log(`PASS template entrance: ${cases} origin/preview poses; measured-frame handoff, original 380ms timing, completion, disposed-session guard and material-library exclusion`);
// Exercise the actual exit methods: no save/unmount before the landing frame.
const exitMethods=source.slice(source.indexOf('  private requestExit('),source.indexOf('  private openMaterials('));
const exitEnv={...env,exports:{},CUSTOMIZER_EXIT_DURATION:moduleEnv.exports.CUSTOMIZER_EXIT_DURATION,cardViewSnapshot:c=>structuredClone(c)};
vm.runInNewContext(ts.transpileModule(`export class ExitSession {
 alive=true;entranceRunning=false;exitRunning=false;busy=false;animateEntrance=true;libraryMode=false;sheet=false;screen='edit';entranceGeneration=0;
 initialCard={id:'clock',palette:'original'};face={id:'clock',palette:'edited'};
 previewRect={x:28,y:120,w:320,h:320};returnOrigin={x:40,y:280,w:220,h:220,rot:12};
 starts=0;saved=[];cancelled=0;animation=null;onExitStart(){this.starts++;}onDone(card){this.saved.push(card);}onCancel(){this.cancelled++;}
 closeSheet(){this.sheet=false;}getUIContext(){return {animateTo:(options,change)=>{this.animation=options;change();}};}
 ${exitMethods}
}`,{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,exitEnv);
const done=new exitEnv.exports.ExitSession();done.finishFace();
assert.equal(done.animation.duration,340);assert.equal(done.starts,1);assert.equal(done.exitRunning,true);assert.equal(done.saved.length,0);assert.equal(done.entranceChrome,0);
assert.equal(done.entranceScale,220/320,'return to the actual canvas card, never the 28vp insertion origin');assert.equal(done.entranceAngle,12);
assert.equal(done.previewRect.x+160+done.entranceX,40+110);assert.equal(done.previewRect.y+160+done.entranceY,280+110);
done.finishFace();done.cancelFace();assert.equal(done.starts,1,'repeat taps cannot double-save or interrupt landing');done.animation.onFinish();assert.equal(done.saved.length,1);assert.equal(done.saved[0].palette,'edited');assert.equal(done.cancelled,0);
const cancel=new exitEnv.exports.ExitSession();cancel.cancelFace();assert.equal(cancel.face.palette,'original');assert.equal(cancel.cancelled,0);cancel.animation.onFinish();assert.equal(cancel.cancelled,1);assert.equal(cancel.saved.length,0);
const back=new exitEnv.exports.ExitSession();back.sheet=true;back.requestExit();assert.equal(back.sheet,false);assert.equal(back.starts,0);back.requestExit();assert.equal(back.starts,1);back.animation.onFinish();assert.equal(back.cancelled,1);
const stale=new exitEnv.exports.ExitSession();stale.finishFace();stale.alive=false;stale.entranceGeneration++;stale.animation.onFinish();assert.equal(stale.saved.length,0);
for(const field of ['entranceRunning','busy']){const blocked=new exitEnv.exports.ExitSession();blocked[field]=true;blocked.finishFace();assert.equal(blocked.starts,0);assert.equal(blocked.saved.length,0);}
for(const field of ['libraryMode','animateEntrance']){const immediate=new exitEnv.exports.ExitSession();immediate[field]=field==='libraryMode';immediate.cancelFace();assert.equal(immediate.animation,null);assert.equal(immediate.cancelled,1);}
console.log('PASS template exit: 340ms reverse pose, delayed single save, cancel discard, system back/sheet dismissal, repeated-input/disposal guards, material and advanced-panel exclusion');
