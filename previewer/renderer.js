/* Browser adapter only. Protocol, sizing and rotation selection come from production models. */
(function(global){
 'use strict';
 const schema=FridgeCore.load('CardSchema'),layout=FridgeCore.load('AlbumLayout'),rotation=FridgeCore.load('AlbumRotation'),depth=FridgeCore.load('CardDepth');
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
  let cursor=g.textY;
  // Native row layout has two lines. Preserve that line capacity in the web adapter.
  const lines=style==='row'?2:1;
  function wrap(value,size){
   if(lines===1)return [fitted(value,size,g.textWidth)];
   const chars=Array.from(value),out=[];let line='';
   if(measure)measure.font='500 '+size+'px system-ui';
   while(chars.length&&out.length<lines){const c=chars.shift();if(line&&measure&&measure.measureText(line+c).width>g.textWidth){out.push(line);line=c;}else line+=c;}
   if(out.length<lines)out.push(line);if(chars.length)out[lines-1]=fitted(out[lines-1]+chars.join(''),size,g.textWidth);return out;
  }
  for(const line of wrap(album.title||'未命名专辑',g.titleSize)){out+=textLine(line,g.textX,cursor+g.titleSize*.9,g.titleSize,g.textWidth);cursor+=g.titleSize*1.15;}
  cursor+=4;
  if(album.artist)for(const line of wrap(album.artist,g.artistSize)){out+=textLine(line,g.textX,cursor+g.artistSize*.9,g.artistSize,g.textWidth,221/255);cursor+=g.artistSize*1.15;}
  return out;
 }
 function shadow(id,r=12,y=5,opacity=53/255){return `<filter id="${id}shadow" x="-40%" y="-40%" width="180%" height="190%"><feDropShadow dx="0" dy="${y}" stdDeviation="${r/2}" flood-opacity="${opacity}"/></filter>`;}
 function albumSVG(album,w,h,style='cover',id='album'){
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" viewBox="0 0 ${w} ${h}" font-family="system-ui,sans-serif"><defs>${shadow(id,style==='cover'?12:10,style==='cover'?5:4,style==='cover'?53/255:40/255)}<clipPath id="${id}card"><rect width="${w}" height="${h}" rx="${schema.ALBUM_CARD_CORNER_RADIUS}"/></clipPath></defs><g clip-path="url(#${id}card)">${albumBody(album,w,h,style,id)}</g></svg>`;
 }
 function issuesFor(pack){
  const issues=[];
  for(const c of pack.state.cards){
   if(c.capability&&c.capability.k!=='album')issues.push(c.id+'：'+c.capability.k+' 尚未接入浏览器渲染，视觉验收阻断');
   if(c.shape==='subject')issues.push(c.id+'：主体蒙版与厚度尚未接入，视觉验收阻断');
   if((c.elements||[]).length)issues.push(c.id+'：自定义元素的字体适配/混合尚未接入，视觉验收阻断');
   if(c.capability?.k==='album'&&(c.w!==c.h))issues.push(c.id+'：非正方形外框的原生裁切尚未对照，视觉验收阻断');
  }
  return issues;
 }
 function renderPackage(pack,width,tick){
  const scene=pack.state,scale=width/schema.BOARD_W,height=width/scene.canvasAspect,assets=new Map();
  const diagnostics=issuesFor(pack);
  for(const a of pack.assets){
   if(!/^[A-Za-z0-9+/]*={0,2}$/.test(a.data)||a.data.length%4!==0)throw Error('图片 Base64 编码无效');
   const mime=a.extension==='.jpg'||a.extension==='.jpeg'?'jpeg':a.extension.slice(1);
   assets.set(a.key,'data:image/'+mime+';base64,'+a.data);
  }
  const media=ref=>assets.get(ref)||'';
  let defs='',body=`<rect width="${width}" height="${height}" fill="${color(scene.background.color)}"/>`;
  if(scene.background.src&&scene.background.mode!=='solid'&&scene.background.mode!=='smart')body+=image(media(scene.background.src),0,0,width,height,0,'backdrop','xMidYMid slice');
  scene.cards.slice().sort((a,b)=>a.z-b.z).forEach((c,i)=>{
   const id='c'+i,r=schema.cardCornerRadius(c),[paper]=schema.materialColors(c.material,c.paper,c.ink),edge=depth.cardEdgeColor(paper,false);
   const content=c.capability?.k==='album'?rotation.activeAlbum(c.capability,tick):null;
   defs+=shadow(id)+shadow(id+'cast',5.5,4,48/255)+shadow(id+'contact',1.4,1.2,72/255)+`<clipPath id="${id}clip"><rect width="${c.w}" height="${c.h}" rx="${r}"/></clipPath>`;
   const x=c.x*scale,y=c.y*height/schema.BOARD_H;
   body+=`<g transform="translate(${x} ${y}) scale(${scale})"><g transform="rotate(${c.rot} ${c.w/2} ${c.h/2})">`;
   // Same face/sidewall/contact/cast layer order as CardFace.backing.
   body+=`<rect y="2" width="${c.w}" height="${c.h}" rx="${r}" fill="${edge}" filter="url(#${id}castshadow)"/><rect y="2" width="${c.w}" height="${c.h}" rx="${r}" fill="${edge}" filter="url(#${id}contactshadow)"/><rect y="2" width="${c.w}" height="${c.h}" rx="${r}" fill="${edge}"/>`;
   body+=`<g clip-path="url(#${id}clip)"><rect width="${c.w}" height="${c.h}" fill="${color(paper)}"/>`;
   if(content)body+=albumBody({...content,cover:media(content.cover),background:media(content.background)},c.w,c.h,'cover',id);
   else if(c.capability||c.shape==='subject'||c.elements.length)body+=`<rect x="8" y="8" width="${Math.max(0,c.w-16)}" height="${Math.max(0,c.h-16)}" rx="8" fill="#F4E6CC"/><text x="${c.w/2}" y="${c.h/2}" text-anchor="middle" font-size="12" fill="#6C5740">未支持的渲染</text>`;
   body+='</g></g></g>';
  });
  return {svg:`<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" viewBox="0 0 ${width} ${height}" font-family="system-ui,sans-serif"><defs>${defs}<clipPath id="board"><rect width="${width}" height="${height}" rx="20"/></clipPath></defs><g clip-path="url(#board)">${body}</g></svg>`,issues:diagnostics,width,height};
 }
 global.FridgeWeb={albumSVG,renderPackage,issuesFor};
})(globalThis);
