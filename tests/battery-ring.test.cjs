const assert=require('node:assert/strict'),fs=require('node:fs'),vm=require('node:vm');
const ts=require('/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript');
const mod={exports:{}};
const code=ts.transpileModule(fs.readFileSync('entry/src/main/ets/model/BatteryPresentation.ets','utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS}}).outputText;
vm.runInThisContext('(function(module,exports){'+code+'\n})')(mod,mod.exports);
const p=mod.exports;
for(const diameter of [38.4,48,72,144]) {
 for(const level of [0,1,20,50,63,100]) {
  const path=p.batteryRingPath(diameter,level);
  if(level===0){assert.equal(path,'');continue;}
  const parts=path.split(' ').map(Number);
  assert.ok(parts.slice(1,3).every(Number.isFinite));
  assert.equal(parts[7],level*2.88>180?1:0);
  if(level===100){assert.ok(Math.abs(parts[1]+parts[9]-diameter)<.002);assert.ok(Math.abs(parts[2]-parts[10])<.002);assert.ok(parts[2]>diameter*.8,'gap is below, not above');}
 }
 assert.equal(p.batteryRingPath(diameter,200),p.batteryRingPath(diameter,100));
}
for(const value of [NaN,-1,0])assert.equal(p.batteryRingPath(value), '');
assert.equal(p.batteryRingPath(72,NaN),'');
assert.equal(p.batteryLevel({percent:0}),0);assert.equal(p.batteryLevel({percent:101}),-1);
assert.notEqual(p.batteryTint({percent:10},'#262824'),'#262824');
assert.equal(p.batteryTint({percent:10,charging:true},'#262824'),p.batteryTint({percent:100,chargeState:'full'},'#262824'));
assert.equal(p.batteryTint({percent:10,refreshState:'failed'},'#262824'),'#262824','stale readings never imply live charging');
console.log('PASS battery ring: bottom 72-degree gap, sweep flags, finite scaled coordinates, zero/unknown level and charge/low/stale states');
for(const diameter of [38.4,48,72,144]) {
 for(const label of ['—','0','18','67','100']) {
  const glyphs=p.batteryArcLabel(diameter,label,diameter/5);
  assert.equal(glyphs.length,label.length);
  for(const glyph of glyphs) {
   assert.ok(Math.abs(Math.hypot(glyph.x-diameter/2,glyph.y-diameter/2)-diameter*.44)<.001,'text centres remain on the ring radius');
   assert.ok(glyph.y>diameter*.8,'label belongs to the bottom gap');
   assert.ok(Number.isFinite(glyph.angle));
  }
  assert.ok(Math.abs(glyphs[0].x+glyphs.at(-1).x-diameter)<.001,'label stays centred');
  assert.ok(Math.abs(glyphs[0].angle+glyphs.at(-1).angle)<.001,'rotations mirror across the centre');
 }
}
console.log('PASS battery arc lettering: same-circle positions, tangent rotations, symmetric centring and zero/unknown/three-digit labels');
