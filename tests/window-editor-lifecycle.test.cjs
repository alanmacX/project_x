const assert=require('node:assert/strict'),fs=require('node:fs'),vm=require('node:vm');
const ts=require('/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript');
const source=fs.readFileSync('entry/src/main/ets/pages/Index.ets','utf8');
function method(start,end){return source.slice(source.indexOf(start),source.indexOf(end,source.indexOf(start)));}
assert.match(source, /@State tick: number = Math\.floor\(Date\.now\(\)\/60000\)\*60000;/, 'initial clock uses the same minute bucket as foreground reconciliation');
const routes=[],reads=[],saves=[];
const context={exports:{},AppStorage:{setOrCreate:(key,value)=>routes.push([key,value])},DismissReason:{PRESS_BACK:0,SLIDE_DOWN:3},needsDataRefresh:cap=>!!cap,capabilityRequestKey:cap=>cap.k,readCapability:async cap=>{reads.push(cap.k);return {...cap,percent:cap.percent+1};}};
const fixture=`class Fixture {
 alive=true;ready=true;context={};appBackgrounded=false;editing=false;viewing=false;pageVisible=true;appWindowFocused=true;foregroundGeneration=0;
 editorSheetOpen=true;editorBackPending=false;arriving=false;heroActive=false;activeBoardId='';layerDrag='';gestureGroup='';refreshingCapabilities=false;
 routeCanvasId='canvas_a';viewRouteId='';routedId='';closed=0;collapsed=0;refreshes=0;renders=0;
 store={state:{canvasId:'canvas_a',cards:[{id:'a',capability:{k:'battery',percent:30}},{id:'b',capability:{k:'battery',percent:40}}]},init(){throw Error('unexpected full reload');},findCard(id){return this.state.cards.find(c=>c.id===id);}};
 closeEditor(){this.closed++;}expandEditor(){this.collapsed++;}scheduleForegroundRefresh(){this.refreshes++;}
 render(){this.renders++;}persist(){saves.push(this.store.state.cards.map(c=>c.capability.percent));}updateScheduledScene(){}
 ${method('  private dismissEditorSheet(', '  private expandEditor(')}
 ${method('  private async reloadWidgetRoute(', '  private calendarAction(')}
 ${method('  private async refreshCapabilities(', '\n\n\n')}
 } exports.Fixture=Fixture;`;
vm.runInNewContext(ts.transpileModule(fixture,{compilerOptions:{target:ts.ScriptTarget.ES2020}}).outputText,{...context,saves});
(async()=>{
 const f=new context.exports.Fixture();let dismissed=0;f.dismissEditorSheet({reason:0,dismiss(){dismissed++;}});assert.equal(dismissed,1,'native overlay is released');assert.equal(f.editorSheetOpen,false,'sheet cannot reopen during the exit animation');assert.equal(f.closed,1);assert.equal(f.collapsed,0,'back exits instead of only collapsing');
 f.heroActive=true;f.dismissEditorSheet({reason:0,dismiss(){}});assert.equal(f.editorBackPending,true,'back during entrance is retained rather than lost');assert.equal(f.closed,1);f.heroActive=false;
 f.dismissEditorSheet({reason:3});assert.equal(f.collapsed,1);assert.equal(f.closed,1,'dragging the sheet down does not leave the editor');
 await f.reloadWidgetRoute();assert.equal(f.refreshes,1);assert.deepEqual(routes,[['routeCanvasId','']]);
 f.editing=true;await f.reloadWidgetRoute();assert.equal(f.editing,true,'same-canvas warm resume preserves in-progress editing');
 assert.equal(saves.length,0,'navigation must not publish a replacement scene');
 await f.refreshCapabilities();assert.equal(f.renders,1);assert.equal(saves.length,1);assert.deepEqual(Array.from(saves[0]),[31,41],'batch results produce one coherent render and persistence');
 // Pause one result, then begin a gesture before it arrives.
 let release;const pending=new Promise(resolve=>release=resolve);
 const isolated={exports:{},AppStorage:context.AppStorage,DismissReason:context.DismissReason,needsDataRefresh:()=>true,capabilityRequestKey:cap=>cap.k,readCapability:async cap=>{await pending;return {...cap,percent:99};},saves:[]};
 vm.runInNewContext(ts.transpileModule(fixture,{compilerOptions:{target:ts.ScriptTarget.ES2020}}).outputText,isolated);
 const moving=new isolated.exports.Fixture(),job=moving.refreshCapabilities();moving.layerDrag='capability';release();await job;
 assert.equal(moving.renders,0);assert.equal(moving.store.state.cards[0].capability.percent,30,'late results cannot mutate artwork during a gesture');assert.equal(moving.refreshes,1,'defer reconciliation until interaction settles');
 console.log('PASS native sheet back semantics, unchanged widget route reuse, atomic capability refresh and late-result gesture isolation');
})().catch(e=>{console.error(e);process.exitCode=1;});
