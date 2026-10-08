const assert=require('node:assert/strict'),fs=require('node:fs'),vm=require('node:vm'),path=require('node:path');
const root=path.resolve(__dirname,'..'),ctx=vm.createContext({});for(const file of ['shared-models.js','subject-authoring.js'])vm.runInContext(fs.readFileSync(path.join(root,'previewer',file),'utf8'),ctx);
const analyze=ctx.FridgeSubjectAuthoring.analyzeRGBA;
function pixels(w,h,inside){const a=new Uint8Array(w*h*4);for(let y=0;y<h;y++)for(let x=0;x<w;x++)if(inside(x,y)){a[(y*w+x)*4]=225;a[(y*w+x)*4+3]=255;}return a;}
const donut=pixels(128,96,(x,y)=>{const r=((x-64)/52)**2+((y-48)/38)**2;return r<1&&r>.2;}),result=analyze(donut,128,96);
assert.equal(result.loops,2,'Outer loop and actual hole survive');assert.equal(result.subjectAspect,128/96);assert.ok(result.points<16384);assert.ok(result.contentBounds.w>.8);assert.ok(result.outline.flat().every(p=>p.x>=0&&p.x<=1&&p.y>=0&&p.y<=1));
const original=Buffer.from(donut);analyze(donut,128,96);assert.deepEqual(Buffer.from(donut),original,'Inspection never edits original alpha/RGB');
assert.throws(()=>analyze(new Uint8Array(1025*4*4),1025,4),/1024px/);
const rect=pixels(32,32,()=>true);assert.throws(()=>analyze(rect,32,32),/透明背景/);assert.throws(()=>analyze(new Uint8Array(32*32*4),32,32),/主体/);
const padded=analyze(pixels(64,64,(x,y)=>x>24&&x<40&&y>24&&y<40),64,64);assert.ok(padded.warnings.length>0);assert.ok(Math.min(...padded.outline[0].map(p=>p.x))>.3,'Outline stays in original PNG coordinates, not recentered');
assert.throws(()=>analyze(pixels(256,256,(x,y)=>(x+y)%2===0),256,256),/碎片过多/);
const native=ctx.FridgeCore.load('SubjectGeometry').traceMask(Int32Array.from(donut.filter((_,i)=>i%4===3)),128,96);assert.equal(JSON.stringify(native),JSON.stringify(result.outline),'Production tracing is the only geometry implementation');
console.log('PASS real alpha geometry, holes, coordinate alignment, source immutability, empty/opaque rejection and bounded noisy inputs');
