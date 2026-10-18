import { BackgroundAnchor } from './CardSchema';
import { colorLab, combineColors, LabColor } from './BackgroundPalette';

function chroma(lab:LabColor):number {return Math.hypot(lab.a,lab.b);}
function colourDistance(a:LabColor,b:LabColor):number {return Math.hypot(a.a-b.a,a.b-b.b);}
/** Reserve space for different chromatic families, rather than several shades of
 * brown. Keep the selected source colour intact: averaging would erase accents. */
export function canvasColourFamilies(points:BackgroundAnchor[],limit:number=6):BackgroundAnchor[]{
  const source=points.filter((p:BackgroundAnchor)=>p.weight>0).slice().sort((a:BackgroundAnchor,b:BackgroundAnchor)=>b.weight-a.weight||a.color.localeCompare(b.color));
  const total=source.reduce((sum:number,p:BackgroundAnchor)=>sum+p.weight,0);
  const coloured=source.filter((p:BackgroundAnchor)=>chroma(colorLab(p.color))>=16&&p.weight/Math.max(total,1e-12)>=.0012);
  const neutral=source.filter((p:BackgroundAnchor)=>!coloured.includes(p));
  if(coloured.length===0)return source.length>0?[aggregate(source,combineColors(source))]:[];
  const labs=coloured.map((p:BackgroundAnchor)=>colorLab(p.color)),chosen:number[]=[0];
  const budget=Math.max(1,limit-(neutral.length>0?1:0));
  while(chosen.length<Math.min(budget,coloured.length)){
    let best=-1,score=0;
    for(let i=0;i<coloured.length;i++){
      if(chosen.includes(i))continue;
      const separation=Math.min(...chosen.map((j:number)=>colourDistance(labs[i],labs[j])));
      if(separation<22)continue;
      const value=separation*Math.pow(coloured[i].weight/Math.max(total,1e-12),.15);
      if(value>score){score=value;best=i;}
    }
    if(best<0)break;chosen.push(best);
  }
  const groups:BackgroundAnchor[][]=chosen.map(()=>[] as BackgroundAnchor[]);
  for(let i=0;i<coloured.length;i++){
    let at=0,best=Infinity;
    for(let k=0;k<chosen.length;k++){const d=colourDistance(labs[i],labs[chosen[k]]);if(d<best){best=d;at=k;}}
    groups[at].push(coloured[i]);
  }
  const result=groups.map((group:BackgroundAnchor[],i:number)=>aggregate(group,coloured[chosen[i]].color));
  if(neutral.length>0)result.push(aggregate(neutral,combineColors(neutral)));
  return result.sort((a:BackgroundAnchor,b:BackgroundAnchor)=>b.weight-a.weight||a.color.localeCompare(b.color));
}
function aggregate(points:BackgroundAnchor[],colour:string):BackgroundAnchor {
  const weight=points.reduce((sum:number,p:BackgroundAnchor)=>sum+p.weight,0);
  return {color:colour,weight:weight,x:points.reduce((sum:number,p:BackgroundAnchor)=>sum+p.x*p.weight,0)/weight,y:points.reduce((sum:number,p:BackgroundAnchor)=>sum+p.y*p.weight,0)/weight};
}
/** Place colours in visible negative space, retaining a loose relationship to
 * their source. Repulsion gives minority colours their own part of the canvas. */
export function canvasFluidLayout(fields:BackgroundAnchor[],coverage:number[],columns:number,rows:number):BackgroundAnchor[]{
  const sorted=fields.slice().sort((a:BackgroundAnchor,b:BackgroundAnchor)=>b.weight-a.weight||a.color.localeCompare(b.color));
  const coloured=sorted.filter((p:BackgroundAnchor)=>chroma(colorLab(p.color))>=16),ordered:BackgroundAnchor[]=[];
  if(coloured.length>0)ordered.push(coloured[0]);
  while(ordered.length<coloured.length){
    let best:BackgroundAnchor=coloured[0],score=-1;
    for(const p of coloured){
      if(ordered.includes(p))continue;
      const separation=Math.min(...ordered.map((other:BackgroundAnchor)=>colourDistance(colorLab(p.color),colorLab(other.color))));
      const value=separation*Math.pow(p.weight,.15);if(value>score){score=value;best=p;}
    }
    ordered.push(best);
  }
  ordered.push(...sorted.filter((p:BackgroundAnchor)=>!coloured.includes(p)));
  const result:BackgroundAnchor[]=[];
  for(const field of ordered){
    let best=-Infinity,bx=field.x,by=field.y;
    for(let y=0;y<rows;y++)for(let x=0;x<columns;x++){
      const nx=(x+.5)/columns,ny=(y+.5)/rows;
      if(nx<.06||nx>.94||ny<.06||ny>.94)continue;
      let free=0,count=0;
      for(let dy=-2;dy<=2;dy++)for(let dx=-2;dx<=2;dx++){
        const px=x+dx,py=y+dy;if(px<0||px>=columns||py<0||py>=rows)continue;
        free+=1-coverage[py*columns+px];count++;
      }
      const separation=result.length>0?Math.min(...result.map((p:BackgroundAnchor)=>Math.hypot(nx-p.x,ny-p.y))):.5;
      const score=free/Math.max(1,count)*1.8+Math.min(.65,separation)*.9-Math.hypot(nx-field.x,ny-field.y)*.22;
      if(score>best){best=score;bx=nx;by=ny;}
    }
    result.push({x:bx,y:by,color:field.color,weight:field.weight});
  }
  return result;
}
