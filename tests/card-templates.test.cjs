process.env.TZ='Asia/Shanghai';
const assert=require('node:assert/strict'),fs=require('node:fs'),vm=require('node:vm');
const ctx=vm.createContext({});vm.runInContext(fs.readFileSync('previewer/shared-models.js','utf8'),ctx);
const load=n=>ctx.FridgeCore.load(n),s=load('CardSchema'),t=load('CardTemplate'),f=load('TemplateFactory'),r=load('TemplateScene'),snap=load('CardViewSnapshot'),p=load('TemplatePackage'),layout=load('CanvasLayout');
const singles=t.CARD_TEMPLATES.filter(t=>t.kind!=='ensemble');assert.equal(singles.length,39);assert.equal(t.CARD_TEMPLATES.length,44);
let id=0;const now=Date.parse('2026-11-01T10:08:00+08:00');
for(const item of t.CARD_TEMPLATES){
 for(const aspect of [0.3,0.9,1,2,3]){
  const cards=f.makeTemplateCards(item.id,aspect,()=>String(++id),now);assert.equal(cards.length,item.sources.length);
  for(const card of cards){
   assert.ok(card.x>=0&&card.x+card.w<=344.001,item.id+' horizontal recipe fit');assert.ok(card.y/470*(344/aspect)+card.h<=344/aspect+.001,item.id+' vertical recipe fit');
   const before=JSON.stringify(card),scene=r.cardTemplateScene(card,now);assert.equal(JSON.stringify(card),before,'render must not mutate card');assert.ok(scene.marks.length>0,item.id);for(const m of scene.marks){for(const k of ['x','y','w','h','angle'])assert.ok(Number.isFinite(m[k]),item.id+' '+k);}
   const state=s.defaultState();state.cards=[card];const restored=s.normalizeState(JSON.parse(JSON.stringify(state))).cards[0];assert.equal(restored.template.id,card.template.id);
   const stored=snap.cardStorageShell(card),view=snap.cardViewSnapshot(card);assert.equal(view.template.id,card.template.id);view.template.palette='ink';assert.equal(card.template.palette,'');assert.equal(stored.template.id,card.template.id);
   const pack=p.packageScene(JSON.stringify(state),'');assert.equal(pack.version,3);assert.equal(p.readPackage(JSON.stringify(pack)).state.cards[0].template.id,card.template.id);
   const old=JSON.parse(JSON.stringify(pack));old.version=2;assert.throws(()=>p.readPackage(JSON.stringify(old)));
   card.template.fill=true;layout.clampCardGeometry(card,344,470,344/aspect);assert.equal(card.x,0);assert.equal(card.y,0);assert.equal(card.w,344);assert.equal(card.h,344/aspect);assert.ok(layout.ensureCapabilitySize(card),'full template must pass editor size gate');state.canvasAspect=aspect;assert.equal(s.normalizeState(JSON.parse(JSON.stringify(state))).cards[0].h,344/aspect,'full height must survive storage on tall canvases');
  }
 }
}
const dial=f.makeTemplateCards('dial',1,()=>String(++id),now)[0],marks=r.cardTemplateScene(dial,now).marks,rects=marks.filter(m=>m.kind==='rect');assert.equal(rects.length,2);assert.equal(marks.filter(m=>m.kind==='text').length,0);assert.equal(rects[0].angle,48);assert.equal(rects[1].angle,304);assert.ok(rects.every(m=>m.end&&m.h>m.w));
const photo=f.makeTemplateCards('portrait',1,()=>String(++id),now)[0],el=new s.CanvasElement();Object.assign(el,{kind:'image',src:'file:///photo.webp',depthForeground:'file:///subject.png',depthEnabled:true,depthSourceAspect:1});photo.elements=[el];let scene=r.cardTemplateScene(photo,now);assert.ok(scene.marks.some(m=>m.layer===3&&m.src===el.depthForeground));photo.template.depth=false;assert.ok(!r.cardTemplateScene(photo,now).marks.some(m=>m.layer===3));
const state=s.defaultState();state.cards=[new s.FridgeCard()];assert.equal(p.packageScene(JSON.stringify(state),'').version,1);assert.equal(s.normalizeState(state).cards[0].template,undefined);
console.log('Native card templates: 39 designs / 5 recipes, 5 canvas ratios, round trips, palette axes, depth layering passed');

const modelRoot=require('node:path').resolve('entry/src/main/ets/model'),ts=require('/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript'),moduleCache=new Map();
function nativeLoad(name){if(moduleCache.has(name))return moduleCache.get(name).exports;const mod={exports:{}};moduleCache.set(name,mod);const code=ts.transpileModule(fs.readFileSync(modelRoot+'/'+name+'.ets','utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText;vm.runInThisContext('(function(require,module,exports){'+code+'\n})')(key=>nativeLoad(key.replace('./','')),mod,mod.exports);return mod.exports;}
const distribution=nativeLoad('CardColorDistribution'),nativeFactory=nativeLoad('TemplateFactory'),paletteCard=nativeFactory.makeTemplateCards('dial',1,()=> 'palette')[0],raster=distribution.cardColorRaster(paletteCard,new Map(),32),colors=new Set();for(let i=0;i<raster.rgba.length;i+=4)colors.add(Array.from(raster.rgba.slice(i,i+3)).join(','));assert.ok(colors.size>30,'smart background must retain gradient colors and their positions, not sample the old white card backing');
const portrait=f.makeTemplateCards('portrait',1,()=> 'portrait')[0];portrait.groupId='group';portrait.depthGroup=true;portrait.elements=[el];const companion=f.makeTemplateCards('date-paper',1,()=> 'companion')[0];companion.groupId='group';assert.equal(load('DepthComposition').depthRenderCards([portrait,companion]).length,2,'template foreground stays internal; group projection cannot duplicate the whole template');
const full=f.makeTemplateCards('dial',1,()=> 'full')[0];full.template.fill=true;p.fitImportedCanvas([full],1,2);assert.equal(full.w,344);assert.equal(full.h,172);assert.equal(full.x,0);assert.equal(full.y,0);
console.log('Native templates: responsive recipes, gradient color distribution, internal depth projection and full-canvas import adaptation passed');

const history=new (nativeLoad('CardEditHistory').CardEditHistory)(),editing=nativeFactory.makeTemplateCards('dial',1,()=> 'history')[0];history.reset(editing);editing.template.palette='cobalt';history.record(editing);assert.ok(history.canUndo(),'palette-only changes must enter undo history');assert.equal(history.undo().template.palette,'');assert.equal(history.redo().template.palette,'cobalt');editing.template.id='portrait';history.record(editing);assert.equal(history.undo().template.id,'dial');
console.log('Native templates: full-size editor gate and template-only undo/redo changes passed');

const paletteModel=nativeLoad('CompositionPalette'),combo=nativeFactory.makeTemplateCards('mix-modular',1,()=>String(++id),now),unrelated=nativeFactory.makeTemplateCards('standby',1,()=>String(++id),now)[0];unrelated.groupId=combo[0].groupId;unrelated.template.palette='cream';combo[1].template.palette='cream';
const peerCards=combo.concat([unrelated]),paletteHistory=new (nativeLoad('CardEditHistory').CardEditHistory)();paletteHistory.reset(combo[0],paletteModel.compositionPaletteState(combo[0],peerCards));
paletteModel.setCompositionPalette(combo[0],peerCards,'cobalt');paletteHistory.record(combo[0],'',paletteModel.compositionPaletteState(combo[0],peerCards));assert.ok(combo.every(c=>c.template.palette==='cobalt'));assert.equal(unrelated.template.palette,'cream');
peerCards[0]=paletteHistory.undo();paletteModel.restoreCompositionPalette(paletteHistory.paletteState(),peerCards);assert.deepEqual(peerCards.map(c=>c.template.palette),['','cream','','cream'],'undo restores exact per-role palettes including imported customization');
peerCards[0]=paletteHistory.redo();paletteModel.restoreCompositionPalette(paletteHistory.paletteState(),peerCards);assert.deepEqual(peerCards.map(c=>c.template.palette),['cobalt','cobalt','cobalt','cream']);
for(const c of peerCards.slice(0,3)){const model=nativeLoad('TemplateScene'),scene=model.cardTemplateScene(c,now);assert.deepEqual(Array.from(model.templateColors(c)),[scene.background,scene.ink,scene.accent]);}
console.log('PASS unified composition palettes: group switch, exact undo/redo of mixed previous palettes, matching swatches and legacy group isolation');
