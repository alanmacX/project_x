import { BoardMotion } from '../model/BoardMotion';
/** Only this lightweight overlay observes guide changes; faces stay cached. */
@Component
export struct CenterGuides {
  @ObjectLink motion:BoardMotion;
  build() {
    Stack() {
      if(this.motion.guideVertical){Column().width(1).height('100%').backgroundColor('#A85B8CF5')}
      if(this.motion.guideHorizontal){Row().width('100%').height(1).backgroundColor('#A85B8CF5')}
    }.width('100%').height('100%').hitTestBehavior(HitTestMode.None).accessibilityLevel('no-hide-descendants')
  }
}
