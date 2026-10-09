const assert=require('node:assert/strict'),fs=require('node:fs'),vm=require('node:vm');
const ts=require('/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript');
const board=fs.readFileSync('entry/src/main/ets/views/BoardCard.ets','utf8'),index=fs.readFileSync('entry/src/main/ets/pages/Index.ets','utf8');
function method(source,start,end){const a=source.indexOf(start);assert.ok(a>=0,start);return source.slice(a,source.indexOf(end,a));}
const moduleMock={exports:{}};
const fixture=`class Fixture {
 controlsOnly=true;card={id:'a',w:100,h:120,rot:12};motion={controlId:'',controlPose:{}};
 resizing=true;liveW=150;liveY=20;rotating=false;liveAngle=34;yScaleFactor=2;
 rotationShift(){return {x:7,y:9};}
 shown(){return true;}controlPosition(right,bottom){return {x:right?100:0,y:bottom?100:0};}
 ${method(board,'  private controlRegions():', '  private publishControlPose():')}
 ${method(board,'  private publishControlPose():','  private shadowFringe():')}
 alive=true;timedScene=null;widgetRefreshes=0;store={state:{canvasId:'home'},refreshWidgets:()=>{this.widgetRefreshes++;return Promise.resolve();}};selectedId='a';groupSelecting=true;groupSelection=['a','b'];backgroundGeneration=0;backgroundTimer=-1;scheduledFocusId='';scheduleVisualGeneration=0;
 renderBoard(){}scheduleBackground(){}getUIContext(){return {animateTo:(options,update)=>{update();options.onFinish?.();}};}
 ${method(index,'  private applyScheduledScene(', '  private scheduleOffset(')}
 ${method(index,'  private capabilityHasEditableData():','  private openEditorSection(')}
 preview={capability:{k:'calendar'}};layerId='capability';elementPreview={kind:'text'};
} module.exports=Fixture;`;
vm.runInNewContext(ts.transpileModule(fixture,{compilerOptions:{target:ts.ScriptTarget.ES2020}}).outputText,{module:moduleMock,Curve:{Friction:'friction'},HitTestMode:{Default:'default',None:'none'}});
const f=new moduleMock.exports();assert.equal(f.controlRegions().length,4);assert.equal(f.controlRegions()[1].width,44);f.card.y=10;f.publishControlPose();
assert.equal(f.motion.controlId,'a');assert.equal(f.motion.controlPose.scale,1.5);assert.equal(f.motion.controlPose.y,20);assert.equal(f.motion.controlPose.angle,12);
f.controlsOnly=false;f.resizing=false;assert.equal(f.resizeScale(),1.5,'artwork consumes the same resize pose as the controls');
f.controlsOnly=true;f.rotating=true;f.publishControlPose();assert.equal(f.motion.controlPose.angle,34);
f.motion.controlId='b';f.clearControlPose();assert.equal(f.motion.controlId,'b','stale portal cannot clear the next card gesture');
f.motion.controlId='a';f.clearControlPose();f.controlsOnly=false;assert.equal(f.resizeScale(),1,'cancel restores base geometry');
for(const k of ['clock','date','calendar','lunar','battery','dayprogress','yearprogress']){f.preview.capability={k};assert.ok(!f.editorTools().includes('数据'),k);}
for(const k of ['countdown','anniversary','worldclock','agenda','timetable']){f.preview.capability={k};assert.ok(f.editorTools().includes('数据'),k);}
f.preview.capability={k:'album'};assert.equal(f.editorTools()[1],'封面与资料');
const scene={key:'base',normalState:{canvasId:'home'},state:{canvasId:'home',background:{}},ruleId:'',focusId:''};f.applyScheduledScene(scene);assert.equal(f.selectedId,'a','same-scene refresh preserves selection');assert.equal(f.groupSelection.length,2);f.applyScheduledScene({...scene,key:'scene:alert',ruleId:'alert'});assert.equal(f.selectedId,'','actual scene change clears selection');assert.equal(f.widgetRefreshes,1,'time projection triggers widget IPC even without scene-data edits');
const commit=method(index,'  private commitGeometry(','  private async pickImage(');
assert.ok(!commit.includes('bringToFront'),'controls must not permanently change card stacking');
assert.match(board,/aboutToDisappear\(\): void \{ this.alive = false; this.clearControlPose\(\)/);
console.log('PASS control portal: shared resize/rotation, cancellation ownership, editable-data availability and stable stacking');
