const fs=require('node:fs'),vm=require('node:vm'),assert=require('node:assert/strict'),ts=require('typescript');
const core=vm.createContext({});vm.runInContext(fs.readFileSync('previewer/shared-models.js','utf8'),core);const nativeCache=new Map();const load=n=>{try{return core.FridgeCore.load(n);}catch(e){if(!String(e.message).startsWith('Unknown shared model'))throw e;}if(nativeCache.has(n))return nativeCache.get(n);const out={exports:{}};nativeCache.set(n,out.exports);vm.runInNewContext(ts.transpileModule(fs.readFileSync('entry/src/main/ets/model/'+n+'.ets','utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,{exports:out.exports,require:p=>load(p.split('/').pop())});return out.exports;};
const source=fs.readFileSync('entry/src/main/ets/pages/Index.ets','utf8');
const local=source.slice(source.indexOf('  @State customizerOpen:'),source.indexOf('  private openMaterialLibrary(')).replaceAll('@State ','');
const route=source.slice(source.indexOf('  private openEditor('),source.indexOf('  private mountEditorSection('));
const env={exports:{},templateFillState:load('TemplateFillPolicy').templateFillState,SceneRect:load('SceneLayout').SceneRect,cardViewSnapshot:load('CardViewSnapshot').cardViewSnapshot,compositionPaletteState:load('CompositionPalette').compositionPaletteState,CardEditHistory:load('CardEditHistory').CardEditHistory};
vm.runInNewContext(ts.transpileModule(`export class Host {
 store={state:{canvasId:'board',cards:[]},findCard:(id)=>this.store.state.cards.find(c=>c.id===id)||null};
 panelLeft=20;panelTop=500;panelWidth=300;selectedId='';preview=null;busy=false;heroActive=false;arriving=false;editing=false;changes=0;legacy=false;scheduledName='';scheduleTransition=false;canvasBackground={mode:'solid',color:'#fff'};
 history=new CardEditHistory();scroller={scrollTo:()=>{}};
 beginCanvasEdit(){}syncHistoryAvailability(){}
 current(){return this.store.findCard(this.selectedId);}select(id){this.selectedId=id;this.preview=this.current();this.history.reset(this.preview);}
 syncFields(){this.preview=this.current();}change(){this.changes++;}templateCanvasBackground(){}editorLandscape(){return false;}
 boardRect(){return {x:40,y:280,w:220,h:220,rot:12};}editorRect(){return {};}setHeroPose(){}setTransitionClip(){}prepareEditorMotion(){this.legacy=true;}
 ${local}${route}
}`,{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,env);
const factory=load('TemplateFactory'),catalog=load('CardTemplate').CARD_TEMPLATES;
for(const template of catalog)for(const created of [false,true]){
 const h=new env.exports.Host(),card=factory.makeTemplateCards(template.id,1,()=>template.id)[0];h.store.state.cards=[card];h.busy=created;
 const before=JSON.stringify(card);h.openEditor(card.id,created);
 assert.equal(h.customizerOpen,true,`${template.id}: direct customization, including insertion while createTemplate is busy`);
 assert.equal(h.legacy,false,'template does not mount the old settings page first');assert.equal(h.editing,false);assert.equal(h.customizerEntranceRunning,true);assert.equal(h.customizerEntranceOrigin.w,created?28:220);assert.equal(h.customizerReturnOrigin.w,220,'new templates land at full canvas size');
 h.closeLocalPanel();assert.equal(JSON.stringify(card),before,'cancel preserves the card');assert.equal(h.changes,0);
}
const h=new env.exports.Host(),card=factory.makeTemplateCards('portrait',1,()=> 'photo')[0];Object.assign(card,{x:37,y:69,w:240,h:260,rot:13,z:7,groupId:'my-group'});const peer={id:'peer',groupId:'my-group',x:12};h.store.state.cards=[card,peer];h.openEditor(card.id);
const next=env.cardViewSnapshot(card);Object.assign(next,{x:0,y:0,w:344,h:344,rot:0,z:99,groupId:''});next.template.palette='ink';h.finishCustomizer(next);
for(const key of ['x','y','w','h','rot','z','groupId'])assert.equal(h.store.state.cards[0][key],card[key],key);
assert.equal(h.store.state.cards[1],peer);assert.equal(h.changes,1);assert.equal(h.customizerOpen,false);assert.equal(h.editing,false);assert.equal(h.history.undo().template.palette,card.template.palette);
h.openEditor(card.id);h.store.state.canvasId='another';const count=h.changes;h.finishCustomizer(next);assert.equal(h.changes,count,'wrong canvas refuses completion');
const a=new env.exports.Host();a.store.state.cards=[card];a.openEditor(card.id,false,true);assert.equal(a.legacy,false,'templates cannot bypass the focused editor through an old advanced flag');assert.equal(a.customizerOpen,true);
const ordinary=new env.exports.Host();ordinary.store.state.cards=[Object.assign(new (load('CardSchema').FridgeCard)(),{id:'ordinary'})];ordinary.openEditor('ordinary');assert.equal(ordinary.legacy,true,'ordinary card retains original precision editor');
console.log('PASS balanced editor: 44 templates × new/existing direct entry, cancel, original geometry/group preservation, single undo commit, canvas guard, no legacy template bypass and original ordinary-card editor');
const popupMethods=source.slice(source.indexOf('  private workspaceChromeVisible()'),source.indexOf('  private cancelGalleryTransition()'))+source.slice(source.indexOf('  private showCardActions()'),source.indexOf('  private selectedActionAnchor()'));
const popupEnv={exports:{}};vm.runInNewContext(ts.transpileModule(`export class PopupHost {selectedId='selected';cardMap={selected:{hidden:false}};selectedGroup(){return [];} ${popupMethods}}`,{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,popupEnv);
const popup=new popupEnv.exports.PopupHost();assert.equal(popup.showCardActions(),true);
for(const panel of ['customizerOpen','materialLibraryOpen']){popup[panel]=true;assert.equal(popup.showCardActions(),false,'canvas delete/edit popup cannot cover '+panel);assert.equal(popup.workspaceChromeVisible(),false);popup[panel]=false;assert.equal(popup.showCardActions(),true);}
console.log('PASS modal return: opening either panel hides canvas action popup/chrome; closing restores original selection actions');

for(const panel of ['homeToolsOpen','backgroundOpen','scheduleOpen']){popup[panel]=true;assert.equal(popup.showCardActions(),false);popup[panel]=false;}
