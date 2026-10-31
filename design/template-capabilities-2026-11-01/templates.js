/* Design-stage specialized renderers. Readings come from the app's shared pure models. */
(function(global){
 const calendar=FridgeCore.load('CapabilityCalendar'),time=FridgeCore.load('TimeCapabilities');
 const safe=v=>String(v).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
 const names={flip:'翻页时钟',paper:'纸本日期',portrait:'我的照片'};
 function defaults(id){return {id,theme:id==='portrait'?'sage':'natural',showDate:id==='flip',hour12:false,zone:'Asia/Shanghai',depth:true,subject:'pipi',scale:1,offset:0,photoMode:'cutout',customSubject:'',customPhoto:''};}
 function reading(tick,zone='Asia/Shanghai'){
  const offset=time.clockOffset(zone,tick),d=new Date(tick-offset*3600000),date=new Date(d.getUTCFullYear(),d.getUTCMonth(),d.getUTCDate());
  return {h:d.getUTCHours(),m:d.getUTCMinutes(),day:date.getDate(),month:date.getMonth()+1,year:date.getFullYear(),week:['星期日','星期一','星期二','星期三','星期四','星期五','星期六'][date.getDay()],date:time.cityReading(zone,tick).date,cells:calendar.calendarCells(date)};
 }
 function render(config,tick,mini=false){const r=reading(tick,config.zone),h=String(config.hour12?r.h%12||12:r.h).padStart(2,'0'),m=String(r.m).padStart(2,'0'),date=config.showDate?`<div class="date-line">${r.month}月${r.day}日<span>${r.week}</span></div>`:'';
  if(config.id==='flip')return `<div class="template flip ${config.theme==='light'?'light':''}" data-template="flip"><div class="flip-digits" aria-label="${h}:${m}">${[h,m].map((n,i)=>`<div class="flip-cell"><span>${n}</span><i class="seam"></i><i class="hinge hinge-left"></i><i class="hinge hinge-right"></i></div>`).join('')}</div>${date}</div>`;
  if(config.id==='paper')return `<div class="template calendar-paper ${config.theme==='cool'?'cool':''}" data-template="paper"><div class="paper-head"><div class="big-day">${r.day}</div><div class="paper-caption"><strong>${r.month}月</strong><span>${r.week}</span><small>${r.year}</small></div></div><div class="month-grid" aria-label="${r.year}年${r.month}月">${['日','一','二','三','四','五','六'].map(s=>`<span class="week-label">${s}</span>`).join('')}${r.cells.map((n,i)=>`<span data-day="${n}" class="month-day ${Math.floor(i/7)===Math.floor(r.cells.indexOf(r.day)/7)?'current-week':''} ${n===r.day?'today':''}">${n||''}</span>`).join('')}</div></div>`;
  const src=config.customSubject||'assets/cat-'+(config.subject==='tabby'?'tabby':'pipi')+'.webp',photo=config.photoMode==='photo',pic=config.customPhoto||src,style=`--subject-scale:${config.scale};--subject-x:${config.offset}%`;
  return `<div class="template portrait ${safe(config.theme)} ${config.depth?'depth':''} ${photo?'photo-mode':''}" style="${style}" data-template="portrait">${photo?`<img class="photo-background" src="${safe(pic)}" alt="照片"><div class="photo-shade"></div>`:''}<div class="portrait-time" aria-label="${h}:${m}">${h}<span>:</span>${m}</div>${!photo?`<div class="subject-wrap"><img class="subject" src="${safe(src)}" alt="${config.customSubject?'自选主体':config.subject==='tabby'?'Matt Buck 拍摄的猫':'Painjet 拍摄的皮皮'}"></div>`:''}${date}</div>`;
 }
 global.TemplateStudy={names,defaults,reading,render};
})(globalThis);
