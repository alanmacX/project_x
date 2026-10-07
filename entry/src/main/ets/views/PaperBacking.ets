import { READING_PAPER_FILL } from '../model/CapabilityPresentation';
/** Size comes from the actual content, never from the movable capability container. */
@Component
export struct PaperBacking {
  @Prop radius:number=8;
  @Prop scaleFactor:number=1;
  build() {
    Stack() {
      Column().width('100%').height('100%').backgroundColor(READING_PAPER_FILL).borderRadius(this.radius)
        .border({width:{bottom:.6*this.scaleFactor},color:'#35A79A82'})
        .shadow({radius:3*this.scaleFactor,color:'#16000000',offsetY:1.2*this.scaleFactor})
      Column().width('100%').height('100%').backgroundImage($r('app.media.reading_paper_fibres'),ImageRepeat.XY)
        .backgroundImageSize({width:160*this.scaleFactor,height:160*this.scaleFactor}).borderRadius(this.radius).clip(true).opacity(.55)
    }.width('100%').height('100%').hitTestBehavior(HitTestMode.None)
  }
}
