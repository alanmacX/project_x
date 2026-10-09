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
const backing=fs.readFileSync('entry/src/main/ets/views/ReadingBacking.ets','utf8');
const study=backing.slice(backing.indexOf('if(this.study>0)'),backing.indexOf("} else if(this.blend==='bare')"));
assert(study.includes('clipShape(new PathShape().commands(this.path()))'),'pigment/light share actual silhouette and punched hole');
assert(!study.includes('.shadow(')&&!study.includes('.blur('),'material does not blur rectangular path layers or underlying content');
assert.equal((study.match(/\.radialGradient\(/g)||[]).length,3,'local pigment and cloud light are separate native pools');
for(const v of [1,2,3]) assert.match(env.exports.micaStudyPigment('#EDC03E',v),/^#[0-9a-f]{8}$/i);
for(const tint of ['#000000','#0000FF','#FF0000','#EDC03E','#252525']) for(const v of [1,2,3]) {
 const base=fill(tint,v),pigment=env.exports.micaStudyPigment(tint,v),a=parseInt(base.slice(1,3),16)/255,p=parseInt(pigment.slice(1,3),16)/255;
 const rgb=[3,5,7].map(i=>(parseInt(base.slice(i,i+2),16)*a*(1-p)+parseInt(pigment.slice(i,i+2),16)*p)/255);
 const lin=rgb.map(c=>c<=.04045?c/12.92:((c+.055)/1.055)**2.4);
 assert((lin[0]*.2126+lin[1]*.7152+lin[2]*.0722+.05)/.055>=4.45,'darkest pigment pool keeps legible black text over a black photo');
}

for(const tint of ['#000000','#0000FF','#FF0000','#EDC03E','#71AD73','invalid']) for(const v of [4,5]) {
 const base=env.exports.tactileFill(tint,v),pigment=env.exports.tactilePigment(tint,v);
 const a=parseInt(base.slice(1,3),16)/255,p=parseInt(pigment.slice(1,3),16)/255;
 const rgb=[3,5,7].map(i=>(parseInt(base.slice(i,i+2),16)*a*(1-p)+parseInt(pigment.slice(i,i+2),16)*p)/255);
 const lin=rgb.map(c=>c<=.04045?c/12.92:((c+.055)/1.055)**2.4);
 assert((lin[0]*.2126+lin[1]*.7152+lin[2]*.0722+.05)/.055>=4.5,'tactile tint keeps dark text readable on a dark subject');
 assert.equal(base,env.exports.tactileFill(tint,v),'surface stays stable across redraws');
}
assert.notEqual(env.exports.tactileFill('#EDC03E',4),env.exports.tactileFill('#EDC03E',5));
console.log('PASS tactile prototypes: deterministic sampled surface and readable darkest colour pool.');
