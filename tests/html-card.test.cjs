const fs=require('node:fs'),vm=require('node:vm'),assert=require('node:assert/strict');
const ctx=vm.createContext({});vm.runInContext(fs.readFileSync('previewer/shared-models.js','utf8'),ctx);
const core=ctx.FridgeCore,html=core.load('HtmlCardTemplate'),reader=core.load('TemplatePackage'),schema=core.load('CardSchema');
const raw=JSON.parse(fs.readFileSync('skills/fridge-create/examples/html-clock.fridge','utf8'));
const pack=reader.readPackage(JSON.stringify(raw));assert.equal(pack.version,2);assert.equal(pack.state.cards[0].html.source,raw.state.cards[0].html.source);assert.equal(pack.state.cards[0].capability.k,'clock');assert.equal(pack.state.cards[0].elements[0].src,'asset://0');
const local=schema.normalizeState(JSON.parse(JSON.stringify(pack.state)));assert.equal(local.cards[0].html.source,raw.state.cards[0].html.source);
let id=0;const imported=reader.importedCards(pack.state,()=>String(++id));assert.equal(imported[0].html.previewElementId,imported[0].elements[0].id);
assert.equal(reader.packageScene(JSON.stringify(local),'').version,2);
const legacy=JSON.parse(JSON.stringify(raw));delete legacy.state.cards[0].html;legacy.version=1;assert.equal(reader.readPackage(JSON.stringify(legacy)).version,1);
for(const change of [p=>p.version=1,p=>p.state.cards[0].html.version=99,p=>p.state.cards[0].html.designVersion=99,p=>p.state.cards[0].html.previewElementId='missing',p=>p.assets=[]]){const copy=JSON.parse(JSON.stringify(raw));change(copy);assert.throws(()=>reader.readPackage(JSON.stringify(copy)));}
for(const source of ['<script>alert(1)</script>','<iframe></iframe>','<img src="https://x/a.png">','<div onclick="x()">x</div>','<style>@import "a.css"</style>','<style>div{background:url(x)}</style>'])assert.throws(()=>html.validateHtmlCard({...raw.state.cards[0].html,source}));
html.validateHtmlCard({...raw.state.cards[0].html,source:'<div style="color:#fff">Offline</div><img src="data:image/png;base64,AAAA">'});
console.log('PASS HTML v2 source/cache/provider persistence, remapped IDs, legacy v1 compatibility and unsafe/future input rejection.');
