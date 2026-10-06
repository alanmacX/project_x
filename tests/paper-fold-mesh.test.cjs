const assert=require('node:assert/strict'),fs=require('node:fs'),vm=require('node:vm');
const ts=require('/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript');
const mod={exports:{}};
vm.runInNewContext(ts.transpileModule(fs.readFileSync('entry/src/main/ets/model/PaperFoldMesh.ts','utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText,{exports:mod.exports,Math});
const {PaperFoldMesh}=mod.exports;
for(const [w,h] of [[320,420],[420,80],[48,640],[28,28]]) {
 const mesh=new PaperFoldMesh(w,h,44),vertices=mesh.vertices.slice(),faces=mesh.triangles.slice();
 assert.equal(vertices.length,49);assert.equal(faces.length,72);
 for(const p of vertices){assert.ok(Math.abs(p.px-(p.u+1)*w/2)<1e-8);assert.ok(Math.abs(p.py-(p.v+1)*h/2)<1e-8);}
 for(let frame=0;frame<=100;frame++) {
  mesh.update(frame/100);
  for(const v of mesh.vertices)for(const n of [v.px,v.py,v.z])assert.ok(Number.isFinite(n));
  for(const f of mesh.triangles){assert.ok(f.shade>=.38&&f.shade<=1);for(const i of [f.a,f.b,f.c])assert.ok(i>=0&&i<49);}
  for(let i=1;i<mesh.triangles.length;i++)assert.ok(mesh.triangles[i-1].depth<=mesh.triangles[i].depth);
 }
 const xs=mesh.vertices.map(p=>p.px),ys=mesh.vertices.map(p=>p.py);
 assert.ok(Math.max(...xs)-Math.min(...xs)<=mesh.radius*2.5,'end silhouette fits a compact ball');
 assert.ok(Math.max(...ys)-Math.min(...ys)<=mesh.radius*2.5);
 assert.ok(mesh.vertices.every((p,i)=>p===vertices[i]),'frame updates reuse vertex objects');
 assert.ok(faces.every(f=>mesh.triangles.includes(f)),'frame updates reuse facets');
 mesh.update(-10);assert.equal(mesh.vertices[0].px,0);mesh.update(10);assert.ok(Number.isFinite(mesh.vertices[0].px));
}
console.log('PASS paper mesh: flat UV alignment, bounded ball, finite geometry, depth ordering and allocation reuse across aspect ratios');
