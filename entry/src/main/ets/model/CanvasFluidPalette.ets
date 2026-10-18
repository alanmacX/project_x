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
  const result=groups.map((group:BackgroundAnchor[],i:number):BackgroundAnchor=>{
    const seed=coloured[chosen[i]],family=aggregate(group,seed.color);
    // The representative hue belongs where it was measured, not at the centre
    // of unrelated same-family shades on other cards.
    family.x=seed.x;family.y=seed.y;return family;
  });
  if(neutral.length>0)result.push(aggregate(neutral,combineColors(neutral)));
  return result.sort((a:BackgroundAnchor,b:BackgroundAnchor)=>b.weight-a.weight||a.color.localeCompare(b.color));
}
function aggregate(points:BackgroundAnchor[],colour:string):BackgroundAnchor {
  const weight=points.reduce((sum:number,p:BackgroundAnchor)=>sum+p.weight,0);
  return {color:colour,weight:weight,x:points.reduce((sum:number,p:BackgroundAnchor)=>sum+p.x*p.weight,0)/weight,y:points.reduce((sum:number,p:BackgroundAnchor)=>sum+p.y*p.weight,0)/weight};
}
/** Local reveal only: colours stay within 12% of the short canvas edge of their
 * measured source. Empty space on the opposite side cannot attract an accent. */
export function canvasFluidLayout(fields:BackgroundAnchor[],coverage:number[],columns:number,rows:number):BackgroundAnchor[]{
  const short=Math.min(columns,rows),sx=columns/short,sy=rows/short;
  const localFree=(nx:number,ny:number):number=>{
    const x=Math.min(columns-1,Math.max(0,Math.floor(nx*columns))),y=Math.min(rows-1,Math.max(0,Math.floor(ny*rows)));
    let free=0,count=0;
    for(let dy=-1;dy<=1;dy++)for(let dx=-1;dx<=1;dx++){
      const px=x+dx,py=y+dy;if(px<0||px>=columns||py<0||py>=rows)continue;
      free+=1-coverage[py*columns+px];count++;
    }
    return free/Math.max(1,count);
  };
  return fields.map((field:BackgroundAnchor):BackgroundAnchor=>{
    let bx=field.x,by=field.y,best=localFree(bx,by)*.65;
    for(let y=0;y<rows;y++)for(let x=0;x<columns;x++){
      const nx=(x+.5)/columns,ny=(y+.5)/rows,distance=Math.hypot((nx-field.x)*sx,(ny-field.y)*sy);
      if(distance>.12)continue;
      const score=localFree(nx,ny)*.65-distance*2.5;
      if(score>best){best=score;bx=nx;by=ny;}
    }
    return {x:bx,y:by,color:field.color,weight:field.weight};
  });
}
