const assert=require('node:assert/strict'),fs=require('node:fs'),path=require('node:path'),vm=require('node:vm');
const ts=require('/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript');
const root=path.resolve(__dirname,'../entry/src/main/ets/model'),cache=new Map(),images=new Map();let packed;
const kits={
 '@kit.CoreFileKit':{fileIo:{OpenMode:{READ_ONLY:0,CREATE:1,READ_WRITE:2},open:async src=>({fd:src}),closeSync:()=>{},access:async()=>false}},
 '@kit.ImageKit':{image:{PixelMapFormat:{RGBA_8888:0},AlphaType:{PREMUL:1,OPAQUE:2},createImageSource:src=>({getImageInfo:async()=>({size:{width:48,height:48}}),createPixelMap:async()=>({getImageInfo:async()=>({size:{width:48,height:48},alphaType:2}),getBytesNumberPerRow:()=>192,readPixelsToBuffer:async buf=>new Uint8Array(buf).set(images.get(src)),release:async()=>{}}),release:async()=>{}}),createPixelMap:async bytes=>{packed=new Uint8Array(bytes);return {release:async()=>{}};},createImagePacker:()=>({packToFile:async()=>{},release:async()=>{}})}},
 '@kit.ArkTS':{taskpool:{}}
};
function load(name){if(cache.has(name))return cache.get(name);const module={exports:{}};cache.set(name,module.exports);const code=ts.transpileModule(fs.readFileSync(path.join(root,name+'.ets'),'utf8').replace(/^@Concurrent\s*$/gm,''),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText;vm.runInThisContext('(function(require,module,exports){'+code+'\n})',{filename:name})(s=>kits[s]||load(s.replace('./','')),module,module.exports);return module.exports;}
function pixels(main,accent,fraction){const out=new Uint8Array(48*48*4);for(let i=0;i<48*48;i++)out.set([...(i<48*48*fraction?main:accent),255],i*4);return out;}
(async()=>{
 const p=load('BackgroundPalette'),{FridgeCard,FridgeState}=load('CardSchema'),{createSmartBackground}=load('BackgroundWorker'),{backgroundSignature}=load('BackgroundInputs');
 const mixed=pixels([245,205,50],[210,35,40],.94),swatches=p.representativeSwatches(mixed);
 assert.ok(swatches[0].weight>.85,'tiny red accent cannot acquire half the image vote');assert.ok(Math.abs(swatches.reduce((s,c)=>s+c.weight,0)-1)<.001);
 const transparent=mixed.slice();for(let i=0;i<transparent.length;i+=4){transparent[i]=255;transparent[i+1]=0;transparent[i+2]=0;transparent[i+3]=0;}assert.equal(p.representativeSwatches(transparent)[0].color,'#C5C1B8');
 const anchors=[{x:.5,y:.5,color:'#F5CD32',weight:1},{x:.4,y:.4,color:'#D22328',weight:.04}],field=p.blendPixels(anchors,'#FFFFFF',96,96);
 let yellow=0;for(let i=0;i<field.length;i+=4)if(field[i+1]>field[i]*.65&&field[i+2]<field[i+1]*.65)yellow++;assert.ok(yellow/(96*96)>.9,'weighted yellow remains yellow after the secondary lighting layer');
 const single=p.blendPixels([{x:.4,y:.35,color:'#F5CD32',weight:1}],'#F2F1EE',96,128);
 let low=100,high=0;
 for(let i=0;i<single.length;i+=4){const hex='#'+Array.from(single.slice(i,i+3)).map(v=>v.toString(16).padStart(2,'0')).join('');const light=p.colorLab(hex).l;low=Math.min(low,light);high=Math.max(high,light);}
 assert.ok(high-low>8,'one dominant hue still produces blurred light and shade instead of a flat fill');
 images.set('/yellow.png',mixed);images.set('/red.png',pixels([210,35,40],[210,35,40],1));
 const state=new FridgeState();state.background.mode='blend';state.canvasAspect=1;
 const yellowCard=new FridgeCard();Object.assign(yellowCard,{id:'yellow',shape:'subject',subjectPhoto:true,cutout:'file:///yellow.png',x:0,y:0,w:300,h:300});
 const redCard=new FridgeCard();Object.assign(redCard,{id:'red',shape:'subject',subjectPhoto:true,cutout:'file:///red.png',x:210,y:0,w:30,h:30});state.cards=[yellowCard,redCard];
 const bg=JSON.parse(await createSmartBackground(JSON.stringify(state),'/cache'));assert.ok(bg.anchors[0].color.startsWith('#'));let predominant=0;for(let i=0;i<packed.length;i+=4)if(packed[i+1]>packed[i]*.65&&packed[i+2]<packed[i+1]*.65)predominant++;assert.ok(predominant/(packed.length/4)>.85,'large yellow artwork outweighs small red artwork in actual worker output');
 const signature=backgroundSignature(state);yellowCard.x+=20;yellowCard.rot=10;assert.equal(backgroundSignature(state),signature,'drag and rotation do not invoke palette extraction');const moved=JSON.parse(await createSmartBackground(JSON.stringify(state),'/cache'));assert.notEqual(moved.src,bg.src,'manual re-extraction uses a new pose bitmap instead of returning stale pixels');yellowCard.subjectVersion++;assert.notEqual(backgroundSignature(state),signature,'updated cutout invalidates cache even at the same path');
 const element=load('CardSchema').CanvasElement;yellowCard.elements=[new element()];yellowCard.elements[0].kind='shape';const sig2=backgroundSignature(state);yellowCard.elements[0].w=.5;assert.notEqual(backgroundSignature(state),sig2,'layer coverage changes invalidate extraction');
 console.log('PASS background: measured cluster proportions, transparent pixels, minority accents, Overlay hue preservation, single-hue light/shade depth, actual weighted worker output and movement-stable/versioned cache');
})().catch(e=>{console.error(e);process.exitCode=1;});
