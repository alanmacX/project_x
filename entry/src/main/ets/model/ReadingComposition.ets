import { FridgeCard, ElementBox } from './CardSchema';
export const READING_COMPOSITIONS:string[]=['bare','badge','sticker','space','tag','dock'];
export const READING_COMPOSITION_LABELS:string[]=['裸字','徽章','自适应贴片','负空间布局','边缘挂签','信息 Dock'];
export const READING_COMPOSITION_NOTES:string[]=['直接排字，细描光保留底图；适合低纹理区域','圆形视觉焦点；适合电量、时间等单项数据','半透、柔软轮廓；适合日期与中等信息量','轻云朵放在主体旁；可拖动到留白区域','带连接环的小标签；适合倒计时与进度','侧边小面板；适合课程表、日程等多行信息'];
export function isReadingComposition(blend:string):boolean {return READING_COMPOSITIONS.includes(blend);}
export function compositionSuggestion(kind:string):string {
  if(kind==='battery')return 'badge';
  if(kind==='clock')return 'bare';
  if(kind==='worldclock')return 'space';
  if(kind==='countdown'||kind==='anniversary'||kind.endsWith('progress'))return 'tag';
  if(kind==='timetable'||kind==='agenda')return 'dock';
  return 'sticker';
}
export function compositionTone(color:string,dark:boolean=false):string {
  const source=/^#[0-9a-fA-F]{6}$/.test(color)?color:'#E8D6B0',target=dark?32:255,mix=dark?.76:.48;
  return '#'+[1,3,5].map((i:number)=>Math.round(parseInt(source.slice(i,i+2),16)*(1-mix)+target*mix).toString(16).padStart(2,'0')).join('');
}
/** Smooth fixed-complexity silhouette; generated in native pixel coordinates, no outline scan. */
export function compositionPath(blend:string,w:number,h:number):string {
  if(!Number.isFinite(w)||!Number.isFinite(h)||w<=0||h<=0)return '';
  if(blend==='space')return `M ${w*.12} ${h*.3} C ${-w*.02} ${h*.03} ${w*.25} ${-h*.04} ${w*.38} ${h*.1} C ${w*.57} ${-h*.05} ${w*.7} ${h*.06} ${w*.74} ${h*.15} C ${w*1.02} ${h*.05} ${w*1.05} ${h*.36} ${w*.94} ${h*.49} C ${w*1.08} ${h*.75} ${w*.83} ${h*1.02} ${w*.64} ${h*.89} C ${w*.46} ${h*1.08} ${w*.21} ${h*.99} ${w*.18} ${h*.86} C ${-w*.04} ${h*.94} ${-w*.06} ${h*.52} ${w*.12} ${h*.3} Z`;
  return `M ${w*.08} ${h*.09} C ${w*.24} ${-h*.03} ${w*.43} ${h*.09} ${w*.6} ${h*.05} C ${w*.81} ${-h*.03} ${w*1.02} ${h*.07} ${w*.96} ${h*.3} C ${w*.91} ${h*.51} ${w*1.06} ${h*.72} ${w*.94} ${h*.9} C ${w*.78} ${h*1.05} ${w*.58} ${h*.91} ${w*.39} ${h*.96} C ${w*.19} ${h*1.04} ${-w*.01} ${h*.93} ${w*.04} ${h*.73} C ${w*.1} ${h*.5} ${-w*.04} ${h*.28} ${w*.08} ${h*.09} Z`;
}
/** Layout is persisted once, then edited normally. Never reposition on refresh or tick. */
export function compositionPlacement(card:FridgeCard,box:ElementBox,blend:string):ElementBox {
  const out=new ElementBox();out.w=box.w;out.h=box.h;out.x=box.x;out.y=box.y;out.opacity=box.opacity;out.rot=box.rot;
  if(blend==='space')out.x=-out.w*.3;
  if(blend==='dock')out.x=.55;
  if(blend==='tag')out.y=Math.min(1-out.h,.7-out.h*.5);
  return out;
}

export function compositionPadding(blend:string):number {return blend==='space'?10:blend==='sticker'?6:4;}
export class CompositionOverflow {left:number=0;top:number=0;right:number=0;bottom:number=0;}
/** Cache fringe includes external attachments, including their rotated corners. */
export function compositionOverflow(card:FridgeCard,scale:number):CompositionOverflow {
 const out=new CompositionOverflow();if(!card.capFree||!isReadingComposition(card.capability?.readingBlend??''))return out;
 const b=card.capBox,w=b.w*card.w,h=b.h*card.h,a=b.rot*Math.PI/180;
 const rw=Math.abs(Math.cos(a))*w+Math.abs(Math.sin(a))*h,rh=Math.abs(Math.sin(a))*w+Math.abs(Math.cos(a))*h;
 const cx=(b.x+b.w/2)*card.w,cy=(b.y+b.h/2)*card.h;
 out.left=Math.max(0,-(cx-rw/2))*scale;out.top=Math.max(0,-(cy-rh/2))*scale;
 out.right=Math.max(0,cx+rw/2-card.w)*scale;out.bottom=Math.max(0,cy+rh/2-card.h)*scale;return out;
}
