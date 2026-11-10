const assert=require('node:assert/strict'),fs=require('node:fs'),vm=require('node:vm'),ts=require('typescript');
const core=vm.createContext({});vm.runInContext(fs.readFileSync('previewer/shared-models.js','utf8'),core);
const load=name=>core.FridgeCore.load(name),schema=load('CardSchema'),factory=load('TemplateFactory'),composition=load('TemplatePhotoComposition');
const compiled=ts.transpileModule(fs.readFileSync('entry/src/main/ets/demo/DemoPhotoGeometry.ets','utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText;
const nativeModule={exports:{}};vm.runInNewContext(compiled,{exports:nativeModule.exports,require:path=>load(path.split('/').pop())});
let count=0;
for(const canvasAspect of [.3,.65,1,2,3])for(const sourceAspect of [.25,.648,1,2,4])for(const zoom of [.25,1,2,4])for(const x of [-1,-.5,0,.5,1])for(const y of [-1,-.5,0,.5,1]){
 const card=factory.makeTemplateCards('portrait',1,()=> 'photo')[0];card.w=300;card.h=300/canvasAspect;
 const photo=new schema.CanvasElement();Object.assign(photo,{kind:'image',src:'file:///source.jpg',depthEnabled:true,depthForeground:'file:///subject.png',depthSourceAspect:sourceAspect});photo.depthCrop={x:.1,y:.15,w:.7,h:.8};card.elements=[photo];
 Object.assign(card.template,{photoMode:'photo',photoFraming:'fit',zoom,offsetX:x,offsetY:y});nativeModule.exports.constrainDemoPhoto(card);
 const frame=composition.portraitPhotoFrame(card,photo),region=composition.photoControlRegion(card);
 assert.equal(region.x,0);assert.equal(region.y,0);assert.ok(frame.x<=1e-7&&frame.y<=1e-7);assert.ok(frame.x+frame.w>=region.w-1e-7&&frame.y+frame.h>=region.h-1e-7);
 assert.equal(card.template.photoFraming,'cover');assert.ok(card.template.zoom>=1);count++;
}
const subject=factory.makeTemplateCards('portrait',1,()=> 'subject')[0];subject.template.photoMode='subject';subject.template.zoom=.5;const before=JSON.stringify(subject);nativeModule.exports.constrainDemoPhoto(subject);assert.equal(JSON.stringify(subject),before);
console.log(`PASS native demo cover: ${count} camera cases, edge coverage on five canvas/source ratios, subject-mode preservation`);
