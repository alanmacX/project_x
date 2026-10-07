const assert=require('node:assert/strict'),fs=require('node:fs'),vm=require('node:vm');
const ts=require('/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript');
const root='entry/src/main/ets/';
const metrics=fs.readFileSync(root+'model/PaperTextWidth.ets','utf8');
// The Form renderer supplies no UIContext, measure utility, or native app import.
const sandbox={exports:{}};
vm.runInNewContext(ts.transpileModule(metrics,{compilerOptions:{module:ts.ModuleKind.CommonJS}}).outputText,sandbox);
for(const font of [8,11,14,24,42,54])for(const text of ['88:88','735','100','课程表','人工智能导论','屏峰校区 计C311','更长的一行名称']){
 const width=sandbox.exports.paperTextWidth(text,font,500);
 assert.ok(Number.isFinite(width)&&width>0);
 assert.equal(width,sandbox.exports.paperTextWidth(text,font,500));
}
for(const view of ['CapBlockView','SummaryCapability','TimetableCapability','BatteryCapability']){
 const src=fs.readFileSync(root+'views/'+view+'.ets','utf8');
 assert.ok(!src.includes('getUIContext()'),view+' must build without the app UIContext');
 assert.ok(!/\.background\(this\.(readingBackground|edgeBacking)\)/.test(src),view+' uses ordinary material children supported by FormKit');
}
const backing=fs.readFileSync(root+'views/ReadingBacking.ets','utf8');
assert.ok(!backing.includes('clearRect'),'dragging a material never blanks its bitmap');
assert.ok(backing.includes('Path().commands(this.path())'));
console.log('PASS Form material construction without UIContext: clock, battery, timetable and variable text metrics; native material children.');
