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
 assert.ok(high-low>2,'single-hue Overlay retains light folds without an artificial dark foundation');
 assert.equal(p.fluidBase([{color:'#F5CD32',weight:.9},{color:'#D22328',weight:.1}]),'#F5CD32','foundation retains the dominant source colour');
 images.set('/yellow.png',mixed);images.set('/red.png',pixels([210,35,40],[210,35,40],1));
 const state=new FridgeState();state.background.mode='blend';state.canvasAspect=1;
 const yellowCard=new FridgeCard();Object.assign(yellowCard,{id:'yellow',shape:'subject',subjectPhoto:true,cutout:'file:///yellow.png',x:0,y:0,w:300,h:300});
 const redCard=new FridgeCard();Object.assign(redCard,{id:'red',shape:'subject',subjectPhoto:true,cutout:'file:///red.png',x:210,y:0,w:30,h:30});state.cards=[yellowCard,redCard];
 const bg=JSON.parse(await createSmartBackground(JSON.stringify(state),'/cache'));assert.ok(bg.anchors[0].color.startsWith('#'));let warm=0;for(let i=0;i<packed.length;i+=4)if(packed[i]>packed[i+2]&&packed[i+1]>packed[i+2])warm++;assert.ok(warm/(packed.length/4)>.85,'large yellow artwork keeps a warm wash while the foundation stays light');
 const spatial=new FridgeState();spatial.background.mode='blend';spatial.canvasAspect=1;
 const left=new FridgeCard(),right=new FridgeCard();
 Object.assign(left,{id:'left',shape:'subject',subjectPhoto:true,cutout:'file:///yellow.png',x:10,y:20,w:70,h:70});
 Object.assign(right,{id:'right',shape:'subject',subjectPhoto:true,cutout:'file:///yellow.png',x:250,y:20,w:70,h:70});spatial.cards=[left,right];
 const separated=JSON.parse(await createSmartBackground(JSON.stringify(spatial),'/cache'));
 const clouds=separated.anchors.filter(a=>a.color===swatches[0].color);
 assert.equal(clouds.length,1,'duplicate colour families share one palette slot');
 const crowded=Array.from({length:9},(_,i)=>({x:(i%3)/3,y:Math.floor(i/3)/3,color:'#BC7C4D',weight:.09-i*.002}));
 crowded.push({x:.8,y:.7,color:'#ADB17A',weight:.04},{x:.2,y:.8,color:'#DDD9D6',weight:.035});
 const retained=p.reduceBackgroundAnchors(crowded);
 assert.equal(retained.length,6);
 assert.ok(retained.some(a=>p.colorLab(a.color).a<0),'quiet green survives repeated brown subjects');
 assert.ok(retained.some(a=>p.colorLab(a.color).l>75),'pale subject survives the six-field budget');
 assert.ok(Math.abs(retained.reduce((s,a)=>s+a.weight,0)-crowded.reduce((s,a)=>s+a.weight,0))<1e-9,'all source colour mass is conserved');
 assert.deepEqual(p.reduceBackgroundAnchors(crowded),retained,'pose selection is deterministic');
 const normalized=load('CardSchema').normalizeBackground({anchors:[{x:.5,y:.5,color:'#ADB17A',weight:.008}]});
 assert.equal(normalized.anchors[0].weight,.008,'saving or sharing does not inflate a small field to .05');
 const signature=backgroundSignature(state);yellowCard.x+=20;yellowCard.rot=10;assert.equal(backgroundSignature(state),signature,'drag and rotation do not invoke palette extraction');const moved=JSON.parse(await createSmartBackground(JSON.stringify(state),'/cache'));assert.notEqual(moved.src,bg.src,'manual re-extraction uses a new pose bitmap instead of returning stale pixels');yellowCard.subjectVersion++;assert.notEqual(backgroundSignature(state),signature,'updated cutout invalidates cache even at the same path');
 const element=load('CardSchema').CanvasElement;yellowCard.elements=[new element()];yellowCard.elements[0].kind='shape';const sig2=backgroundSignature(state);yellowCard.elements[0].w=.5;assert.notEqual(backgroundSignature(state),sig2,'layer coverage changes invalidate extraction');
 const {cardColorRaster,cardColorDistribution}=load('CardColorDistribution'),{CanvasElement}=load('CardSchema');
 const twoTone=pixels([230,40,50],[30,70,225],.5);
 images.set('/two-tone.png',twoTone);
 const duo=new FridgeCard();Object.assign(duo,{id:'duo',shape:'subject',subjectPhoto:true,cutout:'file:///two-tone.png',x:0,y:0,w:240,h:240});
 const duoState=new FridgeState();duoState.canvasAspect=1;duoState.background.mode='blend';duoState.cards=[duo];
 const duoBg=JSON.parse(await createSmartBackground(JSON.stringify(duoState),'/cache'));
 assert.equal(duoBg.palette.length,2,'one card contributes both hues to the persisted palette');
 assert.ok(Math.hypot(duoBg.anchors[0].x-duoBg.anchors[1].x,duoBg.anchors[0].y-duoBg.anchors[1].y)>.25,'different hues retain separate source regions');
 assert.ok(Math.abs(duoBg.anchors[0].weight-duoBg.anchors[1].weight)<.008,'equal areas keep equal votes');
 const read=new Map([['file:///two-tone.png',{width:48,height:48,rgba:twoTone}]]);
 const flat=new FridgeCard();flat.w=240;flat.h=240;flat.paper='#FFFFFF';
 const layer=new CanvasElement();Object.assign(layer,{kind:'image',src:'file:///two-tone.png',x:0,y:0,w:1,h:1});flat.elements=[layer];
 let distribution=cardColorDistribution(cardColorRaster(flat,read));
 assert.equal(distribution.length,2,'a full-cover image excludes hidden paper');
 const cover=new CanvasElement();Object.assign(cover,{kind:'shape',color:'#30AD50',x:0,y:0,w:1,h:.5});flat.elements.push(cover);
 distribution=cardColorDistribution(cardColorRaster(flat,read));
 assert.equal(distribution.length,2,'opaque top layer removes the hidden red half rather than double-counting it');
 assert.ok(distribution.every(p=>colorDistance(p.color,'#E62832')>30),'occluded red does not leak into background');
 cover.opacity=.5;distribution=cardColorDistribution(cardColorRaster(flat,read));
 assert.ok(distribution.every(p=>colorDistance(p.color,'#30AD50')>10),'semi-transparent layers contribute their composited colour');
 flat.elements=[];
 for(let i=0;i<6;i++){const el=new CanvasElement();Object.assign(el,{kind:'shape',color:i===5?'#2255DD':'#DD4433',x:i/6,y:0,w:1/6,h:1});flat.elements.push(el);}
 distribution=cardColorDistribution(cardColorRaster(flat,read));assert.ok(distribution.some(p=>colorDistance(p.color,'#2255DD')<2),'sixth layer is analysed too');
 flat.elements=[layer];layer.w=.5;layer.h=1;layer.rot=0;
 const wide=new Uint8Array(96*48*4);for(let y=0;y<48;y++)for(let x=0;x<96;x++)wide.set(x<24||x>=72?[230,40,50,255]:[30,70,225,255],(y*96+x)*4);
 read.set('file:///two-tone.png',{width:96,height:48,rgba:wide});
 distribution=cardColorDistribution(cardColorRaster(flat,read));
 assert.ok(distribution.every(p=>colorDistance(p.color,'#E62832')>30),'Cover crop excludes the image side strips');
 assert.ok(distribution.some(p=>colorDistance(p.color,'#FFFFFF')<2&&Math.abs(p.weight-.5)<.02),'uncovered neutral paper retains its real area');
 layer.w=1;layer.opacity=1;flat.elements=[];flat.shape='subject';flat.subjectPhoto=true;flat.cutout='file:///alpha.png';
 const alpha=new Uint8Array(48*48*4);for(let i=0;i<alpha.length;i+=4)alpha.set([230,40,50,128],i);
 read.set(flat.cutout,{width:48,height:48,rgba:alpha});
 distribution=cardColorDistribution(cardColorRaster(flat,read));assert.ok(Math.abs(distribution[0].weight-128/255)<.001,'subject alpha is counted once');
 flat.cutout='file:///missing.png';assert.equal(cardColorDistribution(cardColorRaster(flat,read)).length,0,'missing cutout cannot invent a rectangular paper colour');
 const transparentDuo=twoTone.slice();for(let i=0;i<transparentDuo.length;i+=4)transparentDuo[i+3]=0;
 assert.equal(cardColorDistribution({width:48,height:48,rgba:transparentDuo}).length,0,'fully transparent artwork has no colour mass');
 duo.x=-120;const clipped=cardColorDistribution(cardColorRaster(duo,new Map([['file:///two-tone.png',{width:48,height:48,rgba:twoTone}]]),48,1));
 assert.ok(Math.abs(clipped.reduce((sum,p)=>sum+p.weight,0)-.5)<.01,'off-canvas half does not vote');
 duo.elements=[new CanvasElement()];duo.elements[0].kind='shape';const beforeLayer=backgroundSignature(duoState);duo.elements[0].x=.4;assert.notEqual(backgroundSignature(duoState),beforeLayer,'layer position invalidates the composite distribution');
 function colorDistance(a,b){const x=p.colorLab(a),y=p.colorLab(b);return Math.hypot(x.l-y.l,x.a-y.a,x.b-y.b);}
 const wash=p.canvasBlendPixels(anchors,'#F2F1EE',96,96);
 let minLight=100,maxChroma=0;for(let i=0;i<wash.length;i+=4){const lab=p.colorLab('#'+Array.from(wash.slice(i,i+3)).map(v=>v.toString(16).padStart(2,'0')).join(''));minLight=Math.min(minLight,lab.l);maxChroma=Math.max(maxChroma,Math.hypot(lab.a,lab.b));}
 assert.ok(maxChroma>45,'canvas retains the saturation of source colour clouds');
 const opposing=[{x:.2,y:.2,color:'#F5CD32',weight:.7},{x:.8,y:.8,color:'#247ECC',weight:.3}];
 assert.deepEqual(p.canvasBlendPixels(opposing,'#EEECE6',80,120),p.canvasBlendPixels(opposing.slice().reverse(),'#EEECE6',80,120),'changing field order cannot overwrite a minority hue');
 const hueField=p.canvasBlendPixels(opposing,'#EEECE6',96,96);
 const pixelLab=(bytes,x,y)=>p.colorLab('#'+Array.from(bytes.slice((y*96+x)*4,(y*96+x)*4+3)).map(v=>v.toString(16).padStart(2,'0')).join(''));
 assert.ok(pixelLab(hueField,20,20).b>8&&pixelLab(hueField,78,78).b<0,'warm and cool source regions remain distinct in the fluid background');
 const small=p.canvasBlendPixels([{x:.2,y:.2,color:'#F5CD32',weight:.99},{x:.8,y:.8,color:'#247ECC',weight:.01}],'#EEECE6',96,96);
 let coolSmall=0,coolLarge=0;for(let y=0;y<96;y++)for(let x=0;x<96;x++){if(pixelLab(small,x,y).b<0)coolSmall++;if(pixelLab(hueField,x,y).b<0)coolLarge++;}
 assert.ok(coolSmall<coolLarge,'a one-percent accent has a smaller visible footprint than a thirty-percent secondary colour');
 const {visibleCanvasColors}=load('CardColorDistribution');
 const back=new FridgeCard(),front=new FridgeCard();Object.assign(back,{id:'back',x:40,y:50,w:200,h:200,z:1,paper:'#DD4433'});Object.assign(front,{id:'front',x:40,y:50,w:200,h:200,z:2,paper:'#2255DD'});
 const scene=visibleCanvasColors([back,front],[cardColorRaster(back,new Map()),cardColorRaster(front,new Map())],1);
 assert.ok(scene.every(a=>colorDistance(a.color,'#DD4433')>30),'a completely covered card does not contribute source colours');
 assert.ok(scene.reduce((sum,a)=>sum+a.weight,0)<.35,'overlapping cards do not double-count canvas area');
 const {canvasColourFamilies,canvasFluidLayout}=load('CanvasFluidPalette');
 const captured=JSON.parse(fs.readFileSync(path.join(__dirname,'fixtures/canvas-fluid-colours.json'),'utf8'));
 const families=canvasColourFamilies(captured);
 assert.ok(families.some(a=>a.color==='#D60411'),'small vivid red survives warm shades in measured artwork');
 assert.ok(families.some(a=>a.color==='#6BA0A2')&&families.some(a=>a.color==='#E9BE48'),'cyan and yellow also keep a palette slot');
 assert.ok(families.length<=6);
 assert.ok(Math.abs(families.reduce((sum,a)=>sum+a.weight,0)-captured.reduce((sum,a)=>sum+a.weight,0))<1e-9,'family selection preserves measured mass');
 assert.deepEqual(canvasColourFamilies(captured.slice().reverse()),families,'family selection ignores source enumeration order');
 const coverage=new Array(18*18).fill(1);for(let y=0;y<6;y++)for(let x=0;x<18;x++)coverage[y*18+x]=0;
 const positioned=canvasFluidLayout(families,coverage,18,18);
 for(const point of positioned){const source=families.find(p=>p.color===point.color);assert.ok(Math.hypot(point.x-source.x,point.y-source.y)<=.120001,'empty space cannot pull a hue across the canvas');}
 const redSeed=captured.find(p=>p.color==='#D60411'),redFamily=families.find(p=>p.color==='#D60411');
 assert.equal(redFamily.x,redSeed.x);assert.equal(redFamily.y,redSeed.y,'other reddish shades cannot drag the red source centroid away');
 assert.deepEqual(canvasFluidLayout(families,new Array(18*18).fill(0),18,18),families,'an exposed source needs no artificial displacement');
 for(const [columns,rows] of [[18,28],[28,18]]){
   const mapped=canvasFluidLayout(families,new Array(columns*rows).fill(0).map((_,i)=>i%3===0?0:1),columns,rows),short=Math.min(columns,rows);
   mapped.forEach((p,i)=>assert.ok(Math.hypot((p.x-families[i].x)*columns/short,(p.y-families[i].y)*rows/short)<=.120001,'position bound uses the short edge on non-square canvases'));
 }
 const darkWarm=p.canvasBlendPixels([{x:.5,y:.5,color:'#3B3430',weight:.35},{x:.3,y:.3,color:'#E9BE48',weight:.35},{x:.7,y:.7,color:'#976147',weight:.3}],'#EEECE6',96,96);
 let lightSum=0;for(let i=0;i<darkWarm.length;i+=4){const hex='#'+Array.from(darkWarm.slice(i,i+3)).map(v=>v.toString(16).padStart(2,'0')).join('');lightSum+=p.colorLab(hex).l;}
 assert.ok(lightSum/(96*96)>70,'charcoal and brown do not turn the canvas into a dark foundation');
 const vividControl=[{x:.2,y:.2,color:'#E72B35',weight:1},{x:.8,y:.2,color:'#2862D6',weight:1},{x:.5,y:.85,color:'#F5CF32',weight:1}];
 const vivid=p.canvasBlendPixels(vividControl,'#CCCCCC',96,96);let redPixels=0,bluePixels=0,yellowPixels=0;
 for(let i=0;i<vivid.length;i+=4){const r=vivid[i],g=vivid[i+1],b=vivid[i+2];if(r>g*1.3&&r>b*1.2)redPixels++;if(b>r*1.2&&b>g*1.15)bluePixels++;if(r>b*1.4&&g>b*1.4)yellowPixels++;}
 assert.ok(redPixels>300&&bluePixels>300&&yellowPixels>300,'red, blue and yellow are simultaneously visible, not averaged into one colour');
 console.log('PASS background: measured cluster proportions, transparent pixels, minority accents, Overlay hue preservation, single-hue light/shade depth, actual weighted worker output movement-stable/versioned cache, single-card multiple hues, measured spatial distribution, layer occlusion/opacity, all layers, Cover crop, neutral area, alpha and canvas clipping');
})().catch(e=>{console.error(e);process.exitCode=1;});
