const assert=require('node:assert/strict');
const fs=require('node:fs');
const path=require('node:path');
const {validate}=require('../scripts/fridge-package-check.cjs');
const json=fs.readFileSync(path.join(__dirname,'../skills/fridge-create/examples/native-canvas.fridge'),'utf8');
assert.deepEqual(validate(json),{kind:'canvas',cards:3,assets:0});
// All shipped starting points must remain usable with the current production reader.
const examples=path.join(__dirname,'../skills/fridge-create/examples');
function validateExamples(dir){for(const entry of fs.readdirSync(dir,{withFileTypes:true})){const file=path.join(dir,entry.name);if(entry.isDirectory())validateExamples(file);else if(entry.name.endsWith('.fridge')){assert.doesNotThrow(()=>validate(fs.readFileSync(file,'utf8')),file);}}}
validateExamples(examples);
const reject=(mutate,pattern)=>{const pack=JSON.parse(json);mutate(pack);assert.throws(()=>validate(JSON.stringify(pack)),pattern);};
reject(p=>p.state.cards[0].renderer='html',/unsupported field renderer/);
reject(p=>p.state.cards[0].capability.k='fetch',/Unsupported capability/);
reject(p=>p.state.cards[0].capability.url='https://example.com',/network capability field/);
reject(p=>p.state.cards[1].id=p.state.cards[0].id,/duplicate ID/);
reject(p=>p.state.cards[0].groupId='alone',/only one member/);
reject(p=>p.state.cards[0].capability.readingBlend='badge',/reading surface/);
reject(p=>p.state.cards[0].w=1,/reader changed w/);
reject(p=>p.state.cards[0].capBox.x=.99,/reader changed capBox/);
reject(p=>p.state.cards[0].elements=[{id:'text_a',kind:'html',text:'<p>Hi</p>'}],/Unsupported element kind/);
reject(p=>p.state.cards[0].cutout='asset://404',/引用不完整/);
const grouped=JSON.parse(json);grouped.state.cards[0].groupId=grouped.state.cards[1].groupId='pair';validate(JSON.stringify(grouped));
const single=JSON.parse(json);single.kind='card';single.state.cards=single.state.cards.slice(0,1);validate(JSON.stringify(single));
console.log('PASS: native sample and card/group variants; invented HTML, retired network source, unsupported surface, ID collision, singleton groups, clamped geometry and missing assets rejected.');

reject(p=>p.state.background.frameMaterial='marble',/unsupported frameMaterial/);
reject(p=>p.state.background.frameWidth=30,/unsupported field frameWidth/);
reject(p=>p.state.background.mode='fluid',/unsupported mode/);
for(const frameMaterial of ['stone','walnut','oak'])for(const frameStyle of ['none','light','dark','auto']){
 const pack=JSON.parse(json);Object.assign(pack.state.background,{frameMaterial,frameStyle});assert.doesNotThrow(()=>validate(JSON.stringify(pack)));
}

reject(p=>p.state.background.color='cream',/reader changed color/);
