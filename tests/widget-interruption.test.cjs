const assert=require('node:assert/strict'),fs=require('node:fs'),vm=require('node:vm');
const ts=require('/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript');
const source=fs.readFileSync('entry/src/main/ets/pages/Index.ets','utf8');
function method(start,end){const a=source.indexOf(start);assert.ok(a>=0);return source.slice(a,source.indexOf(end,a));}
let sequence=0;const timers=new Map();let release;
const asyncRead=new Promise(r=>release=r);
const moduleMock={exports:{}};
const fixture=`class Fixture {
 alive=true;ready=true;pageVisible=true;appWindowFocused=true;appBackgrounded=false;foregroundGeneration=0;foregroundRefreshTimer=-1;
 saveTimer=-1;previewTimer=-1;gestureGroup='';deletionId='';arriving=false;heroActive=false;activeBoardId='';layerDrag='';
 tick=Math.floor(Date.now()/60000)*60000;saves=0;flushes=0;refreshes=0;scenes=0;
 store={reloadSceneAcknowledgements:()=>asyncRead,repairDesktopSelection:()=>Promise.resolve()};
 persist(){this.saves++;this.saveTimer=-1;}flushPreview(){this.flushes++;this.previewTimer=-1;this.gestureGroup='';this.saveTimer=2;}
 scheduleMaintenance(){}syncSchedules(){}refreshCapabilities(){this.refreshes++;}updateScheduledScene(){this.scenes++;}
 ${method('  private flushPendingEdits(', "\n  @StorageLink('appWindowFocused')")}
 ${method('  private windowFocusChanged(', '  private foregroundGeneration:')}
 ${method('  private cancelForegroundRefresh(', '\n\n  @State repairingSubjects')}
 ${method('  private async foregroundSchedules(', '  private syncSchedules(')}
 ${method('  onPageHide():','  private compareReading(')}
 ${method('  onPageShow():','  private taskSheetHeight(')}
} module.exports=Fixture;`;
vm.runInNewContext(ts.transpileModule(fixture,{compilerOptions:{target:ts.ScriptTarget.ES2020}}).outputText,{module:moduleMock,asyncRead,Date,setTimeout:(fn,ms)=>{const id=++sequence;timers.set(id,{fn,ms});return id;},clearTimeout:id=>timers.delete(id)});
(async()=>{
 const Fixture=moduleMock.exports,f=new Fixture();
 f.onPageShow();assert.equal(timers.size,1);assert.equal([...timers.values()][0].ms,700);
 f.appWindowFocused=false;f.windowFocusChanged();assert.equal(timers.size,0,'native focus loss cancels work before background callback');f.appWindowFocused=true;f.windowFocusChanged();
 f.onPageHide();assert.equal(timers.size,0);assert.equal(f.saves,0,'untouched widget roundtrip does not serialize/publish');
 f.flushPendingEdits();assert.equal(f.saves,0,'duplicate lifecycle callbacks do no work');
 f.saveTimer=7;f.flushPendingEdits();f.flushPendingEdits();assert.equal(f.saves,1,'pending edit is saved once');
 f.previewTimer=8;f.gestureGroup='drag';f.flushPendingEdits();assert.equal(f.flushes,1);assert.equal(f.saves,2,'unfinished gesture is committed and saved');
 f.onPageShow();const generation=f.foregroundGeneration;const pending=f.foregroundSchedules(generation);
 f.onPageHide();f.onPageShow();release();await pending;
 assert.equal(f.refreshes,0);assert.equal(f.scenes,0,'late work from previous entrance cannot mutate the next window animation');
 await f.foregroundSchedules(f.foregroundGeneration);assert.equal(f.refreshes,1);assert.equal(f.scenes,1,'settled visible entrance still refreshes system data and schedule');
 console.log('PASS interrupted widget entrance: pending timer cancellation, stale result isolation, untouched no-op exit and pending edit durability');
})().catch(e=>{console.error(e);process.exitCode=1;});
assert.match(source,/const widgetLaunch=AppStorage.get<boolean>\('launchFromWidget'\)===true/,'cold widget route uses the native launcher transition instead of a second scatter entrance');
assert.match(source,/if \(!routedLaunch && this.cardIds.length > 0\) this.startArrival\(\);/,'icon cold launch retains the designed entrance');
