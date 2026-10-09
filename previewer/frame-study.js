/* Design-only CPU rasterizer: baked silhouette + cross-section normals + deterministic grain.
 * No generated frame PNG, no runtime WebGL dependency, no frame loop at rest.
 * This is an experimental shading model, not a measured PBR stone or Three.js port. */
(() => {
'use strict';
const defaults={material:'stone',wall:'dark',ratio:1.15,width:28,depth:8,grain:30,bevel:28,square:false,content:true};
let state={...defaults},scheduled=0;
const canvas=document.querySelector('#frame'),board=document.querySelector('#board'),ctx=canvas.getContext('2d');
const clamp=(x,a=0,b=1)=>Math.max(a,Math.min(b,x)),mix=(a,b,t)=>a+(b-a)*t;
const smooth=x=>{x=clamp(x);return x*x*(3-2*x);};
function hash(x,y){let n=Math.imul(x,374761393)+Math.imul(y,668265263);n=Math.imul(n^(n>>>13),1274126177);return ((n^(n>>>16))>>>0)/4294967295;}
function noise(x,y){const ix=Math.floor(x),iy=Math.floor(y),a=smooth(x-ix),b=smooth(y-iy);return mix(mix(hash(ix,iy),hash(ix+1,iy),a),mix(hash(ix,iy+1),hash(ix+1,iy+1),a),b);}
function sdf(x,y,w,h,r){const qx=Math.abs(x-w/2)-(w/2-r),qy=Math.abs(y-h/2)-(h/2-r);return Math.hypot(Math.max(qx,0),Math.max(qy,0))+Math.min(Math.max(qx,qy),0)-r;}
function height(d,B,D,bevel){const outside=2.4,inside=B*bevel/100;
 if(d<outside)return D*(.22+.78*Math.sin(clamp(d/outside)*Math.PI/2));
 if(d>B-inside)return D*(.18+.82*(1-smooth((d-B+inside)/inside)));
 return D;
}
function sample(x,y,w,h,B,R,D,bevel){return height(-sdf(x,y,w,h,R),B,D,bevel);}
const palette={stone:[245,244,239],walnut:[113,75,49],oak:[186,155,111]};
function texture(x,y,w,h,B){
 if(state.material==='stone'){
  const fine=noise(x*2.5,y*2.5)-.5,body=noise(x*.11,y*.11)-.5;
  return 1+(fine*.028+body*.014)*state.grain/30;
 }
 // Four mitered rails, each with longitudinal grain. Selecting nearest side
 // splits corners on the 45 degree bisector instead of wrapping grain across it.
 const vertical=Math.min(x,w-x)<Math.min(y,h-y),u=vertical?y:x,v=vertical?Math.min(x,w-x):Math.min(y,h-y);
 const drift=(noise(u*.006,v*.11)-.5)*4+(noise(u*.024,v*.12)-.5)*1.2;
 const veins=Math.sin((v+drift)*2.2)*.5+.5;
 const fiber=noise(u*.14,(v+drift)*2.8)-.5;
 const broad=noise(u*.015,v*.23)-.5;
 return 1+((veins-.5)*.13+fiber*.14+broad*.13)*state.grain/30;
}
function roundPath(context,w,h,r,inset){context.beginPath();context.roundRect(inset,inset,w-2*inset,h-2*inset,r);}
function render(){
 scheduled=0;const start=performance.now(),cssWidth=board.clientWidth,cssHeight=board.clientHeight;
 if(!cssWidth||!cssHeight)return;
 // Shade at two pixels per study unit, capped to avoid unbounded bitmap allocation.
 const dpr=Math.min(devicePixelRatio,2),W=Math.round(cssWidth*dpr),H=Math.round(cssHeight*dpr);
 canvas.width=W;canvas.height=H;
 const scale=cssWidth/600,B=state.width*scale,margin=4*scale,w=cssWidth-margin*2,h=cssHeight-margin*2;
 const R=state.square?0:Math.max(B+7*scale,31*scale),D=state.depth*scale;
 const image=ctx.createImageData(W,H),rgba=image.data,base=palette[state.material];
 const lx=-.38,ly=-.48,lz=.79;
 for(let py=0;py<H;py++)for(let px=0;px<W;px++){
  const x=(px+.5)/dpr-margin,y=(py+.5)/dpr-margin;
  const out=sdf(x,y,w,h,R),inside=sdf(x-B,y-B,w-2*B,h-2*B,Math.max(0,R-B));
  const alpha=clamp(.5-out*dpr)*clamp(.5+inside*dpr);if(alpha===0)continue;
  const d=-out,e=.22*scale;
  let nx=-(sample(x+e,y,w,h,B,R,D,state.bevel)-sample(x-e,y,w,h,B,R,D,state.bevel))/(2*e);
  let ny=-(sample(x,y+e,w,h,B,R,D,state.bevel)-sample(x,y-e,w,h,B,R,D,state.bevel))/(2*e);
  // Bump stays fine and small; no crater or cellular foam pattern.
  if(state.material==='stone'){nx+=(noise(x*2.1,y*2.1)-.5)*.045*state.grain/30;ny+=(noise(x*2.1+30,y*2.1+20)-.5)*.045*state.grain/30;}
  const norm=Math.hypot(nx,ny,1);nx/=norm;ny/=norm;const nz=1/norm;
  const diffuse=Math.max(0,nx*lx+ny*ly+nz*lz);
  const spec=Math.pow(Math.max(0,nx*-.2+ny*-.25+nz*.947),state.material==='stone'?16:28)*.045;
  const occlusion=1-.11*smooth((d-B*.79)/(B*.21));
  let shade=(.61+.45*diffuse+spec)*occlusion;
  if(state.material!=='stone'){
   const horizontal=Math.min(y,h-y),vertical=Math.min(x,w-x);
   shade*=1-.09*(1-smooth(Math.abs(horizontal-vertical)/(.65*scale)));
  }
  const grain=texture(x/scale,y/scale,w/scale,h/scale,B/scale),index=(py*W+px)*4;
  rgba[index]=clamp(base[0]*shade*grain,0,255);rgba[index+1]=clamp(base[1]*shade*grain,0,255);rgba[index+2]=clamp(base[2]*shade*grain,0,255);rgba[index+3]=Math.round(alpha*255);
 }
 // Separate static contact/cast shade; excluded from middle by the hollow stroke.
 ctx.save();ctx.scale(dpr,dpr);ctx.translate(margin,margin);
 ctx.strokeStyle='rgba(23,29,27,.16)';ctx.lineWidth=B*.72;
 ctx.shadowColor='rgba(21,28,27,.28)';ctx.shadowBlur=10*scale;ctx.shadowOffsetY=3*scale;
 roundPath(ctx,w,h,Math.max(0,R-B*.36),B*.36);ctx.stroke();ctx.restore();
 const surface=document.createElement('canvas');surface.width=W;surface.height=H;surface.getContext('2d').putImageData(image,0,0);ctx.drawImage(surface,0,0);
 document.querySelector('#status').textContent=`${W} × ${H} · 本次绘制 ${Math.round(performance.now()-start)} ms · 空闲零重绘`;
 window.FrameStudy={state:()=>({...state}),render,canvas};
}
function schedule(){if(!scheduled)scheduled=requestAnimationFrame(render);}
function update(){
 board.style.aspectRatio=state.ratio;document.querySelector('#stage').dataset.wall=state.wall;
 document.querySelector('#props').classList.toggle('hidden',!state.content);
 for(const group of document.querySelectorAll('[data-key]'))for(const button of group.querySelectorAll('button'))button.setAttribute('aria-pressed',String(String(state[group.dataset.key])===button.dataset.value));
 for(const key of ['width','depth','grain','bevel']){document.getElementById(key).value=state[key];document.getElementById(key+'Out').textContent=state[key]+(key==='grain'||key==='bevel'?'%':'');}
 document.querySelector('#square').checked=state.square;document.querySelector('#content').checked=state.content;
 const labels={stone:'致密白岩 · 细哑光',walnut:'胡桃木 · 哑光封层',oak:'浅橡木 · 自然细纹'};
 document.querySelector('#label').textContent=labels[state.material];
 document.querySelector('#materialNote').textContent=state.material==='stone'?'保留平整正面，微纹理很弱。体积来自内侧斜切和柔光，不用孔洞制造石感。':'木纹沿四根框条的长度方向排列；四角分开拼接，避免纹理横穿整个框。';
 schedule();
}
for(const group of document.querySelectorAll('[data-key]'))group.addEventListener('click',e=>{const button=e.target.closest('button');if(!button)return;state[group.dataset.key]=group.dataset.key==='ratio'?Number(button.dataset.value):button.dataset.value;update();});
for(const key of ['width','depth','grain','bevel'])document.getElementById(key).addEventListener('input',e=>{state[key]=Number(e.target.value);update();});
for(const key of ['square','content'])document.getElementById(key).addEventListener('change',e=>{state[key]=e.target.checked;update();});
document.querySelector('#reset').onclick=()=>{state={...defaults};update();};
document.querySelector('#export').onclick=async()=>{
 const text=JSON.stringify({component:'sculptural-frame',version:1,units:'600px study width; geometry scales proportionally',...state},null,2);
 try{await navigator.clipboard.writeText(text);document.querySelector('#toast').textContent='当前配方已复制';}catch{document.querySelector('#toast').textContent='复制不可用，已下载配方';const a=document.createElement('a');a.href=URL.createObjectURL(new Blob([text],{type:'application/json'}));a.download='frame-recipe.json';a.click();setTimeout(()=>URL.revokeObjectURL(a.href),1000);}
 document.querySelector('#toast').classList.add('show');setTimeout(()=>document.querySelector('#toast').classList.remove('show'),1800);
};
new ResizeObserver(schedule).observe(board);update();
})();
