const assert=require('node:assert/strict'),fs=require('node:fs'),vm=require('node:vm');
const ts=require('/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript');
const mod={exports:{}};
vm.runInNewContext(ts.transpileModule(fs.readFileSync('entry/src/main/ets/model/SuperResolutionPixels.ts','utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,{exports:mod.exports,Uint8Array,Int32Array,Math,Error});
const {extendSubjectColors,copySubjectAlpha}=mod.exports;
const original=Uint8Array.from([0,0,0,0,100,50,25,255,20,10,5,128,0,0,0,0]);
const saved=original.slice(),extended=extendSubjectColors(original,2,2,true);
assert.deepEqual(original,saved,'never mutate source or original alpha');
for(let i=0;i<4;i++)assert.deepEqual([...extended.slice(i*4,i*4+4)],[100,50,25,255],'transparent RGB extends foreground, not black');
assert.throws(()=>extendSubjectColors(new Uint8Array(16),2,2,false),/不透明/);
const nativeMask = new Uint8Array(16).fill(80);copySubjectAlpha(nativeMask,original);
assert.deepEqual([nativeMask[3],nativeMask[7],nativeMask[11],nativeMask[15]],[0,255,128,0]);
assert.equal(nativeMask[0],80);assert.throws(()=>copySubjectAlpha(nativeMask,new Uint8Array(4)),/尺寸/);

console.log('PASS super resolution: transparent edge color, premultiplication, immutable alpha, mask size validation');
