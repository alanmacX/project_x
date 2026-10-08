/* Offline UI. User files remain data, not executable HTML or JavaScript. */
'use strict';
const $=id=>document.getElementById(id);
let pack=null,output=null,album={cover:'',background:'',title:'专辑名称',artist:'歌手名'};
let report=null,loadGeneration=0;
function showError(error){output=null;$('artwork').replaceChildren();$('status').textContent='无法预览：'+error.message;$('export').disabled=true;$('report').disabled=false;report={status:'error',message:error.message};}
function render(){
 if(!pack)return;
 try{
  const tick=new Date($('tick').value).getTime();if(!Number.isFinite(tick))throw Error('数据时间无效');
  output=FridgeWeb.renderPackage(pack,Number($('size').value),tick);$('artwork').innerHTML=output.svg;
  $('issues').replaceChildren(...output.issues.map(message=>{const li=document.createElement('li');li.textContent=message;return li;}));
  report={previewVersion:2,adapter:'browser-svg-v2',sourceFingerprint:FridgeCore.sourceFingerprint,designContract:{contractVersion:FridgeDesignContract.contractVersion,skillContractVersion:FridgeDesignContract.skillContractVersion,identity:FridgeDesignContract.identity,appVersion:FridgeDesignContract.app.versionName},packageVersion:pack.version,schemaVersion:pack.state.schemaVersion,width:output.width,height:output.height,tick,timeZone:Intl.DateTimeFormat().resolvedOptions().timeZone,cards:pack.state.cards.length,status:output.issues.length?'unsupported':'ready-for-review',issues:output.issues,actualFormVerified:false,pixelParityVerified:false};
  $('status').textContent=output.issues.length?'文件已读取，存在未支持能力，不能验收通过':'文件已读取，可以导出对照图';$('export').disabled=false;$('report').disabled=false;
 }catch(error){showError(error);}
}
function study(){
 const value=$('content').value;
 const sample={...album,title:value==='empty'?'':value==='long'?'A Very Long Album Name · 很长的专辑名称测试':album.title,artist:value==='empty'?'':value==='long'?'多位歌手与合作音乐人 / Featured Artists':album.artist};
 const options=[['cover','A · 现有纯封面','保持已批准的 4.9% 留边'],['classic','B · 经典信息款','左上封面，名称与歌手在下方'],['row','D · 并排紧凑款','适合横向卡片']];
 $('albums').replaceChildren(...options.map(([style,label,note],i)=>{
  const el=document.createElement('article');el.className='sample';const art=document.createElement('div');art.className='image';
  art.innerHTML=FridgeWeb.albumSVG(sample,style==='row'?300:180,style==='row'?150:180,style,'study'+i);
  const title=document.createElement('strong');title.textContent=label;const p=document.createElement('p');p.textContent=note;el.append(art,title,p);return el;
 }));
}
function tab(which){$('scenePane').hidden=which!=='scene';$('albumPane').hidden=which!=='album';$('sceneTab').setAttribute('aria-pressed',which==='scene');$('albumTab').setAttribute('aria-pressed',which==='album');}
async function loadText(json){
 const generation=++loadGeneration;pack=null;output=null;report=null;$('artwork').replaceChildren();$('issues').replaceChildren();$('export').disabled=true;$('report').disabled=true;
 try{
 if(json.length>90*1024*1024)throw Error('作品包超过大小限制');
 // Do not silently normalize a future capability into an older one.
 const raw=JSON.parse(json),supported=FridgeCore.load('CardSchema').CAPABILITIES;
 for(const c of raw.state?.cards||[])if(c.capability&&!supported.includes(c.capability.k))throw Error('未知能力 '+c.capability.k+'，请更新预览器');
 const next=FridgeCore.load('TemplatePackage').readPackage(json);
 $('status').textContent='正在解码本地素材…';next.assetDimensions={};
 await Promise.all(next.assets.map(a=>new Promise((resolve,reject)=>{const img=new Image();img.onload=()=>{next.assetDimensions[a.key]={width:img.naturalWidth,height:img.naturalHeight};resolve();};img.onerror=()=>reject(Error('素材无法解码：'+a.key));img.src='data:image/'+(a.extension==='.jpg'||a.extension==='.jpeg'?'jpeg':a.extension.slice(1))+';base64,'+a.data;})));
 if(generation!==loadGeneration)return null;pack=next;
 const cap=pack.state.cards.find(c=>c.capability?.k==='album')?.capability;
 if(cap){const active=FridgeCore.load('AlbumRotation').activeAlbum(cap,new Date($('tick').value).getTime()),map=new Map(pack.assets.map(a=>[a.key,'data:image/'+(a.extension==='.jpg'||a.extension==='.jpeg'?'jpeg':a.extension.slice(1))+';base64,'+a.data]));album={...active,cover:map.get(active.cover)||'',background:map.get(active.background)||''};study();}
 render();await readyImages();if(generation!==loadGeneration)return null;return report;
 }catch(error){if(generation===loadGeneration)showError(error);throw error;}
}
async function readyImages(){
 const images=[...document.querySelectorAll('svg image')];
 await Promise.all(images.map(el=>new Promise((resolve,reject)=>{const img=new Image();img.onload=()=>resolve();img.onerror=()=>reject(Error('作品图片无法解码'));img.src=el.getAttribute('href');})));
 await document.fonts.ready;
}
function download(blob,name){const link=document.createElement('a'),url=URL.createObjectURL(blob);link.href=url;link.download=name;link.click();setTimeout(()=>URL.revokeObjectURL(url),1000);}
async function capture(){
 if(!output)throw Error('尚未读取作品');const snapshot=output;await readyImages();if(output!==snapshot)throw Error('作品已更换，请重新导出');
 const url=URL.createObjectURL(new Blob([snapshot.svg],{type:'image/svg+xml'}));
 try{const img=new Image();await new Promise((resolve,reject)=>{img.onload=resolve;img.onerror=reject;img.src=url;});const canvas=document.createElement('canvas');canvas.width=snapshot.width*2;canvas.height=snapshot.height*2;canvas.getContext('2d').drawImage(img,0,0,canvas.width,canvas.height);return await new Promise(resolve=>canvas.toBlob(resolve,'image/png'));}finally{URL.revokeObjectURL(url);}
}
window.FridgeHarness={loadText,capture,getReport:()=>structuredClone(report),getDesignContract:()=>structuredClone(FridgeDesignContract),getCardMetrics:()=>{if(!pack)throw Error('尚未读取作品');return structuredClone(pack.state.cards.map(FridgeReadouts.inspectCard));},getLayers:()=>{if(!output)throw Error('尚未读取作品');return structuredClone({width:output.width,height:output.height,issues:output.issues,...output.layers});},setSize:(size)=>{if(![180,300,420].includes(size))throw Error('Unsupported size');$('size').value=String(size);render();},showAlbums:()=>tab('album')};
$('file').onchange=async event=>{try{const file=event.target.files[0];if(!file)return;await loadText(await file.text());tab('scene');}catch(error){/* loadText owns errors and ignores stale imports. */}};
for(const id of ['size','tick'])$(id).onchange=render;
$('content').onchange=study;$('sceneTab').onclick=()=>tab('scene');$('albumTab').onclick=()=>tab('album');
for(const name of ['cover','background'])$(name).onchange=async event=>{
 try{const file=event.target.files[0];if(!file)return;if(file.size>24*1024*1024)throw Error('图片过大');const data=await new Promise((resolve,reject)=>{const reader=new FileReader();reader.onload=()=>resolve(reader.result);reader.onerror=reject;reader.readAsDataURL(file);});const bitmap=await createImageBitmap(file);try{if(name==='cover'&&!FridgeCore.load('AlbumLayout').isSquareAlbumCover(bitmap.width,bitmap.height))throw Error('专辑封面必须是正方形');}finally{bitmap.close();}album[name]=data;study();}catch(error){showError(error);}
};
$('export').onclick=async()=>{try{download(await capture(),'fridge-preview.png');}catch(error){showError(error);}};
$('report').onclick=()=>download(new Blob([JSON.stringify(report,null,2)],{type:'application/json'}),'fridge-preview.json');
$('contract').textContent='共享模型 '+FridgeCore.sourceFingerprint.slice(0,12)+' · 全部现有能力、主体蒙版与衬底已接入 · 字体仍需原生对照 · 不联网';study();
