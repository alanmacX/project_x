const assert=require('node:assert/strict'),fs=require('node:fs'),vm=require('node:vm');
const ts=require('/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript');
const source=fs.readFileSync('entry/src/main/ets/pages/Index.ets','utf8');
function block(a,b){return source.slice(source.indexOf(a),source.indexOf(b,source.indexOf(a)));}
let scans=0,layouts=0,shells=0;
const env={exports:{},FridgeCard:class{},ElementBox:class{},EditorViewport:class{},compositionOverflow:()=>{scans++;return {left:10,top:20,right:30,bottom:40};},editorViewport:(w,h,a,width,screen,top,bottom,wide,pane,fringe)=>{layouts++;return {scale:width/w,left:fringe[0],top:fringe[1],height:pane};},cardStorageShell:card=>{shells++;return {...card};}};
const fixture=`class Fixture {
 preview={w:180,h:180,capability:{courses:[1,2]},elements:[{text:'a'}]};screenHeight=800;safeTop=24;safeBottom=24;settingsTab=1;pane=300;width=280;wide=false;
 editingAngle(){return 0;}editorViewportWidth(){return this.width;}editorLandscape(){return this.wide;}previewPaneHeight(){return this.pane;}
 ${block('  private previewViewportCard:', '  private editorScale(')}
 ${block('  private layerBaseSource:', '  @Builder\n  layerThumbnail(')}
} exports.Fixture=Fixture;`;
vm.runInNewContext(ts.transpileModule(fixture,{compilerOptions:{target:ts.ScriptTarget.ES2020}}).outputText,env);
const f=new env.exports.Fixture(),v=f.previewViewport();for(let i=0;i<20;i++)assert.equal(f.previewViewport(),v);assert.equal(scans,1);assert.equal(layouts,1);
f.pane=200;assert.notEqual(f.previewViewport(),v);assert.equal(scans,1,'native sheet height changes reuse cached outline bounds');
for(let pane=200;pane<=450;pane+=2){f.pane=pane;f.previewViewport();}assert.equal(scans,1,'continuous dragging never retraces the card outline');
f.settingsTab=0;assert.equal(f.previewViewport().left,0,'hidden capability does not affect subject fit');
f.safeTop=32;f.previewViewport();assert.equal(scans,2,'safe-area transition repositions without retracing unchanged artwork');
f.preview={...f.preview};f.previewViewport();assert.equal(scans,3,'immutable card updates invalidate fit');
const base=f.layerBaseCard();for(let i=0;i<20;i++)assert.equal(f.layerBaseCard(),base);assert.equal(shells,1);
assert.equal(base.capability,null);assert.equal(base.elements.length,0);assert.equal(f.preview.capability.courses.length,2,'base thumbnail never mutates live course data');assert.equal(f.preview.elements.length,1);
f.preview={...f.preview};assert.notEqual(f.layerBaseCard(),base);assert.equal(shells,2);
console.log('PASS editor frame caching: repeated fit reuse, sheet/safe-area/card invalidation and data-free base thumbnail isolation');
