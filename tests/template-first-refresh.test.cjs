const assert=require('node:assert/strict'),fs=require('node:fs'),vm=require('node:vm'),ts=require('typescript');
const models=vm.createContext({});vm.runInContext(fs.readFileSync('previewer/shared-models.js','utf8'),models);
const source=fs.readFileSync('entry/src/main/ets/pages/Index.ets','utf8');
const creation=source.slice(source.indexOf('  private async createTemplate('),source.indexOf('  private templatePhotoElement('));
const scheduling=source.slice(source.indexOf('  private scheduleForegroundRefresh():'),source.indexOf('  private syncSchedules():'));
const timers=new Map();let sequence=0,id=0;
const env={exports:{},Date,makeTemplateCards:models.FridgeCore.load('TemplateFactory').makeTemplateCards,setTimeout:(fn,delay)=>{assert.ok(delay<60000);timers.set(++sequence,fn);return sequence;},clearTimeout:key=>timers.delete(key)};
const fixture=`export class Host {
 alive=true;busy=false;canvasAspect=2;pageVisible=true;appWindowFocused=true;appBackgrounded=false;foregroundGeneration=0;foregroundRefreshTimer=-1;heroActive=false;arriving=false;deletionId='';activeBoardId='';layerDrag='';gestureGroup='';tick=0;reads=0;
 store={state:{canvasId:'qa',cards:[]},newId:()=>nextId(),addCards:(cards)=>{this.store.state.cards.push(...cards);}};
 canAddCards(){return true;}clamp(){}select(){}change(){}openEditor(){this.heroActive=true;}
 cancelForegroundRefresh(){this.foregroundGeneration++;if(this.foregroundRefreshTimer>=0)clearTimeout(this.foregroundRefreshTimer);this.foregroundRefreshTimer=-1;}
 foregroundSchedules(){this.reads++;for(const c of this.store.state.cards)if(c.capability.k==='battery')c.capability.percent=78;}
 refreshCapabilities(){if(!this.heroActive)this.foregroundSchedules();}
 getUIContext(){return {getPromptAction:()=>({showToast:()=>{throw Error('unexpected creation failure');}})};}
 ${creation}${scheduling}}
`;
vm.runInNewContext(ts.transpileModule(fixture,{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,{...env,nextId:()=>String(++id)});
function flush(){assert.ok(timers.size);const [key,fn]=timers.entries().next().value;timers.delete(key);fn();}
(async()=>{const host=new env.exports.Host();await host.createTemplate('mix-modular');assert.equal(host.store.state.cards.length,3);assert.equal(host.reads,0);assert.equal(timers.size,1,'first provider refresh must survive opening animation');flush();assert.equal(host.reads,0);assert.equal(timers.size,1);host.heroActive=false;flush();assert.equal(host.reads,1);assert.equal(host.store.state.cards.find(c=>c.capability.k==='battery').capability.percent,78);assert.equal(timers.size,0);console.log('PASS new composition refresh: opening transition defers rather than drops the first provider read; no minute-long battery placeholder');})().catch(e=>{console.error(e);process.exitCode=1;});
