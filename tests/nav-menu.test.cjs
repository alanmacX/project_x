const assert=require('node:assert/strict'),fs=require('node:fs'),vm=require('node:vm');
const ts=require('/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript');
const source=fs.readFileSync('entry/src/main/ets/pages/Index.ets','utf8');
const methods=source.slice(source.indexOf('  private finishNavMenu('),source.indexOf('  private async showEditorActions('));
const env={exports:{}};vm.runInNewContext(ts.transpileModule('export class Harness {'+methods+'}',{compilerOptions:{module:ts.ModuleKind.CommonJS}}).outputText,env);
(async()=>{
const view=new env.exports.Harness();Object.assign(view,{screenWidth:400,safeTop:24,navMenuResolve:null,getUIContext:()=>({px2vp:p=>p/2,getComponentUtils:()=>({getRectangleById:()=>({size:{width:80,height:88},windowOffset:{x:600,y:60}})})})});
const choice=view.navChoice('添加',['文字','图片'],'add');assert.equal(view.navMenuX,340);assert.equal(view.navMenuY,78);let resolved=false;choice.then(()=>resolved=true);
assert.equal(await view.navChoice('重复',['错误'],'add'),-1,'a second call cannot replace an active menu');view.navMenuItems[1].action();await Promise.resolve();assert.equal(resolved,false,'wait for native exit before opening the next chooser');view.finishNavMenu(view.navMenuResult);assert.equal(await choice,1);
const next=view.navChoice('格式',['PNG','JPG'],'share');view.finishNavMenu(-1);assert.equal(await next,-1,'back/dismiss/destroy cannot export anything');assert.equal(view.navMenuResolve,null);
console.log('PASS anchored native menus: measured pixel/vp coordinates, single owner, exit-before-next-menu and cancellation.');
})().catch(e=>{console.error(e);process.exitCode=1;});
