(function(g){
 const stamp='2026-11-01T09:41:00+08:00';
 const event=(id,title,start,end,location='')=>({id,title,start:new Date('2026-11-01T'+start+':00+08:00').getTime(),end:new Date('2026-11-01T'+end+':00+08:00').getTime(),location,allDay:false});
 const agenda=[event('a','去公园散步','14:00','15:00','河边公园'),event('b','读书会','16:30','17:30','书店'),event('c','一起吃晚饭','19:00','20:30','')];
 const courses=[['高等数学',1,'10:00','11:40','教学楼 302'],['设计基础',1,'14:00','15:40','美术楼 201'],['英语',2,'08:00','09:40','教学楼 101'],['线性代数',3,'10:00','11:40','教学楼 302'],['程序设计',4,'14:00','15:40','实验楼 402'],['设计实践',5,'10:00','11:40','工作室']].map(([name,day,start,end,room],i)=>({id:'course'+i,name,day,start,end,room,firstWeek:1,lastWeek:18,parity:0}));
 g.LibraryFixtures={stamp,tick:new Date(stamp).getTime(),agenda,courses,semester:'2026-09-07',battery:76,deadline:'2026-11-13',since:'2025-11-01',rangeStart:'2026-10-01',album:{title:'蓝色练习',artist:'本地专辑'}};
})(globalThis);
