import { FluidBackdrop } from './FluidBackdrop';
import { CanvasBackground } from '../model/CardSchema';
@Component
export struct CanvasBackdrop {
  @Prop liveFluid: boolean = false;
  @Prop sceneBackground: CanvasBackground = new CanvasBackground();
  build() {
    Stack() {
      Column().width('100%').height('100%').backgroundColor(this.sceneBackground.color)
      if (this.sceneBackground.src.length > 0 && this.sceneBackground.mode !== 'solid' && this.sceneBackground.mode !== 'smart') {
        Image(this.sceneBackground.src).width('100%').height('100%').objectFit(ImageFit.Cover).draggable(false)
      }
      if (this.liveFluid && this.sceneBackground.mode === 'blend' && this.sceneBackground.anchors.length > 0) {
        FluidBackdrop({ anchors: this.sceneBackground.anchors }).width('100%').height('100%').opacity(this.sceneBackground.src.length>0?.18:1)
      }
    }.width('100%').height('100%').hitTestBehavior(HitTestMode.None)
  }
}
