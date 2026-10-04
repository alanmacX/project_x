/** Geometry-only beautification. The native recognizer is kept separate from this deterministic path. */
export interface SketchPoint { x:number; y:number; }
export interface SketchCurve { start:SketchPoint; segments:SketchSegment[]; closed:boolean; anchors:SketchPoint[]; }
export interface SketchSegment { c1:SketchPoint; c2:SketchPoint; end:SketchPoint; }
export function sketchDistance(a:SketchPoint,b:SketchPoint):number {return Math.hypot(a.x-b.x,a.y-b.y);}
function copy(p:SketchPoint):SketchPoint {return {x:p.x,y:p.y};}
function mix(a:SketchPoint,b:SketchPoint,t:number):SketchPoint {return {x:a.x+(b.x-a.x)*t,y:a.y+(b.y-a.y)*t};}
function lineDistance(p:SketchPoint,a:SketchPoint,b:SketchPoint):number {
  const dx=b.x-a.x,dy=b.y-a.y,s=dx*dx+dy*dy;
  return sketchDistance(p,mix(a,b,s===0?0:Math.max(0,Math.min(1,((p.x-a.x)*dx+(p.y-a.y)*dy)/s))));
}
/** Iterative RDP avoids recursion on long stylus strokes. Endpoints are exact. */
function simplify(points:SketchPoint[],tolerance:number):SketchPoint[] {
  if(points.length<3)return points.map(copy);
  const keep:boolean[]=points.map(()=>false),stack:number[][]=[[0,points.length-1]];
  keep[0]=true;keep[points.length-1]=true;
  while(stack.length>0) {
    const span=stack.pop()!,a=span[0],b=span[1];let best=tolerance,index=-1;
    for(let i=a+1;i<b;i++) {const d=lineDistance(points[i],points[a],points[b]);if(d>best){best=d;index=i;}}
    if(index>=0){keep[index]=true;stack.push([a,index],[index,b]);}
  }
  return points.filter((_p,i)=>keep[i]);
}
/** Uniform arc samples make smoothing independent of writing speed; bounded to 512 samples. */
function resample(points:SketchPoint[],closed:boolean):SketchPoint[] {
  if(points.length<3)return points.map(copy);
  const source=points.map(copy);if(closed)source.push(copy(source[0]));
  let length=0;for(let i=1;i<source.length;i++)length+=sketchDistance(source[i-1],source[i]);
  const step=Math.max(2,length/510),out:SketchPoint[]=[copy(source[0])];let carry=0;
  for(let i=1;i<source.length;i++) {
    const a=source[i-1],b=source[i],d=sketchDistance(a,b);if(d===0)continue;
    let at=step-carry;
    while(at<=d && out.length<511){out.push(mix(a,b,at/d));at+=step;}
    carry=d-(at-step);
  }
  if(!closed && sketchDistance(out[out.length-1],source[source.length-1])>.01)out.push(copy(source[source.length-1]));
  if(closed && out.length>2 && sketchDistance(out[out.length-1],out[0])<step*.5)out.pop();
  return out;
}
function tangent(points:SketchPoint[],i:number,closed:boolean):SketchPoint {
  const p=points[i],prev=points[i===0?(closed?points.length-1:0):i-1],next=points[i===points.length-1?(closed?0:i):i+1];
  const a=sketchDistance(prev,p),b=sketchDistance(p,next);
  if(a===0||b===0)return {x:0,y:0};
  const turn=((p.x-prev.x)*(next.x-p.x)+(p.y-prev.y)*(next.y-p.y))/(a*b);
  // Intentional corners remain corners, rather than rounding triangles into blobs.
  if(turn<.1)return {x:0,y:0};
  const dx=next.x-prev.x,dy=next.y-prev.y,d=Math.hypot(dx,dy),size=Math.min(a,b)/3;
  return d>0?{x:dx/d*size,y:dy/d*size}:{x:0,y:0};
}
export function beautifyContour(raw:SketchPoint[]):SketchCurve {
  const clean:SketchPoint[]=[];
  raw.forEach((p)=>{if(Number.isFinite(p.x)&&Number.isFinite(p.y)&&(clean.length===0||sketchDistance(clean[clean.length-1],p)>.15))clean.push(copy(p));});
  if(clean.length===0)return {start:{x:0,y:0},segments:[],closed:false,anchors:[]};
  const xs=clean.map((p)=>p.x),ys=clean.map((p)=>p.y),diagonal=Math.hypot(Math.max(...xs)-Math.min(...xs),Math.max(...ys)-Math.min(...ys));
  let length=0;for(let i=1;i<clean.length;i++)length+=sketchDistance(clean[i-1],clean[i]);
  const closed=clean.length>8 && diagonal>12 && length>diagonal*2 && sketchDistance(clean[0],clean[clean.length-1])<Math.max(8,Math.min(18,diagonal*.045));
  if(closed && sketchDistance(clean[0],clean[clean.length-1])<1)clean.pop();
  const samples=resample(clean,closed),tolerance=Math.max(.8,Math.min(2.4,diagonal*.006));
  // A single small local filter removes tremor without shrinking the entire silhouette.
  const filtered=samples.map((p,i):SketchPoint=>{
    if(!closed&&(i===0||i===samples.length-1))return copy(p);
    const weights:number[]=[1,8,28,56,70,56,28,8,1];
    const candidate:SketchPoint={x:0,y:0};
    weights.forEach((weight,j)=>{const index=closed?(i+j-4+samples.length)%samples.length:Math.max(0,Math.min(samples.length-1,i+j-4));candidate.x+=samples[index].x*weight/256;candidate.y+=samples[index].y*weight/256;});
    const d=sketchDistance(p,candidate),limit=Math.max(1.5,Math.min(4,diagonal*.009));
    return d>limit?mix(p,candidate,limit/d):candidate;
  });
  let anchors:SketchPoint[];
  if(closed && filtered.length>3) {
    let far=1;for(let i=2;i<filtered.length;i++)if(sketchDistance(filtered[0],filtered[i])>sketchDistance(filtered[0],filtered[far]))far=i;
    const a=simplify(filtered.slice(0,far+1),tolerance),b=simplify(filtered.slice(far).concat([filtered[0]]),tolerance);
    anchors=a.slice(0,-1).concat(b.slice(0,-1));
  } else anchors=simplify(filtered,tolerance);
  const segments:SketchSegment[]=[];
  for(let i=0;i<(closed?anchors.length:anchors.length-1);i++) {
    const j=(i+1)%anchors.length,a=anchors[i],b=anchors[j],ta=tangent(anchors,i,closed),tb=tangent(anchors,j,closed);
    segments.push({c1:{x:a.x+ta.x,y:a.y+ta.y},c2:{x:b.x-tb.x,y:b.y-tb.y},end:copy(b)});
  }
  return {start:copy(anchors[0]??clean[0]),segments:segments,closed:closed,anchors:anchors};
}
/** Retained cubic vector data: export/share can reuse it without running recognition again. */
export function contourSvgPath(curve:SketchCurve):string {
  if(curve.anchors.length===0)return '';
  const n=(v:number):string=>Number(v.toFixed(3)).toString();
  return 'M '+n(curve.start.x)+' '+n(curve.start.y)+curve.segments.map((s)=>' C '+n(s.c1.x)+' '+n(s.c1.y)+' '+n(s.c2.x)+' '+n(s.c2.y)+' '+n(s.end.x)+' '+n(s.end.y)).join('')+(curve.closed?' Z':'');
}
export function roughSketchSample(kind:string,width:number,height:number):SketchPoint[] {
  const points:SketchPoint[]=[],cx=width/2,cy=height/2,r=Math.min(width,height)*.3;
  for(let i=0;i<=200;i++) {
    const a=i/200*Math.PI*2,wobble=1+.016*Math.sin(i*1.77)+.011*Math.cos(i*.83);
    const radius=kind==='leaf'?r*(1+.18*Math.cos(3*a)-.1*Math.sin(2*a)):r;
    points.push({x:cx+Math.cos(a)*radius*wobble,y:cy+Math.sin(a)*radius*(kind==='leaf'?1.12:.82)*wobble});
  }
  return points;
}
