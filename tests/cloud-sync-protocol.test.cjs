const fs=require('node:fs'),vm=require('node:vm'),assert=require('node:assert/strict');
const ts=require('/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript');
const env={exports:{}};vm.runInNewContext(ts.transpileModule(fs.readFileSync('entry/src/main/ets/model/CloudSyncProtocol.ets','utf8'),{compilerOptions:{target:ts.ScriptTarget.ES2020,module:ts.ModuleKind.CommonJS}}).outputText,env);
const api=env.exports;
function record(revision,clock,digest='a',deleted=false){return {version:1,entity:'canvas_a',kind:'canvas',name:'画布',revision,clock,deleted,data:deleted?'':'{}',assets:[],digest:digest.repeat(64)};}
const a=record('a',{A:1}),b=record('b',{A:2}),c=record('c',{A:1,B:1},'b');
assert(api.cloudDominates(b.clock,a.clock));assert(!api.cloudDominates(b.clock,c.clock));assert(!api.cloudDominates(a.clock,a.clock));
assert.equal(api.cloudResolution([b,a]).primary.revision,'b');
for(const group of [[b,c],[c,b]]){const r=api.cloudResolution(group);assert.equal(r.primary.revision,'b');assert.equal(r.copies.length,1);assert.deepEqual(JSON.parse(JSON.stringify(r.clock)),{A:2,B:1});}
const merged=record('m',{A:3,B:1});assert.equal(api.cloudResolution([a,b,c,merged]).primary.revision,'m');assert.equal(api.cloudResolution([a,b,c,merged]).copies.length,0);
const dead=record('dead',{A:1,B:2},'c',true);assert.equal(api.cloudResolution([b,dead]).primary.deleted,false,'offline edit survives concurrent deletion');
const finalDead=record('removed',{A:4,B:2},'c',true);assert.equal(api.cloudResolution([b,finalDead]).primary.deleted,true,'observed deletion wins over old content');
assert.equal(api.cloudResolution([b,record('other',{B:2})]).copies.length,0,'identical independent writes do not make conflict copies');
api.validateCloudRevision(a);for(const invalid of [{...a,entity:'../outside'},{...a,clock:{A:-1}},{...a,clock:[]},{...a,assets:['../../a.png']},{...a,assets:['a'.repeat(64)+'.exe']},{...dead,data:'private'}])assert.throws(()=>api.validateCloudRevision(invalid));
console.log('PASS cloud journal: causality, deterministic conflicts, convergence, edit/delete races, equivalent writes and bounded input validation.');
