const assert=require('node:assert/strict'),fs=require('node:fs'),vm=require('node:vm');
const ts=require('/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript');
const files=new Set(),calls={parse:0,draw:0,pack:0,jobs:0,released:0};let currentFile='';
function load(name,kits={}){const mod={exports:{}};const code=ts.transpileModule(fs.readFileSync('entry/src/main/ets/model/'+name+'.ets','utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText;vm.runInNewContext(code,{exports:mod.exports,require:s=>kits[s],Map,Math,JSON,ArrayBuffer});return mod.exports;}
const geometry=load('SubjectDepthGeometry'),path=load('ContourPath');
const drawing={Canvas:class{save(){}translate(){}attachBrush(){}attachPen(){}drawPath(){calls.draw++;}detachBrush(){}detachPen(){}restore(){}},Path:class{buildFromSvgString(s){calls.parse++;return s.startsWith('M');}},Brush:class{setAntiAlias(){}setColor(){}},Pen:class{setAntiAlias(){}setJoinStyle(){}setColor(){}setStrokeWidth(){}},JoinStyle:{ROUND_JOIN:0}};
const pool={Task:class{constructor(fn,...args){this.fn=fn;this.args=args;}},execute:async t=>{calls.jobs++;return t.fn(...t.args);}};
const mockFile={OpenMode:{CREATE:1,READ_WRITE:2,TRUNC:4},access:async p=>files.has(p),open:async p=>{currentFile=p;return {fd:1};},closeSync(){},rename:async(a,b)=>{files.delete(a);files.add(b);},listFile:async()=>Array.from(files).map(p=>p.split('/').pop()),unlink:async p=>files.delete(p)};
const cache=load('SubjectDepthCache',{'./SubjectDepthGeometry':geometry,'./ContourPath':path,'./RenderContours':{cardOutline:c=>c.outline},'./CardViewSnapshot':{cardRenderSnapshot:c=>({...c,subjectBorder:true})},'./CardSchema':{materialColors:()=>['#FFFFFF']},'./CanvasLayout':{subjectSurfaceFactor:c=>Math.min(1-6/c.w,1-6/c.h)},'./CardDepth':{cardEdgeColor:()=> '#EEEEEE'},'@kit.ArkGraphics2D':{drawing},'@kit.ArkTS':{taskpool:pool},'@kit.CoreFileKit':{fileIo:mockFile},'@kit.ImageKit':{image:{PixelMapFormat:{RGBA_8888:0},AlphaType:{PREMUL:1},createPixelMap:async(_,options)=>{assert.equal(options.alphaType,1);return {release:async()=>calls.released++};},createImagePacker:()=>({packToFile:async()=>{calls.pack++;files.add(currentFile);},release:async()=>calls.released++})}}});
(async()=>{
 const c={cutout:'file://local-photo.png',subjectVersion:4,w:100,h:180,subjectPhoto:true,subjectBorder:true,shape:'subject',material:'white',paper:'',outline:[[{x:0,y:0},{x:1,y:0},{x:1,y:1},{x:0,y:1}]]};
 assert.equal(cache.subjectDepthImage(c,1),'');await cache.prepareSubjectDepth([c],1,'/cache',2);
 assert.equal(calls.parse,1,'all eight relief bands share one native parsed silhouette');assert.equal(calls.draw,8);assert.equal(calls.pack,1);assert.equal(calls.released,2);assert.ok(cache.subjectDepthImage(c,1).endsWith('.png'));
 c.x=30;c.rot=45;c.capability={percent:90};await cache.prepareSubjectDepth([c],1,'/cache',2);assert.equal(calls.jobs,1,'placement and capability data never bake another relief');
 c.shape='rect';assert.equal(cache.subjectDepthImage(c,1),'','shape changes cannot reuse a silhouette backing');c.shape='subject';
 c.w=80;assert.equal(cache.subjectDepthImage(c,1),'','resize cannot use stretched stale relief');await cache.prepareSubjectDepth([c],1,'/cache',2);assert.equal(calls.jobs,2);
 c.subjectVersion++;assert.equal(cache.subjectDepthImage(c,1),'');
 assert.equal(geometry.depthArgb('#30000000',.25),0x0c000000);assert.equal(geometry.depthArgb('#FFFFFF',1),0xffffffff);
 console.log('PASS relief cache: shared path parsing, exact eight bands, resource cleanup, placement/data reuse and size/asset invalidation');
})().catch(e=>{console.error(e);process.exitCode=1;});
