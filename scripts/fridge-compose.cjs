#!/usr/bin/env node
/** Assemble independent packages without flattening editable source or copying provider data. */
const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm');
const [manifestPath,out]=process.argv.slice(2);if(!manifestPath||!out)throw Error('fridge-compose.cjs manifest.json output.fridge');
const ctx=vm.createContext({});vm.runInContext(fs.readFileSync(path.resolve(__dirname,'../previewer/shared-models.js'),'utf8'),ctx);
const core=ctx.FridgeCore,schema=core.load('CardSchema'),manifest=JSON.parse(fs.readFileSync(manifestPath,'utf8')),state=new schema.FridgeState(),assets=[];
state.canvasAspect=manifest.canvasAspect??1;state.background=schema.normalizeBackground(manifest.background??{});
if(manifest.backgroundImage){const file=path.resolve(path.dirname(manifestPath),manifest.backgroundImage),extension=path.extname(file).toLowerCase();if(!['.png','.jpg','.jpeg','.webp'].includes(extension))throw Error('Use a supported static background image');assets.push({key:'asset://0',extension,data:fs.readFileSync(file).toString('base64')});state.background.mode='photo';state.background.photo='asset://0';state.background.src='asset://0';}

for(const [index,entry] of (manifest.cards??[]).entries()){
 const pkg=JSON.parse(fs.readFileSync(path.resolve(path.dirname(manifestPath),entry.file),'utf8'));core.load('TemplatePackage').readPackage(JSON.stringify(pkg));
 if(pkg.kind!=='card'||pkg.state.cards.length!==1)throw Error('Each composition input must be a single card package');
 const keys=new Map();for(const asset of pkg.assets){const key='asset://'+assets.length;keys.set(asset.key,key);assets.push({...asset,key});}
 const card=pkg.state.cards[0],prefix='c'+index+'_';card.id=prefix+card.id;card.groupId=entry.groupId??'';
 const remap=value=>typeof value==='string'&&keys.has(value)?keys.get(value):value;
 card.cutout=remap(card.cutout);for(const element of card.elements??[]){const old=element.id;element.id=prefix+old;element.src=remap(element.src);if(card.html?.previewElementId===old)card.html.previewElementId=element.id;}
 if(card.capability){card.capability=core.load('SharedCapability').sharedCapability(card.capability);for(const key of ['albumCover','albumBackground'])card.capability[key]=remap(card.capability[key]);for(const item of card.capability.albumItems??[]){item.cover=remap(item.cover);item.background=remap(item.background);}}
 for(const key of ['x','y','w','h','rot','z'])if(entry[key]!==undefined)card[key]=entry[key];
 card.z=entry.z??index+1;state.cards.push(card);
}
if(state.cards.length===0||state.cards.length>16)throw Error('Composition requires 1–16 cards');
state.maxZ=Math.max(...state.cards.map(c=>c.z));
const pkg={format:'fridgememo-template',version:state.cards.some(c=>c.html)?2:1,kind:'canvas',state,assets};core.load('TemplatePackage').readPackage(JSON.stringify(pkg));
fs.writeFileSync(out,JSON.stringify(pkg));console.log('PASS editable composition: '+state.cards.length+' cards, '+assets.length+' assets; provider data sanitized');
