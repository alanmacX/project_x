const fs=require('node:fs'),vm=require('node:vm'),ts=require('typescript'),assert=require('node:assert/strict');
const ctx=vm.createContext({});vm.runInContext(fs.readFileSync('previewer/shared-models.js','utf8'),ctx);
const cache=new Map();function load(n){try{return ctx.FridgeCore.load(n);}catch(e){if(!e.message.startsWith('Unknown shared model'))throw e;}if(cache.has(n))return cache.get(n);const env={exports:{},require:p=>load(p.split('/').pop())};cache.set(n,env.exports);vm.runInNewContext(ts.transpileModule(fs.readFileSync(`entry/src/main/ets/model/${n}.ets`,'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,env);return env.exports;}
const policy=load('TemplateFillPolicy'),{toggleTemplateCanvasFill:toggle}=load('TemplateCanvasPlacement'),{CardEditHistory}=load('CardEditHistory'),schema=load('CardSchema'),factory=load('TemplateFactory');
const create=(id,aspect=1)=>factory.makeTemplateCards('flip',aspect,()=>id)[0];
const geometry=c=>JSON.stringify([c.x,c.y,c.w,c.h,c.rot,c.groupId,c.z]);
let scenarios=0;
for(const aspect of [.3,.5,1,2,3]){
 const a=create('a',aspect),b=create('b',aspect),ordinary=new schema.FridgeCard();ordinary.id='ordinary';a.z=1;b.z=2;a.groupId='old-group';a.rot=12;b.rot=-8;
 const cards=[a,b,ordinary],originalA=geometry(a),originalB=geometry(b),originalOrdinary=JSON.stringify(ordinary);
 toggle(a,aspect);const history=new CardEditHistory();history.reset(b,[],undefined,policy.templateFillState(cards));
 toggle(b,aspect);assert.deepEqual(Array.from(policy.enforceSingleTemplateFill(cards,aspect,b.id)),['a']);assert.equal(geometry(a),originalA);assert.equal(cards.filter(c=>c.template?.fill).length,1);
 history.record(b,'replace-fill',[],undefined,policy.templateFillState(cards));a.capability.title='live data';
 cards[1]=history.undo();policy.restoreTemplateFillState(history.fillState(),cards,aspect);assert.equal(a.template.fill,true);assert.equal(geometry(cards[1]),originalB);assert.equal(a.capability.title,'live data');assert.equal(cards.filter(c=>c.template?.fill).length,1);
 cards[1]=history.redo();policy.restoreTemplateFillState(history.fillState(),cards,aspect);assert.equal(cards[1].template.fill,true);assert.equal(geometry(a),originalA);assert.equal(JSON.stringify(ordinary),originalOrdinary);
 const raw=schema.defaultState();raw.canvasAspect=aspect;raw.cards=cards;const reopened=schema.normalizeState(JSON.parse(JSON.stringify(raw)));assert.equal(reopened.cards.filter(c=>c.template?.fill).length,1);assert.equal(reopened.cards.find(c=>c.id==='b').template.fill,true);
 // Legacy duplicates are resolved deterministically without losing content or card identities.
 const legacy=schema.defaultState();legacy.canvasAspect=aspect;legacy.cards=[create('low',aspect),create('high',aspect)];legacy.cards.forEach((c,i)=>{c.z=i+1;toggle(c,aspect);});
 const restored=schema.normalizeState(JSON.parse(JSON.stringify(legacy)));assert.equal(restored.cards.length,2);assert.equal(restored.cards[0].template.fill,false);assert.equal(restored.cards[1].template.fill,true);assert.equal(JSON.stringify(schema.normalizeState(restored)),JSON.stringify(restored),'migration is idempotent');scenarios++;
}
// Execute real storage insertion/cross-canvas copy methods, not a policy-only simulation.
const source=fs.readFileSync('entry/src/main/ets/model/FridgeModel.ets','utf8');
const add=source.slice(source.indexOf('  addCard('),source.indexOf('  removeCard('));
const copy=source.slice(source.indexOf('  copyCard('),source.indexOf('  async deleteTimedScene('));
const env={exports:{},...policy,BOARD_W:344,BOARD_H:470,assertCanvasCapacity:(old,n)=>{if(old+n>100)throw Error('capacity');},canvasKey:id=>id,storageSnapshot:JSON.stringify};
vm.runInNewContext(ts.transpileModule(`export class Store {state={canvasId:'a',canvasAspect:1,cards:[]};catalog={scenes:[]};seq=10;target=null;saveQueue=Promise.resolve();prefs={put:async()=>{},flush:async()=>{}};documents=[];savedScenes={};newId(){return 'copy'+(++this.seq);}nextZ(){return ++this.seq;}canvasSnapshot(){return Promise.resolve(this.target);}queueFor(){return{waitForIdle:async()=>{},invalidate(){},submit:async()=>{}};} ${add}${copy}}`,{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,env);
(async()=>{
 const store=new env.exports.Store(),owner=create('owner');toggle(owner,1);store.state.cards=[owner];
 const copy=structuredClone(owner);copy.id='duplicated';store.addCard(copy);assert.equal(owner.template.fill,true);assert.equal(copy.template.fill,false);assert.equal(store.state.cards.length,2);
 const imported=[create('import1'),create('import2')];imported.forEach(c=>toggle(c,1));store.addCards(imported);assert.equal(store.state.cards.filter(c=>c.template?.fill).length,1);assert(imported.every(c=>!c.template.fill));
 store.target={canvasId:'b',canvasAspect:2,maxZ:20,cards:[create('target',2)]};toggle(store.target.cards[0],2);await store.copyCardTo(owner,'b');assert.equal(store.target.cards.filter(c=>c.template?.fill).length,1);assert.equal(store.target.cards[0].template.fill,true);assert.equal(owner.template.fill,true);
 const empty=new env.exports.Store(),full=create('only');toggle(full,1);empty.addCard(full);assert.equal(full.template.fill,true,'empty canvas can accept a full-canvas import');
 console.log(`PASS single full-canvas policy: ${scenarios} ratios; switch/restore, paired undo/redo, ordinary-card isolation, legacy migration, idempotent reopening, actual add/import/duplicate/cross-canvas copy methods`);
})().catch(e=>{console.error(e);process.exitCode=1;});
