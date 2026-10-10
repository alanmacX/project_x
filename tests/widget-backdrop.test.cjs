const assert=require('node:assert/strict'),fs=require('node:fs'),vm=require('node:vm');
const ts=require('/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript');
const source=fs.readFileSync('entry/src/main/ets/widget/pages/FridgeWidgetCard.ets','utf8');
const controller=source.slice(source.indexOf('  private refresh()'),source.indexOf('  private syncPacket()'));
const jobs=[],env={exports:{},Curve:{EaseInOut:0},animateTo:(options,update)=>{update();jobs.push(options);}};
vm.runInNewContext(ts.transpileModule('export class Harness {aboutToAppear(){this.alive=true;}aboutToDisappear(){this.alive=false;this.generation++;this.incoming=null;}'+controller+'}',{compilerOptions:{module:ts.ModuleKind.CommonJS}}).outputText,env);
const view=new env.exports.Harness();Object.assign(view,{canvasBackground:{mode:'solid',color:'white',src:''},sceneReady:false,generation:0,mix:0,hasArtwork:false,incoming:null});
view.aboutToAppear();view.canvasBackground={mode:'photo',src:'first',color:'cream'};view.sceneReady=true;view.refresh();assert.equal(view.displayed.src,'first');assert.equal(jobs.length,0,'cold artwork appears immediately');
view.refresh();assert.equal(jobs.length,0,'identical background is free');
view.canvasBackground={mode:'photo',src:'second',color:'cream'};view.refresh();assert.equal(view.displayed.src,'first');assert.equal(jobs.length,0,'old image stays until new decode completes');
view.imageReady('first');assert.equal(jobs.length,0,'outdated image event ignored');view.imageReady('second');assert.equal(view.mix,1,'new decoded artwork is visible even if completion is dropped');assert.equal(jobs[0].duration,240);
const stale=jobs.shift();view.canvasBackground={mode:'solid',src:'',color:'yellow'};view.refresh();stale.onFinish();assert.equal(view.incoming.color,'yellow','stale completion cannot erase newer artwork');
jobs.shift().onFinish();assert.equal(view.displayed.color,'yellow');assert.equal(view.incoming,null);
view.canvasBackground={mode:'photo',src:'third',color:'yellow'};view.refresh();view.imageReady('third');const hidden=jobs.shift();view.aboutToDisappear();hidden.onFinish();assert.equal(jobs.length,0);assert.equal(view.incoming,null);
const form=fs.readFileSync('entry/src/main/ets/widget/pages/FridgeWidgetCard.ets','utf8');let routed;
const open=form.slice(form.indexOf('  private open()'),form.indexOf('  build()'));
const routerEnv={exports:{},postCardAction:(_,action)=>routed=action};vm.runInNewContext(ts.transpileModule('export class Router {'+open+'}',{compilerOptions:{module:ts.ModuleKind.CommonJS}}).outputText,routerEnv);
const router=new routerEnv.exports.Router();Object.assign(router,{displayCanvasId:'shown',canvasId:'base',dim:'4*4',sceneAnimating:true,widthValue:()=>400,heightValue:()=>300});router.open();assert.equal(routed.params.canvasId,'shown');assert.equal(routed.params.viewCardId,'');assert.equal(routed.action,'router');assert(!form.includes('widgetHit'));assert(!form.includes('Button('));
console.log('PASS Form backdrop: immediate cold load, decode-gated fade, repeated/interrupting packets, hidden cleanup and whole-widget routing.');

assert.ok(form.trimEnd().endsWith(".accessibilityText('打开冰箱贴画布')\n      .onClick(() => this.open())\n  }\n}"), 'root Form directly owns the launch action');
assert.ok(!form.includes('HitTestMode.Block')&&!form.includes(".accessibilityLevel('no')"), 'no separate blocking overlay or inaccessible root');
const clockSource=form.slice(form.indexOf('  private syncRenderClock()'),form.indexOf("  @LocalStorageProp('canvasId')"));
const clockEnv={exports:{},Date};vm.runInNewContext(ts.transpileModule('export class Clock {'+clockSource+'}',{compilerOptions:{module:ts.ModuleKind.CommonJS}}).outputText,clockEnv);
const clock=new clockEnv.exports.Clock();let writes=0,value=120000;
Object.defineProperty(clock,'renderTick',{get:()=>value,set:v=>{value=v;writes++;}});
clock.rev=120100;clock.syncRenderClock();clock.rev=150000;clock.syncRenderClock();assert.equal(writes,0,'identical minute revisions do not dirty every Form card');
clock.rev=180001;clock.syncRenderClock();assert.equal(writes,1);assert.equal(value,180000,'time-based cards still advance at the next minute');
assert.match(form,/tick:capabilityRenderTick\(this.cardMap\[id\]\.capability,this.renderTick\)/);
assert.match(form,/\.renderGroup\(this.incoming===null\)/,'whole bounded Form caches native launch scaling, background fades stay live');
console.log('PASS Form render clock: repeated revisions do not rerender unchanged artwork; minute boundaries still update.');

// Both decode-gated background layers must be siblings of the authored viewport.
// Otherwise a non-square desktop host exposes solid-colour orientation bands.
const build=form.slice(form.indexOf('  build()'));
const artworkStart=build.indexOf('Stack({alignContent:Alignment.TopStart})');
const fitStart=build.indexOf('.width(this.viewport().w/this.widthValue()');
assert.ok(artworkStart>build.lastIndexOf('Image('), 'all background image layers fill the host, outside the fitted artwork');
assert.ok(artworkStart<build.indexOf('ForEach(this.cardIds')&&fitStart>build.indexOf('ForEach(this.cardIds'), 'card geometry still uses the unchanged authored viewport');
assert.ok(build.indexOf('CanvasFrame({')>fitStart, 'physical frame remains outside the authored viewport');
console.log('PASS full-host backdrop and frame with uniformly fitted authored cards; no letterbox background layer.');
