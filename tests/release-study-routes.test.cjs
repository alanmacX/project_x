const assert=require('node:assert/strict'),fs=require('node:fs'),vm=require('node:vm');
const ts=require('/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript');
const src=fs.readFileSync('entry/src/main/ets/entryability/EntryAbility.ets','utf8');
const method=src.slice(src.indexOf('  onCreate('),src.indexOf('  private mainWindow:'));
const mod={exports:{}};vm.runInNewContext(ts.transpileModule(`class Harness{launchPage='pages/Index';routed=0;routeCard(){this.routed++}routeTemplate(){this.routed++}${method}}module.exports=Harness`,{compilerOptions:{target:ts.ScriptTarget.ES2020}}).outputText,{module:mod,startStartupTrace(){},startupMark(){},hilog:{info(){}},TAG:'test',AppStorage:{setOrCreate(){}}});
for(const debug of [false,true]) for(const name of ['sketch','cloud','edges','mica','album','preview']){const h=new mod.exports();h.context={applicationInfo:{debug},config:{}};h.updateAppearance=()=>{};h.onCreate({parameters:{demo:name}},{});assert.equal(h.launchPage,'pages/Index',name);assert.equal(h.routed,2,'normal widget/file routing retained');}
const pages=JSON.parse(fs.readFileSync('entry/src/main/resources/base/profile/main_pages.json','utf8')).src;
assert.deepEqual(pages,['pages/Index','pages/ReceiveTemplate']);
for(const name of ['SketchLab','ReadingDemo','MicaStudy','ReadingEdgeStudy','CloudAcceptance','AlbumStudy','FridgePreviewer']) {
 assert.equal(fs.existsSync(`entry/src/main/ets/pages/${name}.ets`),false,`${name} must be outside the application source tree`);
 assert.ok(fs.existsSync(`design/native-studies/archive/pages/${name}.ets`),`${name} source retained outside the build`);
}
console.log('PASS experimental pages excluded from app sources and page registry; demo intents ignored in debug and release; production file/widget routing retained.');
