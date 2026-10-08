const assert=require('node:assert/strict'),fs=require('node:fs'),path=require('node:path'),vm=require('node:vm');
const ts=require('/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript');
const root=path.resolve(__dirname,'../entry/src/main/ets/model'),cache=new Map();
function load(name){const file=path.resolve(root,name+'.ets');if(cache.has(file))return cache.get(file).exports;const mod={exports:{}};cache.set(file,mod);const code=ts.transpileModule(fs.readFileSync(file,'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText;vm.runInThisContext('(function(require,module,exports){'+code+'\n})',{filename:file})(s=>s==='@kit.ArkTS'?{taskpool:{}}:load(path.relative(root,path.resolve(path.dirname(file),s))),mod,mod.exports);return mod.exports;}
const schema=load('CardSchema'),styles=load('ReadingStylePolicy'),composition=load('ReadingComposition'),layout=load('CanvasLayout'),metrics=load('CapabilityMetrics'),fixtures=load('CloudAcceptanceFixtures'),cloud=load('CloudReadingGeometry'),presentation=load('CapabilityPresentation');
for(const kind of schema.CAPABILITIES){
 if(kind==='album'){assert.deepEqual(styles.readingStyles(kind),[]);continue;}
 assert(styles.readingStyles(kind).includes('cloud'),'cloud selectable for '+kind);
 for(const compact of [false,true])for(const empty of [false,true]){
  const c=fixtures.cloudAcceptanceCard(kind,compact,empty);c.capability.readingBlend='cloud';c.capBox.rot=27;c.capBox.x=-.12;
  const state=schema.defaultState();state.cards=[c];const next=schema.normalizeState(JSON.parse(JSON.stringify(state))).cards[0];
  assert.equal(next.capability.readingBlend,'cloud','cloud survives save and Form normalization');assert.equal(next.capBox.rot,27);assert.equal(next.capBox.x,-.12,'free placement retained');
  const min=layout.cardCapabilityMinimum(c,true);c.capability.readingBlend='bare';const old=layout.cardCapabilityMinimum(c,true);
  assert.deepEqual(min,old,'cloud does not inflate readable minimum '+kind);c.capability.readingBlend='cloud';
  assert(presentation.readingSurface(c.capability,false,false),'all hosts enable cloud even on a solid card');
  assert(composition.isReadingComposition('cloud'));
 }
}
assert.equal(styles.preferredReadingStyle('battery'),'badge');assert.equal(styles.preferredReadingStyle('album'),'');assert.equal(styles.defaultReadingStyle('clock'),'bare','legacy migration is unchanged');
const c=fixtures.cloudAcceptanceCard('clock',true);c.capFree=false;c.capBox.x=0;c.capBox.y=0;assert(composition.compositionOverflow(c,1).left>=cloud.CLOUD_READING_FRINGE,'auto placement caches include cloud fringe');
for(const size of [[70.4,41.6],[100,74],[180,150]])for(const s of [.8,1,2]){
 const commands=cloud.cloudReadingPath(size[0]*s,size[1]*s,s);assert(commands.endsWith(' Z'));assert(!commands.includes('NaN'));
 // The entire existing 8vp inset remains inside the cloud's guaranteed safe rectangle.
 const outerW=size[0]*s+2*cloud.CLOUD_READING_OUTSET*s,outerH=size[1]*s+2*cloud.CLOUD_READING_OUTSET*s;
 const pad=load('ReadingEdgeStudy').edgeStudyInset(outerW,outerH,s)-cloud.CLOUD_READING_OUTSET*s;
 assert(pad<=cloud.CLOUD_READING_PADDING*s+.001);
}
const backing=fs.readFileSync('entry/src/main/ets/views/ReadingBacking.ets','utf8'),src=backing.slice(backing.indexOf("if(this.blend==='cloud')"),backing.indexOf('else if(this.study>0)'));
assert(!src.includes('.shadow(')&&!src.includes('Image(')&&!src.includes('setInterval'),'production cloud has two stable paths, no material experimentation');
console.log('PASS production cloud: all 12 eligible capabilities; restore, free placement, unchanged minima, external fringe, legacy styles and album/battery exceptions.');
