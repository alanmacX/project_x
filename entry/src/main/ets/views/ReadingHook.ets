import { hookPoint } from '../model/ReadingComposition';
/** Foreground attachment: background builders clip overflow, so the hook lives in an overlay. */
@Component
export struct ReadingHook {
 @Prop hook:number=.2;
 @Prop scaleFactor:number=1;
 build() {
  Stack({alignContent:Alignment.TopStart}) {
   Image($r('app.media.mica_hook')).sourceSize({width:64,height:64}).width(28*this.scaleFactor).height(36*this.scaleFactor).objectFit(ImageFit.Contain).draggable(false)
    .position({x:(hookPoint(this.hook)[0]*100)+'%',y:(hookPoint(this.hook)[1]*100)+'%'}).translate({x:(-14+(hookPoint(this.hook)[0]-.5)*16)*this.scaleFactor,y:(-25+(hookPoint(this.hook)[1]-.5)*16)*this.scaleFactor})
  }.width('100%').height('100%').hitTestBehavior(HitTestMode.None)
 }
}
