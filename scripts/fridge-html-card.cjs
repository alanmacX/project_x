#!/usr/bin/env node
// Offline authoring helper. No browser dependencies, no execution of imported scripts.
const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm');
const repo=path.resolve(__dirname,'..'),ctx=vm.createContext({});
vm.runInContext(fs.readFileSync(path.join(repo,'previewer/shared-models.js'),'utf8'),ctx);
const core=ctx.FridgeCore,schema=core.load('CardSchema'),htmlModel=core.load('HtmlCardTemplate');
const [mode,sourcePath,configPath,last,outputPath]=process.argv.slice(2);
if(!['prepare','pack'].includes(mode)||!sourcePath||!configPath||!last||(mode==='pack'&&!outputPath))throw Error('prepare source.html config.json preview.html | pack source.html config.json preview.png output.fridge');
const source=fs.readFileSync(sourcePath,'utf8'),config=JSON.parse(fs.readFileSync(configPath,'utf8'));
const template={version:1,designVersion:1,width:config.width,height:config.height,source,previewElementId:'html-appearance'};
htmlModel.validateHtmlCard(template);
if(config.width>320||config.height>420)throw Error('Native card authoring dimensions must be <=320 × 420 vp');
if(mode==='prepare'){
 const csp="default-src 'none'; img-src data:; style-src 'unsafe-inline'; font-src 'none'; base-uri 'none'; form-action 'none'; script-src 'none'; connect-src 'none'";
 const document='<!doctype html><meta http-equiv="Content-Security-Policy" content="'+csp+'"><style>html,body{margin:0;width:100%;height:100%;overflow:hidden}</style>'+source;
 const escaped=document.replace(/[&"<>]/g,c=>({'&':'&amp;','"':'&quot;','<':'&lt;','>':'&gt;'}[c]));
 fs.writeFileSync(last,'<!doctype html><meta charset="utf-8"><title>Fridge HTML appearance</title><style>body{margin:0}iframe{display:block;border:0;transform:scale(2);transform-origin:top left}</style><iframe title="HTML 外观缓存" sandbox="" width="'+config.width+'" height="'+config.height+'" srcdoc="'+escaped+'"></iframe>');
 console.log('Prepared isolated static HTML. Capture its 2x appearance viewport ('+(config.width*2)+' × '+(config.height*2)+' pixels); no native capability text belongs in this appearance.');
}else{
 const bytes=fs.readFileSync(last);
 if(bytes.subarray(0,8).toString('hex')!=='89504e470d0a1a0a')throw Error('Appearance cache must be PNG');
 const w=bytes.readUInt32BE(16),h=bytes.readUInt32BE(20);
 if(w<32||h<32||w>2048||h>2048||Math.abs(w/h-config.width/config.height)>.01)throw Error('Screenshot dimensions do not match the HTML viewport');
 const state=schema.defaultState(),card=new schema.FridgeCard(),el=new schema.CanvasElement();
 card.id='html-card';card.w=config.width;card.h=config.height;card.html=template;card.material='white';card.frame=false;
 if(config.capability){if(!schema.CAPABILITIES.includes(config.capability.k)||config.capability.k==='album')throw Error('Use one supported native capability; album retains its own appearance');card.capability=core.load('SharedCapability').sharedCapability(schema.normalizeCapability(config.capability));if(config.capBox)card.capBox=schema.normalizeBox(config.capBox);card.capFree=true;}
 Object.assign(el,{id:'html-appearance',kind:'image',src:'asset://0',x:0,y:0,w:1,h:1,rot:0,opacity:1,behindCapability:true});card.elements=[el];state.cards=[card];
 const pack={format:'fridgememo-template',version:2,kind:'card',state,assets:[{key:'asset://0',extension:'.png',data:bytes.toString('base64')}]};
 const json=JSON.stringify(pack);core.load('TemplatePackage').readPackage(json);fs.writeFileSync(outputPath,json);
 console.log('PASS v2 HTML source + appearance + native capability package: '+outputPath);
}
