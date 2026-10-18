const assert=require('node:assert/strict'),fs=require('node:fs'),vm=require('node:vm'),ts=require('/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript');
const code=ts.transpileModule(fs.readFileSync('entry/src/main/ets/model/ChromeMaterial.ets','utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText;
(async()=>{for(const [api,supported] of [[24,false],[26,false],[26,true]]){
 const styles={exports:{}};vm.runInNewContext(ts.transpileModule(fs.readFileSync('entry/src/main/ets/model/AppDesign.ets','utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS}}).outputText,styles);
 const exports={},native={default:{isImmersiveMaterialSupported:()=>supported,ImmersiveStyle:{REGULAR:1,THIN:0},ImmersiveMaterial:class{constructor(options){this.options=options;}}}};
 vm.runInNewContext(code,{exports,require:name=>name==='./AppDesign'?styles.exports:name==='@kit.BasicServicesKit'?{deviceInfo:{sdkApiVersion:api}}:native,Color:{Transparent:0},BlurStyle:{COMPONENT_THIN:1,NONE:0}});
 await exports.prepareChromeMaterial();
 for(const dark of [false,true])for(const emphasized of [false,true]){
  const calls={},control=new Proxy({}, {get:(_,key)=>(value)=>{calls[key]=value;return control;}});
  exports.immersiveChrome(dark,emphasized).applyNormalAttribute(control);
  assert.equal(calls.border.width,api===26&&supported||emphasized?0:.5);
  if(api===26&&supported){assert.ok(calls.systemMaterial);assert.equal(calls.backgroundBlurStyle,undefined,'No extra blur stacked under system material');}
  else {assert.ok(calls.shadow);if(!emphasized)assert.equal(calls.backgroundBlurStyle,1);}
 }
 for(const dark of [false,true])for(const emphasized of [false,true]){
  const calls={},control=new Proxy({}, {get:(_,key)=>(value)=>{calls[key]=value;return control;}});exports.opaqueChrome(dark,emphasized).applyNormalAttribute(control);
  assert.match(calls.backgroundColor,/^#[0-9A-Fa-f]{6}$/);assert.equal(calls.backgroundBlurStyle,0);assert.equal(calls.systemMaterial,undefined);assert(calls.shadow,'opaque fill retains floating relief');
 }
}console.log('PASS API24 fallback and supported/unsupported API26 chrome: exactly one curved edge and no double blur.');})().catch(e=>{console.error(e);process.exitCode=1;});
