const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),sharp=require('sharp');
const root=__dirname,repo=path.resolve(root,'../..'),ctx=vm.createContext({console});
vm.runInContext(fs.readFileSync(path.join(repo,'previewer/shared-models.js'),'utf8'),ctx);
vm.runInContext(fs.readFileSync(path.join(repo,'previewer/subject-authoring.js'),'utf8'),ctx);
const box=(x=.1,y=.1,w=.8,h=.8)=>({x,y,w,h,rot:0,opacity:1});
function card(id,x,y,w,h,paper,ink,cap,extra={}){return {id,x,y:y/344*470,w,h,rot:0,z:1,shape:'rect',frame:false,material:'white',paper,ink,capability:cap?{...cap,readingBlend:'bare',readingStyle:'plain',readingOpacity:0}:null,capBox:box(),capFree:true,elements:[],cutout:'',outline:[],groupId:'',subjectPhoto:false,subjectBorder:true,subjectAspect:1,subjectInk:ink,subjectVersion:0,inDoor:false,...extra};}
const battery={k:'battery',percent:-1,charging:false,updatedAt:0,attemptedAt:0};
async function cutout(name,svg){fs.writeFileSync(path.join(root,'sources',name+'.svg'),svg);const png=await sharp(Buffer.from(svg)).png().toBuffer();fs.writeFileSync(path.join(root,'sources',name+'.png'),png);const {data,info}=await sharp(png).ensureAlpha().raw().toBuffer({resolveWithObject:true});const geometry=ctx.FridgeSubjectAuthoring.analyzeRGBA(data,info.width,info.height);return {png,geometry};}
(async()=>{
 const ticket=await cutout('ticket','<svg xmlns="http://www.w3.org/2000/svg" width="888" height="384" viewBox="0 0 888 384"><path fill="#FFF6DE" d="M20 4H868V151A41 41 0 0 0 868 233V380H20V233A41 41 0 0 0 20 151Z"/><path d="M106 24V360M782 24V360" stroke="#B8A68C" stroke-width="2" stroke-dasharray="8 8"/></svg>');
 let points=[];for(let i=0;i<32;i++){const a=i*Math.PI/16-Math.PI/2,r=i%2?137:157;points.push(`${160+Math.cos(a)*r},${160+Math.sin(a)*r}`);}
 const flower=await cutout('sunburst',`<svg xmlns="http://www.w3.org/2000/svg" width="640" height="640" viewBox="0 0 320 320"><polygon fill="#E6F175" points="${points.join(' ')}"/></svg>`);
 const subject=(c,art,key)=>({...c,shape:'subject',cutout:key,outline:art.geometry.outline,subjectPhoto:true,subjectBorder:false,subjectAspect:art.geometry.subjectAspect,subjectVersion:1});
 const families=[
  {id:'instrument',name:'仪表',bg:'#121517',variants:[
   {dim:'4*4',cards:[card('time',16,16,312,116,'#1C2225','#E5F866',{k:'clock'}, {capBox:box(.04,.05,.92,.9)}),card('date',16,144,184,76,'#1C2225','#F5F5EE',{k:'date'}),card('power',212,166,116,116,'#282F32','#E5F866',battery,{shape:'round',capBox:box(.13,.13,.74,.74)}),card('day',16,232,184,96,'#1C2225','#F5F5EE',{k:'dayprogress'})]},
   {dim:'2*2',cards:[card('time',20,24,304,160,'#1C2225','#E5F866',{k:'clock'},{capBox:box(.04,.05,.92,.9)}),card('power',20,204,112,112,'#282F32','#E5F866',battery,{shape:'round',capBox:box(.13,.13,.74,.74)}),card('date',148,208,176,100,'#1C2225','#F5F5EE',{k:'date'})]}
  ]},
  {id:'paper',name:'纸本',bg:'#B66341',art:ticket,variants:[
   {dim:'4*4',cards:[subject(card('time',24,24,296,128,'#FFF6DE','#553D31',{k:'clock'},{rot:-4,capBox:box(.16,.15,.68,.7)}),ticket,'asset://0'),card('agenda',20,166,192,156,'#F1DEC1','#553D31',{k:'agenda',agendaSource:'system',events:[]},{rot:3,capBox:box(.07,.06,.86,.88)}),card('power',230,186,94,94,'#E5C07F','#553D31',battery,{shape:'round',rot:6,capBox:box(.13,.13,.74,.74)})]},
   {dim:'2*2',cards:[subject(card('time',24,42,296,128,'#FFF6DE','#553D31',{k:'clock'},{rot:-4,capBox:box(.16,.15,.68,.7)}),ticket,'asset://0'),card('date',54,192,236,112,'#F1DEC1','#553D31',{k:'date'},{rot:4})]}
  ]},
  {id:'pop',name:'色块拼贴',bg:'#3348B8',art:flower,variants:[
   {dim:'4*4',cards:[card('time',20,24,304,116,'#F88D5A','#242D76',{k:'clock'},{rot:-3,shape:'pill',capBox:box(.08,.1,.84,.8)}),subject(card('date',10,150,196,184,'#E6F175','#242D76',{k:'date'},{rot:7,capBox:box(.2,.23,.6,.54)}),flower,'asset://0'),card('power',214,172,112,112,'#DDD6F4','#242D76',battery,{shape:'round',capBox:box(.13,.13,.74,.74)})]},
   {dim:'2*2',cards:[card('time',20,38,304,116,'#F88D5A','#242D76',{k:'clock'},{rot:-3,shape:'pill',capBox:box(.08,.1,.84,.8)}),subject(card('date',90,170,164,154,'#E6F175','#242D76',{k:'date'},{rot:7,capBox:box(.2,.23,.6,.54)}),flower,'asset://0')]}
  ]}
 ];
 const index=[];for(const f of families)for(const v of f.variants){const id=f.id+'-'+v.dim.replace('*','x');v.cards.forEach((c,i)=>c.z=i+1);const pack={format:'fridgememo-template',version:1,kind:'canvas',state:{schemaVersion:2,canvasId:'canvas_main',canvasDimension:v.dim,canvasAspect:1,background:{mode:'solid',color:f.bg,src:'',photo:'',frameStyle:'none',frameMaterial:'stone',palette:[],anchors:[],signature:''},maxZ:v.cards.length,cards:v.cards,sceneLayouts:[],sceneRules:[],sceneBaseLayoutId:''},assets:f.art?[{key:'asset://0',extension:'.png',data:f.art.png.toString('base64')}]:[]};fs.writeFileSync(path.join(root,'canvases',id+'.fridge'),JSON.stringify(pack,null,2)+'\n');index.push({id,family:f.id,name:f.name,dimension:v.dim,canvas:'canvases/'+id+'.fridge'});}
 fs.writeFileSync(path.join(root,'modules.json'),JSON.stringify(index,null,2)+'\n');console.log('Built 3 families × 2 independently composed sizes');
})().catch(e=>{console.error(e);process.exitCode=1;});
