const assert=require('node:assert/strict'),fs=require('node:fs'),vm=require('node:vm');
const ts=require('/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript');
const timers=new Map();let serial=0;
const sandbox={exports:{},setTimeout:(fn,delay)=>{assert.equal(delay,2000);timers.set(++serial,fn);return serial;},clearTimeout:id=>timers.delete(id)};
vm.runInNewContext(ts.transpileModule(fs.readFileSync('entry/src/main/ets/model/StartupPresentation.ets','utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,sandbox);
(async()=>{
 const gate=sandbox.exports;let removed=0;
 gate.deferStartupReveal(async()=>{removed++;});assert.equal(removed,0,'initial empty frame must not remove the starting window');
 await Promise.all([gate.revealStartup(),gate.revealStartup()]);assert.equal(removed,1);assert.equal(timers.size,0);
 gate.deferStartupReveal(async()=>{removed++;});gate.cancelStartupReveal();await gate.revealStartup();assert.equal(removed,1,'destroyed window cannot be removed later');
 gate.deferStartupReveal(async()=>{removed+=100;});gate.deferStartupReveal(async()=>{removed++;});assert.equal(timers.size,1,'new stage supersedes previous deadline');
 timers.values().next().value();await Promise.resolve();assert.equal(removed,2,'deadline reveals the current stage');assert.equal(timers.size,0);
 gate.deferStartupReveal(async()=>{throw Error('window gone');});await gate.revealStartup();assert.equal(timers.size,0,'native rejection cannot leave the page held');
 const config=fs.readFileSync('entry/src/main/module.json5','utf8');assert.ok(config.includes('"enable.remove.starting.window","value":"true"'));
 console.log('PASS starting-window handoff: once-only reveal, cancellation, stage replacement, deadline and native rejection');
})().catch(e=>{console.error(e);process.exitCode=1;});
