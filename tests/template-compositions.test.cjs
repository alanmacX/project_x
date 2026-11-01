process.env.TZ='Asia/Shanghai';
const assert=require('node:assert/strict'),fs=require('node:fs'),vm=require('node:vm');
const ctx=vm.createContext({});vm.runInContext(fs.readFileSync('previewer/shared-models.js','utf8'),ctx);
const load=n=>ctx.FridgeCore.load(n),catalog=load('CompositionCatalog'),factory=load('TemplateFactory'),schema=load('CardSchema'),sceneModel=load('TemplateScene'),text=load('TemplateTextLayout'),layout=load('CanvasLayout'),pack=load('TemplatePackage');
const publicFaces=load('CardTemplate').CARD_TEMPLATES.filter(x=>x.kind==='ensemble');
assert.deepEqual(Array.from(catalog.COMPOSITIONS,c=>c.id).sort(),Array.from(publicFaces,c=>c.id).sort(),'every combination needs an authored face');
let sequence=0,scenes=0,labels=0;
const tick=Date.parse('2026-11-01T10:08:00+08:00'),long='超长名称·👨‍👩‍👧‍👦Cafe\u0301🇨🇳 '.repeat(25),measure=(v,size)=>text.templateClusters(v).reduce((n,c)=>n+size*(/[^\x00-\xff]/.test(c)?1:.62),0),ids=new Set();
for(const face of catalog.COMPOSITIONS){
 assert.ok(Number.isInteger(face.revision)&&face.revision>0);assert.deepEqual(Array.from(face.slots,s=>s.kind),Array.from(publicFaces.find(f=>f.id===face.id).sources),'registered sources match face roles');assert.equal(face.slots.filter(s=>s.primary).length,1);assert.equal(face.slots[0].primary,true);
 for(const slot of face.slots){assert.ok(!ids.has(slot.id));ids.add(slot.id);assert.ok(slot.role&&slot.kind);assert.ok(load('CardTemplate').templateDefinition(slot.id));assert.ok(!load('CardTemplate').CARD_TEMPLATES.some(t=>t.id===slot.id),'internal roles stay out of standalone gallery');}
 for(const aspect of [1,2]){const design=catalog.compositionLayout(face,aspect),slots=design.slots.filter(s=>!s.primary);for(const a of slots){assert.ok(a.x>=0&&a.y>=0&&a.x+a.w<=design.width&&a.y+a.h<=design.height,face.id+' slot bounds');for(const b of slots){if(a===b)continue;assert.ok(a.x+a.w<=b.x||b.x+b.w<=a.x||a.y+a.h<=b.y||b.y+b.h<=a.y,face.id+' overlapping supporting slots');}}}
 for(const aspect of [.3,.9,1,2,3])for(const palette of ['','cream','cobalt','ink'])for(const mode of ['empty','long','invalid','photo']){
  const cards=factory.makeTemplateCards(face.id,aspect,()=>String(++sequence),tick),state=schema.defaultState();state.canvasAspect=aspect;state.cards=cards;const group=cards[0].groupId;
  assert.equal(new Set(cards.map(c=>c.id)).size,cards.length);assert.ok(group&&cards.every(c=>c.groupId===group));
  const colors=[];
  for(const card of cards){const cap=card.capability;card.template.palette=palette;
   cap.title=mode==='long'?long:'设计评审';cap.city=mode==='long'?long:'上海';cap.zone='Asia/Shanghai';cap.date=mode==='invalid'?'2026-02-31':'2027-01-01';cap.percent=mode==='invalid'?NaN:76;
   if(mode!=='empty'){cap.events=[{id:'event',title:cap.title,start:tick+3600000,end:tick+7200000,location:long}];cap.semester='2026-08-31';cap.courses=[{id:'course',name:long,room:long,day:7,start:'11:00',end:'12:00',firstWeek:1,lastWeek:60,parity:0}];}
   if(mode==='photo'){const p=new schema.CanvasElement();Object.assign(p,{kind:'image',src:'file:///photo.webp',depthForeground:'file:///cutout.png',depthEnabled:true,depthSourceAspect:8});card.elements=[p];}
   const before=JSON.stringify(card),scene=sceneModel.cardTemplateScene(card,tick);scenes++;assert.equal(JSON.stringify(card),before);assert.equal(scene.surface,catalog.compositionSlot(card.template.id).primary);colors.push([scene.background,scene.ink,scene.accent].join());
   assert.ok(layout.ensureCapabilitySize(card));
   for(const m of scene.marks){for(const key of ['x','y','w','h','size','angle','opacity','start','sweep'])assert.ok(Number.isFinite(m[key]),`${face.id}/${card.template.id} ${key}`);
    if(m.kind!=='text')continue;labels++;const name=card.template.id+' '+m.text.slice(0,15);
    assert.ok(m.x>=0&&m.y>=0&&m.x+m.w<=scene.width+.001&&m.y+m.h<=scene.height+.001,name+' text outside face');assert.ok(!/undefined|NaN|Infinity/.test(m.text),name);
    if(scene.surface){const scale=card.w/scene.width,cy=card.y/470*(344/aspect);for(const other of cards.filter(c=>c!==card)){const ox=card.x+m.x*scale,oy=cy+m.y*scale,ow=m.w*scale,oh=m.h*scale,sy=other.y/470*(344/aspect);assert.ok(ox+ow<=other.x+.01||other.x+other.w<=ox+.01||oy+oh<=sy+.01||sy+other.h<=oy+.01,name+' overlaps supporting role '+other.template.id);}}
    const fit=text.layoutTemplateText(m,measure);assert.ok(fit.fontSize>0);assert.ok(fit.lines.length<=m.lines);assert.ok(fit.lineHeight*fit.lines.length<=m.h+.001,name+' height');for(const line of fit.lines)assert.ok(measure(line,fit.fontSize)<=m.w+.01,name+' width');
   }
  }
  assert.equal(new Set(colors).size,1,'default face slots share color roles');
  const restored=schema.normalizeState(JSON.parse(JSON.stringify(state)));assert.equal(restored.cards.length,cards.length);
  cards.forEach((card,i)=>{assert.equal(restored.cards[i].template.id,card.template.id);assert.ok(Math.abs(restored.cards[i].h-card.h)<.001,'thin slot height survives persistence');});
  const portable=JSON.parse(JSON.stringify(state));portable.cards.forEach(c=>c.elements=[]);const exported=pack.packageScene(JSON.stringify(portable),'');const imported=pack.readPackage(JSON.stringify(exported)).state;assert.equal(imported.cards.length,cards.length);assert.equal(new Set(imported.cards.map(c=>c.groupId)).size,1);
 }
}
const photo=factory.makeTemplateCards('mix-memory',1,()=>String(++sequence),tick)[0],p=new schema.CanvasElement();Object.assign(p,{kind:'image',src:'file:///photo.webp',depthForeground:'file:///cutout.png',depthEnabled:true,depthSourceAspect:1});photo.elements=[p];
assert.ok(sceneModel.cardTemplateScene(photo,tick).marks.some(m=>m.src===p.depthForeground));photo.template.depth=false;assert.ok(sceneModel.cardTemplateScene(photo,tick).marks.some(m=>m.src===p.src));assert.ok(!sceneModel.cardTemplateScene(photo,tick).marks.some(m=>m.src===p.depthForeground));
// Old ordinary cards/groups retain their original geometry; catalog changes only affect new insertions.
const legacy=schema.defaultState();legacy.cards=factory.makeTemplateCards('standby',1,()=> 'legacy',tick);legacy.cards[0].groupId='old-group';const normalized=schema.normalizeState(JSON.parse(JSON.stringify(legacy)));assert.equal(normalized.cards[0].template.id,'standby');assert.equal(normalized.cards[0].groupId,'old-group');assert.equal(normalized.cards[0].h,legacy.cards[0].h);
console.log(`PASS unified faces: ${scenes} scenes / ${labels} text slots, 5 faces, 5 canvas ratios, 4 palettes, 4 extremes; transparent roles, unique IDs, shared themes, storage/package/depth/legacy gates`);
