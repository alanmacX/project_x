/** Observe a direct touch without consuming Scroll's native gesture or inertia. */
export class EditorScrollDetent {
  private x:number=0;
  private y:number=0;
  private active:boolean=false;
  private snapped:boolean=false;
  begin(x:number,y:number):void {this.x=x;this.y=y;this.active=true;this.snapped=false;}
  end():void {this.active=false;}
  move(x:number,y:number,expanded:boolean,offset:number):boolean|undefined {
    if(!this.active||this.snapped)return undefined;
    const dx=x-this.x,dy=y-this.y;
    if(Math.abs(dx)>Math.abs(dy))return undefined;
    // Scrolled content must reach its start before a downward pull collapses it.
    if(expanded&&offset>1){this.x=x;this.y=y;return undefined;}
    if((!expanded&&dy<=-48)||(expanded&&dy>=56)) {
      this.snapped=true;return !expanded;
    }
    return undefined;
  }
}
