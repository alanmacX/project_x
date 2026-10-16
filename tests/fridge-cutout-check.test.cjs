const assert=require('node:assert/strict'),sharp=require('sharp');
const {checkCutouts}=require('../scripts/fridge-cutout-check.cjs');
(async()=>{
 async function fixture(alpha){const bytes=await sharp({create:{width:2,height:2,channels:4,background:{r:255,g:230,b:0,alpha}}}).png().toBuffer();return {state:{cards:[{id:'s',shape:'subject',cutout:'asset://0',elements:[]}]},assets:[{key:'asset://0',data:bytes.toString('base64')}]};}
 assert.equal((await checkCutouts(await fixture(1))).passed,false,'Opaque source cannot pass as a cutout');
 assert.equal((await checkCutouts(await fixture(0))).passed,false,'Invisible cutout cannot pass');
 const raw=await fixture(1),bytes=await sharp(Buffer.from([255,230,0,0,255,230,0,128,255,230,0,255,255,230,0,0]),{raw:{width:2,height:2,channels:4}}).png().toBuffer();raw.assets[0].data=bytes.toString('base64');
 const result=await checkCutouts(raw);assert.equal(result.passed,true);assert.equal(result.cutouts[0].transparentPixels,2);assert.equal(result.cutouts[0].partialPixels,1);
 raw.state.cards[0].cutout='asset://missing';assert.equal((await checkCutouts(raw)).passed,false);
 console.log('PASS actual media alpha QA: valid cutout, opaque background, invisible image and missing asset.');
})().catch(e=>{console.error(e);process.exitCode=1;});
