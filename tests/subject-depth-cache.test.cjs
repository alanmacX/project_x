const assert=require('node:assert/strict'),fs=require('node:fs'),vm=require('node:vm');
const ts=require('/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript');
const files=new Set(),calls={parse:0,draw:0,pack:0,jobs:0,released:0,blur:[]};let currentFile='';
function load(name,kits={}){const mod={exports:{}};const code=ts.transpileModule(fs.readFileSync('entry/src/main/ets/model/'+name+'.ets','utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText;vm.runInNewContext(code,{exports:mod.exports,require:s=>kits[s],Map,Math,JSON,ArrayBuffer});return mod.exports;}
const geometry=load('SubjectDepthGeometry'),path=load('ContourPath');
const drawing={Canvas:class{save(){}translate(){}attachBrush(){}attachPen(){}drawPath(){calls.draw++;}detachBrush(){}detachPen(){}restore(){}},Path:class{buildFromSvgString(s){calls.parse++;return s.startsWith('M');}},Brush:class{setAntiAlias(){}setColor(){}setMaskFilter(){}},Pen:class{setAntiAlias(){}setJoinStyle(){}setColor(){}setMaskFilter(){}setStrokeWidth(){}},MaskFilter:{createBlurMaskFilter:(type,sigma)=>{calls.blur.push(sigma);return {};}},BlurType:{NORMAL:0},JoinStyle:{ROUND_JOIN:0}};
const pool={Task:class{constructor(fn,...args){this.fn=fn;this.args=args;}},execute:async t=>{calls.jobs++;return t.fn(...t.args);}};
const mockFile={OpenMode:{CREATE:1,READ_WRITE:2,TRUNC:4},access:async p=>files.has(p),open:async p=>{currentFile=p;return {fd:1};},closeSync(){},rename:async(a,b)=>{files.delete(a);files.add(b);},mkdir:async p=>files.add(p),listFile:async()=>Array.from(files).map(p=>p.split('/').pop()),unlink:async p=>files.delete(p)};
const cache=load('SubjectDepthCache',{'./SubjectDepthGeometry':geometry,'./ContourPath':path,'./RenderContours':{cardOutline:c=>c.outline},'./CardViewSnapshot':{cardRenderSnapshot:c=>({...c,subjectBorder:true})},'./CardSchema':{materialColors:()=>['#FFFFFF']},'./CanvasLayout':{subjectSurfaceFactor:c=>Math.min(1-6/c.w,1-6/c.h)},'./CardDepth':{cardEdgeColor:()=> '#EEEEEE',CARD_SIDE:1.35,CARD_CAST_RADIUS:9,CARD_CAST_Y:4.5,CARD_CAST_COLOR:'#290E0904',CARD_CONTACT_RADIUS:1.6,CARD_CONTACT_Y:.6,CARD_CONTACT_COLOR:'#320E0904'},'@kit.ArkGraphics2D':{drawing},'@kit.ArkTS':{taskpool:pool},'@kit.CoreFileKit':{fileIo:mockFile},'@kit.ImageKit':{image:{PixelMapFormat:{RGBA_8888:0},AlphaType:{PREMUL:1},createPixelMap:async(_,options)=>{assert.equal(options.alphaType,1);return {release:async()=>calls.released++};},createImagePacker:()=>({packToFile:async()=>{calls.pack++;files.add(currentFile);},release:async()=>calls.released++})}}});
(async()=>{
 const c={id:'one',cutout:'file://local-photo.png',subjectVersion:4,w:100,h:180,subjectPhoto:true,subjectBorder:true,shape:'subject',material:'white',paper:'',outline:[[{x:0,y:0},{x:1,y:0},{x:1,y:1},{x:0,y:1}]]};
 assert.equal(cache.subjectDepthImage(c,1),'');await cache.prepareSubjectDepth([c],1,'/cache',2);
 assert.equal(calls.parse,1,'all four native passes share one native parsed silhouette');assert.equal(calls.draw,4);assert.deepEqual(calls.blur,[9,1.6]);assert.equal(calls.pack,1);assert.equal(calls.released,2);assert.ok(cache.subjectDepthImage(c,1).endsWith('.png'));
 c.x=30;c.rot=45;c.capability={percent:90};await cache.prepareSubjectDepth([c],1,'/cache',2);assert.equal(calls.jobs,1,'placement and capability data never bake another relief');
 c.shape='rect';assert.equal(cache.subjectDepthImage(c,1),'','shape changes cannot reuse a silhouette backing');c.shape='subject';
 c.w=80;assert.equal(cache.subjectDepthImage(c,1),'','resize cannot use stretched stale relief');await cache.prepareSubjectDepth([c],1,'/cache',2);assert.equal(calls.jobs,2);
 c.subjectVersion++;assert.equal(cache.subjectDepthImage(c,1),'');
 assert.equal(geometry.depthArgb('#30000000',.25),0x0c000000);assert.equal(geometry.depthArgb('#FFFFFF',1),0xffffffff);
 const scene=load('SceneRelief',{'@kit.CoreFileKit':{fileIo:mockFile},'./SubjectDepthCache':cache});
 c.cutout='file:///local/image.png';const first=JSON.parse(await scene.prepareSceneRelief(JSON.stringify([c]))),packed=calls.pack;
 assert.ok(first.one.startsWith('file:///local/relief-cache/'));
 c.x=500;c.rot=30;c.capability={percent:12};
 assert.equal(JSON.parse(await scene.prepareSceneRelief(JSON.stringify([c]))).one,first.one);assert.equal(calls.pack,packed,'desktop movement and live data reuse cached bitmap');
 c.id='duplicate';assert.equal(JSON.parse(await scene.prepareSceneRelief(JSON.stringify([c]))).duplicate,first.one,'identical artwork shares cache across cards');
 c.w++;assert.notEqual(JSON.parse(await scene.prepareSceneRelief(JSON.stringify([c]))).duplicate,first.one);
 console.log('PASS relief cache: shared path parsing, two blurred shadows and two surfaces, resource cleanup, placement/data reuse and size/asset invalidation');
})().catch(e=>{console.error(e);process.exitCode=1;});
