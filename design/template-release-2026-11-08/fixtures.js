(function(root){
 const load=n=>FridgeCore.load(n),factory=load('TemplateFactory'),sources=load('TemplateSources'),tick=Date.parse('2026-11-08T10:08:00+08:00'),long='跨学科工程研究与创新实践 · 👨‍👩‍👧‍👦 Café 🇨🇳 '.repeat(12);
 function card(id,mode,palette,aspect=1,at=tick,filled=false){let seq=0;const c=factory.makeTemplateCards(id,aspect,()=>id+seq++,at)[0];c.template.palette=palette;
 for(const cap of sources.cardCapabilities(c)){
  cap.title=mode==='long'?long:mode==='empty'?'':'设计讨论';cap.city=mode==='long'?long:'加德满都';cap.zone='Asia/Kathmandu';cap.date=mode==='empty'?'':mode==='invalid'?'2026-02-31':mode==='long'?'1900-01-01':'2027-01-01';cap.seed=mode==='invalid'?'not-a-date':'2026-01-01';cap.percent=mode==='empty'?-1:mode==='invalid'?NaN:100;cap.semester='2026-08-31';cap.skipHolidays=false;cap.artist=mode==='long'?long:'本地音乐';
  cap.events=mode==='empty'?[]:[0,1,2].map(i=>({id:'event'+i,title:cap.title,start:at+i*3600000,end:at+(i+1)*3600000,location:mode==='long'?long:'设计工作室',allDay:i===0}));
  cap.courses=mode==='empty'?[]:Array.from({length:mode==='long'?128:3},(_,i)=>({id:'course'+i,name:cap.title,room:mode==='long'?long:'东楼 308',day:7,start:mode==='long'?'00:00':'09:00',end:mode==='long'?'23:59':'11:00',firstWeek:1,lastWeek:60,parity:0}));
 }if(filled){c.w=300;c.h=300/aspect;}return c;
 }
 root.TemplateReview={card,catalog:load('CardTemplate').CARD_TEMPLATES,tick};
})(globalThis);
