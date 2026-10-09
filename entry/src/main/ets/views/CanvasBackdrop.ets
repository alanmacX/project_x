import { CanvasBackground } from '../model/CardSchema';
/** Display the generated, blurred light-fold pose unchanged in App, FormKit and export. */
@Component
export struct CanvasBackdrop {
  @Prop sceneBackground: CanvasBackground = new CanvasBackground();
  build() {
    Stack() {
      if(this.sceneBackground.mode!=='transparent'){
      Column().width('100%').height('100%').backgroundColor(this.sceneBackground.color)
      if (this.sceneBackground.src.length > 0 && this.sceneBackground.mode !== 'solid' && this.sceneBackground.mode !== 'smart') {
        Image(this.sceneBackground.src).width('100%').height('100%').objectFit(ImageFit.Cover).draggable(false)
      }
      }
    }.width('100%').height('100%').hitTestBehavior(HitTestMode.None)
  }
}
