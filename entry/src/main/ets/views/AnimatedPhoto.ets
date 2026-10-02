import { AnimatedDrawableDescriptor } from '@kit.ArkUI';

@Component
export struct AnimatedPhoto {
  @Prop src: string = '';
  @Prop animated: boolean = false;
  @Prop widget: boolean = false;
  private animationSource: string = '';
  private animatedDrawable: AnimatedDrawableDescriptor | undefined = undefined;
  private drawable(): AnimatedDrawableDescriptor {
    if (this.animatedDrawable === undefined || this.animationSource !== this.src) {
      this.animatedDrawable?.getAnimationController()?.stop();
      this.animationSource = this.src; this.animatedDrawable = new AnimatedDrawableDescriptor(this.src, { iterations: -1 });
    }
    return this.animatedDrawable;
  }
  aboutToDisappear(): void { this.animatedDrawable?.getAnimationController()?.stop(); }
  build() {
    if (this.animated && !this.widget) {
      Image(this.drawable()).width('100%').height('100%').objectFit(ImageFit.Cover).draggable(false)
        .onVisibleAreaChange([0], (visible: boolean) => {
          const controller = this.animatedDrawable?.getAnimationController(); if (visible) controller?.start(); else controller?.stop();
        })
    } else {
      Image(this.src).width('100%').height('100%').objectFit(ImageFit.Cover).draggable(false)
    }
  }
}
