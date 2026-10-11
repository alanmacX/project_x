/* Synthetic provider data belongs to the preview host, never to portable artwork. */
(function(global){
 'use strict';
 const fields={battery:['percent','charging','chargeState'],agenda:['events'],timetable:['semester','courses','holidayDates','teachingDays','courseChanges'],countdown:['title','date'],anniversary:['title','date']};
 const clone=v=>JSON.parse(JSON.stringify(v));
 function object(value,label){if(!value||typeof value!=='object'||Array.isArray(value))throw Error(label+' must be an object');}
 function validate(input,pack){
  object(input,'Preview data');if(JSON.stringify(input).length>256*1024)throw Error('Preview data too large');
  for(const key of Object.keys(input))if(!['format','version','byCard'].includes(key))throw Error('Unknown preview data field: '+key);
  if(input.format!=='fridge-preview-data'||input.version!==1)throw Error('Unsupported preview data format');
  object(input.byCard,'byCard');const cards=new Map(pack.state.cards.map(c=>[c.id,c]));
  for(const [id,values] of Object.entries(input.byCard)){
   const c=cards.get(id);if(!c?.capability)throw Error('Unknown capability card: '+id);object(values,id);
   const allowed=fields[c.capability.k]||[];
   for(const key of Object.keys(values))if(!allowed.includes(key))throw Error(id+': cannot override '+key);
   for(const key of ['events','courses','holidayDates','teachingDays','courseChanges'])if(values[key]!==undefined&&(!Array.isArray(values[key])||values[key].length>64))throw Error(id+': invalid '+key);
   if(values.percent!==undefined&&(!Number.isFinite(values.percent)||values.percent< -1||values.percent>100))throw Error(id+': invalid battery percentage');
   if(values.charging!==undefined&&typeof values.charging!=='boolean')throw Error(id+': invalid charging');
   if(values.chargeState!==undefined&&!['charging','full','discharging','none','unknown'].includes(values.chargeState))throw Error(id+': invalid chargeState');
   for(const key of ['title','date','semester'])if(values[key]!==undefined&&(typeof values[key]!=='string'||values[key].length>160))throw Error(id+': invalid '+key);
   for(const key of ['date','semester'])if(values[key]&&!global.FridgeCore.load('HolidayCalendar').validDay(values[key]))throw Error(id+': invalid date');
   for(const e of values.events||[])if(!e||typeof e.id!=='string'||typeof e.title!=='string'||typeof e.location!=='string'||!Number.isFinite(e.start)||!Number.isFinite(e.end)||e.end<=e.start||typeof e.allDay!=='boolean')throw Error(id+': invalid event');
   for(const c of values.courses||[])if(!c||typeof c.id!=='string'||typeof c.name!=='string'||typeof c.room!=='string'||!Number.isInteger(c.day)||c.day<1||c.day>7||!/^(?:[01]\d|2[0-3]):[0-5]\d$/.test(c.start)||!/^(?:[01]\d|2[0-3]):[0-5]\d$/.test(c.end)||c.end<=c.start||!Number.isInteger(c.firstWeek)||!Number.isInteger(c.lastWeek)||c.firstWeek<1||c.lastWeek<c.firstWeek||c.lastWeek>100||![0,1,2].includes(c.parity))throw Error(id+': invalid course');
  }
  return clone(input);
 }
 function profile(pack,tick,mode){
  const byCard={},date=new Date(tick),key=d=>d.getFullYear()+'-'+String(d.getMonth()+1).padStart(2,'0')+'-'+String(d.getDate()).padStart(2,'0');
  const dayStart=new Date(date.getFullYear(),date.getMonth(),date.getDate()).getTime(),later=new Date(tick);later.setDate(later.getDate()+24);
  for(const c of pack.state.cards){const k=c.capability?.k;if(!fields[k])continue;const empty=mode==='empty',long=mode==='long';
   if(k==='battery')byCard[c.id]={percent:empty?-1:67,charging:!empty,chargeState:empty?'unknown':'charging'};
   if(k==='agenda')byCard[c.id]={events:empty?[]:[{id:'demo-walk',title:long?'一次很长很长的日程名称与地点排版测试':'散步',start:tick+3600000,end:tick+5400000,location:long?'城市公园北侧入口集合地点':'公园',allDay:false},{id:'demo-evening',title:'整理收藏',start:tick+7200000,end:tick+9000000,location:'家',allDay:false}]};
   if(k==='countdown'||k==='anniversary')byCard[c.id]={title:empty?'':long?'很长的纪念与倒计时标题排版测试':k==='countdown'?'周末出发':'相伴',date:empty?'':key(later)};
   if(k==='timetable')byCard[c.id]={semester:key(new Date(dayStart-((date.getDay()+6)%7)*86400000)),courses:empty?[]:[['设计基础','A101','09:00','10:30'],['摄影实践','工作室','15:00','16:30'],['创作讨论','B202','18:00','19:00']].map(([name,room,start,end],i)=>({id:'demo-course-'+i,name:long?'跨学科创意设计基础与实践'+i:name,room,day:date.getDay()||7,start,end,firstWeek:1,lastWeek:20,parity:0})),teachingDays:empty?[]:[{date:key(date),sourceDate:key(date)}],holidayDates:[],courseChanges:[]};
  }
  return {format:'fridge-preview-data',version:1,byCard};
 }
 function project(pack,input){
  if(!input)return {pack,appliedCards:[]};const checked=validate(input,pack),appliedCards=[];
  const cards=pack.state.cards.map(c=>{const patch=checked.byCard[c.id];if(!patch)return c;appliedCards.push(c.id);return {...c,capability:global.FridgeCore.load('CardSchema').normalizeCapability({...c.capability,...patch})};});
  return {pack:{...pack,state:{...pack.state,cards}},appliedCards};
 }
 global.FridgePreviewData={validate,profile,project};
})(globalThis);
