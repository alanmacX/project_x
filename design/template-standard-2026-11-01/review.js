(async()=>{
 const load=n=>FridgeCore.load(n),catalog=load('CompositionCatalog'),factory=load('TemplateFactory'),schema=load('CardSchema'),tick=Date.parse('2026-11-01T10:08:00+08:00');
 const bytes=new Uint8Array(await (await fetch('../template-capabilities-2026-11-01/assets/cat-tabby.webp')).arrayBuffer()),photo=btoa(Array.from(bytes,b=>String.fromCharCode(b)).join(''));const photoImage=new Image();photoImage.src='data:image/webp;base64,'+photo;await photoImage.decode();let serial=0;
 function draw(face,aspect){const state=schema.defaultState();state.canvasAspect=aspect;state.canvasDimension=aspect===2?'2*4':'4*4';state.background.mode='transparent';state.cards=factory.makeTemplateCards(face.id,aspect,()=>String(++serial),tick);const mode=document.querySelector('#data').value,palette=document.querySelector('#palette').value;
  state.cards.forEach(c=>{c.template.palette=palette;const cap=c.capability;cap.title=mode==='long'?'跨学科研究方法与现代工程实践 · 下一个值得纪念的日子 👨‍👩‍👧‍👦':'设计讨论';cap.percent=76;cap.city='上海';cap.date=cap.k==='anniversary'?'2025-06-12':'2026-11-18';cap.semester='2026-08-31';
   if(mode!=='empty'){cap.events=[{id:'demo-event',title:cap.title,start:tick+3600000,end:tick+7200000,location:mode==='long'?'东区教学楼 · 创新设计中心 · 308 工作室':'设计工作室'}];cap.courses=[{id:'demo-course',name:mode==='long'?cap.title:'设计思维',room:'东楼 308',day:7,start:'11:00',end:'12:00',firstWeek:1,lastWeek:60,parity:0}];
    if(cap.k==='anniversary'){cap.title=mode==='long'?cap.title:'陪伴的日子';const el=new schema.CanvasElement();el.kind='image';el.src='asset://review-cat.webp';c.elements=[el];}
   }else{cap.title='';cap.date='';cap.percent=-1;}
  });
  const pack={format:'fridgememo-template',version:3,kind:'canvas',state,assets:[]};if(mode!=='empty'){pack.assets=[{key:'asset://review-cat.webp',extension:'.webp',data:photo}];pack.assetDimensions={'asset://review-cat.webp':{width:photoImage.naturalWidth,height:photoImage.naturalHeight}};}
  return FridgeWeb.renderPackage(pack,344,tick,{namespace:'face'+(++serial)}).svg;
 }
 function update(){document.body.classList.toggle('compact',document.querySelector('#size').value==='180');document.querySelector('#faces').innerHTML=catalog.COMPOSITIONS.map(face=>`<article><div class="square">${draw(face,1)}</div><div class="wide">${draw(face,2)}</div><h2>${face.name}</h2><p class="roles">${face.slots.map(s=>s.role).join(' · ')}</p></article>`).join('');}
 for(const control of document.querySelectorAll('select'))control.addEventListener('change',update);await document.fonts.ready;update();
})();
