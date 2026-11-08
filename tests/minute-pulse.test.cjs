const fs=require('node:fs'),vm=require('node:vm'),ts=require('typescript'),assert=require('node:assert/strict');
let now=Date.parse('2026-11-08T12:34:47.123Z'),id=0;const timers=new Map(),events=[],env={exports:{},Date:{now:()=>now},setTimeout:(fn,delay)=>{timers.set(++id,{fn,delay});return id;},clearTimeout:id=>timers.delete(id)};
vm.runInNewContext(ts.transpileModule(fs.readFileSync('entry/src/main/ets/model/MinutePulse.ets','utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,env);
const pulse=new env.exports.MinutePulse(()=>events.push(now));pulse.start();assert.equal(timers.size,1);assert.equal([...timers.values()][0].delay,12893);
function fire(late=0){const [key,timer]=[...timers.entries()][0];timers.delete(key);now+=timer.delay+late;timer.fn();}
fire();assert.equal(events.length,1);assert.equal(now%60000,16);assert.equal([...timers.values()][0].delay,60000);fire(2200);assert.equal([...timers.values()][0].delay,57800,'a late callback must realign, not drift every minute');
pulse.start();assert.equal(timers.size,1,'reappearance cannot duplicate the timer');pulse.stop();assert.equal(timers.size,0);const stopping=new env.exports.MinutePulse(()=>stopping.stop());stopping.start();fire();assert.equal(timers.size,0,'stopping inside callback must not rearm');
console.log('PASS one aligned minute pulse: delayed startup, late callback, restart and disposal');
