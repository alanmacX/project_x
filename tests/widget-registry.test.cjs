const assert=require('node:assert/strict'),fs=require('node:fs'),path=require('node:path'),vm=require('node:vm');
const ts=require('/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript');
const {createWidgetRdb}=require('./helpers/widget-rdb.cjs'),rdb=createWidgetRdb(),disk=new Map(),nativeDims=new Map(),root=path.resolve('entry/src/main/ets/model');
const prefs={get:async(k,f)=>disk.get(k)??f,put:async(k,v)=>disk.set(k,v),flush:async()=>{},delete:async k=>disk.delete(k)};
function processLoader(){const cache=new Map();return function load(name){if(name==='LibraryStorage')return {getLibraryPreferences:async()=>prefs};if(cache.has(name))return cache.get(name);const module={exports:{}};cache.set(name,module.exports);const code=ts.transpileModule(fs.readFileSync(path.join(root,name+'.ets'),'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText;
 const kits={'@kit.ArkData':rdb,'@ohos.data.preferences':{default:{getPreferences:async()=>prefs,removePreferencesFromCache:async()=>{}}},'@kit.FormKit':{formProvider:{getPublishedRunningFormInfoById:async id=>{if(!nativeDims.has(id))throw Error('not published');return {dimension:nativeDims.get(id)};}}}};
 vm.runInThisContext('(function(require,module,exports){'+code+'\n})')(s=>kits[s]||load(s.replace('./','')),module,module.exports);return module.exports;};}
(async()=>{
 const app=processLoader()('WidgetRegistry'),form=processLoader()('WidgetRegistry'),edit=processLoader()('WidgetRegistry'),context={databaseDir:'/same-database'};
 const canvases=[['large','4*4'],['small','2*2'],['strip','2*4']];
 disk.set('fridge_canvases_json',JSON.stringify({version:1,activeId:'large',desktopFollowsSelection:true,canvases:canvases.map(([id])=>({id,name:id}))}));
 for(const [id,canvasDimension] of canvases)disk.set('fridge_canvas_'+id,JSON.stringify({canvasId:id,canvasDimension,cards:[]}));
 assert.equal(app.widgetDimension(undefined),'','unknown is never guessed as 4×4');assert.equal(app.widgetDimension(2),'2*2');
 nativeDims.set('A',4);nativeDims.set('B',2);nativeDims.set('C',3);
 await Promise.all([form.registerWidget(context,'A','4*4'),form.registerWidget(context,'B','2*2'),form.registerWidget(context,'C','2*4')]);
 await Promise.all([edit.selectWidgetCanvas(context,'A','large','4*4'),edit.selectWidgetCanvas(context,'B','small','2*2'),edit.selectWidgetCanvas(context,'C','strip','2*4')]);
 assert.equal((await app.widgetInstance(context,'A')).canvasId,'large');assert.equal((await app.widgetInstance(context,'B')).canvasId,'small');
 await assert.rejects(edit.selectWidgetCanvas(context,'A','small','4*4'),/相同尺寸/);
 // A delayed onAdd with absent or wrong dimension cannot rewrite the real system size or binding.
 await form.registerWidget(context,'B','4*4');await form.registerWidget(context,'A','');
 assert.equal((await app.widgetInstance(context,'B')).dimension,'2*2');assert.equal((await app.widgetInstance(context,'B')).canvasId,'small');
 await assert.rejects(edit.registerWidget(context,'A','2*2','B',true),/不能覆盖/);
 await edit.registerWidget(context,'P','4*4','B',true);assert.equal((await form.widgetInstance(context,'P')).dimension,'2*2','preview inherits its owner, never a default');
 await form.removeWidget(context,'P');await assert.rejects(form.registerWidget(context,'P','2*2','B',true),/已移除/);
 assert.equal((await app.widgetInstance(context,'B')).canvasId,'small','preview removal never deletes its owner');
 // Legacy imports and foreground changes can neither reset native choices nor resurrect tombstones.
 disk.set('fridge_form_dims_json',JSON.stringify({A:'2*2',B:'4*4',P:'4*4'}));disk.set('fridge_form_bindings_json',JSON.stringify({A:'small',B:'large',P:'large'}));
 await app.importLegacyWidgets(context);assert.equal((await app.widgetInstance(context,'A')).canvasId,'large');assert((await app.widgetInstance(context,'P')).removed);
 // Cross-process delivery fences: stale revision rejected, live IPC globally serialized.
 const old=await app.widgetInstance(context,'A'),guard=new app.WidgetGuard(context,old),lease=await app.acquireWidgetDelivery(guard);assert(lease);
 let acquired=false;const competing=form.acquireWidgetDelivery(new form.WidgetGuard(context,old)).then(token=>{acquired=true;return token;});
 await new Promise(r=>setTimeout(r,100));assert(!acquired,'another process cannot publish over in-flight IPC');await app.releaseWidgetDelivery(guard,lease);
 const nextLease=await competing;assert(nextLease);await form.releaseWidgetDelivery(guard,nextLease);
 await edit.selectWidgetCanvas(context,'A','large','4*4');assert.equal(await app.acquireWidgetDelivery(guard),'','queued old revision cannot overwrite a new binding');
 const restart=processLoader()('WidgetRegistry');assert.equal((await restart.widgetInstance(context,'B')).canvasId,'small','binding survives process restart');
 assert.equal((await app.widgetInstances(context)).length,3,'native previews excluded from routine refresh');
 disk.set('fridge_canvas_small','{broken');await assert.rejects(edit.selectWidgetCanvas(context,'B','small','2*2'));assert.equal((await app.widgetInstance(context,'B')).canvasId,'small','failed read preserves previous binding');
 console.log('PASS real SQLite registry: 3 processes/sizes, concurrent writes, strict dimensions, absent Want values, preview isolation, stale migrations, tombstones, IPC lease/revision fences and restart.');
})().catch(e=>{console.error(e);process.exitCode=1;});
