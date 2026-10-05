const assert=require('node:assert/strict'),fs=require('node:fs'),vm=require('node:vm');
const ts=require(process.env.FRIDGE_TYPESCRIPT||'/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript');
const closed=[],released=[],packed=[],shown=[];let failPacking=false;
const kits={
 '@kit.ImageKit':{image:{createImagePacker:()=>({packToFile:async(pixel,fd,opts)=>{packed.push({pixel,fd,opts});if(failPacking)throw Error('encoder failure');},release:async()=>released.push(true)})}},
 '@kit.CoreFileKit':{fileIo:{OpenMode:{CREATE:1,READ_WRITE:2},open:async path=>({fd:7}),closeSync:fd=>closed.push(fd)},fileUri:{getUriFromPath:path=>'file://app'+path}},
 '@kit.ShareKit':{systemShare:{SharedData:class{constructor(record){this.record=record;}},ShareController:class{constructor(data){this.data=data;}async show(context,options){shown.push({context,options,record:this.data.record});}},SharePreviewMode:{DETAIL:1}}},
 '@kit.ArkData':{uniformTypeDescriptor:{UniformDataType:{JPEG:'general.jpeg',PNG:'general.png',FILE:'general.file'}}},'@kit.AbilityKit':{},'./IncomingTemplate':{TEMPLATE_UTD:'com.fridgememo.template'}
};
const mod={exports:{}},source=fs.readFileSync('entry/src/main/ets/model/ImageShare.ets','utf8');
const js=ts.transpileModule(source,{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText;
vm.runInThisContext('(function(require,module,exports){'+js+'})')(s=>kits[s],mod,mod.exports);
(async()=>{
 const context={cacheDir:'/cache'},pixel={id:'pixel'};
 await mod.exports.sharePixelMap(context,pixel,false,'shareCard');
 assert.equal(packed[0].opts.format,'image/png');assert.equal(shown[0].record.utd,'general.png');assert.ok(shown[0].record.uri.startsWith('file://app/cache/'));assert.equal(shown[0].options.anchor,'shareCard');assert.equal(shown[0].record.content,undefined,'image bytes are not embedded in IPC');
 await mod.exports.sharePixelMap(context,pixel,true,'shareCanvas');assert.equal(packed[1].opts.format,'image/jpeg');assert.equal(shown[1].record.utd,'general.jpeg');assert.equal(shown[1].options.previewMode,1);assert.equal(shown[1].record.title,'我的画布 · created by 冰箱贴');
 failPacking=true;await assert.rejects(mod.exports.sharePixelMap(context,pixel,false,'shareCard'),/encoder failure/);assert.equal(closed.length,3);assert.equal(released.length,3);assert.equal(shown.length,2,'failed export cannot open a share panel with incomplete data');
 await mod.exports.shareTemplateFile(context,'/cache/卡片_1.fridge','shareCard');assert.equal(shown[2].record.utd,'com.fridgememo.template');assert.equal(shown[2].record.uri,'file://app/cache/卡片_1.fridge');assert.equal(shown[2].record.title,'可编辑卡片');assert.equal(shown[2].record.content,undefined,'editable package uses a URI, never a large IPC payload');
 console.log('PASS: PNG/JPEG packing, legal app file URI, native preview and anchors, resource cleanup, failed export never shared.');
})().catch(e=>{console.error(e);process.exitCode=1;});
