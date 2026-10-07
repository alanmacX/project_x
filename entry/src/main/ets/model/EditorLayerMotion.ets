import { ElementBox } from './CardSchema';
/** Transient geometry is observed only by the canvas layer and its controls.
 * Storage, inspector, history and card snapshots change once at gesture completion. */
@Observed
export class EditorLayerMotion {
  @Track edge:string='';
  @Track id: string = '';
  @Track box: ElementBox = new ElementBox();
  update(id:string,box:ElementBox):void {
    const next=new ElementBox();next.x=box.x;next.y=box.y;next.w=box.w;next.h=box.h;next.rot=box.rot;next.opacity=box.opacity;
    this.box=next;if(this.id!==id)this.id=id;
  }
  clear():void {this.id='';this.edge='';}
}
