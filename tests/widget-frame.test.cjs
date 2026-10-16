const fs=require('node:fs'),vm=require('node:vm'),assert=require('node:assert/strict');
const ts=require('/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript'),ctx={exports:{}};
vm.runInNewContext(ts.transpileModule(fs.readFileSync('entry/src/main/ets/model/WidgetFrameGeometry.ets','utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS}}).outputText,ctx);
for(const [width,height] of [[172,154],[190,170],[344,154],[360,172],[344,300],[600,520]]){
 const m=ctx.exports.widgetFrameMetrics(width,height),corner=width*m.cornerPercent/100;
 assert(m.radius>=24-1e-8,'small frame corner follows host mask');assert(corner<=Math.min(width,height)/2,'edge strips retain nonnegative lengths');assert(Math.abs(m.radius-corner*31/48)<1e-8);
}
const small=ctx.exports.widgetFrameMetrics(190,170),large=ctx.exports.widgetFrameMetrics(600,520);assert(small.cornerPercent>large.cornerPercent,'small frames need larger corner proportions');
console.log('PASS widget frame: 2×2, 2×4 and 4×4 host masking, proportional tiles and nonnegative edge lengths.');

const gallery=fs.readFileSync('entry/src/main/ets/views/CanvasGallery.ets','utf8'),widget=fs.readFileSync('entry/src/main/ets/widget/pages/FridgeWidgetCard.ets','utf8'),binding=fs.readFileSync('entry/src/main/ets/pages/WidgetBinding.ets','utf8');
assert.match(gallery,/borderRadius\(this.previewRadius\(state\)\)\.clip\(true\)/,'snapshot clips artwork and texture together');
assert.doesNotMatch(widget,/CanvasFrame\(\{[^\n]+square:true/,'desktop keeps its original rounded frame');assert.doesNotMatch(gallery,/CanvasFrame\(\{[^\n]+square:true/,'preview keeps the same original rounded frame');
assert.doesNotMatch(gallery,/backgroundColor\(AppDesign.surface\(this.appDark\)\)\.borderRadius\(16\)\.clip/,'no opaque thumbnail surface can peek through corners');
assert.doesNotMatch(binding,/width\(44\)\.height\(44\)\.borderRadius/,'thumbnail does not add a second corner mask');
