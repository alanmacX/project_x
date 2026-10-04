const assert=require('node:assert/strict'),fs=require('node:fs'),vm=require('node:vm');
const ts=require('/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript');
const file=__dirname+'/../entry/src/main/ets/model/SketchContour.ets',mod={exports:{}};
const code=ts.transpileModule(fs.readFileSync(file,'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText;
vm.runInThisContext('(function(module,exports){'+code+'\n})',{filename:file})(mod,mod.exports);
const {beautifyContour,roughSketchSample,contourSvgPath,sketchDistance}=mod.exports;
function samples(curve){const out=[curve.start];let a=curve.start;for(const s of curve.segments){for(let i=1;i<=20;i++){const t=i/20,u=1-t;out.push({x:u*u*u*a.x+3*u*u*t*s.c1.x+3*u*t*t*s.c2.x+t*t*t*s.end.x,y:u*u*u*a.y+3*u*u*t*s.c1.y+3*u*t*t*s.c2.y+t*t*t*s.end.y});}a=s.end;}return out;}
function area(p){let sum=0;for(let i=0;i<p.length;i++){const q=p[(i+1)%p.length];sum+=p[i].x*q.y-q.x*p[i].y;}return Math.abs(sum)/2;}
assert.equal(contourSvgPath(beautifyContour([])),'');
assert.equal(beautifyContour([{x:1,y:2},{x:1,y:2},{x:NaN,y:3}]).anchors.length,1);
const line=Array.from({length:250},(_,i)=>({x:i,y:100+Math.sin(i*1.8)*.55}));
const saved=JSON.stringify(line),smooth=beautifyContour(line);
assert.equal(JSON.stringify(line),saved,'original raw data stays untouched');
assert.equal(smooth.closed,false);assert.deepEqual(smooth.start,line[0]);assert.deepEqual(smooth.segments.at(-1).end,line.at(-1));
assert.ok(smooth.anchors.length<15,'remove dense subpixel tremor');
for(const kind of ['oval','leaf']) {
  const raw=roughSketchSample(kind,640,480),curve=beautifyContour(raw),p=samples(curve);
  assert.ok(curve.closed);assert.ok(curve.anchors.length<raw.length*.65);
  assert.ok(Math.abs(area(p)/area(raw)-1)<.04,'preserve silhouette area, no global shrink');
  assert.deepEqual(curve.segments.at(-1).end,curve.start,'closed seam is exact');
  assert.ok(contourSvgPath(curve).endsWith(' Z'));
  const xs=raw.map(p=>p.x),ys=raw.map(p=>p.y);
  assert.ok(p.every(q=>q.x>=Math.min(...xs)-4&&q.x<=Math.max(...xs)+4&&q.y>=Math.min(...ys)-4&&q.y<=Math.max(...ys)+4),'no large Bezier overshoot');
}
const triangle=[];const vertices=[{x:50,y:10},{x:150,y:180},{x:5,y:180},{x:50,y:10}];
for(let edge=0;edge<3;edge++)for(let i=0;i<80;i++){const t=i/80,a=vertices[edge],b=vertices[edge+1];triangle.push({x:a.x+(b.x-a.x)*t,y:a.y+(b.y-a.y)*t});}triangle.push(vertices[0]);
const tri=beautifyContour(triangle);assert.ok(tri.closed);
for(const v of vertices)assert.ok(tri.anchors.some(p=>sketchDistance(p,v)<3),'keep deliberate corner positions');
const long=Array.from({length:4096},(_,i)=>({x:i/8,y:120+Math.sin(i/40)*35}));
const before=performance.now(),result=beautifyContour(long);
assert.ok(result.anchors.length<=512);assert.equal(result.closed,false);assert.ok(Number.isFinite(result.start.x));
console.log('PASS sketch contour: endpoints, untouched original, exact closed seam, corner retention, <4% silhouette-area change, bounded long-stroke output; 4096 samples '+(performance.now()-before).toFixed(2)+' ms (host only)');
