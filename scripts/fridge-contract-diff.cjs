#!/usr/bin/env node
// Compare release metadata, not user artwork. Never migrate or rewrite a .fridge.
const fs=require('node:fs');
function compare(before,after){
 for(const contract of [before,after])if(contract.contractVersion!==1)throw Error('Unsupported contract version');
 const removed=[],added=[],visual=[],protocol=[];
 for(const key of ['format','version','schemaVersion','htmlSupported'])if(before.package[key]!==after.package[key])protocol.push(key);
 const oldCaps=new Map(before.capabilities.map(c=>[c.kind,c])),newCaps=new Map(after.capabilities.map(c=>[c.kind,c]));
 for(const [kind,cap] of oldCaps){const next=newCaps.get(kind);if(!next){removed.push('capability:'+kind);continue;}for(const style of cap.readingStyles)if(!next.readingStyles.includes(style))removed.push(kind+'.readingStyle:'+style);}
 for(const kind of newCaps.keys())if(!oldCaps.has(kind))added.push('capability:'+kind);
 for(const group of Object.keys(before.fields)){for(const field of before.fields[group])if(!after.fields[group]?.includes(field))removed.push(group+'.'+field);for(const field of after.fields[group]||[])if(!before.fields[group].includes(field))added.push(group+'.'+field);}
 for(const part of ['models','materials','browserAdapter','nativeViews'])if(before.identity[part]!==after.identity[part])visual.push(part);
 const uncovered=after.capabilities.map(c=>c.kind).filter(kind=>!after.preview.supportedCapabilities.includes(kind));
 return {beforeApp:before.app.versionName,afterApp:after.app.versionName,protocolChanges:protocol,removed,added,changedImplementations:visual,uncoveredPreviewCapabilities:uncovered,requiresCompatibilityReview:protocol.length>0||removed.length>0,requiresVisualReview:visual.length>0,canAutomaticallyApprove:false};
}
module.exports={compare};
if(require.main===module){try{if(process.argv.length!==4)throw Error('Usage: node scripts/fridge-contract-diff.cjs previous-contract.json current-contract.json');console.log(JSON.stringify(compare(...process.argv.slice(2).map(file=>JSON.parse(fs.readFileSync(file,'utf8')))),null,2));}catch(error){console.error(error.message);process.exitCode=1;}}
