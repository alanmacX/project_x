const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),{DatabaseSync}=require('node:sqlite');
const ts=require('./typescript.cjs');
const cache=new Map(),databases=new Map();const root=path.resolve('entry/src/main/ets/model');let killedPoint=false;
function wrap(db){const api={executeSql:async(sql,args=[])=>db.prepare(sql).run(...args),execute:async(sql,args=[])=>{
 const out=db.prepare(sql).run(...args);if(process.env.POINT==='mid'&&!killedPoint&&sql.startsWith('INSERT OR REPLACE INTO library_values')&&args[0]==='fridge_canvas_a'){killedPoint=true;process.send({point:'mid'});await new Promise(()=>{});}return out.changes;
},querySql:async(sql,args=[])=>{const rows=db.prepare(sql).all(...args);let i=-1;return {goToFirstRow(){i=0;return !!rows.length;},goToNextRow(){return ++i<rows.length;},getString(c){return Object.values(rows[i])[c]},close(){}};}};
api.createTransaction=async()=>{db.exec('BEGIN IMMEDIATE');return {...api,commit:async()=>{db.exec('COMMIT');if(process.env.POINT==='committed'&&!killedPoint){killedPoint=true;process.send({point:'committed'});await new Promise(()=>{});}},rollback:async()=>db.exec('ROLLBACK')};};return api;}
function load(name){if(cache.has(name))return cache.get(name);const out={exports:{}};cache.set(name,out.exports);
const env={exports:out.exports,console,require:s=>{
 if(s==='./LibraryBackup')return {queueLibraryBackup:()=>{}};
 if(s==='@kit.ArkData')return {relationalStore:{SecurityLevel:{S1:1},getRdbStore:async(ctx,options)=>{const file=path.join(ctx.databaseDir,options.name);if(!databases.has(file)){const db=new DatabaseSync(file);db.exec('PRAGMA busy_timeout=15000; PRAGMA journal_mode=WAL; PRAGMA synchronous=FULL');databases.set(file,db);}return wrap(databases.get(file));}}};
 if(s==='@kit.CoreFileKit')return {fileIo:{accessSync:p=>fs.existsSync(p)}};
 if(s==='@ohos.data.preferences')return {default:{getPreferences:async()=>({getAll:async()=>({fridge_canvases_json:JSON.stringify({version:1,canvases:[{id:'a',name:'old'}]}),fridge_canvas_a:JSON.stringify({canvasId:'a',cards:[{id:'old'}]})})})}};
 if(s==='./CanvasLibrary')return {readCatalog:json=>{const c=JSON.parse(json);if(c.version!==1||!Array.isArray(c.canvases)||!c.canvases.length)throw Error('bad catalog');return {...c,scenes:c.scenes??[]};}};
 if(s==='./CardSchema')return {};
 return load(s.replace('./',''));
}};vm.runInNewContext(ts.transpileModule(fs.readFileSync(path.join(root,name+'.ets'),'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,env);return out.exports;}
(async()=>{const session=await load('LibraryStorage').getLibraryPreferences({databaseDir:process.env.DB_DIR,preferencesDir:process.env.DB_DIR,filesDir:process.env.DB_DIR});
if(process.env.MODE==='mutate'){
 await session.get('fridge_canvas_a','');await session.get('fridge_canvases_json','');await session.put('fridge_canvas_a',JSON.stringify({canvasId:'a',cards:[{id:'new'}]}));await session.put('fridge_canvases_json',JSON.stringify({version:1,canvases:[{id:'a',name:'new'}]}));await session.flush();
}else if(process.env.MODE==='parallel'){
 for(let i=0;i<40;i++){await session.put('independent_'+process.env.ACTOR+'_'+i,i);await session.flush();}
}
for(const db of databases.values())db.close();process.send({done:true});process.disconnect();})().catch(e=>{process.send({error:e.stack});process.exitCode=1;process.disconnect();});
