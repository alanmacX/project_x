import { readingSurfaceColor } from '../model/CapabilityPresentation';
import { PaperBacking } from './PaperBacking';
/** Material and content geometry are separate; all materials share the same tight bounds. */
@Component
export struct ReadingBacking {
  @Prop blend:string='paper';
  @Prop ink:string='#262824';
  @Prop radius:number=8;
  @Prop scaleFactor:number=1;
  private texture():Resource {
    const color=readingSurfaceColor(this.ink),scrim=this.blend==='scrim';
    if(color==='#252824')return scrim?$r('app.media.reading_scrim_dark'):$r('app.media.reading_feather_dark');
    if(color==='#FFFFFF')return scrim?$r('app.media.reading_scrim_white'):$r('app.media.reading_feather_white');
    if(color==='#000000')return scrim?$r('app.media.reading_scrim_black'):$r('app.media.reading_feather_black');
    return scrim?$r('app.media.reading_scrim_warm'):$r('app.media.reading_feather_warm');
  }
  build() {
    Stack() {
      if(this.blend==='paper') {PaperBacking({radius:this.radius,scaleFactor:this.scaleFactor})}
      else if(this.blend!=='halo') {Image(this.texture()).width('100%').height('100%').objectFit(ImageFit.Fill).draggable(false)}
    }.width('100%').height('100%').hitTestBehavior(HitTestMode.None)
  }
}
