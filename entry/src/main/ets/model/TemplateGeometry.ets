import { TemplateMark } from './TemplateScene';
/** Path coordinates are physical pixels; the shared scene itself uses 300 logical units. */
export function templateArcPath(m:TemplateMark,unit:number):string{
  if(!Number.isFinite(m.sweep)||m.sweep<=0||m.r<=0)return '';
  const cx=m.x*unit,cy=m.y*unit,r=m.r*unit,a=m.start*Math.PI/180,sweep=Math.min(360,m.sweep),b=(m.start+sweep)*Math.PI/180;
  const x=cx+Math.cos(a)*r,y=cy+Math.sin(a)*r;
  if(sweep>=359.99)return 'M '+x+' '+y+' A '+r+' '+r+' 0 1 1 '+(cx-Math.cos(a)*r)+' '+(cy-Math.sin(a)*r)+' A '+r+' '+r+' 0 1 1 '+x+' '+y;
  return 'M '+x+' '+y+' A '+r+' '+r+' 0 '+(sweep>180?1:0)+' 1 '+(cx+Math.cos(b)*r)+' '+(cy+Math.sin(b)*r);
}
