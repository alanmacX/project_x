const assert=require('node:assert/strict'),fs=require('node:fs'),vm=require('node:vm');
const ctx=vm.createContext({console});
for(const file of ['shared-models.js','shared-materials.js','capabilities.js','renderer.js'])vm.runInContext(fs.readFileSync('previewer/'+file,'utf8'),ctx);
const raw=JSON.parse(fs.readFileSync('skills/fridge-create/examples/native-canvas.fridge','utf8'));
raw.state.cards=[raw.state.cards[0]];
Object.assign(raw.state.cards[0],{shape:'subject',material:'white',paper:'',subjectPhoto:true,subjectDepth:true,capability:null,elements:[],cutout:'asset://0',outline:[[{x:0,y:0},{x:1,y:0},{x:1,y:1},{x:0,y:1}]]});
raw.assets=[{key:'asset://0',extension:'.png',data:'iVBORw0KGgo='}];
const read=ctx.FridgeCore.load('TemplatePackage').readPackage;
for(const subjectDepth of [true,false]){
 raw.state.cards[0].subjectDepth=subjectDepth;
 const pack=read(JSON.stringify(raw)),card=pack.state.cards[0],result=ctx.FridgeWeb.renderPackage(pack,300,1791439200000);
 assert.equal(result.issues.length,0);
 const markup=result.layers.cards[0].markup;
 const paper=ctx.FridgeCore.load('CardSchema').materialColors(card.material,card.paper,card.ink)[0];
 const backing=`<rect width="${card.w}" height="${card.h}" fill="${paper}"/>`;
 if(subjectDepth)assert.ok(!markup.includes(backing),'Depth subject must not receive opaque rectangular paper backing');
 else {assert.ok(markup.includes('mask="url('),'Ordinary subject retains alpha mask');assert.ok(markup.includes(backing),'Control: normal rendering includes masked paper');}
 assert.ok(markup.includes('photo'),'Both branches display the subject artwork');
}
console.log('PASS depth cutout has no opaque rectangular backing; ordinary subject retains alpha mask.');
