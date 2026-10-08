import { CapBlock, FridgeCard, ElementBox } from './CardSchema';
import { capabilityMinimum, capabilityReadableMinimum } from './CapabilityMetrics';
export const CLOUD_ACCEPTANCE_GROUPS:string[][]=[['clock','date','calendar','worldclock'],['countdown','anniversary','dayprogress','yearprogress'],['agenda','timetable','timetable-next','lunar'],['battery','battery-cloud','album']];
export const CLOUD_ACCEPTANCE_TICK:number=new Date('2026-10-08T13:50:00').getTime();
export function cloudAcceptanceCard(kind:string,compact:boolean,empty:boolean=false,album:CapBlock|null=null):FridgeCard {
 const c=new FridgeCard();c.id='cloud-accept-'+kind;c.shape='blob';c.paper='#E9BB46';c.ink='#302D25';c.capFree=true;
 const k=kind==='timetable-next'?'timetable':kind==='battery-cloud'?'battery':kind;
 const cap:CapBlock={k,readingBlend:k==='battery'?(kind==='battery-cloud'?'cloud':'badge'):k==='album'?undefined:'cloud',readingStyle:'surface',zone:'America/New_York',percent:67,charging:true,date:k==='anniversary'?'2023-05-01':'2026-12-20',title:'周末去看海',agendaSource:'local',semester:'2026-09-07',skipHolidays:false,timetableMode:kind==='timetable-next'?'next':'day'};
 if(k==='agenda')cap.events=empty?[]:[{id:'a',title:'讨论新的设计方案',location:'图书馆二楼',start:CLOUD_ACCEPTANCE_TICK+3600000,end:CLOUD_ACCEPTANCE_TICK+7200000,allDay:false},{id:'b',title:'和朋友一起吃晚饭',location:'校门口',start:CLOUD_ACCEPTANCE_TICK+10800000,end:CLOUD_ACCEPTANCE_TICK+14400000,allDay:false}];
 if(k==='timetable')cap.courses=empty?[]:[{id:'a',name:'软件工程',room:'计C311',day:4,start:'14:00',end:'15:35',firstWeek:1,lastWeek:20,parity:0},{id:'b',name:'计算机网络',room:'博学楼201',day:4,start:'16:00',end:'17:35',firstWeek:1,lastWeek:20,parity:0},{id:'c',name:'体育',room:'运动场',day:4,start:'19:00',end:'20:00',firstWeek:1,lastWeek:20,parity:0}];
 if(k==='battery'&&empty){cap.percent=-1;cap.charging=false;}
 c.capability=k==='album'&&album?album:cap;
 if(k==='album'){c.w=180;c.h=180;c.shape='rect';return c;}
 const size=compact?capabilityReadableMinimum(cap):capabilityMinimum(cap,false,k==='timetable'?104:0);
 c.w=Math.max(130,size.w+72);c.h=Math.max(124,size.h+70);
 const b=new ElementBox();b.w=(size.w+16)/c.w;b.h=(size.h+16)/c.h;b.x=(1-b.w)/2;b.y=(1-b.h)/2;c.capBox=b;
 return c;
}
