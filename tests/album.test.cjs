const assert=require('node:assert/strict'),fs=require('node:fs'),path=require('node:path'),vm=require('node:vm');
const ts=require(process.env.FRIDGE_TYPESCRIPT||'/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript');
const root=path.resolve(__dirname,'../entry/src/main/ets/model'),cache=new Map(),files=new Map(),fds=new Map();let fd=0;
const io={OpenMode:{READ_ONLY:0,CREATE:1,READ_WRITE:2,TRUNC:4},openSync(p,mode){p=p.replace(/^file:\/\//,'');if(mode){files.set(p,Buffer.alloc(0));}if(!files.has(p))throw Error('missing');fds.set(++fd,p);return{fd};},statSync(d){return{size:files.get(fds.get(d)).length};},readSync(d,b,o){const src=files.get(fds.get(d)),n=Math.min(b.byteLength,src.length-o.offset);new Uint8Array(b).set(src.subarray(o.offset,o.offset+n));return n;},writeSync(d,b,o){const p=fds.get(d),out=Buffer.alloc(Math.max(files.get(p).length,o.offset+b.byteLength));files.get(p).copy(out);Buffer.from(b).copy(out,o.offset);files.set(p,out);return b.byteLength;},closeSync(d){fds.delete(d);},unlinkSync(p){files.delete(p);}};
const kits={'@kit.CoreFileKit':{fileIo:io},'@kit.ArkTS':{util:{Base64Helper:class{encodeToStringSync(b){return Buffer.from(b).toString('base64');}decodeSync(s){return new Uint8Array(Buffer.from(s,'base64'));}},TextEncoder:class{encodeInto(s){return new TextEncoder().encode(s);}},TextDecoder:class{decodeWithStream(b){return new TextDecoder().decode(b);}}}}};
function load(name){if(cache.has(name))return cache.get(name);const module={exports:{}};cache.set(name,module.exports);const code=ts.transpileModule(fs.readFileSync(path.join(root,name+'.ets'),'utf8').replace(/^@Concurrent\s*$/gm,''),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText;vm.runInThisContext('(function(require,module,exports){'+code+'\n})', {filename:name})(s=>kits[s]||load(s.replace('./','')),module,module.exports);cache.set(name,module.exports);return module.exports;}

const {albumSearchURL,parseAlbums,albumCoverURL}=load('AlbumCatalog');
const {albumCoverSize,albumAnchors}=load('AlbumLayout');
const {blendPixels}=load('BackgroundPalette');
const {FridgeCard,normalizeState,defaultState,typeLabel}=load('CardSchema');
assert.throws(()=>albumSearchURL('   '));
const query=new URL(albumSearchURL('Abbey Road Beatles')).searchParams.get('query');assert.ok(query.includes('releasegroup:"Beatles" OR artist:"Beatles"'));assert.ok(query.endsWith('primarytype:album'));
const id='9162580e-5df4-32de-80cc-f45a8d8a9b1d';
assert.equal(parseAlbums(JSON.stringify({'release-groups':[{id,title:'Abbey Road','artist-credit':[{artist:{name:'The Beatles'}}],'first-release-date':'1969-09-26'},{id,title:'duplicate'}]})).length,1);
assert.equal(parseAlbums(JSON.stringify({'release-groups':[{id,title:'Abbey Road','artist-credit':[{artist:{name:'The Beatles'}}]}]}))[0].artist,'The Beatles');
assert.throws(()=>albumCoverURL('../path'));assert.equal(albumCoverURL(id),'https://coverartarchive.org/release-group/'+id+'/front-500');
assert.equal(albumCoverSize(80,180),56);assert.equal(albumCoverSize(240,120),84);
const anchors=albumAnchors(['#AB2233','#D5A862','#415E89']),a=blendPixels(anchors,'#AB2233',48,48),b=blendPixels(anchors,'#AB2233',48,48);assert.deepEqual(a,b,'static field is deterministic');assert.equal(a.length,48*48*4);assert.ok(a.every((v,i)=>i%4!==3||v===255));
const card=new FridgeCard();card.id='album';card.shape='subject';card.frame=true;card.capability={k:'album',albumCover:'https://untrusted/image',albumBackground:'file:///saved/background.png',artist:'The Beatles'};const state=defaultState();state.cards=[card];const saved=normalizeState(state).cards[0];assert.equal(saved.capability.albumCover,'');assert.equal(saved.capability.albumBackground,'file:///saved/background.png');assert.equal(saved.shape,'rect');assert.equal(saved.frame,false);assert.equal(typeLabel('album'),'音乐专辑');
console.log('PASS: album search and IDs; centre sizing; deterministic static FluidGradient field; locked shape; local asset normalization.');
