import { cardTemplateScene, TemplateMark } from './TemplateScene';
import { FridgeCard, CanvasElement, materialColors, BOARD_W, BOARD_H, RECT_CORNER_RADIUS, ALBUM_CARD_CORNER_RADIUS } from './CardSchema';
import { BackgroundAnchor } from './CardSchema';
import { colorLab, representativeSwatches } from './BackgroundPalette';

export interface ColorRaster { width:number; height:number; rgba:Uint8Array; }
/** Small, detached artwork raster. Never reads back a live ArkUI/HDS surface. */
export function cardColorRaster(card:FridgeCard, images:Map<string,ColorRaster>, size:number=48, canvasAspect:number=0):ColorRaster {
  const width=size,height=Math.max(12,Math.min(96,Math.round(size*card.h/Math.max(1,card.w))));
  const rgba=new Uint8Array(width*height*4),paper=rgb(materialColors(card.material,card.paper)[0]);
  const subject=card.shape==='subject',mask=images.get(card.cutout),album=card.capability?.k==='album'?images.get(card.capability.albumCover??''):undefined;
  const template=card.template?cardTemplateScene(card,Date.now()):undefined,marks=template?.marks.filter(m=>['rect','circle','arc','image'].includes(m.kind))??[];
  const elements=card.elements.filter((el:CanvasElement)=>el.kind==='image'||el.kind==='shape');
  // Match the two image/shape stacks surrounding the capability foreground.
  const layers=elements.filter((el:CanvasElement)=>el.behindCapability).concat(elements.filter((el:CanvasElement)=>!el.behindCapability));
  for(let y=0;y<height;y++)for(let x=0;x<width;x++){
    const u=(x+.5)/width,v=(y+.5)/height,i=(y*width+x)*4;
    if(canvasAspect>0){
      const angle=card.rot*Math.PI/180,worldX=card.x/BOARD_W+u*card.w/BOARD_W*Math.cos(angle)+(1-v)*card.h/BOARD_W*Math.sin(angle);
      const worldY=card.y/BOARD_H+card.h/BOARD_W*canvasAspect+u*card.w/BOARD_W*canvasAspect*Math.sin(angle)-(1-v)*card.h/BOARD_W*canvasAspect*Math.cos(angle);
      if(worldX<0||worldX>1||worldY<0||worldY>1)continue;
    }
    if(card.shape==='round'&&((u-.5)**2+(v-.5)**2)*4>1)continue;
    if(!subject&&card.shape!=='round'&&card.shape!=='pill'){
      const radius=Math.min(card.w/2,card.h/2,card.capability?.k==='album'?ALBUM_CARD_CORNER_RADIUS:RECT_CORNER_RADIUS);
      const px=u*card.w,py=v*card.h,dx=Math.max(radius-px,0,px-(card.w-radius)),dy=Math.max(radius-py,0,py-(card.h-radius));
      if(dx*dx+dy*dy>radius*radius)continue;
    }
    if(card.shape==='pill'){
      const radius=Math.min(card.w,card.h)/2,px=u*card.w,py=v*card.h;
      const dx=Math.max(radius-px,0,px-(card.w-radius)),dy=Math.max(radius-py,0,py-(card.h-radius));
      if(dx*dx+dy*dy>radius*radius)continue;
    }
    let out=template?templatePixel(card,marks,images,u,v,rgb(template.background)):paper.slice();
    if(template){rgba.set(out.map((n:number)=>Math.round(n)),i);continue;}
    if(subject&&card.subjectPhoto&&mask!==undefined)out=layers.length===0?sample(mask,u,v,card.w/card.h,false):over(out,sample(mask,u,v,card.w/card.h,false),1);
    if(album!==undefined)out=over(out,sample(album,u,v,card.w/card.h,true),1);
    for(const el of layers){
      const angle=-el.rot*Math.PI/180,dx=(u-el.x-el.w/2)*card.w,dy=(v-el.y-el.h/2)*card.h;
      const ex=(dx*Math.cos(angle)-dy*Math.sin(angle))/(el.w*card.w)+.5,ey=(dx*Math.sin(angle)+dy*Math.cos(angle))/(el.h*card.h)+.5;
      if(ex<0||ex>=1||ey<0||ey>=1)continue;
      if(el.kind==='image'){
        const source=images.get(el.src);if(source!==undefined)out=over(out,sample(source,ex,ey,el.w*card.w/(el.h*card.h),true),el.opacity);
      }else{
        if(el.primitive==='circle'&&((ex-.5)**2+(ey-.5)**2)*4>1)continue;
        if(el.primitive==='line'&&ey*el.h*card.h>3)continue;
        out=over(out,rgb(el.color||materialColors(card.material,card.paper,card.ink)[1]),el.opacity);
      }
    }
    if(subject){if(mask===undefined)continue;if(!card.subjectPhoto||layers.length>0)out[3]*=sample(mask,u,v,card.w/card.h,false)[3]/255;}
    rgba.set(out.map((n:number)=>Math.round(n)),i);
  }
  return {width:width,height:height,rgba:rgba};
}
function rgb(hex:string):number[]{return [parseInt(hex.slice(1,3),16),parseInt(hex.slice(3,5),16),parseInt(hex.slice(5,7),16),255];}
function over(base:number[],top:number[],opacity:number):number[]{
  const a=top[3]/255*Math.max(0,Math.min(1,opacity)),b=base[3]/255*(1-a),total=a+b;
  return total>0?[(top[0]*a+base[0]*b)/total,(top[1]*a+base[1]*b)/total,(top[2]*a+base[2]*b)/total,total*255]:[0,0,0,0];
}
function sample(source:ColorRaster,u:number,v:number,aspect:number,cover:boolean):number[]{
  if(cover){const ratio=source.width/source.height;if(ratio>aspect)u=.5+(u-.5)*aspect/ratio;else v=.5+(v-.5)*ratio/aspect;}
  const x=Math.max(0,Math.min(source.width-1,Math.floor(u*source.width))),y=Math.max(0,Math.min(source.height-1,Math.floor(v*source.height))),i=(y*source.width+x)*4;
  return [source.rgba[i],source.rgba[i+1],source.rgba[i+2],source.rgba[i+3]];
}
/** Up to six perceptual hues with actual visible area and measured centroids.
 * Alpha is area, not a chroma boost: a tiny saturated accent cannot outweigh paper. */
export function cardColorDistribution(raster:ColorRaster,minArea:number=.005):BackgroundAnchor[]{
  if(!raster.rgba.some((value:number,i:number)=>i%4===3&&value>0))return [];
  const palette=representativeSwatches(raster.rgba,false,6,true),labs=palette.map(p=>colorLab(p.color));
  const fields=palette.map(p=>({x:0,y:0,color:p.color,weight:0} as BackgroundAnchor));
  for(let y=0;y<raster.height;y++)for(let x=0;x<raster.width;x++){
    const i=(y*raster.width+x)*4,alpha=raster.rgba[i+3]/255;if(alpha<.1)continue;
    const hex='#'+Array.from(raster.rgba.subarray(i,i+3)).map((v:number)=>v.toString(16).padStart(2,'0')).join(''),lab=colorLab(hex);
    let at=0,best=Infinity;for(let k=0;k<labs.length;k++){const d=(lab.l-labs[k].l)**2+(lab.a-labs[k].a)**2+(lab.b-labs[k].b)**2;if(d<best){best=d;at=k;}}
    const p=fields[at];p.weight+=alpha;p.x+=(x+.5)/raster.width*alpha;p.y+=(y+.5)/raster.height*alpha;
  }
  const total=raster.width*raster.height;
  return fields.filter(p=>p.weight/total>=minArea).map(p=>({x:p.x/p.weight,y:p.y/p.weight,color:p.color,weight:p.weight/total} as BackgroundAnchor));
}

/** Measure only artwork visible after other cards cover it. The canvas grid bounds
 * memory/work, and alpha transmittance keeps translucent foregrounds honest. */
export function visibleCanvasColors(cards:FridgeCard[],rasters:ColorRaster[],aspect:number):BackgroundAnchor[]{
  const width=96,height=Math.max(32,Math.min(160,Math.round(width/aspect))),covered=new Float32Array(width*height);
  const order=cards.map((card:FridgeCard,i:number)=>i).sort((a:number,b:number)=>cards[b].z-cards[a].z||b-a);
  const anchors:BackgroundAnchor[]=[];
  for(const at of order){
    const card=cards[at],source=rasters[at],rgba=new Uint8Array(width*height*4),angle=card.rot*Math.PI/180,cos=Math.cos(angle),sin=Math.sin(angle);
    for(let y=0;y<height;y++)for(let x=0;x<width;x++){
      const index=y*width+x;if(covered[index]>.999)continue;
      const dx=((x+.5)/width-card.x/BOARD_W)*BOARD_W,dy=((y+.5)/height-card.y/BOARD_H)*BOARD_W/aspect-card.h;
      const u=(dx*cos+dy*sin)/card.w,v=1-(dx*sin-dy*cos)/card.h;
      if(u<0||u>=1||v<0||v>=1)continue;
      const color=sample(source,u,v,card.w/card.h,false),alpha=color[3]/255,visible=alpha*(1-covered[index]);
      rgba.set([color[0],color[1],color[2],Math.round(visible*255)],index*4);
      covered[index]+=visible;
    }
    anchors.push(...cardColorDistribution({width:width,height:height,rgba:rgba},.0005));
  }
  return anchors;
}

/** Coarse artwork coverage for placing fluid colour clouds in exposed space. */
export function canvasArtworkCoverage(cards:FridgeCard[],rasters:ColorRaster[],aspect:number,columns:number,rows:number):number[]{
  const coverage:number[]=new Array<number>(columns*rows).fill(0);
  for(let at=0;at<cards.length;at++){
    const card=cards[at],angle=card.rot*Math.PI/180,cos=Math.cos(angle),sin=Math.sin(angle);
    for(let y=0;y<rows;y++)for(let x=0;x<columns;x++){
      const dx=((x+.5)/columns-card.x/BOARD_W)*BOARD_W,dy=((y+.5)/rows-card.y/BOARD_H)*BOARD_W/aspect-card.h;
      const u=(dx*cos+dy*sin)/card.w,v=1-(dx*sin-dy*cos)/card.h;
      if(u<0||u>=1||v<0||v>=1)continue;
      const index=y*columns+x,alpha=sample(rasters[at],u,v,card.w/card.h,false)[3]/255;
      coverage[index]+=alpha*(1-coverage[index]);
    }
  }
  return coverage;
}

/** Sample shared template geometry off-thread; no UI snapshots or full-size bitmap allocation. */
function templatePixel(card:FridgeCard,marks:TemplateMark[],images:Map<string,ColorRaster>,u:number,v:number,base:number[]):number[]{
  const edge=Math.min(card.w,card.h),x=(u*card.w-(card.w-edge)/2)/edge*300,y=(v*card.h-(card.h-edge)/2)/edge*300;
  let out=base;
  for(const m of marks){
    const a=-m.angle*Math.PI/180,dx=x-m.x-m.w/2,dy=y-m.y-m.h/2,px=dx*Math.cos(a)-dy*Math.sin(a)+m.w/2,py=dx*Math.sin(a)+dy*Math.cos(a)+m.h/2;
    if(m.kind==='arc'){
      const distance=Math.hypot(x-m.x,y-m.y);if(Math.abs(distance-m.r)>m.stroke/2)continue;
      const angle=(Math.atan2(y-m.y,x-m.x)*180/Math.PI-m.start+720)%360;if(angle>m.sweep)continue;out=over(out,rgb(m.color),m.opacity);continue;
    }
    if(px<0||py<0||px>m.w||py>m.h)continue;
    if(m.kind==='image'){const source=images.get(m.src);if(source)out=over(out,sample(source,px/m.w,py/m.h,m.w/m.h,true),m.opacity);continue;}
    if(m.kind==='circle'&&((px/m.w-.5)**2+(py/m.h-.5)**2)*4>1)continue;
    if(m.kind==='rect'){
      const r=Math.min(m.r,m.w/2,m.h/2),cx=Math.max(r-px,0,px-(m.w-r)),cy=Math.max(r-py,0,py-(m.h-r));if(cx*cx+cy*cy>r*r)continue;
      if(m.stroke&&px>m.stroke&&py>m.stroke&&px<m.w-m.stroke&&py<m.h-m.stroke)continue;
    }
    let color=rgb(m.color);if(m.end){const end=rgb(m.end),q=Math.max(0,Math.min(1,(px/m.w+py/m.h)/2));color=color.map((c:number,i:number)=>i===3?255:c+(end[i]-c)*q);}
    out=over(out,color,m.opacity);
  }return out;
}
