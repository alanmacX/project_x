const assert=require('node:assert/strict'),fs=require('node:fs'),path=require('node:path'),vm=require('node:vm');
const ts=require('/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript');
const root=path.resolve(__dirname,'../entry/src/main/ets/model'),cache=new Map();
function load(name){const file=path.resolve(root,name+'.ets');if(cache.has(file))return cache.get(file).exports;const mod={exports:{}};cache.set(file,mod);const code=ts.transpileModule(fs.readFileSync(file,'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText;vm.runInThisContext('(function(require,module,exports){'+code+'\n})',{filename:file})(s=>s==='@kit.ArkTS'?{taskpool:{}}:load(path.relative(root,path.resolve(path.dirname(file),s))),mod,mod.exports);return mod.exports;}
const schema=load('CardSchema'),styles=load('ReadingStylePolicy'),composition=load('ReadingComposition'),layout=load('CanvasLayout'),metrics=load('CapabilityMetrics'),fixtures=load('CloudAcceptanceFixtures'),cloud=load('CloudReadingGeometry'),presentation=load('CapabilityPresentation');
for(const kind of schema.CAPABILITIES){
 if(kind==='album'){assert.deepEqual(styles.readingStyles(kind),[]);continue;}
 assert(styles.readingStyles(kind).includes('cloud'),'cloud selectable for '+kind);
 for(const compact of [false,true])for(const empty of [false,true]){
  const c=fixtures.cloudAcceptanceCard(kind,compact,empty);c.capability.readingBlend='cloud';c.capBox.rot=27;c.capBox.x=-.12;
  const state=schema.defaultState();state.cards=[c];const next=schema.normalizeState(JSON.parse(JSON.stringify(state))).cards[0];
  assert.equal(next.capability.readingBlend,'cloud','cloud survives save and Form normalization');assert.equal(next.capBox.rot,27);assert.equal(next.capBox.x,-.12,'free placement retained');
  const min=layout.cardCapabilityMinimum(c,true);c.capability.readingBlend='bare';const old=layout.cardCapabilityMinimum(c,true);
  assert.deepEqual(min,old,'cloud does not inflate readable minimum '+kind);c.capability.readingBlend='cloud';
  assert(presentation.readingSurface(c.capability,false,false),'all hosts enable cloud even on a solid card');
  assert(composition.isReadingComposition('cloud'));
 }
}
assert.equal(styles.preferredReadingStyle('battery'),'badge');assert.equal(styles.preferredReadingStyle('album'),'');assert.equal(styles.defaultReadingStyle('clock'),'bare','legacy migration is unchanged');
const c=fixtures.cloudAcceptanceCard('clock',true);c.capFree=false;c.capBox.x=0;c.capBox.y=0;assert(composition.compositionOverflow(c,1).left>=cloud.CLOUD_READING_FRINGE,'auto placement caches include cloud fringe');
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
for(const size of [[32,24],[70.4,41.6],[100,74],[180,150],[320,40],[40,320]])for(const scale of [.6,.8,1,2,3]){
 const w=size[0]*scale,h=size[1]*scale,commands=cloud.cloudReadingPath(w,h,scale),poly=polygon(commands);
 assert(commands.endsWith(' Z'));assert.equal((commands.match(/C/g)||[]).length,12,'fixed curve budget across aspect ratios');
 const W=w+32*scale,H=h+32*scale;
 assert(poly.every(([x,y])=>Number.isFinite(x)&&Number.isFinite(y)&&x>=0&&y>=0&&x<=W&&y<=H),'edge stays inside existing export fringe');
 const pad=(cloud.CLOUD_READING_OUTSET+cloud.CLOUD_READING_PADDING)*scale;
 for(let x=0;x<=10;x++)for(let y=0;y<=10;y++)assert(inside(pad+(w-16*scale)*x/10,pad+(h-16*scale)*y/10,poly),'entire readable rectangle stays inside soft silhouette');
 assert.equal(commands,cloud.cloudReadingPath(w,h,scale),'dragging cannot generate a different edge');
}
for(const value of [0,-1,NaN,Infinity])assert.equal(cloud.cloudReadingPath(value,40,1),'');
assert.equal(cloud.cloudReadingPath(40,40,0),'');
const before=polygon(cloud.cloudReadingPath(100,80,1)),after=polygon(cloud.cloudReadingPath(100.01,80,1));
assert.equal(before.length,after.length);assert(Math.max(...before.map((p,i)=>Math.hypot(p[0]-after[i][0],p[1]-after[i][1])))<.02,'fractional resize has no lobe threshold jump');

const backing=fs.readFileSync('entry/src/main/ets/views/ReadingBacking.ets','utf8'),src=backing.slice(backing.indexOf("if(this.blend==='cloud')"),backing.indexOf('else if(this.study>0)'));
assert(!src.includes('.shadow(')&&!src.includes('Image(')&&!src.includes('setInterval'),'production cloud has two stable paths, no material experimentation');
console.log('PASS production cloud: all 12 eligible capabilities; restore, free placement, unchanged minima, external fringe, legacy styles and album/battery exceptions.');
