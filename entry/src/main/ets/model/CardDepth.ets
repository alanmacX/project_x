/** All physical relief scales with artwork, including smaller desktop hosts. */
export function cardDepthScale(scale: number): number { return Number.isFinite(scale)?Math.max(0,scale):1; }
export function cardEdgeColor(color: string, photoSubject: boolean): string {
  const source=photoSubject?'#FFFFFF':color;
  if(!/^#[0-9a-fA-F]{6}$/.test(source))return '#D2CEC5';
  // Warm neutral substrate; preserve each card's hue instead of a generic grey slab.
  const channels=[0,1,2].map((i:number)=>Math.round(parseInt(source.slice(1+i*2,3+i*2),16)*.78+[35,33,29][i]));
  return '#'+channels.map((n:number)=>Math.max(0,Math.min(255,n)).toString(16).padStart(2,'0')).join('');
}
