const assert=require('node:assert/strict'),fs=require('node:fs'),vm=require('node:vm');
const ts=require('/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript');
function execute(source,globals={}){const env={exports:{},...globals};vm.runInNewContext(ts.transpileModule(source,{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,env);return env.exports;}
const cache=new Map();function load(name){if(cache.has(name))return cache.get(name);const api=execute(fs.readFileSync('entry/src/main/ets/model/'+name+'.ets','utf8'),{require:id=>load(id.replace('./',''))});cache.set(name,api);return api;}
const resolve=load('WakeUpImport'),school=load('SchoolImport');
const source=fs.readFileSync('entry/src/main/ets/views/TimetableImportSheet.ets','utf8');
const methods=source.slice(source.indexOf('  private accept('),source.indexOf('  build(){'));
const {Flow}=execute(`export class Flow {
 alive=true;stage=false;previewReady=false;error='';periods=false;replace=false;keepCalendar=false;writes=[];closed=0;
 onClose(){this.closed++;}onImport(...args){this.writes.push(args);}
 ${methods}
}`,resolve);
const snapshot={token:'fixture',done:true,courses:[{name:'测试课程',position:'A101',day:3,weeks:[1,3,5],startSection:11,endSection:12}],slots:[{number:11,startTime:'20:00',endTime:'20:45'},{number:12,startTime:'20:55',endTime:'21:40'}],config:{semesterStartDate:'2026-09-09'}};
const flow=new Flow();flow.accept(school.parseSchoolCourses(JSON.stringify(snapshot),'学校'));assert.equal(flow.stage,true);assert.equal(flow.previewReady,true);assert.equal(flow.writes.length,0,'reading school data only previews it');assert.equal(flow.closed,0,'read moves within the same sheet');flow.confirm();assert.equal(flow.writes.length,1);assert.equal(flow.closed,1);assert.equal(flow.writes[0][0],'2026-09-07');assert(flow.writes[0][1].every(c=>c.start==='20:00'&&c.end==='21:40'));
const incomplete=new Flow();incomplete.accept(school.parseSchoolCourses(JSON.stringify({...snapshot,slots:[]}), '学校'));assert.equal(incomplete.periods,true);assert.equal(incomplete.previewReady,false);incomplete.confirm();assert.equal(incomplete.writes.length,0);assert.equal(incomplete.closed,0,'missing real period times cannot import or close the sheet');assert(incomplete.error);
const failed=new Flow();failed.accept(school.parseSchoolCourses(JSON.stringify(snapshot),'学校'));failed.onImport=()=>{throw Error('保存失败');};failed.confirm();assert.equal(failed.closed,0);assert.equal(failed.error,'保存失败');
assert(!fs.existsSync('entry/src/main/ets/views/WakeUpImportDialog.ets'));
assert(!source.includes('CustomDialogController'));const settings=fs.readFileSync('entry/src/main/ets/views/CapabilitySettings.ets','utf8');assert(settings.includes('.bindSheet($$this.timetableImportOpen'));
console.log('PASS single school import sheet: read → preview → explicit commit, missing-time protection, failed save retains sheet and legacy entry removed.');
