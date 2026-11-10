const assert=require('node:assert/strict'),fs=require('node:fs'),vm=require('node:vm');
const ts=require('/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript');
const source=fs.readFileSync('entry/src/main/ets/form/WidgetConfigAbility.ets','utf8');
class Storage{constructor(){this.values=new Map();}setOrCreate(k,v){this.values.set(k,v);}}
(async()=>{
const env={exports:{},LocalStorage:Storage,require:s=>s==='@kit.FormKit'?{FormEditExtensionAbility:class{}}:{widgetDimension:v=>v===2?'2*2':'',registerWidget:async(context,id,dimension)=>({dimension:dimension||'2*2'})}};
vm.runInNewContext(ts.transpileModule(source,{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,env);
const ability=new env.exports.default(),sessions=[];
for(const [cardId,previewCardId] of [['actual-A','preview-A'],['actual-B','preview-B']])await ability.prepare({parameters:{cardId,previewCardId,'ohos.extra.param.key.form_dimension':2}},{loadContent:(page,storage)=>sessions.push({page,storage})});
assert.equal(sessions[0].page,'pages/WidgetBinding');assert.equal(sessions[0].storage.values.get('formId'),'actual-A');assert.equal(sessions[1].storage.values.get('formId'),'actual-B');assert.equal(sessions[0].storage.values.get('previewFormId'),'preview-A');assert.notEqual(sessions[0].storage,sessions[1].storage,'each system session owns its local state');
const manifest=fs.readFileSync('entry/src/main/module.json5','utf8'),config=JSON.parse(fs.readFileSync('entry/src/main/resources/base/profile/form_config.json','utf8'));
assert.match(manifest,/"name":"WidgetConfigAbility"[^\n]+"type":"formEdit"/);
assert.deepEqual(config.forms[0].supportDimensions,['4*4','2*4','2*2']);assert.equal(config.forms[0].formConfigAbility,'ability://WidgetConfigAbility');
const panel=fs.readFileSync('entry/src/main/ets/pages/WidgetBinding.ets','utf8');assert.match(panel,/getSharedLocalStorage/);assert.doesNotMatch(panel,/AddFormMenuItem|HdsNavigation|router\./,'system owns preview, title, size picker and Done');
const gallery=fs.readFileSync('entry/src/main/ets/views/CanvasGallery.ets','utf8');assert.doesNotMatch(gallery,/pages\/WidgetBinding/,'no app gallery binding route');
const index=fs.readFileSync('entry/src/main/ets/pages/Index.ets','utf8'),start=index.indexOf('  private showCardActions()'),end=index.indexOf('  private selectedActionAnchor()',start);
const fixture={exports:{}};vm.runInNewContext(ts.transpileModule('export class Fixture{'+index.slice(start,end)+'}',{compilerOptions:{module:ts.ModuleKind.CommonJS}}).outputText,fixture);
const f=new fixture.exports.Fixture();f.cardMap={a:{hidden:false}};f.selectedId='a';f.selectedGroup=()=>[];
for(const panel of ['backgroundOpen','homeToolsOpen','scheduleOpen']){f[panel]=true;assert.equal(f.showCardActions(),false,'panel owns selected-card actions while open: '+panel);f[panel]=false;}
f.editing=true;assert.equal(f.showCardActions(),false);f.editing=false;f.cardMap.a.hidden=true;assert.equal(f.showCardActions(),false);
console.log('PASS native formEdit sessions, independent preview IDs, system-only configuration route, three sizes and selected-card actions across panels.');

})().catch(e=>{console.error(e);process.exitCode=1;});
