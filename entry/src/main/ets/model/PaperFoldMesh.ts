export class PaperVertex {
  u=0;v=0;x=0;y=0;z=0;px=0;py=0;bx=0;by=0;bz=0;ridge=0;pleatX=0;pleatY=0;phase=0;
}
export class PaperTriangle {
  a=0;b=0;c=0;depth=0;shade=1;
  constructor(a:number,b:number,c:number){this.a=a;this.b=b;this.c=c;}
}
function smooth(value:number):number {const t=Math.max(0,Math.min(1,value));return t*t*(3-2*t);}
/** Bounded, authored deformation: 49 vertices / 72 facets, no cloth solver. */
export class PaperFoldMesh {
  readonly steps=6;
  readonly vertices:PaperVertex[]=[];
  readonly triangles:PaperTriangle[]=[];
  readonly radius:number;
  constructor(readonly width:number,readonly height:number,ballDiameter:number) {
    this.radius=Math.min(ballDiameter/2,width*.22,height*.22);
    for(let row=0;row<=this.steps;row++)for(let col=0;col<=this.steps;col++) {
      const point=new PaperVertex();point.u=col/this.steps*2-1;point.v=row/this.steps*2-1;
      const lon=point.u*Math.PI*1.32+.32*Math.sin(point.v*4),lat=point.v*1.12;
      const rough=1+.12*Math.sin(col*2.9+row*4.1);
      point.bx=this.radius*Math.cos(lat)*Math.sin(lon)*rough;
      point.by=this.radius*Math.sin(lat)*rough;
      point.bz=this.radius*Math.cos(lat)*Math.cos(lon)*rough;
      point.pleatX=col%2===0?-1:1;point.pleatY=row%2===0?-1:1;
      point.ridge=(col%2===0?-1:1)*.58+(row%2===0?-1:1)*.42;
      point.phase=((col*3+row*7)%5)*.015;
      this.vertices.push(point);
    }
    for(let row=0;row<this.steps;row++)for(let col=0;col<this.steps;col++) {
      const a=row*(this.steps+1)+col,b=a+1,c=a+this.steps+1,d=c+1;
      // Alternate diagonals avoid a regular "blinds" appearance.
      if((row+col)%2===0){this.triangles.push(new PaperTriangle(a,b,d),new PaperTriangle(a,d,c));}
      else{this.triangles.push(new PaperTriangle(a,b,c),new PaperTriangle(b,d,c));}
    }
    this.update(0);
  }
  update(progress:number):void {
    const p=Math.max(0,Math.min(1,progress)),roll=p*.28,cs=Math.cos(roll),sn=Math.sin(roll);
    for(const point of this.vertices) {
      const q=Math.max(0,Math.min(1,(p-point.phase)/(1-point.phase)));
      const foldX=smooth(q/.62)*1.36,foldY=smooth((q-.1)/.65)*1.30;
      const wrap=smooth((q-.56)/.44);
      // Accordion ridges retain surface depth while edges fold inward at staggered times.
      const fx=point.u*this.width*.5*Math.cos(foldX)+point.v*this.width*.025*Math.sin(foldY)+point.pleatX*this.width*.04*Math.sin(foldX);
      const fy=point.v*this.height*.5*Math.cos(foldY)-point.u*this.height*.022*Math.sin(foldX)+point.pleatY*this.height*.032*Math.sin(foldY);
      const fz=point.ridge*Math.min(this.width,this.height)*.17*Math.sin(foldX);
      const x=fx*(1-wrap)+point.bx*wrap,y=fy*(1-wrap)+point.by*wrap;
      point.x=x*cs-y*sn;point.y=x*sn+y*cs;point.z=fz*(1-wrap)+point.bz*wrap;
      const perspective=Math.max(.75,Math.min(1.3,1/(1-point.z/(Math.max(this.width,this.height)*3))));
      point.px=this.width*.5+point.x*perspective;point.py=this.height*.5+point.y*perspective;
    }
    for(const face of this.triangles) {
      const a=this.vertices[face.a],b=this.vertices[face.b],c=this.vertices[face.c];
      const ax=b.x-a.x,ay=b.y-a.y,az=b.z-a.z,bx=c.x-a.x,by=c.y-a.y,bz=c.z-a.z;
      const nx=ay*bz-az*by,ny=az*bx-ax*bz,nz=ax*by-ay*bx;
      const length=Math.max(.00001,Math.sqrt(nx*nx+ny*ny+nz*nz));
      const light=(nx*.24-ny*.38+Math.abs(nz)*.89)/length;
      face.shade=1-p+p*Math.max(.38,Math.min(1,.55+.45*light));
      face.depth=(a.z+b.z+c.z)/3;
    }
    this.triangles.sort((a:PaperTriangle,b:PaperTriangle)=>a.depth-b.depth);
  }
}
