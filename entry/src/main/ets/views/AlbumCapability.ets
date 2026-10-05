import { CapBlock } from '../model/CardSchema';
import { albumCoverSize } from '../model/AlbumLayout';
@Component
export struct AlbumCapability {
  @Prop cap:CapBlock={k:'album'};
  @Prop cardWidth:number=180;
  @Prop cardHeight:number=180;
  @Prop scaleFactor:number=1;
  build() {
    Stack() {
      Column().width('100%').height('100%').backgroundColor('#D9D4CD')
      if(this.cap.albumBackground) {Image(this.cap.albumBackground).width('100%').height('100%').objectFit(ImageFit.Fill).draggable(false)}
      if(this.cap.albumCover) {
        Image(this.cap.albumCover).width(albumCoverSize(this.cardWidth,this.cardHeight)*this.scaleFactor).height(albumCoverSize(this.cardWidth,this.cardHeight)*this.scaleFactor)
          .objectFit(ImageFit.Contain).borderRadius(4*this.scaleFactor).draggable(false)
          .shadow({radius:12*this.scaleFactor,color:'#35000000',offsetY:5*this.scaleFactor})
          .accessibilityText((this.cap.title??'专辑')+' · '+(this.cap.artist??''))
      } else {Text('选择一张专辑').fontSize(14*this.scaleFactor).fontColor('#494640')}
    }.width('100%').height('100%').hitTestBehavior(HitTestMode.None)
  }
}
