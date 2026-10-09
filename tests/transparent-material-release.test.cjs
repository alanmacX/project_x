const fs=require('node:fs'),vm=require('node:vm'),assert=require('node:assert/strict');
vm.runInThisContext(fs.readFileSync('previewer/shared-models.js','utf8'));
const load=FridgeCore.load,schema=load('CardSchema'),material=load('MicaMaterialStudy');
for(const mode of ['solid','smart','blend','photo','preset','transparent'])assert.equal(schema.normalizeBackground({mode}).mode,mode);
assert.equal(schema.normalizeBackground({mode:'fake'}).mode,'solid');
assert.equal(material.readingMaterialVariant(undefined,undefined),5);
assert.equal(material.readingMaterialVariant(undefined,'matte'),4);
assert.equal(material.readingMaterialVariant(0,'paper'),0);
const cap=schema.normalizeCapability({k:'clock',readingBlend:'cloud',readingMaterial:'matte',readingMaterialStudy:2});
assert.equal(cap.readingMaterial,'matte');assert.equal(cap.readingMaterialStudy,undefined,'experimental appearance cannot override host material after import');
const shared=load('SharedCapability').sharedCapability({...cap,readingTintKey:'local-path-hash'});
assert.equal(shared.readingMaterial,'matte');assert.equal(shared.readingTintKey,undefined,'local source cache key stays private');
for(const k of schema.CAPABILITIES.filter(k=>k!=='album')){
 const card=new schema.FridgeCard();card.capability={k,readingBlend:k==='battery'?'badge':'cloud'};
 const choices=load('EditorVisualChoices').editorVisualChoices(card,'material');
 assert.equal(choices.length,2);
 for(const choice of choices){assert.equal(choice.card.capability.k,k);assert.equal(choice.card.capability.readingBlend,card.capability.readingBlend);assert.equal(choice.card.w,card.w);assert.equal(choice.card.h,card.h);assert(Number.isFinite(choice.scale)&&choice.scale>0);}
 choices[0].card.capability.readingMaterial='matte';assert.equal(card.capability.readingMaterial,undefined);
}
const forms=JSON.parse(fs.readFileSync('entry/src/main/resources/base/profile/form_config.json','utf8')).forms;
assert.equal(forms[0].transparencyEnabled,true);assert.deepEqual(forms[0].supportDimensions,['4*4']);
vm.runInThisContext(fs.readFileSync('previewer/shared-materials.js','utf8'));
vm.runInThisContext(fs.readFileSync('previewer/capabilities.js','utf8'));
const c=new schema.FridgeCard();c.capability={k:'clock',readingBlend:'cloud',readingStyle:'surface'};c.capFree=true;
assert(FridgeReadouts.capability(c,Date.now(),'paper').includes('matte'),'production default reaches web renderer, not just preview IDs');
c.capability.readingMaterial='matte';assert.notEqual(FridgeReadouts.capability(c,0,'same'),FridgeReadouts.capability({...c,capability:{...c.capability,readingMaterial:'paper'}},0,'same'));
console.log('PASS release: transparent background survives normalization, manual Form configuration, portable material selection, detached actual previews and default browser material.');
