const fs=require('node:fs'),path=require('node:path');
const root=__dirname;
function card(id,w,h,paper,ink,cap,box={x:.1,y:.1,w:.8,h:.8,rot:0,opacity:1}){
 return {id,x:(344-w)/2,y:0,w,h,rot:0,z:1,shape:'rect',frame:false,material:'white',paper,ink,capability:{...cap,readingBlend:'bare',readingStyle:'plain',readingOpacity:0},capBox:box,capFree:true,elements:[],cutout:'',outline:[],groupId:'',subjectPhoto:false,subjectBorder:true,subjectAspect:1,subjectInk:ink,subjectVersion:0,inDoor:false};
}
const specs=[
 {id:'clock',name:'时间',dim:'2*4',bg:'#E7E8EB',card:card('module-clock',312,132,'#22242A','#F5F6F8',{k:'clock'},{x:.06,y:.15,w:.88,h:.70,rot:0,opacity:1})},
 {id:'calendar',name:'月历',dim:'4*4',bg:'#DCE2EC',card:card('module-calendar',308,304,'#F8F9FC','#243E79',{k:'calendar',calendarOffset:0},{x:.07,y:.06,w:.86,h:.88,rot:0,opacity:1})},
 {id:'timetable',name:'下一课',dim:'2*4',bg:'#E7E4DE',card:card('module-timetable',312,140,'#FAF8F3','#34332F',{k:'timetable',timetableMode:'next',courses:[]},{x:.07,y:.06,w:.86,h:.88,rot:0,opacity:1})},
 {id:'agenda',name:'接下来',dim:'2*4',bg:'#DFE8EA',card:card('module-agenda',312,156,'#F5FAFB','#22474E',{k:'agenda',agendaSource:'system',events:[]},{x:.075,y:.02,w:.85,h:.96,rot:0,opacity:1})},
 {id:'countdown',name:'倒计日',dim:'2*2',bg:'#E8DDD9',card:card('module-countdown',296,296,'#973F37','#FFF8F3',{k:'countdown'},{x:.09,y:.15,w:.82,h:.70,rot:0,opacity:1})},
 {id:'battery',name:'电量',dim:'2*2',bg:'#E5E8DE',card:card('module-battery',280,280,'#F6F7F0','#465E3D',{k:'battery',percent:-1,charging:false,updatedAt:0,attemptedAt:0},{x:.12,y:.12,w:.76,h:.76,rot:0,opacity:1})}
];
specs[5].card.shape='round';
function pack(kind,dim,bg,c){const aspect=dim==='2*4'?2:1,H=344/aspect,art=JSON.parse(JSON.stringify(c));art.y=(H-art.h)/2/H*470;
 return {format:'fridgememo-template',version:1,kind,state:{schemaVersion:2,canvasId:'canvas_main',canvasDimension:dim,canvasAspect:aspect,background:{mode:'solid',color:bg,src:'',photo:'',frameStyle:'none',frameMaterial:'stone',palette:[],anchors:[],signature:''},maxZ:1,cards:[art],sceneLayouts:[],sceneRules:[],sceneBaseLayoutId:''},assets:[]};}
for(const s of specs){fs.writeFileSync(path.join(root,'cards',s.id+'.fridge'),JSON.stringify(pack('card',s.dim,s.bg,s.card),null,2)+'\n');const canvas=pack('canvas',s.dim,s.bg,s.card);if(s.id==='timetable'){const primary=canvas.state.cards[0];primary.w=220;primary.x=16;const time=card('module-class-time',88,140,'#34332F','#FAF8F3',{k:'clock'},{x:.03,y:.2,w:.94,h:.6,rot:0,opacity:1});time.x=240;time.y=primary.y;time.z=2;canvas.state.cards.push(time);canvas.state.maxZ=2;}fs.writeFileSync(path.join(root,'canvases',s.id+'.fridge'),JSON.stringify(canvas,null,2)+'\n');}
fs.writeFileSync(path.join(root,'modules.json'),JSON.stringify(specs.map(({id,name,dim})=>({id,name,dimension:dim,card:'cards/'+id+'.fridge',canvas:'canvases/'+id+'.fridge'})),null,2)+'\n');
console.log('Built six native modules: 6 cards + 6 sized canvases; no external assets.');
