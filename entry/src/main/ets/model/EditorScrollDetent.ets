/** Direct-touch resistance; settling is decided on release, never during inertia. */
export class EditorScrollDetent {
  private x:number=0;
  private y:number=0;
  private active:boolean=false;
  private travel:number=0;
  begin(x:number,y:number):void {this.x=x;this.y=y;this.active=true;this.travel=0;}
  end():void {this.active=false;this.travel=0;}
  move(x:number,y:number,expanded:boolean,offset:number):number {
    if(!this.active)return 0;
    const dx=x-this.x,dy=y-this.y;
    if(Math.abs(dx)>Math.abs(dy)&&Math.abs(dx)>12){this.end();return 0;}
    // Downward pulls only become sheet gestures after content reaches its start.
    if(expanded&&offset>1){this.x=x;this.y=y;this.travel=0;return 0;}
    this.travel=expanded?Math.max(0,dy):Math.min(0,dy);
    // Progressive resistance: pulling farther gives diminishing visual travel.
    return this.travel*.32/(1+Math.abs(this.travel)/72);
  }
  finish(expanded:boolean):boolean|undefined {
    const target=this.active&&((!expanded&&this.travel<=-80)||(expanded&&this.travel>=96))?!expanded:undefined;
    this.end();return target;
  }
}
