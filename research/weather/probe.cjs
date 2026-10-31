// One explicit-city request for an integration investigation; no polling or user location.
const https=require('node:https'),fs=require('node:fs'),path=require('node:path');
const out=path.resolve(__dirname,'../../output/weather-research-20261031'),saved=path.join(out,'met-probe.json');
try{const cached=JSON.parse(fs.readFileSync(saved,'utf8'));if(Date.parse(cached.expires)>Date.now()){console.log(JSON.stringify({...cached,reusedCache:true},null,2));process.exit(0);}}catch(_){}
const url='https://api.met.no/weatherapi/locationforecast/2.0/compact?lat=31.23&lon=121.47';
const start=Date.now();const request=https.get(url,{headers:{'User-Agent':'FridgeMemoWeatherEvaluation/0.1 (https://github.com/alanmacX/fridge-creating-skill)','Accept-Encoding':'identity'}},response=>{
 let chunks=[],bytes=0;response.on('data',chunk=>{bytes+=chunk.length;if(bytes>2*1024*1024)request.destroy(Error('response too large'));else chunks.push(chunk);});response.on('end',()=>{
  const body=Buffer.concat(chunks).toString('utf8');let data;try{data=JSON.parse(body);}catch(_){}
  const rows=data?.properties?.timeseries||[],first=rows[0];
  const result={checkedAt:new Date().toISOString(),host:'api.met.no',sampleCity:'Shanghai public city centre',status:response.statusCode,elapsedMs:Date.now()-start,bytes,expires:response.headers.expires,lastModified:response.headers['last-modified'],updatedAt:data?.properties?.meta?.updated_at,forecastRows:rows.length,firstForecastAt:first?.time,firstTemperature:first?.data?.instant?.details?.air_temperature,symbol:first?.data?.next_1_hours?.summary?.symbol_code,platform:'macOS Node HTTPS, not HarmonyOS native',keyUsed:false};
  fs.mkdirSync(out,{recursive:true});fs.writeFileSync(saved,JSON.stringify(result,null,2));console.log(JSON.stringify(result,null,2));
 });
});request.setTimeout(15000,()=>request.destroy(Error('15s timeout')));request.on('error',error=>{console.error(error.message);process.exitCode=1;});
