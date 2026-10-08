'use strict';
const subjectUI=id=>document.getElementById(id);let preparedSubject=null,subjectGeneration=0;
subjectUI('source').onchange=async event=>{
 const file=event.target.files[0];if(!file)return;const generation=++subjectGeneration;preparedSubject=null;subjectUI('save').disabled=true;subjectUI('preview').replaceChildren();subjectUI('warnings').replaceChildren();
 try{
  if(file.size>24*1024*1024)throw Error('素材文件过大');
  const bytes=new Uint8Array(await file.arrayBuffer());if(bytes.slice(0,8).join(',')!=='137,80,78,71,13,10,26,10')throw Error('请选择真实 PNG 文件');
  if(bytes.length<24)throw Error('PNG 文件不完整');const header=new DataView(bytes.buffer),headerW=header.getUint32(16),headerH=header.getUint32(20);if(headerW<4||headerH<4||headerW*headerH>4194304)throw Error('素材尺寸无效或超过 4MP');
  if(Math.max(headerW,headerH)>1024)throw Error('请先等比缩到长边 1024px 的透明 PNG，并保留高清原件');
  const url=URL.createObjectURL(file),image=new Image();
  try{await new Promise((resolve,reject)=>{image.onload=resolve;image.onerror=()=>reject(Error('PNG 无法解码'));image.src=url;});}finally{URL.revokeObjectURL(url);}
  const width=image.naturalWidth,height=image.naturalHeight;if(width*height>4194304)throw Error('请先把素材准备为不超过 4MP');
  const canvas=document.createElement('canvas');canvas.width=width;canvas.height=height;const context=canvas.getContext('2d',{willReadFrequently:true});context.drawImage(image,0,0);
  const analysis=FridgeSubjectAuthoring.analyzeRGBA(context.getImageData(0,0,width,height).data,width,height);
  const dataURL=await new Promise((resolve,reject)=>{const reader=new FileReader();reader.onload=()=>resolve(reader.result);reader.onerror=reject;reader.readAsDataURL(file);});
  if(generation!==subjectGeneration)return;
  const hash=Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256',bytes)),b=>b.toString(16).padStart(2,'0')).join('');
  if(generation!==subjectGeneration)return;
  preparedSubject={toolVersion:1,sourceFingerprint:FridgeCore.sourceFingerprint,source:{name:file.name,width,height,sha256:hash},asset:{key:'asset://0',extension:'.png',data:dataURL.split(',')[1]},cardFields:{shape:'subject',cutout:'asset://0',subjectPhoto:true,subjectBorder:true,subjectAspect:analysis.subjectAspect,outline:analysis.outline},analysis:{...analysis,outline:undefined}};
  const path=FridgeCore.load('ContourPath').contourPath(analysis.outline,width,height,1);
  // Source URL is produced by FileReader, never user-authored SVG or HTML.
  subjectUI('preview').innerHTML=`<svg xmlns="http://www.w3.org/2000/svg" width="${Math.min(420,width)}" viewBox="0 0 ${width} ${height}"><image href="${dataURL}" width="${width}" height="${height}"/><path d="${path}" fill="none" stroke="#B83239" stroke-width="${Math.max(width,height)/300}"/></svg>`;
  subjectUI('status').textContent=`${width} × ${height} · ${analysis.loops} 个轮廓 · ${analysis.points} 个点`;subjectUI('warnings').replaceChildren(...analysis.warnings.map(message=>{const li=document.createElement('li');li.textContent=message;return li;}));subjectUI('save').disabled=false;
 }catch(error){if(generation===subjectGeneration){subjectUI('status').textContent='无法使用：'+error.message;}}
};
subjectUI('save').onclick=()=>{if(!preparedSubject)return;const url=URL.createObjectURL(new Blob([JSON.stringify(preparedSubject)],{type:'application/json'})),link=document.createElement('a');link.href=url;link.download='fridge-subject.json';link.click();setTimeout(()=>URL.revokeObjectURL(url),1000);};
