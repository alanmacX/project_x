const assert=require('node:assert/strict'),fs=require('node:fs'),vm=require('node:vm'),path=require('node:path');
const root=path.resolve(__dirname,'..'),ctx=vm.createContext({console});
vm.runInContext(fs.readFileSync(path.join(root,'previewer/shared-models.js'),'utf8'),ctx);
vm.runInContext(fs.readFileSync(path.join(root,'previewer/shared-materials.js'),'utf8'),ctx);
vm.runInContext(fs.readFileSync(path.join(root,'previewer/capabilities.js'),'utf8'),ctx);
vm.runInContext(fs.readFileSync(path.join(root,'previewer/renderer.js'),'utf8'),ctx);
const read=ctx.FridgeCore.load('TemplatePackage').readPackage;
const example=read(fs.readFileSync(path.join(root,'skills/fridge-create/examples/native-canvas.fridge'),'utf8'));
const preview=ctx.FridgeWeb.renderPackage(example,300,1791439200000);
assert.equal(preview.issues.length,0,'Current native capabilities must actually render');
for(const kind of ['clock','date','battery'])assert.ok(preview.svg.includes('data-capability="'+kind+'"'));
assert.ok(!preview.svg.includes('未支持的渲染'));
assert.throws(()=>read(JSON.stringify({...example,version:99})),/支持/);
const pack=JSON.parse(JSON.stringify(example));pack.state.cards=[pack.state.cards[0]];pack.state.cards[0].capability={k:'album',title:'<script>bad</script>',artist:'Artist',albumCover:'asset://0',albumBackground:''};pack.state.cards[0].w=180;pack.state.cards[0].h=180;pack.assets=[{key:'asset://0',extension:'.png',data:'iVBORw0KGgo='}];
const actual=ctx.FridgeWeb.renderPackage(read(JSON.stringify(pack)),420,1791439200000);
assert.equal(actual.issues.length,0);assert.ok(actual.svg.includes('data:image/png;base64,'));assert.ok(!actual.svg.includes('<script>'));
const svg=ctx.FridgeWeb.albumSVG({cover:'data:image/png;base64,iVBORw0KGgo=',background:'',title:'<script>alert(1)</script>',artist:'A&B'},208,208,'classic');
assert.ok(svg.includes('&lt;script&gt;'));assert.ok(svg.includes('A&amp;B'));assert.ok(!svg.includes('<script>'));
assert.equal(ctx.FridgeCore.sourceFingerprint.length,64);
assert.ok(fs.readFileSync(path.join(root,'entry/src/main/ets/model/PreviewDesignContract.ets'),'utf8').includes(ctx.FridgeCore.sourceFingerprint));
for(const kind of ctx.FridgeCore.load('CardSchema').CAPABILITIES){
 const fixture=JSON.parse(JSON.stringify(example));fixture.state.cards=[fixture.state.cards[0]];const card=fixture.state.cards[0];card.w=220;card.h=220;card.capability={k:kind,date:'2026-12-01',title:'长中文名称测试',semester:'2026-08-31',courses:[],timetableMode:'day',percent:67,charging:true,readingBlend:kind==='battery'?'badge':'cloud'};
 const scene=ctx.FridgeWeb.renderPackage(read(JSON.stringify(fixture)),300,1791439200000);
 assert.equal(scene.issues.length,0,kind);assert.ok(!scene.svg.includes('NaN'),kind);assert.ok(!scene.svg.includes('undefined'),kind);
 if(kind!=='album')assert.ok(scene.svg.includes('data-capability="'+kind+'"'),kind);
}
const missing=JSON.parse(JSON.stringify(example));missing.state.cards[0].shape='subject';assert.ok(ctx.FridgeWeb.issuesFor(missing).length>0,'Missing masks cannot silently pass QA');
console.log('PASS all native readouts, assets, missing-mask blockers, safe metadata, native model identity');

for(const blend of ['bare','badge','sticker','tag','cloud']){
 const fixture=JSON.parse(JSON.stringify(example)),c=fixture.state.cards[0];fixture.state.cards=[c];c.shape='subject';c.w=180;c.h=240;c.cutout='asset://0';c.subjectPhoto=true;c.outline=[[{x:0,y:0},{x:1,y:0},{x:1,y:1},{x:0,y:1}]];c.capFree=true;c.capability={k:'date',readingBlend:blend,readingOutside:true,readingEdge:'right'};fixture.assets=[{key:'asset://0',extension:'.png',data:'iVBORw0KGgo='}];
 const scene=ctx.FridgeWeb.renderPackage(read(JSON.stringify(fixture)),300,1791439200000);assert.equal(scene.issues.length,0,blend);assert.ok(scene.svg.includes('mask-type:alpha'));assert.equal(scene.svg.split('base64,iVBORw0KGgo=').length-1,1,'Artwork is embedded once');assert.ok(!scene.svg.includes('NaN'),blend);
}
if(process.argv[2]){
 const real=read(fs.readFileSync(process.argv[2],'utf8')),scene=ctx.FridgeWeb.renderPackage(real,300,1791429300000);assert.equal(scene.issues.length,0);assert.ok(!/[=\s(",]NaN(?:[\s)",]|$)/.test(scene.svg));assert.ok(!scene.svg.includes('未支持的渲染'));console.log('PASS supplied package:',real.state.cards.length,'cards,',real.assets.length,'assets');
}
