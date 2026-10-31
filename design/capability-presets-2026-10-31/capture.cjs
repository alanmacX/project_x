const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto');
let pw;try{pw=require('playwright');}catch(_){pw=require(process.env.FRIDGE_PLAYWRIGHT||path.resolve(__dirname,'../../../parcel-prototype/node_modules/playwright'));}
(async()=>{const browser=await pw.chromium.launch({headless:true,...(process.env.FRIDGE_CHROME?{executablePath:process.env.FRIDGE_CHROME}:{channel:'chrome'})});try{
const context=await browser.newContext({viewport:{width:1200,height:900},deviceScaleFactor:1,timezoneId:'Asia/Shanghai'}),page=await context.newPage();
page.on('pageerror',e=>console.error('PAGE',e.message));page.on('requestfailed',r=>console.error('REQUEST',r.url(),r.failure()));await page.goto(process.env.FRIDGE_PREVIEW_URL||'http://127.0.0.1:8766/previewer/');
await page.waitForFunction(()=>!!window.FridgeHarness);const modules=JSON.parse(fs.readFileSync(path.join(__dirname,'modules.json'))),tick='2026-11-02T09:10:00+08:00';
for(const m of modules){const source=fs.readFileSync(path.join(__dirname,m.canvas),'utf8');require('node:child_process').execFileSync(process.execPath,[path.resolve(__dirname,'../../scripts/fridge-package-check.cjs'),path.join(__dirname,m.canvas)],{stdio:'pipe'});await page.evaluate(async({source,tick})=>{await FridgeHarness.loadText(source);FridgeHarness.setTick(tick);},{source,tick});let checks=[];
 for(const mode of ['demo','empty','long']){await page.evaluate(mode=>FridgeHarness.setDataProfile(mode),mode);
  for(const size of (m.dimension==='2*2'?[180,300]:[300,420])){await page.evaluate(size=>FridgeHarness.setSize(size),size);const report=await page.evaluate(()=>FridgeHarness.getReport()),metrics=await page.evaluate(()=>FridgeHarness.getCardMetrics());if(!Array.isArray(report.issues))throw Error(m.id+' render '+JSON.stringify(report));if(report.issues.length||metrics.some(x=>x.fits===false))throw Error(m.id+' '+mode+' '+size+' does not fit '+JSON.stringify(metrics));
   const bytes=await page.evaluate(async()=>Array.from(new Uint8Array(await(await FridgeHarness.capture()).arrayBuffer())));fs.writeFileSync(path.join(__dirname,'previews',`${m.id}-${mode}-${size}.png`),Buffer.from(bytes));checks.push({mode,size,metrics,report});
  }
 }
 const contract=await page.evaluate(()=>FridgeHarness.getDesignContract());fs.writeFileSync(path.join(__dirname,m.id+'.qa.json'),JSON.stringify({sha256:crypto.createHash('sha256').update(source).digest('hex'),dimension:m.dimension,tick,contract:contract.identity,structureValidated:true,visualReview:'pending',actualFormVerified:false,checks},null,2));console.log(m.id+' captured demo / empty / long');
}
}finally{await browser.close();}})().catch(e=>{console.error(e);process.exitCode=1;});
