#!/usr/bin/env node
/** Offline author-time rendering only. Runtime never creates a Web component. */
const fs=require('node:fs'),path=require('node:path'),cp=require('node:child_process'),crypto=require('node:crypto');
const [source,config,out]=process.argv.slice(2);if(!source||!config||!out)throw Error('fridge-static-render.cjs source.html config.json output.fridge');
const {chromium}=require('playwright'),sharp=require('sharp');
const repo=path.resolve(__dirname,'..'),base=path.resolve(out).replace(/\.fridge$/,''),preview=base+'.appearance.html',png=base+'.appearance.png';
fs.mkdirSync(path.dirname(base),{recursive:true});
cp.execFileSync(process.execPath,[path.join(__dirname,'fridge-html-card.cjs'),'prepare',path.resolve(source),path.resolve(config),preview],{stdio:'inherit'});
(async()=>{
 const settings=JSON.parse(fs.readFileSync(config,'utf8'));
 const browser=await chromium.launch({headless:true,...(process.env.FRIDGE_CHROME?{executablePath:process.env.FRIDGE_CHROME}:{})});
 try{
  const context=await browser.newContext({viewport:{width:settings.width*2,height:settings.height*2},deviceScaleFactor:1,javaScriptEnabled:false});
  let blocked=0;await context.route('**/*',route=>{if(/^https?:/.test(route.request().url())){blocked++;route.abort();}else route.continue();});
  const page=await context.newPage();await page.setContent(fs.readFileSync(preview,'utf8'),{waitUntil:'load'});
  await page.screenshot({path:png,omitBackground:true,animations:'disabled'});
  if(blocked)throw Error('Appearance attempted remote requests');
  cp.execFileSync(process.execPath,[path.join(__dirname,'fridge-html-card.cjs'),'pack',path.resolve(source),path.resolve(config),png,path.resolve(out)],{stdio:'inherit'});
  if(settings.shape==='subject'){
    const vm=require('node:vm'),ctx=vm.createContext({});vm.runInContext(fs.readFileSync(path.join(repo,'previewer/shared-models.js'),'utf8'),ctx);
    const {data,info}=await sharp(png).ensureAlpha().raw().toBuffer({resolveWithObject:true}),mask=Int32Array.from({length:info.width*info.height},(_,i)=>data[i*4+3]);
    const loops=ctx.FridgeCore.load('SubjectGeometry').traceMask(mask,info.width,info.height);if(!loops.length)throw Error('Static silhouette has no opaque subject');
    const pkg=JSON.parse(fs.readFileSync(out,'utf8')),card=pkg.state.cards[0];card.shape='subject';card.cutout='asset://0';card.outline=loops;card.subjectPhoto=false;card.subjectBorder=true;card.subjectAspect=settings.width/settings.height;card.elements=[];card.html.previewElementId='html-appearance';
    // The PNG supplies mask only; its source-linked image layer draws appearance exactly once.
    card.elements=[{id:'html-appearance',kind:'image',src:'asset://0',x:0,y:0,w:1,h:1,rot:0,opacity:1,behindCapability:true}];
    ctx.FridgeCore.load('TemplatePackage').readPackage(JSON.stringify(pkg));fs.writeFileSync(out,JSON.stringify(pkg));
  }
  const hash=crypto.createHash('sha256').update(fs.readFileSync(out)).digest('hex');
  fs.writeFileSync(base+'.render.json',JSON.stringify({renderer:'offline-static-chromium',width:settings.width,height:settings.height,cacheScale:2,networkRequests:blocked,sourceChecksum:crypto.createHash('sha256').update(fs.readFileSync(source)).digest('hex'),packageChecksum:hash,nativeVerified:false},null,2));
  console.log('PASS static source/cache/shape export; native review remains required: '+out);
 }finally{await browser.close();}
})().catch(error=>{console.error(error.message);process.exitCode=1;});
