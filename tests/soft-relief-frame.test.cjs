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
assert(!result.layers.background.includes('<rect'),'transparent canvas never regains an opaque browser background');assert.equal((result.layers.frame.match(/<image /g)||[]).length,8);assert(!result.layers.frame.includes('<rect'));
state.background.frameStyle='none';assert.equal(FridgeWeb.renderPackage({state,assets:[]},400,0).layers.frame,'');
console.log('PASS hollow frame normalization and transparent renderer; Gaussian contour relief alpha conservation.');

const nativeFrame=fs.readFileSync('entry/src/main/ets/views/CanvasFrame.ets','utf8'),index=fs.readFileSync('entry/src/main/ets/pages/Index.ets','utf8');
assert(nativeFrame.includes('48/600'));assert.equal((nativeFrame.match(/this.(?:corner|strip)\(/g)||[]).length,8);assert(!nativeFrame.includes('.blur('));
assert(!/@State|onAreaChange|onSizeChange|widthVp|heightVp/.test(nativeFrame),'frame geometry cannot depend on a previous layout measurement');
const share=index.slice(index.indexOf('  shareScene() {'),index.indexOf('  private templateError'));assert(share.includes('showFrame:false'));assert(share.includes('square:true'));assert(share.indexOf('square:true')>share.indexOf('ForEach(this.shareCards'),'share frame overlays cards with straight corners');

for(const mode of ['solid','smart','blend','photo','preset','transparent']){
 const bg=schema.normalizeBackground({mode,frameStyle:'light'});assert.equal(bg.frameStyle,'light');state.background=bg;
 assert.equal((FridgeWeb.renderPackage({state,assets:[]},400,0).layers.frame.match(/<image /g)||[]).length,8);
}
assert.equal(schema.normalizeBackground({mode:'solid'}).frameStyle,'none');
assert.equal(schema.normalizeBackground({mode:'transparent',transparentFrame:'dark'}).frameStyle,'dark');
assert.equal(schema.normalizeBackground({mode:'transparent',frameStyle:'none',transparentFrame:'dark'}).frameStyle,'none');
assert(fs.readFileSync('entry/src/main/ets/model/BackgroundWorker.ets','utf8').includes('bg.frameStyle=state.background.frameStyle'));

const study=fs.readFileSync('previewer/frame-study.js','utf8');
assert(study.includes('margin=0'),'production frame must not retain demo inset');
assert(index.includes("width: this.canvasBackground.frameStyle==='none'?.5:0"),'frame owns the only visible outer boundary');
assert(index.includes("(this.canvasBackground.frameStyle==='none'?24:BOARD_W*this.boardScale*31/600)).clip(true)"),'card scene clip must match the sculptural frame contour');
