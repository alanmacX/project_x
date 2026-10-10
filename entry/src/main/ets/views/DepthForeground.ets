import { FridgeCard, CanvasElement, ElementBox } from '../model/CardSchema';
import { depthElement, depthPhotoBox } from '../model/DepthComposition';
import { EditorLayerMotion } from '../model/EditorLayerMotion';

/** No additional shadows, masks or extraction during interaction. */
@Component
export struct DepthForeground {
  @Prop card:FridgeCard=new FridgeCard();
  @State motion:EditorLayerMotion=new EditorLayerMotion();
  private element():CanvasElement|undefined{return depthElement(this.card);}
  private box():ElementBox {const el=this.element();return el&&this.motion.id===el.id?this.motion.box:el??new ElementBox();}
  private crop():ElementBox {return depthPhotoBox(this.element()??new CanvasElement(),this.box().w*this.card.w,this.box().h*this.card.h);}
  build(){
    Stack({alignContent:Alignment.TopStart}) {
      if(this.element()!==undefined){
        Stack({alignContent:Alignment.TopStart}){
          Image(this.element()!.depthForeground).objectFit(ImageFit.Fill).draggable(false)
            .width(this.crop().w*100+'%').height(this.crop().h*100+'%')
            .position({x:this.crop().x*100+'%',y:this.crop().y*100+'%'})
        }.width(this.box().w*100+'%').height(this.box().h*100+'%')
          .position({x:this.box().x*100+'%',y:this.box().y*100+'%'}).clip(true)
          .rotate({angle:this.box().rot}).opacity(this.box().opacity).renderGroup(true)
      }else if(this.card.shape==='subject'&&this.card.subjectPhoto&&this.card.cutout.length>0){
        Image(this.card.cutout).width('100%').height('100%').objectFit(ImageFit.Fill).draggable(false)
      }
    }.width('100%').height('100%').hitTestBehavior(HitTestMode.None)
  }
}
