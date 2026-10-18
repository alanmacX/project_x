const fs=require('fs'),vm=require('vm'),assert=require('node:assert/strict'),path=require('path');
const ts=require('/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript');const cache=new Map();
function load(name){if(cache.has(name))return cache.get(name);const mod={exports:{}};cache.set(name,mod.exports);const source=fs.readFileSync(path.join('entry/src/main/ets/model',name+'.ets'),'utf8');vm.runInThisContext('(function(require,module,exports){'+ts.transpileModule(source,{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText+'})')(s=>load(s.slice(2)),mod,mod.exports);cache.set(name,mod.exports);return mod.exports;}
const {FridgeCard,CAPABILITIES}=load('CardSchema'),{editorVisualChoices}=load('EditorVisualChoices'),{compositionOverflow,readingStyles}=load('ReadingComposition');
const {capabilityInset,capabilityPlacement}=load('CanvasLayout'),{hookReserve}=load('MicaGeometry'),{capabilityFits}=load('CapabilityMetrics');
for(const kind of CAPABILITIES){const card=new FridgeCard();card.capability={k:kind,title:'A long preview title',readingBlend:kind==='battery'?'badge':'cloud',readingEdge:'right',readingOutside:true,albumCover:'file:///cover.png',albumBackground:'file:///background.png',albumPresentation:'classic'};card.capFree=true;card.capBox.x=.4;card.capBox.y=.2;card.capBox.w=.8;card.capBox.h=.6;const before=JSON.stringify(card);const mode=kind==='album'?'album':'reading',choices=editorVisualChoices(card,mode);assert.equal(choices.length,kind==='album'?3:readingStyles(kind).length);assert.equal(JSON.stringify(card),before,'previews never edit source '+kind);assert.equal(new Set(choices.map(c=>c.key)).size,choices.length);for(const c of choices){const o=compositionOverflow(c.card,1);assert.ok((c.card.w+o.left+o.right)*c.scale<=82.001);assert.ok((c.card.h+o.top+o.bottom)*c.scale<=92.001);assert.ok(Number.isFinite(c.offsetX)&&Number.isFinite(c.offsetY));assert.notEqual(c.card.capability,card.capability);if(c.key==='sticker')assert.equal(c.card.capability.readingEdge,'right');}
 if(kind==='album'){assert.equal(choices[2].card.w/choices[2].card.h,2);assert.equal(choices[0].card.w,choices[0].card.h);}
}
const subject=new FridgeCard();subject.shape='subject';subject.subjectAspect=.5;subject.cutout='file:///subject.png';subject.outline=[[[0,0],[1,0],[1,1],[0,1]]];const shapeOptions=editorVisualChoices(subject,'shape');assert.equal(shapeOptions.length,5);assert.equal(shapeOptions[4].card.h,shapeOptions[4].card.w/.5);assert.equal(subject.shape,'subject');assert.equal(editorVisualChoices(new FridgeCard(),'shape').length,4);
for(const kind of CAPABILITIES.filter(k=>k!=='album')) {
 const tiny=new FridgeCard();tiny.w=64;tiny.h=80;tiny.capability={k:kind};tiny.capFree=true;tiny.capBox.w=.4;tiny.capBox.h=.25;
 for(const {card,key} of editorVisualChoices(tiny,'reading')) {
  const box=capabilityPlacement(card),inset=capabilityInset(card),w=card.w*box.w-2*inset,h=card.h*box.h-2*inset-hookReserve(key);
  assert.ok(capabilityFits(card.capability,w,h),'real candidates reserve readable content for '+kind+' / '+key);
 }
}
console.log('PASS all 13 capabilities: detached real-artwork alternatives, overflow-safe thumbnails, album proportions, subject shapes and saved attachment side.');
const {editorViewport}=load('EditorViewport');
for(const angle of [-145,-45,0,30,145])for(const [vw,pane] of [[320,260],[540,450]]) {
 const v=editorViewport(80,120,angle,vw,720,36,24,false,pane,[90,20,45,30]),a=angle*Math.PI/180,c=Math.cos(a),s=Math.sin(a);
 for(const [x,y] of [[-90,-20],[125,-20],[125,150],[-90,150]]) {
  const px=v.left+(x*c-(y-120)*s)*v.scale,py=v.top+(120+x*s+(y-120)*c)*v.scale;
  assert.ok(px>=27.99&&px<=vw-27.99,'external content keeps horizontal control clearance');
  assert.ok(py>=23.99&&py<=pane-23.99,'external content keeps vertical control clearance');
 }
}
console.log('PASS rotated external content fits both phone and wide editor previews.');

const external=new FridgeCard();external.cutout='file:///subject.png';external.capability={k:'timetable',readingBlend:'tag'};external.capFree=true;external.capBox.x=-2;external.capBox.w=3;external.capBox.h=2;
for(const c of editorVisualChoices(external,'shape')){assert.equal(c.card.capability,null,'hidden content cannot offset the shape thumbnail');assert.equal(c.offsetX,0);assert.equal(c.offsetY,0);assert.ok(Math.abs(Math.max(c.card.w*c.scale/82,c.card.h*c.scale/92)-1)<.00001,'shape fills the fitted thumbnail frame');}
const large=editorViewport(40,80,0,400,900,36,24,false,700);assert.ok(large.scale*80>600,'small source artwork still uses available editor height');
console.log('PASS shape choices ignore hidden/external data and small cards fill the preview.');

const {applyEditorShape}=load('EditorVisualChoices');
for(const key of ['round','pill']){const c=new FridgeCard();c.w=180;c.h=180;applyEditorShape(c,key);assert.equal(c.h,108);c.w=220;c.h=140;applyEditorShape(c,key);assert.equal(c.h,140);}
const square=new FridgeCard();square.w=180;square.h=180;
for(const c of editorVisualChoices(square,'shape').filter(c=>['round','pill'].includes(c.key)))assert.equal(c.card.w/c.card.h,180/108);
assert.equal(square.h,180,'shape candidates do not resize the artwork');

for(const [w,h] of [[120,240],[300,100],[180,180]]){
 const source=new FridgeCard();source.w=w;source.h=h;
 for(const key of ['round','pill']){
  const live=load('CardViewSnapshot').cardViewSnapshot(source);applyEditorShape(live,key);
  const candidate=editorVisualChoices(source,'shape').find(c=>c.key===key).card;
  assert.equal(candidate.w/candidate.h,live.w/live.h,'shape preview preserves applied aspect for '+key+' '+w+'x'+h);
 }
}
const {editorVisualChoiceSignature}=load('EditorVisualChoices');
const signatureCard=new FridgeCard();let signature=editorVisualChoiceSignature(signatureCard,'shape');
for(const change of [c=>c.shape='round',c=>c.frame=!c.frame,c=>c.subjectPhoto=!c.subjectPhoto,c=>c.subjectAspect=2,c=>c.paper='#112233']){
 change(signatureCard);const next=editorVisualChoiceSignature(signatureCard,'shape');assert.notEqual(next,signature);signature=next;
}
signatureCard.x+=20;signatureCard.rot+=15;assert.equal(editorVisualChoiceSignature(signatureCard,'shape'),signature,'board placement does not rebuild visual choices');
signatureCard.capability={k:'timetable',courses:[{name:'before'}]};const readingBefore=editorVisualChoiceSignature(signatureCard,'reading');signatureCard.capability.courses[0].name='after';assert.notEqual(editorVisualChoiceSignature(signatureCard,'reading'),readingBefore,'same-length course changes update real artwork');
const choicesView=fs.readFileSync('entry/src/main/ets/views/EditorVisualChoices.ets','utf8');
assert(choicesView.includes("choice.key+':'+this.choiceGeneration"),'replaced plain candidate objects rebuild their ForEach render nodes');
console.log('PASS shape aspect parity and candidate invalidation for borders, subject geometry and same-length content changes.');
