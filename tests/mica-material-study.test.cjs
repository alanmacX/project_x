const assert=require('node:assert/strict'),fs=require('node:fs'),vm=require('node:vm');
const ts=require('/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript');
const env={exports:{}};vm.runInNewContext(ts.transpileModule(fs.readFileSync('entry/src/main/ets/model/MicaMaterialStudy.ets','utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS}}).outputText,env);
const fill=env.exports.micaStudyFill;
for(const tint of ['#FFC928','#4075CA','#71AD73','#000000','#FFFFFF','bad']) {
 const variants=[1,2,3].map(v=>fill(tint,v));
 variants.forEach(v=>{
  assert.match(v,/^#[0-9a-f]{8}$/i);const alpha=parseInt(v.slice(1,3),16)/255;
  const channels=[3,5,7].map(i=>{const c=parseInt(v.slice(i,i+2),16)*alpha/255;return c<=.04045?c/12.92:((c+.055)/1.055)**2.4});
  assert.ok((channels[0]*.2126+channels[1]*.7152+channels[2]*.0722+.05)/.055>=4.45,'dark image keeps readable foreground');
 });
 assert.equal(new Set(variants).size,3);
 assert.ok(parseInt(variants[0].slice(1,3),16)<parseInt(variants[2].slice(1,3),16));
}
assert.equal(env.exports.micaStudyTint([{color:'#252525',weight:.7},{color:'#E5C139',weight:.25},{color:'#C43636',weight:.05}]),'#E5C139','neutral subject shadows do not wash away chromatic accents');
assert.notEqual(fill('#FFC928',2),fill('#4075CA',2),'actual sampled hue reaches native fill');
const comparison=fs.readFileSync('entry/src/main/ets/views/ReadingComparison.ets','utf8');
const update=comparison.slice(comparison.indexOf('private updateMaterial'),comparison.indexOf('aboutToDisappear'));
assert(!update.includes('taskpool')&&!update.includes('queueDepth'),'switching presets neither decodes images nor rebuilds subject depth');
const schema=fs.readFileSync('entry/src/main/ets/model/CardSchema.ets','utf8');
assert(!schema.includes('cap.readingMaterialStudy='),'study selection never gets restored into user artwork');
console.log('PASS mica study: distinct sampled hues, increasing opacity, preview-only choices and decode-free switching.');
