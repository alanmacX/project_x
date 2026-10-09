(async()=>{
const assert=require('node:assert/strict'),fs=require('node:fs'),vm=require('node:vm');
const ts=require('/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript');
const source=fs.readFileSync('entry/src/main/ets/pages/Index.ets','utf8');
const frame=source.slice(source.indexOf('class PreparedTransition'),source.indexOf('@Entry'));
const arrival=source.slice(source.indexOf('  private arrivalOffsets:'),source.indexOf('  private arrivalX(')).replace(/@State\s*/g,'');
const frames=[],timers=[],animations=[],marks=[];
const sandbox={FrameCallback:class{},setTimeout:fn=>{timers.push(fn);return timers.length;},revealStartup:async()=>{},startupMark:s=>marks.push(s),BOARD_W:400,arrivalOffset:()=>({x:1,y:1}),Curve:{Friction:1},exports:{}};
const fixture=frame+'\nclass Fixture { alive=true;editing=false;viewing=false;cards=[{id:"a"},{id:"b"},{id:"c"}];cardIds=["a","b","c"];boardScale=1;boardHeight=400;frameRate={};arriving=false;arrival=0;boardOpacity=1;getUIContext(){return ui;}\n'+arrival+'\n}\nexports.Fixture=Fixture;exports.Frame=PreparedTransition;';
sandbox.ui={postFrameCallback:f=>frames.push(f),animateTo:(opts,fn)=>{animations.push(opts);fn();}};
vm.runInNewContext(ts.transpileModule(fixture,{compilerOptions:{target:ts.ScriptTarget.ES2020}}).outputText,sandbox);
const Frame=sandbox.exports.Frame;let calls=0;
const callback=new Frame(()=>calls++);callback.onIdle(0);assert.equal(calls,0);
callback.onFrame(1);assert.equal(calls,0,'do not run application work inside the frame callback');timers.shift()();assert.equal(calls,1,'a busy renderer that never calls onIdle must still progress');
const idle=new Frame(()=>calls++,true);idle.onFrame(1);assert.equal(timers.length,0);idle.onIdle(2);assert.equal(calls,2,'startup idle measurement remains separate from transition scheduling');
const f=new sandbox.exports.Fixture();f.startArrival();assert.equal(f.startupCardCount,0);assert.ok(f.boardOpacity>0,'zero alpha would prevent texture warming');
function next(){frames.shift().onFrame(1);timers.shift()();}
for(let i=1;i<=3;i++){next();assert.equal(f.startupCardCount,i);assert.equal(animations.length,0,'never expose a partially constructed card scene');}
next();assert.equal(f.startupCardCount,-1);assert.equal(f.arrival,1);assert.equal(f.boardOpacity,0);assert.equal(animations.length,0,'commit the offscreen pose before animation');
next();await new Promise(setImmediate);assert.equal(animations.length,1);assert.equal(f.arrival,0);assert.equal(f.boardOpacity,1);assert.deepEqual(marks,['surfaces-ready','arrival-start']);animations[0].onFinish();assert.equal(f.arriving,false);
const stopped=new sandbox.exports.Fixture();stopped.startArrival();stopped.alive=false;next();assert.equal(animations.length,1,'destroyed pages cannot launch pending animations');assert.equal(frames.length,0);
const widget=new sandbox.exports.Fixture();widget.prepareWidgetScene();
assert.equal(widget.startupCardCount,0);assert.equal(widget.arrival,0,'widget native transition uses the final card pose');
for(let i=1;i<=3;i++){next();assert.equal(widget.startupCardCount,i);}
next();assert.equal(widget.startupCardCount,-1);assert.equal(widget.boardOpacity,1);assert.equal(widget.arriving,false);
next();assert.equal(animations.length,1,'widget preparation never starts another scatter animation');
assert.ok(marks.includes('widget-surfaces-ready'));
console.log('PASS startup: frame callbacks progress without idle budget; one card per prepared frame; warm textures before coordinated arrival; destroyed-page cancellation');
const foreground=source.slice(source.indexOf('  private scheduleForegroundRefresh():'),source.indexOf('  private syncSchedules():'));
const pending=new Map();let sequence=0,refreshes=0;
const resume={exports:{},Date,setTimeout:(fn,delay)=>{assert.equal(delay,700);pending.set(++sequence,fn);return sequence;},clearTimeout:id=>pending.delete(id)};
vm.runInNewContext(ts.transpileModule('class Resume {pageVisible=true;appWindowFocused=true;foregroundGeneration=0;cancelForegroundRefresh(){this.foregroundGeneration++;if(this.foregroundRefreshTimer>=0)clearTimeout(this.foregroundRefreshTimer);this.foregroundRefreshTimer=-1;}alive=true;appBackgrounded=false;arriving=false;heroActive=false;activeBoardId="";gestureGroup="";foregroundRefreshTimer=-1;tick=0;foregroundSchedules(){refresh();}'+foreground+'}\nexports.Resume=Resume;', {compilerOptions:{target:ts.ScriptTarget.ES2020}}).outputText,{...resume,refresh:()=>refreshes++});
const resumed=new resume.exports.Resume();resumed.scheduleForegroundRefresh();resumed.scheduleForegroundRefresh();assert.equal(pending.size,1,'PageShow and Foreground coalesce');assert.equal(refreshes,0,'no scene reconciliation during system entrance');
function runPending(){const [id,fn]=pending.entries().next().value;pending.delete(id);fn();}
resumed.heroActive=true;runPending();assert.equal(refreshes,0);assert.equal(pending.size,1,'do not refresh during an app transition');
resumed.heroActive=false;runPending();assert.equal(refreshes,1);assert.equal(resumed.tick%60000,0,'same-minute resumes do not invalidate time content twice');
resumed.scheduleForegroundRefresh();resumed.appBackgrounded=true;runPending();assert.equal(refreshes,1,'returning to background cancels reconciliation');
console.log('PASS resume: lifecycle coalescing, window entrance budget, gesture/transition deferral and background cancellation');

})().catch(e=>{console.error(e);process.exitCode=1;});
