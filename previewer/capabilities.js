/* ArkUI readout adapter. Geometry/data/materials are the actual production pure models. */
(function(global){
 'use strict';
 const load=FridgeCore.load, schema=load('CardSchema'),layout=load('CanvasLayout'),metrics=load('CapabilityMetrics'),edge=load('EdgeAttachment'),composition=load('ReadingComposition'),mica=load('MicaGeometry'),material=load('MicaMaterialStudy'),calendar=load('CapabilityCalendar'),holidays=load('HolidayCalendar'),time=load('TimeCapabilities'),data=load('CapabilityData'),battery=load('BatteryPresentation'),present=load('CapabilityPresentation'),measure=load('PaperTextWidth').paperTextWidth;
 const esc=s=>String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
 const col=c=>/^#[\da-f]{8}$/i.test(c)?'#'+c.slice(3)+c.slice(1,3):c;
 const fonts=typeof document==='undefined'?null:document.createElement('canvas').getContext('2d');
 function fitted(value,fs,width,weight=400){let s=String(value);if(!fonts)return s;fonts.font=weight+' '+fs+'px system-ui';if(fonts.measureText(s).width<=width)return s;const chars=Array.from(s);while(chars.length&&fonts.measureText(chars.join('')+'…').width>width)chars.pop();return chars.join('')+'…';}
 function txt(value,x,y,fs,ink,width=Infinity,anchor='start',weight=400,opacity=1){return `<text x="${x}" y="${y+fs*.91}" font-size="${fs}" font-weight="${weight}" fill="${col(ink)}" opacity="${opacity}" text-anchor="${anchor}">${esc(fitted(value,fs,width,weight))}</text>`;}
 function hook(x,s){const d=`M ${x-3*s} ${0} L ${x-3*s} ${-7*s} C ${x-3*s} ${-15*s} ${x+6*s} ${-15*s} ${x+6*s} ${-7*s} L ${x+6*s} ${5*s} C ${x+6*s} ${11*s} ${x} ${13*s} ${x} ${10*s}`;return [ ['rgba(29,35,42,.16)',3.4],['#90979E',2.6],['#E4E8EC',1.3] ].map(([color,width])=>`<path d="${d}" fill="none" stroke="${color}" stroke-width="${width*s}" stroke-linecap="round"/>`).join('');}
 function backing(w,h,blend,s,ink,tint,cap,contact,id){
  let p=contact.profile.length?edge.attachedPath(w,h,contact.profile,contact.left,6*s):mica.micaPath(blend,w,h,s,cap.readingEdge||'');
  const reserve=mica.hookReserve(blend),hx=mica.hookCenter(cap.readingHook??.2,w,s);
  if(reserve){const r=3.3*s,y=10*s;p+=` M ${hx+r} ${y} A ${r} ${r} 0 1 0 ${hx-r} ${y} A ${r} ${r} 0 1 0 ${hx+r} ${y} Z`;}
  if(blend==='cloud'){
   const d=load('CloudReadingGeometry').cloudReadingPath(w,h,s),off=16*s;
   return `<g transform="translate(${-off} ${-off})"><path d="${d}" transform="translate(0 ${2*s})" fill="#9C8B6C24"/><path d="${d}" fill="#FAF4E3E6" stroke="#FFFDF6" stroke-width="${1.1*s}"/></g>`;
  }
  if(blend==='paper')return `<defs><pattern id="${id}fibres" width="${160*s}" height="${160*s}" patternUnits="userSpaceOnUse"><image href="${FridgeMaterials.reading_paper_fibres}" width="${160*s}" height="${160*s}" opacity=".55"/></pattern></defs><rect width="${w}" height="${h}" rx="${Math.min(8*s,w*.12)}" fill="#FBF7EE80"/><rect width="${w}" height="${h}" rx="${Math.min(8*s,w*.12)}" fill="url(#${id}fibres)"/>`;
  if(!composition.isReadingComposition(blend)){
   if(blend==='halo')return '';
   const color=present.readingSurfaceColor(ink),suffix=color==='#252824'?'dark':color==='#FFFFFF'?'white':color==='#000000'?'black':'warm',source=FridgeMaterials['reading_'+(blend==='scrim'?'scrim':'feather')+'_'+suffix];
   return `<image href="${source}" width="${w}" height="${h}" preserveAspectRatio="none"/>`;
  }
  if((cap.readingMaterialStudy??0)>0){const variant=cap.readingMaterialStudy;
   return `<defs><clipPath id="${id}mica"><path d="${p}"/></clipPath><radialGradient id="${id}pigment" cx="86%" cy="82%" r="92%"><stop stop-color="${col(material.micaStudyPigment(tint,variant))}"/><stop offset=".46" stop-color="${col(material.micaStudyPigment(tint,variant,.4))}"/><stop offset="1" stop-color="transparent"/></radialGradient><radialGradient id="${id}light" cx="15%" cy="22%" r="80%"><stop stop-color="#FFFFF8B8"/><stop offset=".35" stop-color="#FFFFF850"/><stop offset="1" stop-color="#FFFFF800"/></radialGradient></defs><path d="${p}" transform="translate(0 ${1.2*s})" fill="#B29D7428"/><g clip-path="url(#${id}mica)"><rect width="${w}" height="${h}" fill="${col(material.micaStudyFill(tint,variant))}"/><image href="${FridgeMaterials.reading_mica_cloud}" width="${w}" height="${h}" preserveAspectRatio="none" opacity=".55"/><rect width="${w}" height="${h}" fill="url(#${id}pigment)"/><rect width="${w}" height="${h}" fill="url(#${id}light)"/></g><path d="${p}" fill="none" stroke="${blend==='bare'?'#FFFCF142':'#FFFDF6C8'}" stroke-width="${(blend==='bare'?.6:1.5)*s}"/>`;
  }
  if(blend==='bare'){
   let out='';for(let pass=0;pass<8;pass++){const inset=composition.compositionPadding(blend)*s*.35*pass/7;out+=`<path d="${mica.micaPath(blend,w-2*inset,h-2*inset,s,cap.readingEdge||'')}" transform="translate(${inset} ${inset})" fill="#F7F9FC18"/>`;}
   for(let i=0;i<28;i++){const y=(i+.2+(i%3)*.25)*h/28,tip=(.2+(i*7%9)*.32)*s;out+=`<path d="M ${tip} ${y} C ${w*.28} ${y-.7*s} ${w*.68} ${y+.7*s} ${w-tip} ${y+.25*s}" fill="none" stroke="${i%3===0?'#FFFFFF1F':'#EAF0F70F'}" stroke-width="${(.25+i%4*.13)*s}"/>`;}return out;
  }
  return `<path d="${p}" fill="#F7F9FCBD" stroke="#FFFFFF57" stroke-width="${.6*s}"/>`;
 }
 function readoutGeometry(c){
  const cap=c.capability;
  const blend=cap.readingBlend||'feather',box=layout.capabilityPlacement(c);
  let contact={profile:[],gutter:0,left:true,box};
  if(blend==='sticker'){const result=edge.edgeAttachment(c,box,cap.readingEdge||'left',cap.readingOutside===true);contact={...result,left:(cap.readingEdge!=='right')!==(cap.readingOutside===true)};}
  const b=contact.box,bw=c.w*b.w,bh=c.h*b.h,inset=layout.capabilityInset(c),cw=Math.max(1,bw-2*inset-contact.gutter),ch=Math.max(1,c.h*box.h-2*inset-mica.hookReserve(blend));
  return {blend,contact,b,bw,bh,inset,cw,ch};
 }
 function inspectCard(c){
  const result={id:c.id,minimumCardSize:layout.minimumCardSize(c),requestedBox:c.capBox,placement:layout.capabilityPlacement(c)};
  if(!c.capability||c.capability.k==='album')return result;
  const g=readoutGeometry(c),compact=metrics.compactCapability(c.capability,g.cw,g.ch);
  return {...result,contentWidth:g.cw,contentHeight:g.ch,compact,contentScale:metrics.capabilityContentScale(c.capability,g.cw,g.ch),readableMinimum:metrics.capabilityMinimum(c.capability,compact,g.cw),fits:metrics.capabilityFits(c.capability,g.cw,g.ch)};
 }
 function capability(c,tick,id){
  const cap=c.capability;if(!cap||cap.k==='album')return '';
  const {blend,contact,b,bw,bh,inset,cw,ch}=readoutGeometry(c);
  let ink=c.shape==='subject'&&c.subjectPhoto&&!c.ink?c.subjectInk:schema.materialColors(c.material,c.paper,c.ink)[1];
  const surface=present.readingSurface(cap,c.shape==='subject'&&c.subjectPhoto,layout.capabilityObstructed(c));
  if(surface&&!c.ink&&['paper','cloud','bare','badge','sticker','space','tag','dock'].includes(blend))ink=present.paperReadingInk(ink);
  const tint=cap.readingTint||schema.materialColors(c.material,c.paper,c.ink)[0],compact=metrics.compactCapability(cap,cw,ch),min=metrics.capabilityMinimum(cap,compact,cw),u=Math.max(.001,Math.min(2,cw/min.w,ch/min.h)),now=new Date(tick),pad=surface?composition.compositionPadding(blend)*u:0;
  const text=(v,x,y,fs,width=cw,anchor='start',weight=400,opacity=1)=>txt(v,x,y,fs,ink,width,anchor,weight,opacity);
  let body='',width=cw,height=0,s=u;
  function centerLine(value,font,weight=400,opacity=1,advance=font*1.2){body+=text(value,width/2,height,font,width,'middle',weight,opacity);height+=advance;}
  if(cap.k==='battery'){
   const d=(compact?48:72)*u,fs=(compact?10:14)*u,label=battery.batteryLevel(cap)<0?'—':String(battery.batteryLevel(cap)),paperD=d*.88+fs*1.25+4*u,hr=mica.hookReserve(blend)*u;
   let dial='';
   if(surface){dial+=`<g transform="translate(${(d-paperD)/2} ${(d-paperD)/2-hr})">`+backing(paperD,paperD+hr,blend,u,ink,tint,cap,{profile:[],left:true},id+'battery')+(['tag','dock'].includes(blend)?hook(mica.hookCenter(cap.readingHook??.2,paperD,u),u):'')+'</g>';}
   dial+=`<path d="${battery.batteryRingPath(d)}" fill="none" stroke="${ink}" opacity=".14" stroke-width="${(compact?3.5:5)*u}" stroke-linecap="round"/>`;
   if(battery.batteryLevel(cap)>0)dial+=`<path d="${battery.batteryRingPath(d,battery.batteryLevel(cap))}" fill="none" stroke="${battery.batteryTint(cap,ink)}" opacity="${cap.refreshState==='failed'?.45:1}" stroke-width="${(compact?3.5:5)*u}" stroke-linecap="round"/>`;
   if(cap.charging||cap.chargeState==='full'){const bs=(compact?15:22)*u;dial+=`<path d="M .57 0 L .16 .57 L .47 .57 L .39 1 L .86 .39 L .53 .39 Z" transform="translate(${d/2-bs/2} ${d/2-bs/2}) scale(${bs})" fill="${battery.batteryTint(cap,ink)}"/>`;}
   for(const g of battery.batteryArcLabel(d,label,fs))dial+=`<g transform="rotate(${g.angle} ${g.x} ${g.y})">${txt(g.character,g.x,g.y-fs*.55,fs,ink,Infinity,'middle',500)}</g>`;
   return `<g data-capability="battery" transform="translate(${b.x*c.w+(bw-d)/2} ${b.y*c.h+(bh-d-8*u)/2+hr/2}) rotate(${b.rot} ${d/2} ${d/2})" opacity="${b.opacity}">${dial}</g>`;
  }
  if(cap.k==='timetable'){
   s=Math.min(1,metrics.capabilityContentScale(cap,cw,ch));const display=data.timetableDisplay(cap,tick),cols=load('TimetableLayout').briefColumns(cw/Math.max(.001,s)+.01),dt=new Date(display.date),label=(dt.getMonth()+1)+'.'+dt.getDate();
   let content='';
   let measured=measure(display.heading,10*s)+measure(label,8.5*s)+18*s;
   if(!display.lessons.length)measured=Math.max(measured,measure(display.empty,11.5*s));
   else{let cell=0;for(const lesson of display.lessons)cell=Math.max(cell,measure(lesson.title,11.5*s),measure(lesson.location||'地点待定',8.5*s));measured=Math.max(measured,(cell+44*s)*(cap.timetableMode==='day'?cols:1));}
   width=surface?Math.max(1,Math.min(cw+2*composition.compositionPadding(blend),Math.ceil(measured)+2*composition.compositionPadding(blend)*s)-2*composition.compositionPadding(blend)*s):cw;
   const pending=cap.skipHolidays!==false&&!holidays.holidayKnown(dt.getFullYear())&&!(cap.teachingDays||[]).some(d=>d.date===holidays.dateKey(dt))&&!(cap.holidayDates||[]).some(d=>d.date===holidays.dateKey(dt));
   content+=text(pending?'假期待确认':display.heading,0,3*s,10*s,Math.max(1,width-35*s),'start',500)+text(label,width-13*s,4*s,8.5*s,Infinity,'end',400,.6);
   content+=`<g transform="translate(${width-10*s} ${4*s}) scale(${s})"><rect width="9" height="9" rx="1.4" fill="none" stroke="${ink}" stroke-width="1"/><path d="M 0 3 H 9 M 2 0 V 2 M 7 0 V 2" stroke="${ink}" stroke-width="1"/></g>`;height=18*s;
   if(!metrics.capabilityFits(cap,cw,ch)){content+=text('放大卡片以显示课程',0,height,12*s,width);height+=15*s;}
   else if(!display.lessons.length){content+=text(display.empty,0,height,11.5*s,width,'start',500);height+=14*s;if(ch>=70){content+=text((cap.courses||[]).length?(cap.timetableMode==='day'?'查看周课表安排':'开课前一晚显示下一课'):'导入或添加你的课程',0,height+3*s,11*s,width,'start',400,.55);height+=17*s;}}
   else{const shown=cap.timetableMode==='day'?display.lessons:display.lessons.slice(0,1),columns=cap.timetableMode==='day'?cols:1,cellW=width/columns;
    shown.forEach((lesson,i)=>{const x=i%columns*cellW,y=height+Math.floor(i/columns)*32*s,highlight=lesson.id===display.lessons.find(e=>e.end>tick)?.id;
     content+=`<rect x="${x}" y="${y}" width="${cellW}" height="${29*s}" rx="${7*s}" fill="${highlight?'#F5C94B45':'#A69A7C16'}"/>`;
     content+=text(data.timeText(lesson.start),x+5*s,y+3*s,9.5*s,30*s,'start',500)+text(data.timeText(lesson.end),x+5*s,y+15*s,8.5*s,30*s,'start',400,.6);
     content+=text(lesson.title,x+39*s,y+(lesson.location?2:8)*s,11.5*s,Math.max(1,cellW-44*s),'start',500);
     if(lesson.location)content+=text(lesson.location,x+39*s,y+17*s,8.5*s,Math.max(1,cellW-44*s),'start',400,.6);
    });height+=Math.ceil(shown.length/columns)*32*s;
   }body=content;
  }else if(cap.k==='agenda'){
   s=Math.max(.001,metrics.capabilityContentScale(cap,cw,ch));const display=present.summaryPresentation(cap,ch/s,tick);let measured=measure(display.heading,11*s)+(display.remaining?measure('+'+display.remaining,11*s)+8*s:0);
   for(const event of display.events)measured=Math.max(measured,measure(event.title,16*s),measure(data.eventWhen(event,tick)+(event.location?' · '+event.location:''),11*s));
   if(!display.events.length)measured=Math.max(measured,measure(display.empty,16*s));
   width=surface?Math.max(1,Math.min(cw+2*composition.compositionPadding(blend),Math.ceil(measured)+2*composition.compositionPadding(blend)*s)-2*composition.compositionPadding(blend)*s):cw;
   body+=text(display.heading,0,0,11*s,width,'start',400,.65);if(display.remaining)body+=text('+'+display.remaining,width,0,11*s,Infinity,'end',400,.65);height=24*s;
   if(!display.events.length){body+=text(display.empty,0,height,16*s,width,'start',500);height+=20*s;}
   for(const event of display.events){body+=text(event.title,0,height,16*s,width,'start',500)+text(data.eventWhen(event,tick)+(event.location?' · '+event.location:''),0,height+22*s,11*s,width,'start',400,.65);height+=40*s;}
  }else{
   const clockFont=metrics.boundedReadoutFont((compact?24:42)*u,cw,3.2),dateFont=metrics.boundedReadoutFont((compact?24:54)*u,cw,2.8),days=calendar.daysLeftOf(cap.date||'',tick),counterFont=Math.max(16*u,Math.min((compact?24:44)*u,(cw-32*u)/(String(Math.abs(days)).length*.6)));
   let nominalWidth=cw;
   if(cap.k==='clock')nominalWidth=measure('88:88',clockFont,500);
   else if(cap.k==='date'){const caption=holidays.holidayName(now)||(compact?'':now.getFullYear()+'年')+(now.getMonth()+1)+'月 · '+['周日','周一','周二','周三','周四','周五','周六'][now.getDay()]+(holidays.holidayMarker(now)==='班'?' · 班':'');nominalWidth=Math.max(measure('88日',dateFont,500),measure(caption,12*u));}
   else if(['countdown','anniversary'].includes(cap.k))nominalWidth=Math.max(measure(cap.title||schema.typeLabel(cap.k),12*u),measure(String(Math.abs(days)),counterFont,500)+measure(cap.k==='anniversary'?(days>0?'天后':'天'):(days<0?'天前':'天'),12*u)+3*u,compact?0:measure(cap.date||'',10*u));
   else if(cap.k==='calendar')nominalWidth=7*(measure('88',12*u)+(compact?3:7)*u);
   else if(cap.k==='worldclock'){const city=time.cityReading(cap.zone||'',tick);nominalWidth=Math.max(measure(city.city,12*u),measure('88:88',metrics.boundedReadoutFont((compact?28:40)*u,cw,3.2),500),measure('12月31日 · 周三',11*u),compact?0:measure(city.difference,11*u));}
   else if(cap.k==='lunar'){const lunar=time.lunarReading(tick),font=Math.min(compact?18:26,Math.max(16,cw/(lunar.date.replace(/\s/g,'').length+.35)))*u;nominalWidth=Math.max(measure('农历',12*u),measure(lunar.date,font,500),measure(lunar.year,12*u));}
   else nominalWidth=Math.max(64*u,measure(schema.typeLabel(cap.k),12*u),measure('100%',(compact?24:38)*u));
   width=surface&&!contact.profile.length?Math.max(1,Math.min(cw+2*composition.compositionPadding(blend),Math.ceil(nominalWidth)+2*composition.compositionPadding(blend)*u)-2*composition.compositionPadding(blend)*u):cw;
   if(!metrics.capabilityFits(cap,cw,ch)){centerLine('放大卡片',12);}
   else if(cap.k==='clock')centerLine(('0'+now.getHours()).slice(-2)+':'+('0'+now.getMinutes()).slice(-2),clockFont,500,1,clockFont*1.35);
   else if(cap.k==='date'){centerLine(new Intl.DateTimeFormat('zh-CN',{day:'2-digit'}).format(now),dateFont,500,1,dateFont*1.35);height+=4*u;centerLine(holidays.holidayName(now)||(compact?'':now.getFullYear()+'年')+(now.getMonth()+1)+'月 · '+['周日','周一','周二','周三','周四','周五','周六'][now.getDay()]+(holidays.holidayMarker(now)==='班'?' · 班':''),12*u,400,.65);}
   else if(['countdown','anniversary'].includes(cap.k)){centerLine(cap.title||schema.typeLabel(cap.k),12*u);height+=4*u;const suffix=!cap.date?'':cap.k==='anniversary'?(days>0?'天后':'天'):(days<0?'天前':'天'),number=cap.date?String(Math.abs(days)):'—',nw=measure(number,counterFont,500),sw=measure(suffix,12*u),left=(width-nw-sw-3*u)/2;body+=text(number,left,height,counterFont,nw,'start',500)+text(suffix,left+nw+3*u,height+counterFont*1.2-12*u*1.2,12*u,sw);height+=counterFont*1.2;if(!compact){height+=4*u;centerLine(cap.date||'设置日期',10*u,400,.6);}}
   else if(cap.k==='calendar'){
    if(compact&&(cap.calendarOffset??0)!==0){const month=new Date(now.getFullYear(),now.getMonth()+(cap.calendarOffset??0),1);centerLine(month.getFullYear()+'年',12*u,400,.65);height+=4*u;centerLine(month.getMonth()+1+'月',28*u);height+=4*u;centerLine('点按查看月历',10*u,400,.6);}
    else{
     const month=new Date(now.getFullYear(),now.getMonth()+(cap.calendarOffset??0),1),cells=compact?Array.from({length:7},(_,i)=>new Date(now.getFullYear(),now.getMonth(),now.getDate()-now.getDay()+i).getDate()):calendar.calendarCells(month);
     centerLine(compact?(now.getMonth()+1)+'月 · 本周':month.getFullYear()+'年'+(month.getMonth()+1)+'月',(compact?12:14)*u);height+=4*u;const colW=width/7;
     ['日','一','二','三','四','五','六'].forEach((day,i)=>body+=text(day,(i+.5)*colW,height,10*u,colW,'middle',400,.6));height+=14*u;
     cells.forEach((day,i)=>{const x=(i%7+.5)*colW,y=height+Math.floor(i/7)*22*u,selected=day===now.getDate()&&(cap.calendarOffset??0)===0;if(selected)body+=`<rect x="${x-colW/2}" y="${y}" width="${colW}" height="${20*u}" rx="4" fill="${ink}"/>`;body+=txt(day||'',x,y+2*u,12*u,selected?schema.contrastingInk(ink):ink,colW,'middle');const date=compact?new Date(now.getFullYear(),now.getMonth(),now.getDate()-now.getDay()+i):new Date(month.getFullYear(),month.getMonth(),day);if(day)body+=text(holidays.holidayMarker(date),compact?x:x+colW*.35,compact?y+21*u:y,compact?7*u:6*u,colW,'middle',400,.65);});height+=Math.ceil(cells.length/7)*(compact?30:22)*u;
    }
   }else if(cap.k==='worldclock'){const city=time.cityReading(cap.zone||'',tick),world=new Date(tick-time.clockOffset(cap.zone||'',tick)*3600000);centerLine(city.city,12*u,400,.65);height+=4*u;const fs=metrics.boundedReadoutFont((compact?28:40)*u,cw,3.2);centerLine(('0'+world.getUTCHours()).slice(-2)+':'+('0'+world.getUTCMinutes()).slice(-2),fs,500,1,fs*1.35);height+=4*u;centerLine(city.date,11*u);if(!compact){height+=4*u;centerLine(city.difference,11*u,400,.65);}}
   else if(cap.k==='lunar'){const lunar=time.lunarReading(tick),fs=Math.min(compact?18:26,Math.max(16,cw/(lunar.date.replace(/\s/g,'').length+.35)))*u;centerLine('农历',12*u,400,.65);height+=4*u;centerLine(lunar.date,fs,500);height+=4*u;centerLine(lunar.year,12*u,400,.65);}
   else{const progress=calendar.progressOf(cap.k,now);centerLine(schema.typeLabel(cap.k),12*u,400,.65);height+=4*u;centerLine(Math.floor(progress*100)+'%',(compact?24:38)*u);height+=4*u;body+=`<rect y="${height}" width="${width}" height="${4*u}" rx="${2*u}" fill="${ink}" opacity=".12"/><rect y="${height}" width="${width*progress}" height="${4*u}" rx="${2*u}" fill="${ink}"/>`;height+=4*u;}
  }
  const p=surface?composition.compositionPadding(blend)*s:0,hr=surface?mica.hookReserve(blend)*s:0,visibleHeight=surface?Math.min(height,ch):height,labelW=surface?width+2*p+contact.gutter:width,labelH=contact.profile.length?bh:visibleHeight+2*p+hr,left=(bw-labelW)/2,top=(bh-labelH)/2;
  let out=`<g data-capability="${cap.k}" transform="translate(${b.x*c.w} ${b.y*c.h}) rotate(${blend==='sticker'?0:b.rot} ${bw/2} ${bh/2})" opacity="${b.opacity}"><g transform="translate(${left} ${top})">`;
  if(surface)out+=backing(labelW,labelH,blend,s,ink,tint,cap,contact,id);
  out+=`<defs><clipPath id="${id}text"><rect x="${p+(contact.left?contact.gutter:0)}" y="${p+hr}" width="${width}" height="${surface?ch:Math.max(height,bh)}"/></clipPath></defs><g clip-path="url(#${id}text)"><g transform="translate(${p+(contact.left?contact.gutter:0)} ${p+hr})">${body}</g></g>`;
  if(surface&&['tag','dock'].includes(blend))out+=hook(mica.hookCenter(cap.readingHook??.2,labelW,s),s);
  return out+'</g></g>';
 }
 global.FridgeReadouts={capability,backing,inspectCard,supportedKinds:Object.freeze(['clock','date','calendar','countdown','anniversary','dayprogress','yearprogress','battery','timetable','agenda','worldclock','lunar'])};
})(globalThis);
