const fs=require('node:fs'),vm=require('node:vm'),assert=require('node:assert/strict');
vm.runInThisContext(fs.readFileSync('previewer/shared-models.js','utf8'));
const schema=FridgeCore.load('CardSchema'),depth=FridgeCore.load('CardDepth');
for(const style of ['auto','light','dark','none'])assert.equal(schema.normalizeBackground({mode:'transparent',transparentFrame:style}).transparentFrame,style);
assert.equal(schema.normalizeBackground({mode:'transparent',transparentFrame:'wrong'}).transparentFrame,'auto');
for(const radius of [1.6,9,13]){
 const amplitude=.16,bands=depth.contourReliefBands(radius,amplitude);let a=0,previous=Infinity;
 for(const band of bands){assert(band.extra<=previous&&band.opacity>=0&&band.opacity<=1);previous=band.extra;a=a+(1-a)*amplitude*band.opacity;}
 assert(Math.abs(a-amplitude)<.003,'soft relief conserves shadow opacity, avoiding stacked dark halos');
}
vm.runInThisContext(fs.readFileSync('previewer/shared-materials.js','utf8'));vm.runInThisContext(fs.readFileSync('previewer/capabilities.js','utf8'));vm.runInThisContext(fs.readFileSync('previewer/renderer.js','utf8'));
const state=new schema.FridgeState();state.background=schema.normalizeBackground({mode:'transparent',transparentFrame:'dark'});
const result=FridgeWeb.renderPackage({state,assets:[]},400,0);
assert(!result.layers.background.includes('<rect'),'transparent canvas never regains an opaque browser background');assert(result.layers.frame.includes('#292B2D'));assert(result.layers.frame.includes('fill="none"'));
state.background.transparentFrame='none';assert.equal(FridgeWeb.renderPackage({state,assets:[]},400,0).layers.frame,'');
console.log('PASS hollow frame normalization and transparent renderer; Gaussian contour relief alpha conservation.');
