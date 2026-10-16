#!/usr/bin/env node
// Media QA supplements the Node-only schema checker; requires Sharp.
const fs=require('node:fs'),crypto=require('node:crypto'),sharp=require('sharp');
async function inspectAlpha(bytes){
 const decoded=await sharp(bytes,{limitInputPixels:40000000}).toColourspace('srgb').ensureAlpha().raw().toBuffer({resolveWithObject:true});
 const {data,info}=decoded;let transparent=0,visible=0,partial=0;
 for(let i=3;i<data.length;i+=4){if(data[i]===0)transparent++;else visible++;if(data[i]>0&&data[i]<255)partial++;}
 return {width:info.width,height:info.height,transparentPixels:transparent,visiblePixels:visible,partialPixels:partial,sha256:crypto.createHash('sha256').update(bytes).digest('hex')};
}
async function checkCutouts(raw){
 const assets=new Map((raw.assets||[]).map(a=>[a.key,a])),reports=[],errors=[],cache=new Map();
 const refs=[];for(const c of raw.state.cards){
  if(c.shape==='subject')refs.push({card:c.id,role:'subject',key:c.cutout});
  for(const e of c.elements||[])if(e.depthEnabled)refs.push({card:c.id,element:e.id,role:'depthForeground',key:e.depthForeground});
 }
 for(const ref of refs){try{
  const asset=assets.get(ref.key);if(!asset)throw Error('missing embedded cutout asset');
  if(!cache.has(ref.key))cache.set(ref.key,await inspectAlpha(Buffer.from(asset.data,'base64')));
  const stats=cache.get(ref.key);reports.push({...ref,...stats});
  if(!stats.visiblePixels)errors.push({...ref,error:'fully transparent cutout'});
  if(!stats.transparentPixels)errors.push({...ref,error:'no fully transparent pixels: cutout background is opaque'});
 }catch(e){errors.push({...ref,error:e.message});}}
 return {passed:errors.length===0,cutouts:reports,errors};
}
module.exports={inspectAlpha,checkCutouts};
if(require.main===module)(async()=>{
 if(process.argv.length!==3)throw Error('Usage: node scripts/fridge-cutout-check.cjs work.fridge (Sharp required)');
 const result=await checkCutouts(JSON.parse(fs.readFileSync(process.argv[2],'utf8')));console.log(JSON.stringify(result,null,2));if(!result.passed)process.exitCode=1;
})().catch(e=>{console.error(e.message);process.exitCode=1;});
