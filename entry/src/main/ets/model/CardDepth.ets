/** All physical relief scales with artwork, including smaller desktop hosts. */
export function cardDepthScale(scale: number): number { return Number.isFinite(scale)?Math.max(0,scale):1; }
export function cardEdgeColor(color: string, photoSubject: boolean): string {
  const source=photoSubject?'#FFFFFF':color;
  if(!/^#[0-9a-fA-F]{6}$/.test(source))return '#D2CEC5';
  // Warm neutral substrate; preserve each card's hue instead of a generic grey slab.
  const channels=[0,1,2].map((i:number)=>Math.round(parseInt(source.slice(1+i*2,3+i*2),16)*.78+[35,33,29][i]));
  return '#'+channels.map((n:number)=>Math.max(0,Math.min(255,n)).toString(16).padStart(2,'0')).join('');
}

/** One soft-light relief recipe for all hosts. Values are logical artwork units. */
export const CARD_SIDE: number = 1.35;
export const CARD_CAST_RADIUS: number = 9;
export const CARD_CAST_Y: number = 4.5;
export const CARD_CAST_COLOR: string = '#290E0904';
export const CARD_CONTACT_RADIUS: number = 1.6;
export const CARD_CONTACT_Y: number = .6;
export const CARD_CONTACT_COLOR: string = '#320E0904';

export class ReliefBand { extra:number=0; opacity:number=0; }
/** Gaussian falloff, sampled once as geometry; no rectangular node shadow on a silhouette. */
export function contourReliefBands(radius:number,amplitude:number=.16):ReliefBand[] {
  if(!Number.isFinite(radius)||radius<=0)return [];
  const result:ReliefBand[]=[],steps=radius>3?16:6,sigma=radius/2;
  let previous=0;
  for(let i=steps;i>=0;i--){
    const distance=radius*1.5*i/steps,alpha=Math.exp(-distance*distance/(2*sigma*sigma));
    const band=new ReliefBand();band.extra=2*distance;band.opacity=(alpha-previous)/(1-amplitude*previous);previous=alpha;result.push(band);
  }
  return result;
}
