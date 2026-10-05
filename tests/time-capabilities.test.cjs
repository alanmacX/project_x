const assert=require('node:assert/strict'),fs=require('node:fs'),path=require('node:path'),vm=require('node:vm');
const ts=require('/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript');
const root=path.resolve(__dirname,'../entry/src/main/ets/model'),cache=new Map();
function load(name){const file=path.resolve(root,name+'.ets');if(cache.has(file))return cache.get(file).exports;const mod={exports:{}};cache.set(file,mod);const code=ts.transpileModule(fs.readFileSync(file,'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText;vm.runInThisContext('(function(require,module,exports){'+code+'\n})',{filename:file})(s=>load(path.relative(root,path.resolve(path.dirname(file),s))),mod,mod.exports);return mod.exports;}
const time=load('TimeCapabilities'),schema=load('CardSchema'),data=load('CapabilityData'),metrics=load('CapabilityMetrics');
const winter=Date.parse('2026-01-15T12:00:00Z'),summer=Date.parse('2026-07-15T12:00:00Z');
assert.equal(time.clockOffset('Asia/Shanghai',summer),-8);
assert.equal(time.clockOffset('America/New_York',winter),5);assert.equal(time.clockOffset('America/New_York',summer),4);
assert.equal(time.clockOffset('Europe/London',winter),0);assert.equal(time.clockOffset('Europe/London',summer),-1);
assert.equal(time.clockOffset('Asia/Kolkata',summer),-5.5);assert.equal(time.clockOffset('Asia/Kathmandu',summer),-5.75);
assert.equal(time.clockOffset('Australia/Adelaide',winter),-10.5);assert.equal(time.clockOffset('Australia/Adelaide',summer),-9.5);
assert.equal(time.clockZone('bad/zone'),'Asia/Shanghai');
assert.ok(time.cityReading('Asia/Tokyo',Date.parse('2026-10-04T18:00:00Z')).date.startsWith('10月5日'));
assert.ok(time.cityReading('America/Los_Angeles',Date.parse('2026-10-04T03:00:00Z')).date.startsWith('10月3日'));
assert.equal(time.clockOffset('America/New_York',Date.parse('2026-03-08T06:59:59Z')),5);
assert.equal(time.clockOffset('America/New_York',Date.parse('2026-03-08T07:00:00Z')),4);
assert.equal(time.nextCityMidnight('America/New_York',Date.parse('2026-03-08T05:30:00Z')),Date.parse('2026-03-09T04:00:00Z'),'next midnight follows the new DST offset');
assert.equal(time.nextCityBoundary('America/New_York',Date.parse('2026-03-08T06:48:00Z')),Date.parse('2026-03-08T07:00:00Z'),'schedule the nearby DST transition');
assert.equal(schema.normalizeCapability({k:'worldclock',zone:'invalid'}).zone,'Asia/Shanghai');
assert.equal(data.nextDataBoundary({k:'worldclock',zone:'Asia/Tokyo'},Date.parse('2026-10-04T14:59:00Z')),Date.parse('2026-10-04T15:00:00Z'));
assert.ok(time.lunarReading(new Date('2026-02-17T12:00:00').getTime()).date.includes('初一'));
assert.ok(time.lunarReading(new Date('2026-09-25T12:00:00').getTime()).date.includes('十五'));
assert.ok(time.lunarReading(new Date('2025-07-25T12:00:00').getTime()).date.includes('闰六月'),'keep leap-month identity');
assert.equal(time.lunarReading(new Date('2026-02-17T12:00:00').getTime()).year,'丙午年');
const min=metrics.capabilityReadableMinimum({k:'lunar'});assert.equal(metrics.capabilityFits({k:'lunar'},min.w,min.h),true);assert.equal(metrics.capabilityFits({k:'lunar'},min.w-1,min.h),false);
for(const k of ['worldclock','lunar']) {const state=schema.normalizeState({...schema.defaultState(),cards:[{...new schema.FridgeCard(),id:k,capability:{k,zone:'America/New_York'}}]});assert.equal(state.cards[0].capability.k,k);}
console.log('PASS native time capabilities: DST changes and midnight scheduling, half/quarter-hour zones, civil-day rollover, lunar new year/full moon/leap month and readable minimum sizes');

// The default full clock used 42vp in 112vp: its five native glyphs wrapped.
// Check both compact and full layouts at minimum widths and every host scale.
for (const width of [54.4,68,80,104,112,144,240]) {
 for (const host of [.45,1,1.75,3]) {
  const font=metrics.boundedReadoutFont(42*host,width*host,3.2);
  assert.ok(font*3.2<=width*host+.001,'HH:mm remains one native line');
  assert.ok(font<=42*host);
 }
}
assert.equal(metrics.boundedReadoutFont(42,112,3.2),35);
console.log('PASS fixed-format clock sizing at native glyph budget across compact/full host sizes');
