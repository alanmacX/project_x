const assert=require('node:assert/strict'),fs=require('node:fs'),vm=require('node:vm');
const ts=require('/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript');
const page=fs.readFileSync('entry/src/main/ets/pages/Index.ets','utf8');
const start=page.indexOf('  private async refreshCapabilities():');
const method=page.slice(start,page.indexOf('\n\n\n  build()',start));
let requests=0,resolveData;
const sandbox={exports:{},cardCapabilities:card=>(card.capability?[card.capability]:[]).concat(card.template?.sources??[]),replaceCardCapability:(card,old,next)=>{if(card.capability===old)card.capability=next;else card.template.sources[card.template.sources.indexOf(old)]=next;},needsDataRefresh:()=>true,capabilityRequestKey:()=>'',readCapability:()=>{requests++;return new Promise(resolve=>resolveData=resolve);}};
vm.runInNewContext(ts.transpileModule(`export class Fixture {
 ready=true;alive=true;pageVisible=true;appWindowFocused=true;appBackgrounded=false;canvasChanging=false;galleryTransitioning=false;arriving=false;heroActive=false;activeBoardId='';layerDrag='';gestureGroup='';refreshingCapabilities=false;context={};foregroundGeneration=0;renderCount=0;deferred=0;
 card={id:'photo',capability:{k:'weather',temperature:20}};
 store={state:{canvasId:'a',cards:[this.card]},findCard:()=>this.card};
 render(){this.renderCount++;}persist(){}updateScheduledScene(){}scheduleForegroundRefresh(){this.deferred++;}
 ${method}
}`,{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,sandbox);
(async()=>{
 const f=new sandbox.exports.Fixture();f.galleryTransitioning=true;
 await f.refreshCapabilities();assert.equal(requests,0,'landing phase must not start network/data refreshes');
 f.galleryTransitioning=false;const refresh=f.refreshCapabilities();assert.equal(requests,1);
 f.galleryTransitioning=true;resolveData({k:'weather',temperature:21});await refresh;
 assert.equal(f.renderCount,0,'in-flight results cannot replace card textures during the transition');
 assert.equal(f.card.capability.temperature,20);assert.equal(f.deferred,1);assert.equal(f.refreshingCapabilities,false);
 f.galleryTransitioning=false;const settled=f.refreshCapabilities();resolveData({k:'weather',temperature:22});await settled;
 assert.equal(f.renderCount,1);assert.equal(f.card.capability.temperature,22,'deferred content updates resume after landing');
 console.log('PASS gallery surface readiness: no refresh starts or texture replacement during landing; settled refresh still applies.');
})().catch(e=>{console.error(e);process.exitCode=1;});
