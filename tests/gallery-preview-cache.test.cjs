const assert=require('node:assert/strict'),fs=require('node:fs'),vm=require('node:vm');
const ts=require('/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript');
const gallery=fs.readFileSync('entry/src/main/ets/views/CanvasGallery.ets','utf8');assert.match(gallery,/primeRenderContours\(state.cards, storageSnapshot\(state\)\)/,'contour worker receives JSON, never the opaque cache key');
const files=new Map(),handles=new Map();let fd=0;
const fileIo={OpenMode:{CREATE:1,READ_WRITE:2,TRUNC:4},readText:async p=>{if(!files.has(p))throw Error('missing');return files.get(p);},access:async p=>files.has(p),open:async p=>{handles.set(++fd,p);files.set(p,'');return {fd};},write:async(d,s)=>files.set(handles.get(d),s),close:async()=>{},rename:async(a,b)=>{files.set(b,files.get(a));files.delete(a);},unlink:async p=>files.delete(p)};
function load(){const context={exports:{},require:()=>({fileIo})};vm.runInNewContext(ts.transpileModule(fs.readFileSync('entry/src/main/ets/model/GalleryPreviewCache.ets','utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,context);return context.exports;}
(async()=>{
 let cache=load();assert.equal(await cache.cachedGalleryPreview('/cache','a'),null);
 files.set('/cache/gallery_v2_a_1.png','image');const item={source:'document-revision',path:'file:///cache/gallery_v2_a_1.png',dimension:'2*2',aspect:1};
 await cache.saveGalleryPreview('/cache','a',item);
 cache=load();assert.equal((await cache.cachedGalleryPreview('/cache','a')).source,'document-revision','cold process restores the persisted preview');
 files.set('/cache/gallery_v2_a_2.png','new');await cache.saveGalleryPreview('/cache','a',{...item,source:'updated-revision',path:'file:///cache/gallery_v2_a_2.png'});
 assert(!files.has('/cache/gallery_v2_a_1.png'),'replaced image is reclaimed after metadata is committed');
 cache=load();assert.equal((await cache.cachedGalleryPreview('/cache','a')).source,'updated-revision');
 files.delete('/cache/gallery_v2_a_2.png');assert.equal(await load().cachedGalleryPreview('/cache','a'),null,'evicted image triggers regeneration');
 files.set('/cache/gallery_v2_bad.json','{broken');assert.equal(await cache.cachedGalleryPreview('/cache','bad'),null,'damaged cache never damages artwork');
 console.log('PASS gallery disk cache: cold restore, atomic replacement, stale-image cleanup, missing images and malformed metadata.');
})().catch(e=>{console.error(e);process.exitCode=1;});
