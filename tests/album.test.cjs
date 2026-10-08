const assert=require('node:assert/strict'),fs=require('node:fs'),path=require('node:path'),vm=require('node:vm');
const ts=require(process.env.FRIDGE_TYPESCRIPT||'/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript');
const root=path.resolve(__dirname,'../entry/src/main/ets/model'),cache=new Map(),files=new Map(),fds=new Map();let fd=0;
const io={OpenMode:{READ_ONLY:0,CREATE:1,READ_WRITE:2,TRUNC:4},openSync(p,mode){p=p.replace(/^file:\/\//,'');if(mode){files.set(p,Buffer.alloc(0));}if(!files.has(p))throw Error('missing');fds.set(++fd,p);return{fd};},statSync(d){return{size:files.get(fds.get(d)).length};},readSync(d,b,o){const src=files.get(fds.get(d)),n=Math.min(b.byteLength,src.length-o.offset);new Uint8Array(b).set(src.subarray(o.offset,o.offset+n));return n;},writeSync(d,b,o){const p=fds.get(d),out=Buffer.alloc(Math.max(files.get(p).length,o.offset+b.byteLength));files.get(p).copy(out);Buffer.from(b).copy(out,o.offset);files.set(p,out);return b.byteLength;},closeSync(d){fds.delete(d);},unlinkSync(p){files.delete(p);}};
const kits={'@kit.CoreFileKit':{fileIo:io},'@kit.ArkTS':{util:{Base64Helper:class{encodeToStringSync(b){return Buffer.from(b).toString('base64');}decodeSync(s){return new Uint8Array(Buffer.from(s,'base64'));}},TextEncoder:class{encodeInto(s){return new TextEncoder().encode(s);}},TextDecoder:class{decodeWithStream(b){return new TextDecoder().decode(b);}}}}};
function load(name){if(cache.has(name))return cache.get(name);const module={exports:{}};cache.set(name,module.exports);const code=ts.transpileModule(fs.readFileSync(path.join(root,name+'.ets'),'utf8').replace(/^@Concurrent\s*$/gm,''),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText;vm.runInThisContext('(function(require,module,exports){'+code+'\n})', {filename:name})(s=>kits[s]||load(s.replace('./','')),module,module.exports);cache.set(name,module.exports);return module.exports;}

const {albumCoverSize,albumCoverRadius,albumAnchors,isSquareAlbumCover}=load('AlbumLayout');
const {blendPixels}=load('BackgroundPalette');
const {FridgeCard,normalizeState,defaultState,typeLabel}=load('CardSchema');
assert.ok(Math.abs(albumCoverSize(80,180)-72.16)<1e-9);assert.ok(Math.abs(albumCoverSize(240,120)-108.24)<1e-9);assert.equal(albumCoverSize(100,100,3),94);assert.equal(albumCoverSize(100,100,15),70);
const {shapeRadius,cardCornerRadius}=load('CardSchema');const roundedAlbum=new FridgeCard();roundedAlbum.capability={k:'album'};
assert.equal(albumCoverRadius(180,180),14);assert.equal(albumCoverRadius(180,300,3),14);assert.equal(cardCornerRadius(roundedAlbum),20);assert.equal(cardCornerRadius(roundedAlbum,2),40);assert.equal(cardCornerRadius(new FridgeCard()),shapeRadius('rect'));assert.ok(albumCoverRadius(20,20)<=albumCoverSize(20,20)/2);
for(const shape of ['round','pill','blob','subject']){const restricted=defaultState();const c=new FridgeCard();c.shape=shape;c.capability={k:'album'};restricted.cards=[c];assert.equal(normalizeState(restricted).cards[0].shape,'rect');}
assert.equal(isSquareAlbumCover(500,500),true);for(const [w,h] of [[500,499],[400,600],[0,0],[-1,-1],[NaN,500],[20.5,20.5]])assert.equal(isSquareAlbumCover(w,h),false);
const anchors=albumAnchors(['#AB2233','#D5A862','#415E89']),a=blendPixels(anchors,'#AB2233',48,48),b=blendPixels(anchors,'#AB2233',48,48);assert.deepEqual(a,b,'static field is deterministic');assert.equal(a.length,48*48*4);assert.ok(a.every((v,i)=>i%4!==3||v===255));
const card=new FridgeCard();card.id='album';card.shape='subject';card.frame=true;card.capability={k:'album',albumCover:'https://untrusted/image',albumBackground:'file:///saved/background.png',artist:'The Beatles'};const state=defaultState();state.cards=[card];const saved=normalizeState(state).cards[0];assert.equal(saved.capability.albumCover,'');assert.equal(saved.capability.albumBackground,'file:///saved/background.png');assert.equal(saved.shape,'rect');assert.equal(saved.frame,false);assert.equal(typeLabel('album'),'音乐专辑');
console.log('PASS: centre sizing; deterministic static FluidGradient field; locked shape; local asset normalization.');

const {activeAlbum,nextAlbumBoundary,selectAlbum}=load('AlbumRotation');
const {normalizeCapability}=load('CardSchema');
const {nextDataBoundary}=load('CapabilityData');
const {refreshMinutes}=load('WidgetRefreshPolicy');
const items=[{id:'a',cover:'file:///saved/a.jpg',background:'file:///saved/a.png',title:'A',artist:'One'},{id:'b',cover:'file:///saved/b.jpg',background:'file:///saved/b.png',title:'B',artist:'Two'}];
const epoch=1700000000000,cap={k:'album',albumItems:items,albumId:'a',albumCover:items[0].cover,albumBackground:items[0].background,albumRotationMinutes:60,albumRotationStart:epoch};
assert.equal(activeAlbum(cap,epoch+3599999).id,'a');assert.equal(activeAlbum(cap,epoch+3600000).id,'b');assert.equal(activeAlbum(cap,epoch+7200000).id,'a');
assert.equal(nextAlbumBoundary(cap,epoch+3600000),epoch+7200000);assert.equal(nextAlbumBoundary({...cap,albumRotationMinutes:0},epoch),Infinity);
assert.equal(nextDataBoundary(cap,epoch+3590000),epoch+3600000);const timed=defaultState();const timedCard=new FridgeCard();timedCard.capability=cap;timed.cards=[timedCard];assert.equal(refreshMinutes(timed,epoch+3000000),10);
assert.equal(normalizeCapability({...cap,albumItems:[...items,{id:'bad',cover:'https://remote/cover',background:'file:///saved/b.png'}],albumInset:100}).albumItems.length,2);assert.equal(normalizeCapability({...cap,albumInset:100}).albumInset,4.9);
const selected=selectAlbum(cap,items[1],epoch+4000000);assert.equal(activeAlbum(selected,epoch+4000000).id,'b');assert.equal(activeAlbum(selected,epoch+7600000).id,'a');
const {exportTemplate,materializeTemplate}=load('TemplateIO');
(async()=>{for(const item of items){files.set(item.cover.slice(7),Buffer.from('cover'));files.set(item.background.slice(7),Buffer.from('background'));}
const shared=defaultState();const album=new FridgeCard();album.id='playlist';album.capability=cap;shared.cards=[album];
const file=await exportTemplate(JSON.stringify(shared),'playlist','/saved','/cache');const raw=files.get(file).toString();assert.equal(JSON.parse(raw).assets.length,4);
const imported=JSON.parse(await materializeTemplate(raw,'/received')).cards[0].capability;assert.equal(imported.albumItems.length,2);assert.equal(activeAlbum(imported,epoch+3600000).title,'B');assert.ok(imported.albumItems.every(a=>a.cover.startsWith('file:///received/')&&a.background.startsWith('file:///received/')));
const htmlPack=JSON.parse(fs.readFileSync(path.resolve(__dirname,'../skills/fridge-create/examples/html-clock.fridge'),'utf8'));
const htmlState=htmlPack.state;htmlState.cards[0].elements[0].src='file:///saved/html.png';files.set('/saved/html.png',Buffer.from(htmlPack.assets[0].data,'base64'));
const htmlFile=await exportTemplate(JSON.stringify(htmlState),'html-card','/saved','/cache');
const htmlExport=JSON.parse(files.get(htmlFile).toString());assert.equal(htmlExport.version,2);assert.equal(htmlExport.state.cards[0].html.source,htmlPack.state.cards[0].html.source);
const htmlImported=JSON.parse(await materializeTemplate(files.get(htmlFile).toString(),'/received'));assert.equal(htmlImported.cards[0].html.previewElementId,htmlImported.cards[0].elements[0].id);assert.ok(htmlImported.cards[0].elements[0].src.startsWith('file:///received/'));
console.log('PASS HTML source/cache export and filesystem materialization round trip.');
console.log('PASS: rotation boundaries, restart determinism, manual selection anchor, portable cover-library assets.');})().catch(e=>{console.error(e);process.exitCode=1;});

const {albumInfoGeometry}=load('AlbumLayout');
for(const style of ['classic','portrait','row'])for(const [w,h] of [[208,208],[280,180],[160,160],[244,148]]) {
 const g=albumInfoGeometry(w,h,style);
 assert.ok(g.coverSize>0&&g.coverX>=0&&g.coverY>=0);
 assert.ok(g.coverX+g.coverSize<=w&&g.coverY+g.coverSize<=h,'square cover fits card');
 assert.ok(g.textWidth>0&&g.textX+g.textWidth<=w+1e-8&&g.textY<h,'metadata stays within card');
}
console.log('PASS: album metadata candidates preserve square artwork and bounded metadata regions.');
// Approved geometry and mode survive local storage / portable package normalization.
const classic=albumInfoGeometry(180,180,'classic'),row=albumInfoGeometry(300,150,'row');
assert.equal(classic.coverSize,97.5);assert.equal(classic.textY,119);assert.equal(classic.titleLines,2);assert.equal(classic.artistLines,1);assert.equal(classic.artistGap,3);
assert.equal(row.coverSize,123);assert.equal(row.textX,151.5);assert.equal(row.textY,75);assert.equal(row.centerText,true);assert.equal(row.artistLines,2);
assert.equal(normalizeCapability({k:'album',albumPresentation:'row'}).albumPresentation,'row');
assert.equal(normalizeCapability({k:'album',albumPresentation:'classic'}).albumPresentation,'classic');
assert.equal(normalizeCapability({k:'album',albumPresentation:'portrait'}).albumPresentation,'cover');
console.log('PASS approved classic/row geometry and durable album presentation.');
