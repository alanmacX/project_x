const assert=require('node:assert/strict'),fs=require('node:fs'),vm=require('node:vm');
const ts=require('/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript');
const index=fs.readFileSync('entry/src/main/ets/pages/Index.ets','utf8');
const open=index.slice(index.indexOf('  private async openScenePanel('),index.indexOf('  private async editTimedScene('));
const toggle=index.slice(index.indexOf('  private async toggleSceneRule('),index.indexOf('  @Builder\n  scheduleEditor()'));
const leave=index.slice(index.indexOf('  private async leaveTimedScene('),index.indexOf('  private async toggleSceneRule('));
const mod={exports:{}};let resolveMigration;
const gate=new Promise(resolve=>resolveMigration=resolve);
vm.runInNewContext(ts.transpileModule(`class Fixture {
 alive=true;pageVisible=true;scenePanelGeneration=0;sceneNavigationBusy=false;canvasChanging=false;editing=false;scheduleOpen=false;backgroundOpen=false;
 store={upgradeTimedScenes:()=>gate};refreshCanvasList(){}syncSchedules(){}templateError(){throw new Error('unexpected failure');}
 sceneToggleRequests={};scheduleGeneration=0;cancelScheduledTransition(){this.scheduleGeneration++;}armScheduleTimer(){}updateScheduledScene(){}
 ${open}
 ${toggle}
 ${leave}
}module.exports=Fixture;`,{compilerOptions:{target:ts.ScriptTarget.ES2020}}).outputText,{module:mod,gate});
(async()=>{
 const f=new mod.exports(),pending=f.openScenePanel();f.scenePanelGeneration++;f.backgroundOpen=true;resolveMigration();await pending;assert.equal(f.scheduleOpen,false,'late timing panel cannot replace a newer background panel');assert.equal(f.backgroundOpen,true);
 await f.openScenePanel();assert.equal(f.scheduleOpen,true,'the latest valid intent still opens');
 f.scheduleOpen=false;f.pageVisible=false;await f.openScenePanel();assert.equal(f.scheduleOpen,false,'hidden app cannot reopen a panel');
 f.pageVisible=true;f.sceneNavigationBusy=true;await f.openScenePanel();assert.equal(f.scheduleOpen,false,'panel cannot race scene navigation');
 const inspector=index.slice(index.indexOf('  editorInspector()'),index.indexOf('  private editorSheetHeight()'));
 assert(inspector.includes('String(this.editorTools().length)'),'equal-count choices keep their native component identity');assert(!inspector.includes('.transition('),'navigation does not fade away when the inspector body changes');
 let rejectOld,resolveLatest;const oldRead=new Promise((resolve,reject)=>rejectOld=reject),latestRead=new Promise(resolve=>resolveLatest=resolve);let reads=0,saves=0;
 const rule={id:'job',targetId:'scene',enabled:false};f.store={catalog:{sceneRules:[rule]},canvasSnapshot:()=>++reads===1?oldRead:latestRead,save:async()=>saves++};
 const oldToggle=f.toggleSceneRule('job',true);await f.toggleSceneRule('job',false);const latestToggle=f.toggleSceneRule('job',true);rejectOld(new Error('late read failure'));await oldToggle;assert.equal(rule.enabled,true,'older failure cannot revert a newer toggle');resolveLatest({cards:[{}]});await latestToggle;assert.equal(rule.enabled,true);assert.equal(saves,2,'only latest accepted intents publish');
let returnTarget='';f.sceneNavigationBusy=false;f.sceneReturnId='deleted';f.store={state:{canvasId:'remaining'},catalog:{activeId:'remaining',canvases:[{id:'remaining'}],scenes:[]},save:async()=>{}};f.loadCanvas=async id=>returnTarget=id;f.refreshCanvasList=()=>{};await f.leaveTimedScene();assert.equal(returnTarget,'remaining','deleted return canvas falls back to a surviving normal canvas');assert.equal(f.sceneNavigationBusy,false);
 console.log('PASS latest home panel intent, hidden/navigation cancellation and stable inspector navigation');
})().catch(e=>{console.error(e);process.exitCode=1;});
