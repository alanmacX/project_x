const fs=require('node:fs'),vm=require('node:vm'),assert=require('node:assert/strict');
const ts=require('/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript');
const source=fs.readFileSync('entry/src/main/ets/pages/WidgetBinding.ets','utf8'),calls=[];let fail=false;
const start=source.indexOf('  private async load()'),end=source.indexOf('  @Builder',start);
const env={exports:{},BindingChoice:class{},widgetInstance:async()=>({dimension:'2*2',canvasId:'',removed:false}),bindingCanvases:async()=>[
 {id:'empty',name:'空画布',dimension:'2*2',aspect:1,cardCount:0},{id:'full',name:'日常',dimension:'2*2',aspect:1,cardCount:2},{id:'large',name:'大画布',dimension:'4*4',aspect:1,cardCount:4}],cachedGalleryPreview:async()=>null,bindWidget:async(ctx,id,canvas,dim)=>{if(fail)throw Error('save failed');calls.push([id,canvas,dim]);}};
vm.runInNewContext(ts.transpileModule(`export class Fixture{alive=true;formId='new-widget';previewFormId='system-preview';dimension='';choices=[];ready=false;busy=false;error='';selectedId='';context(){return {config:{colorMode:0},cacheDir:'/cache'};} ${source.slice(start,end)}}`,{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,env);
(async()=>{
 const f=new env.exports.Fixture();await f.load();assert.equal(f.ready,true);assert.deepEqual(Array.from(f.choices,c=>c.id),['empty','full'],'new unbound widget can list empty and populated matching canvases');assert.equal(f.selectedId,'');assert.equal(calls.length,0,'loading choices never silently binds the first canvas');
 await f.choose('empty');assert.equal(f.selectedId,'empty');assert.deepEqual(calls,[['new-widget','empty','2*2'],['system-preview','empty','2*2']]);
 fail=true;await f.choose('full');assert.equal(f.selectedId,'empty','failed save retains previous choice');assert.equal(f.busy,false);assert.match(f.error,/save failed/);
 assert.doesNotMatch(source,/backgroundColor\(AppDesign\.control|backgroundColor\(item\.id===this\.selectedId\?AppDesign\.control/,'option rows have no separate colored backplates');
 console.log('PASS system binding panel: new unbound session, empty canvas selection, size filtering, independent preview update, retained choice on save failure and no separate option backplates.');
})().catch(e=>{console.error(e);process.exitCode=1;});
