const fs=require('node:fs'),vm=require('node:vm'),assert=require('node:assert/strict');
const ts=require('/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript');
const source=fs.readFileSync('entry/src/main/ets/model/SceneImageCache.ets','utf8');
let calls=0,alive=0,maxAlive=0,gate=null;const released=[],sourcesReleased=[];
const fakeImage={createImageSource:path=>({createPixelMap:async()=>{
 calls++;alive++;maxAlive=Math.max(maxAlive,alive);if(gate)await gate;else await new Promise(setImmediate);alive--;
 if(path.includes('missing'))throw Error('missing');
 return {path,getImageInfo:async()=>({size:{height:2048}}),getBytesNumberPerRow:()=>8192,release:async()=>released.push(path)};
},release:async()=>sourcesReleased.push(path)})};
const env={exports:{},require:name=>name==='@kit.ImageKit'?{image:fakeImage}:name==='./AlbumRotation'?{activeAlbum:cap=>({cover:cap.albumCover||'',background:cap.albumBackground||''})}:{} };
vm.runInNewContext(ts.transpileModule(source,{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,env);
const api=env.exports;
function scene(paths){return {background:{mode:'solid',src:''},cards:paths.map(src=>({hidden:false,shape:'subject',subjectPhoto:true,cutout:src,reliefSrc:'',elements:[],capability:null}))};}
(async()=>{
 const first=scene(['file://a','file://b','file://a']);let release;gate=new Promise(r=>release=r);
 const p=api.prepareSceneImages(first),same=api.prepareSceneImages(first);await new Promise(setImmediate);assert.equal(calls,2,'deduplicate shared assets and overlapping scene requests');release();gate=null;await Promise.all([p,same]);
 assert.equal(api.sceneImage('file://a').path,'a');assert.equal(api.sceneImage('memory://form'),'memory://form');assert.equal(api.sceneImage('file://missing'),'file://missing');
 await api.prepareSceneImages(first);assert.equal(calls,2,'warm entrance does not decode again');
 const second=scene(['file://c','file://d','file://e','file://f']);await api.prepareSceneImages(second);assert.equal(maxAlive,2,'one scene has at most two concurrent native decoders');api.trimSceneImages(second);
 assert(released.includes('a')&&released.includes('b'),'evict inactive images when budget is exceeded');assert.equal(api.sceneImage('file://c').path,'c','visible working set remains valid even if larger than idle cache budget');
 let unlock;gate=new Promise(r=>unlock=r);const overlap=[api.prepareSceneImages(scene(['file://g','file://h'])),api.prepareSceneImages(scene(['file://i','file://j']))];await new Promise(setImmediate);assert.equal(alive,2,'different canvases share the global decoder budget');unlock();gate=null;await Promise.all(overlap);assert.equal(maxAlive,2,'rapid cross-canvas entrances never exceed two decoders');
 const missing=scene(['file://missing']);await api.prepareSceneImages(missing);assert.equal(api.sceneImage('file://missing'),'file://missing');assert(sourcesReleased.includes('missing'),'decode failure releases the image source');
 const mixed=scene([]);mixed.cards=[{hidden:true,shape:'subject',subjectPhoto:true,cutout:'file://hidden',reliefSrc:'',elements:[]},{hidden:false,shape:'rect',subjectPhoto:false,cutout:'',reliefSrc:'',elements:[{kind:'image',src:'file://gif',animated:true},{kind:'image',src:'file://still',animated:false}],capability:{k:'album',albumCover:'file://cover',albumBackground:'file://background'}}];
 assert.deepEqual(Array.from(api.sceneImageSources(mixed)),['file://still','file://cover','file://background'],'skip hidden/animated artwork; retain active album surfaces');
 console.log('PASS scene images: async full-resolution decode, shared in-flight work, warm reuse, concurrency cap, inactive LRU eviction, visible-image safety and failure cleanup.');
})().catch(e=>{console.error(e);process.exitCode=1;});
