const fs=require('node:fs'),vm=require('node:vm'),assert=require('node:assert/strict'),ts=require('typescript');
const ctx=vm.createContext({});vm.runInContext(fs.readFileSync('previewer/shared-models.js','utf8'),ctx);
const cache=new Map();function load(name){try{return ctx.FridgeCore.load(name);}catch(e){if(!e.message.startsWith('Unknown shared model'))throw e;}if(cache.has(name))return cache.get(name);const file=['DemoMaterialBinding'].includes(name)?'demo':'model',env={exports:{},require:p=>load(p.split('/').pop())};cache.set(name,env.exports);vm.runInNewContext(ts.transpileModule(fs.readFileSync(`entry/src/main/ets/${file}/${name}.ets`,'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,env);return env.exports;}
const {toggleTemplateCanvasFill}=load('TemplateCanvasPlacement'),{CARD_TEMPLATES,normalizeCardTemplate,copyCardTemplate}=load('CardTemplate'),factory=load('TemplateFactory'),{cardViewSnapshot}=load('CardViewSnapshot');
let cases=0;for(const t of CARD_TEMPLATES)for(const aspect of [.5,1,2])for(const rotation of [-18,0,23]){
 const c=factory.makeTemplateCards(t.id,aspect,()=>t.id)[0];Object.assign(c,{x:35,y:58,w:150,h:130,rot:rotation,groupId:'group'});const before=JSON.stringify([c.x,c.y,c.w,c.h,c.rot,c.groupId]);
 toggleTemplateCanvasFill(c,aspect);assert.equal(c.w,344);assert.equal(c.h,344/aspect);assert.equal(c.rot,0);assert.equal(c.template.fill,true);
 const saved=cardViewSnapshot(c);saved.template=normalizeCardTemplate(JSON.parse(JSON.stringify(saved.template)));toggleTemplateCanvasFill(saved,aspect);
 assert.equal(JSON.stringify([saved.x,saved.y,saved.w,saved.h,saved.rot,saved.groupId]),before,`${t.id}: saved/reopened placement`);assert.equal(saved.template.fill,false);cases++;
}
const malformed=copyCardTemplate({...factory.makeTemplateCards('portrait',1,()=> 'x')[0].template,freePlacement:{x:NaN,y:0,w:0,h:2,rot:0}});assert.equal(malformed.freePlacement,undefined);
const old=factory.makeTemplateCards('mix-standby',2,()=> 'old')[0];old.template.fill=true;toggleTemplateCanvasFill(old,2);assert.ok(old.w>0&&old.h>0);assert.equal(old.template.fill,false);
const {filterDemoAssets,bindDemoPhoto,bindDemoAlbum}=load('DemoMaterialBinding');
const photo={id:'photo',name:'photo',category:'照片',original:'file://original',subject:'file://subject',aspect:.65,crop:{x:.1,y:.2,w:.7,h:.6},tones:[]},cover={...photo,id:'cover',category:'专辑',photoSource:false,albumCover:'file://square',albumBackground:'file://fluid',albumTitle:'Album',albumArtist:'Artist'},both={...cover,id:'both',photoSource:true};
assert.equal(filterDemoAssets([photo,cover,both],'照片').length,2);assert.equal(filterDemoAssets([photo,cover,both],'专辑').length,2);assert.equal(filterDemoAssets([photo,{...cover,subject:''}],'抠图').length,1);
for(const id of ['portrait','anniversary-photo','mix-memory']){
 const c=factory.makeTemplateCards(id,1,()=>id)[0];const sources=JSON.stringify(c.template.sources);c.template.photoMode='photo';bindDemoPhoto(c,photo,true);const el=c.elements.find(e=>e.kind==='image');assert.equal(el.src,photo.original);assert.equal(el.depthForeground,photo.subject);assert.equal(c.template.photoMode,'photo');assert.equal(JSON.stringify(c.template.sources),sources);
 c.template.photoMode='subject';bindDemoPhoto(c,photo,true);assert.equal(c.template.photoMode,'subject');bindDemoPhoto(c,{...photo,subject:''},true);assert.equal(c.template.photoMode,'photo');assert.equal(c.template.depth,false);
}
const album=factory.makeTemplateCards('album-record',1,()=> 'album')[0];assert.equal(bindDemoAlbum(album,0,cover),true);assert.equal(album.capability.albumCover,cover.albumCover);assert.equal(album.capability.albumItems.length,1);album.capability.albumItems[0].title='User title';bindDemoAlbum(album,0,cover);assert.equal(album.capability.albumItems.length,1);assert.equal(album.capability.title,'User title');
for(let i=1;i<12;i++)assert.equal(bindDemoAlbum(album,0,{...cover,id:'c'+i,albumCover:'file://square'+i}),true);const before=JSON.stringify(album);assert.equal(bindDemoAlbum(album,0,{...cover,id:'13',albumCover:'file://13'}),false);assert.equal(JSON.stringify(album),before);assert.equal(bindDemoAlbum(album,0,cover),true,'existing item still selectable at capacity');assert.equal(bindDemoAlbum(album,1,cover),false);
const {cardActionAnchor}=load('CardActionPlacement');for(const width of [280,320,390,844])for(const x of [-100,0,300]){const c={x,y:80,w:200,h:200,rot:20};const a=cardActionAnchor(c,1,1,0,80,500,width,844,30,20,[],260);assert.ok(a.x-130>=8&&a.x+130<=width-8);}
const native=fs.readFileSync('entry/src/main/ets/pages/Index.ets','utf8'),ui=fs.readFileSync('entry/src/main/ets/views/CardCustomizer.ets','utf8');assert.ok(!ui.includes('高级布局'));assert.ok(!native.includes('this.templateAppearance()'));assert.ok(!native.includes('customizeAdvanced'));
console.log(`PASS unified template workflow: ${cases} fill/save/reopen/restore cases; legacy fill fallback; photo/subject pairing; real asset filters; album selection, metadata, deduplication and capacity; 12 toolbar edge placements; no old template editor entry`);
// Actual async selection methods must not write into a departed editor or wrong target.
const source=fs.readFileSync('entry/src/main/ets/views/CardCustomizer.ets','utf8'),methods=source.slice(source.indexOf('  private materialAlbum('),source.indexOf('  private label('));
const asyncEnv={exports:{},bindDemoAlbum};vm.runInNewContext(ts.transpileModule(`export class Selection {
 alive=true;screen='edit';busy=false;assetsReady=true;libraryMode=false;libraryPurpose='image';sheet=false;sheetType='';materialReturnSheet='';materialTarget='';materialOwner='';materialCapabilityIndex=0;assets=[];face=null;published=0;messages=[];
 camera={reset:()=>{}};toast(m){this.messages.push(m);}publishFace(){this.published++;}smartClock(){}attachPhoto(){}
 ${methods}
}`,{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,asyncEnv);
(async()=>{
 const create=()=>{const s=new asyncEnv.exports.Selection();s.face=factory.makeTemplateCards('album-record',1,()=> 'draft')[0];let resolve;s.library={items:[cover],prepareAlbum:()=>new Promise(r=>resolve=r)};s.resolve=()=>resolve();return s;};
 const live=create();live.sheet=true;live.sheetType='content';live.openMaterials('album');const pending=live.useMaterial(cover);assert.equal(live.busy,true);live.closeSheet();assert.equal(live.sheetType,'materials','busy selection blocks dismissal');live.resolve();await pending;assert.equal(live.face.capability.albumCover,cover.albumCover);assert.equal(live.published,1);assert.equal(live.sheet,true);assert.equal(live.sheetType,'content','returns to the previous content layer');
 for(const reason of ['disposed','different-card','different-target']){const s=create();s.openMaterials('album');const before=JSON.stringify(s.face),p=s.useMaterial(cover);if(reason==='disposed')s.alive=false;else if(reason==='different-card')s.face.id='another';else s.materialTarget='face';s.resolve();await p;assert.equal(s.published,0,reason);assert.ok(!s.face.capability.albumCover,reason);}
 console.log('PASS async material session: one apply, nested return, busy dismissal guard, and disposed/card/target identity guards');
})().catch(e=>{console.error(e);process.exitCode=1;});
