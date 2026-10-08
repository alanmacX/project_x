const assert=require('node:assert/strict'),fs=require('node:fs'),vm=require('node:vm');
const ts=require('/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript');
const env={exports:{}};vm.runInNewContext(ts.transpileModule(fs.readFileSync('entry/src/main/ets/model/ReadingEdgeStudy.ets','utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS}}).outputText,env);
const {edgeStudyPath:path,edgeStudyInset:inset}=env.exports;
function polygon(path){
 const tokens=path.match(/[MCQZ]|-?\d+(?:\.\d+)?(?:e[+-]?\d+)?/gi),out=[];let i=0,from;
 while(i<tokens.length){const cmd=tokens[i++];if(cmd==='Z')break;const n=cmd==='M'?2:cmd==='Q'?4:6,v=tokens.slice(i,i+n).map(Number);i+=n;
  if(cmd==='M'){from=v;out.push(v);continue;}
  for(let k=1;k<=24;k++){const t=k/24,u=1-t;
   const p=cmd==='Q'?[u*u*from[0]+2*u*t*v[0]+t*t*v[2],u*u*from[1]+2*u*t*v[1]+t*t*v[3]]:[u*u*u*from[0]+3*u*u*t*v[0]+3*u*t*t*v[2]+t*t*t*v[4],u*u*u*from[1]+3*u*u*t*v[1]+3*u*t*t*v[3]+t*t*t*v[5]];out.push(p);
  }from=v.slice(-2);
 }return out;
}
function inside(x,y,p){let yes=false;for(let i=0,j=p.length-1;i<p.length;j=i++){const a=p[i],b=p[j];if((a[1]>y)!==(b[1]>y)&&x<(b[0]-a[0])*(y-a[1])/(b[1]-a[1])+a[0])yes=!yes;}return yes;}
for(const [w,h] of [[72,40],[160,90],[160,148],[210,166],[320,60],[64,240]])for(const s of [.6,1,2,3])for(let kind=0;kind<3;kind++){
 const p=polygon(path(kind,w*s,h*s,s)),pad=inset(w*s,h*s,s);
 assert(p.every(([x,y])=>Number.isFinite(x)&&Number.isFinite(y)&&x>=0&&y>=0&&x<=w*s&&y<=h*s),'contour stays inside render box');
 for(let x=0;x<=8;x++)for(let y=0;y<=8;y++)assert(inside(pad+.01+(w*s-2*pad-.02)*x/8,pad+.01+(h*s-2*pad-.02)*y/8,p),'safe rectangular content core survives lobes');
 assert((path(kind,w*s,h*s,s).match(/C/g)||[]).length<=32,'bounded curve complexity');
}
assert.equal(path(0,0,40),'');assert.equal(path(0,40,NaN),'');assert.equal(path(0,40,40,0),'');
const backing=fs.readFileSync('entry/src/main/ets/views/ReadingEdgeBacking.ets','utf8');assert(!/\.shadow\(|Canvas\(|setInterval/.test(backing),'no rectangular shadow or frame redraw loop');
console.log('PASS edge studies: 3 contours, 6 aspect ratios, 4 densities; rectangular core containment and fixed complexity.');
