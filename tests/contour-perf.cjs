// Measures real saved contours without copying private artwork into the report.
const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm');
const ts=require('/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript');
const modulePath=path.resolve(__dirname,'../entry/src/main/ets/model/ContourGeometry.ets');
const mod={exports:{}};
const js=ts.transpileModule(fs.readFileSync(modulePath,'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2020}}).outputText;
vm.runInThisContext('(function(require,module,exports){'+js+'})',{filename:modulePath})(require,mod,mod.exports);
const xml=fs.readFileSync(process.argv[2],'utf8'), match=xml.match(/<string key="fridge_state_json">([\s\S]*?)<\/string>/);
const state=JSON.parse(match[1].replace(/&quot;/g,'"').replace(/&apos;/g,"'").replace(/&lt;/g,'<').replace(/&gt;/g,'>').replace(/&amp;/g,'&'));
const report=[];
for(const card of state.cards){
 if(!card.outline?.length)continue;
 const start=performance.now(),after=mod.exports.compactContours(card.outline),elapsed=performance.now()-start;
 let maximum=0;
 for(let ring=0;ring<card.outline.length;ring++)for(const p of card.outline[ring]){
  let nearest=Infinity;
  for(let i=0;i<after[ring].length;i++){
   const a=after[ring][i],b=after[ring][(i+1)%after[ring].length],dx=b.x-a.x,dy=b.y-a.y,n=dx*dx+dy*dy,t=n?Math.max(0,Math.min(1,((p.x-a.x)*dx+(p.y-a.y)*dy)/n)):0;
   nearest=Math.min(nearest,Math.hypot(p.x-a.x-t*dx,p.y-a.y-t*dy));
  }
  maximum=Math.max(maximum,nearest);
 }
 report.push({cardId:card.id,loopsBefore:card.outline.length,loopsAfter:after.length,pointsBefore:card.outline.reduce((n,l)=>n+l.length,0),pointsAfter:after.reduce((n,l)=>n+l.length,0),maximumNormalizedDeviation:maximum,compressionCpuMs:elapsed});
 if(maximum>.000350001)throw Error('Contour deviates beyond the hard bound');
}
console.log(JSON.stringify(report,null,2));
