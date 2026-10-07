const assert=require('node:assert/strict'),fs=require('node:fs'),path=require('node:path'),vm=require('node:vm');
const ts=require('/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript');
const source=fs.readFileSync(path.resolve(__dirname,'../entry/src/main/ets/views/AlbumCapability.ets'),'utf8');
const method=source.slice(source.indexOf('  private ready('),source.indexOf('  @Builder private artwork'));
const code=ts.transpileModule('class Subject {'+method+'};globalThis.Subject=Subject;', {compilerOptions:{target:ts.ScriptTarget.ES2020}}).outputText;
const context={Curve:{EaseInOut:0}};vm.createContext(context);vm.runInContext(code,context);
function subject(widget,previous){const s=new context.Subject();Object.assign(s,{widget,current:{cover:'new'},previous:{cover:previous},coverReady:false,backgroundReady:false,opacityValue:0,generation:1});s.getUIContext=()=>{throw Error('Form has no app UIContext')};return s;}
const form=subject(true,'old');form.ready('stale',false);assert.equal(form.coverReady,false);form.ready('new',false);assert.equal(form.opacityValue,0);form.ready('new',true);assert.equal(form.opacityValue,1);assert.equal(form.previous.cover,'');
const first=subject(false,'');first.ready('new',true);first.ready('new',false);assert.equal(first.opacityValue,1);
const app=subject(false,'old');let animation;app.getUIContext=()=>({animateTo:(options,apply)=>{animation=options;apply();}});app.ready('new',true);assert.equal(animation,undefined);app.ready('new',false);assert.equal(animation.duration,420);assert.equal(app.opacityValue,1);app.generation++;animation.onFinish();assert.equal(app.previous.cover,'old');
console.log('PASS album image callbacks: Form and initial load need no app UIContext; paired app transitions preserve generation guards.');
