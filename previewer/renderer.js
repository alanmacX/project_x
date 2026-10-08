/* Browser adapter only. Protocol, sizing and rotation selection come from production models. */
(function(global){
 'use strict';
 const schema=FridgeCore.load('CardSchema'),layout=FridgeCore.load('AlbumLayout'),rotation=FridgeCore.load('AlbumRotation'),depth=FridgeCore.load('CardDepth'),canvas=FridgeCore.load('CanvasLayout');
 let dimensions=new Map();
 const escape=s=>String(s??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
 const color=c=>/^#[\da-f]{6}$/i.test(c)?c:'#30322D';
 const measure=typeof document==='undefined'?null:document.createElement('canvas').getContext('2d');
 function fitted(text,size,width){
  if(!measure)return String(text);
  measure.font='500 '+size+'px system-ui';
  if(measure.measureText(text).width<=width)return text;
  const chars=Array.from(text);while(chars.length&&measure.measureText(chars.join('')+'…').width>width)chars.pop();return chars.join('')+'…';
 }
 function textLine(text,x,y,size,width,opacity=1){return `<text x="${x}" y="${y}" font-size="${size}" font-weight="500" fill="white" opacity="${opacity}">${escape(fitted(text,size,width))}</text>`;}
 function image(src,x,y,w,h,r,id,fit='xMidYMid meet'){
  if(!src)return '';
  if(src.startsWith('#')){
   let dx=x,dy=y,dw=w,dh=h;const size=dimensions.get(src);
   if(size&&fit!=='none'){const ratio=fit.endsWith('slice')?Math.max(w/size.width,h/size.height):Math.min(w/size.width,h/size.height);dw=size.width*ratio;dh=size.height*ratio;dx=x+(w-dw)/2;dy=y+(h-dh)/2;}
   return `<defs><clipPath id="${id}"><rect x="${x}" y="${y}" width="${w}" height="${h}" rx="${r}"/></clipPath></defs><g clip-path="url(#${id})"><use href="${src}" transform="translate(${dx} ${dy}) scale(${dw} ${dh})"/></g>`;
  }
  return `<defs><clipPath id="${id}"><rect x="${x}" y="${y}" width="${w}" height="${h}" rx="${r}"/></clipPath></defs><image href="${escape(src)}" x="${x}" y="${y}" width="${w}" height="${h}" preserveAspectRatio="${fit}" clip-path="url(#${id})"/>`;
 }
 function albumBody(album,w,h,style,id){
  let out=`<rect width="${w}" height="${h}" fill="#D9D4CD"/>`;
  if(album.background)out+=image(album.background,0,0,w,h,0,id+'bg','none');
  if(!album.cover)return out+`<text x="${w/2}" y="${h/2+5}" text-anchor="middle" fill="#494640" font-size="14">选择一张专辑</text>`;
  if(style==='cover'){
   const size=layout.albumCoverSize(w,h),r=layout.albumCoverRadius(w,h);
   return out+`<g filter="url(#${id}shadow)">`+image(album.cover,(w-size)/2,(h-size)/2,size,size,r,id+'cover')+'</g>';
  }
  const g=layout.albumInfoGeometry(w,h,style);
  out+=`<rect width="${w}" height="${h}" fill="black" opacity="${56/255}"/>`;
  out+=`<g filter="url(#${id}shadow)">`+image(album.cover,g.coverX,g.coverY,g.coverSize,g.coverSize,14,id+'cover')+'</g>';
  function wrap(value,size,lines){
   const chars=Array.from(value||''),result=[];let line='';
   if(measure)measure.font='500 '+size+'px system-ui';
   while(chars.length){const c=chars[0];if(line&&measure&&measure.measureText(line+c).width>g.textWidth){if(result.length===lines-1){result.push(fitted(line+chars.join(''),size,g.textWidth));return result;}result.push(line);line='';}else{line+=chars.shift();}}
   if(line)result.push(line);return result;
  }
  const titles=wrap(album.title||'未命名专辑',g.titleSize,g.titleLines),artists=wrap(album.artist,g.artistSize,g.artistLines);
  const textHeight=titles.length*g.titleSize*1.15+(artists.length?g.artistGap+artists.length*g.artistSize*1.15:0);
  let cursor=g.textY-(g.centerText?textHeight/2:0);
  for(const line of titles){out+=textLine(line,g.textX,cursor+g.titleSize*.9,g.titleSize,g.textWidth);cursor+=g.titleSize*1.15;}
  cursor+=g.artistGap;
  for(const line of artists){out+=textLine(line,g.textX,cursor+g.artistSize*.9,g.artistSize,g.textWidth,221/255);cursor+=g.artistSize*1.15;}
  return out;
 }
 function shadow(id,r=12,y=5,opacity=53/255){return `<filter id="${id}shadow" x="-40%" y="-40%" width="180%" height="190%"><feDropShadow dx="0" dy="${y}" stdDeviation="${r/2}" flood-opacity="${opacity}"/></filter>`;}
 function albumSVG(album,w,h,style='cover',id='album'){
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" viewBox="0 0 ${w} ${h}" font-family="system-ui,sans-serif"><defs>${shadow(id,style==='cover'?12:10,style==='cover'?5:4,style==='cover'?53/255:40/255)}<clipPath id="${id}card"><rect width="${w}" height="${h}" rx="${schema.ALBUM_CARD_CORNER_RADIUS}"/></clipPath></defs><g clip-path="url(#${id}card)">${albumBody(album,w,h,style,id)}</g></svg>`;
 }
 function issuesFor(pack){
  const issues=[];
  for(const c of pack.state.cards){
   if(c.capability&&!schema.CAPABILITIES.includes(c.capability.k))issues.push(c.id+'：未知能力，视觉验收阻断');
   else if(c.capability&&c.capability.k!=='album'&&!FridgeReadouts.supportedKinds.includes(c.capability.k))issues.push(c.id+'：预览器尚未适配此能力，视觉验收阻断');
   if(c.shape==='subject'&&!c.cutout)issues.push(c.id+'：缺少主体蒙版，视觉验收阻断');
   if(c.shape==='subject'&&!c.outline.length)issues.push(c.id+'：缺少厚度轮廓，视觉验收阻断');
   for(const el of c.elements||[])if(!['text','image','shape'].includes(el.kind))issues.push(c.id+'：未知元素，视觉验收阻断');
  }
  return issues;
 }
 function element(el,w,h,ox,oy,ink,media,id){
  const x=ox+el.x*w,y=oy+el.y*h,ew=el.w*w,eh=el.h*h;let body='';
  if(el.kind==='image')body=image(media(el.src),0,0,ew,eh,0,id+'img','xMidYMid slice');
  else if(el.kind==='shape')body=`<rect width="${ew}" height="${el.primitive==='line'?3:eh}" rx="${el.primitive==='circle'?Math.min(ew,eh)/2:4}" fill="${color(el.color||ink)}"/>`;
  else{
   const value=String(el.text||''),weight=el.bold?500:400;let fs=el.fs,lines=[];
   function wrap(){const out=[];let line='';if(measure)measure.font=weight+' '+fs+'px system-ui';for(const char of value){if(char==='\n'){out.push(line);line='';continue;}if(line&&measure&&measure.measureText(line+char).width>ew){out.push(line);line=char;}else line+=char;}out.push(line);return out;}
   lines=wrap();while(fs>Math.min(8,el.fs)&&lines.length*fs*1.2>eh){fs=Math.max(Math.min(8,el.fs),fs-.5);lines=wrap();}
   const capacity=Math.max(1,Math.floor(eh/(fs*1.2))),shown=lines.slice(0,capacity);if(lines.length>capacity)shown[capacity-1]=fitted(shown[capacity-1]+'…',fs,ew);
   const anchor=el.align==='center'?'middle':el.align==='right'?'end':'start',tx=anchor==='middle'?ew/2:anchor==='end'?ew:0;
   body=`<defs><clipPath id="${id}txt"><rect width="${ew}" height="${eh}"/></clipPath></defs><g clip-path="url(#${id}txt)">`+shown.map((line,i)=>`<text x="${tx}" y="${i*fs*1.2+fs*.91}" font-size="${fs}" font-weight="${weight}" text-anchor="${anchor}" fill="${color(el.color||ink)}">${escape(line)}</text>`).join('')+'</g>';
  }
  return `<g data-element="${escape(el.id)}" transform="translate(${x} ${y}) rotate(${el.rot} ${ew/2} ${eh/2})" opacity="${el.opacity}">${body}</g>`;
 }
 function renderPackage(pack,width,tick,options={}){
  const namespace=options.namespace||'fridge';if(!/^[A-Za-z][A-Za-z0-9_-]{0,63}$/.test(namespace))throw Error('Invalid SVG namespace');
  if(!Number.isFinite(width)||width<=0||!Number.isFinite(tick))throw Error('Invalid render dimensions/time');
  const scene=pack.state,scale=width/schema.BOARD_W,height=width/scene.canvasAspect,assets=new Map();dimensions=new Map();
  const diagnostics=issuesFor(pack);
  let assetDefs='';for(const [index,a] of pack.assets.entries()){
   if(!/^[A-Za-z0-9+/]*={0,2}$/.test(a.data)||a.data.length%4!==0)throw Error('图片 Base64 编码无效');
   const mime=a.extension==='.jpg'||a.extension==='.jpeg'?'jpeg':a.extension.slice(1);
   const key='#'+namespace+'media'+index;assets.set(a.key,key);dimensions.set(key,pack.assetDimensions?.[a.key]||{width:1,height:1});
   assetDefs+=`<image id="${key.slice(1)}" href="data:image/${mime};base64,${a.data}" width="1" height="1" preserveAspectRatio="none"/>`;
  }
  const media=ref=>assets.get(ref)||'';
  let defs=assetDefs,body=`<rect width="${width}" height="${height}" fill="${color(scene.background.color)}"/>`;
  if(scene.background.src&&scene.background.mode!=='solid'&&scene.background.mode!=='smart')body+=image(media(scene.background.src),0,0,width,height,0,namespace+'backdrop','xMidYMid slice');
  const background=body,cards=[];
  scene.cards.slice().sort((a,b)=>a.z-b.z).forEach((c,i)=>{
   const start=body.length,id=namespace+'c'+i,r=schema.cardCornerRadius(c),[paper,ink]=schema.materialColors(c.material,c.paper,c.ink),edge=depth.cardEdgeColor(paper,c.shape==='subject'&&c.subjectPhoto),f=canvas.subjectSurfaceFactor(c);
   const content=c.capability?.k==='album'?rotation.activeAlbum(c.capability,tick):null;
   defs+=shadow(id)+shadow(id+'cast',5.5,4,48/255)+shadow(id+'contact',1.4,1.2,72/255)+`<clipPath id="${id}clip"><rect width="${c.w}" height="${c.h}" rx="${r}"/></clipPath>`;
   const x=c.x*scale,y=c.y*height/schema.BOARD_H;
   body+=`<g data-fridge-card="${escape(c.id)}"><g transform="translate(${x} ${y}) scale(${scale})"><g transform="rotate(${c.rot} ${c.w/2} ${c.h/2})">`;
   if(c.shape==='subject'&&c.outline.length){
    const commands=FridgeCore.load('ContourPath').contourPath(c.outline,c.w,c.h,f),border=c.subjectBorder?6:0;
    for(const [radius,y,alpha] of [[5.5,6,48/255],[1.4,3.2,72/255]])for(const [extra,opacity] of [[2*radius,.15],[radius,.25],[0,.6]])body+=`<path d="${commands}" transform="translate(0 ${y})" fill="black" stroke="black" stroke-width="${border+extra}" stroke-linejoin="round" opacity="${alpha*opacity}"/>`;
    body+=`<path d="${commands}" transform="translate(0 2)" fill="${edge}" stroke="${edge}" stroke-width="${border}" stroke-linejoin="round"/><path d="${commands}" fill="${c.subjectPhoto?'white':paper}" stroke="${c.subjectPhoto?'white':paper}" stroke-width="${border}" stroke-linejoin="round"/>`;
   }else body+=`<rect y="2" width="${c.w}" height="${c.h}" rx="${r}" fill="${edge}" filter="url(#${id}castshadow)"/><rect y="2" width="${c.w}" height="${c.h}" rx="${r}" fill="${edge}" filter="url(#${id}contactshadow)"/><rect y="2" width="${c.w}" height="${c.h}" rx="${r}" fill="${edge}"/>`;
   const innerW=c.w*f,innerH=c.h*f,offsetX=(c.w-innerW)/2,offsetY=(c.h-innerH)/2;
   if(c.shape==='subject'&&c.cutout){defs+=`<mask id="${id}alpha" maskUnits="userSpaceOnUse" x="0" y="0" width="${c.w}" height="${c.h}" style="mask-type:alpha"><use href="${media(c.cutout)}" transform="translate(${offsetX} ${offsetY}) scale(${innerW} ${innerH})"/></mask>`;}
   const isFree=c.capFree||FridgeCore.load('ReadingComposition').isReadingComposition(c.capability?.readingBlend||''),readout=c.capability&&!content?FridgeReadouts.capability(c,tick,id+'cap'):'';
   body+=`<g ${c.shape==='subject'&&c.cutout?`mask="url(#${id}alpha)"`:`clip-path="url(#${id}clip)"`}>`;
   if(content)body+=albumBody({...content,cover:media(content.cover),background:media(content.background)},c.w,c.h,c.capability.albumPresentation||'cover',id);
   else{
    body+=`<rect width="${c.w}" height="${c.h}" fill="${color(paper)}"/>`;
    if(c.shape==='subject'&&c.subjectPhoto&&c.cutout)body+=image(media(c.cutout),offsetX,offsetY,innerW,innerH,0,id+'photo','none');
    const layers=behind=>(c.elements||[]).filter(el=>el.behindCapability===behind).map((el,j)=>element(el,innerW,innerH,offsetX,offsetY,ink,media,id+(behind?'back':'front')+j)).join('');
    body+=layers(true);if(!isFree&&!canvas.capabilityObstructed(c))body+=readout;body+=layers(false);if(!isFree&&canvas.capabilityObstructed(c))body+=readout;
   }
   body+='</g>';if(isFree)body+=readout;
   if(c.frame&&c.shape!=='subject')body+=`<rect x="1.5" y="1.5" width="${Math.max(0,c.w-3)}" height="${Math.max(0,c.h-3)}" rx="${Math.max(0,r-1.5)}" fill="none" stroke="white" stroke-width="3"/>`;
   if(c.shape!=='subject'){defs+=`<linearGradient id="${id}lip" x2="0" y2="1"><stop stop-color="#FFFFFF88"/><stop offset="1" stop-color="#00000020"/></linearGradient>`;body+=`<rect width="${c.w}" height="${c.h}" rx="${r}" fill="none" stroke="url(#${id}lip)" stroke-width=".6"/>`;}
   body+='</g></g></g>';
   cards.push({id:c.id,groupId:c.groupId,z:c.z,x,y,width:c.w*scale,height:c.h*scale,rotation:c.rot,pivot:{x:x+c.w*scale/2,y:y+c.h*scale/2},markup:body.slice(start)});
  });
  return {svg:`<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" viewBox="0 0 ${width} ${height}" font-family="system-ui,sans-serif"><defs>${defs}<clipPath id="${namespace}board"><rect width="${width}" height="${height}" rx="20"/></clipPath></defs><g clip-path="url(#${namespace}board)">${body}</g></svg>`,issues:diagnostics,width,height,layers:{version:1,namespace,defs,background,cards}};
 }
 // Same render pass, no second appearance implementation and no timeline in the app.
 function renderLayers(pack,width,tick,options={}){const result=renderPackage(pack,width,tick,options);return {width:result.width,height:result.height,issues:result.issues,...result.layers};}
 global.FridgeWeb={albumSVG,renderPackage,renderLayers,issuesFor};
})(globalThis);
