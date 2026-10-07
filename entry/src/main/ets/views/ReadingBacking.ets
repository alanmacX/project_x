import { readingSurfaceColor } from '../model/CapabilityPresentation';
import { isReadingComposition } from '../model/ReadingComposition';
import { PaperBacking } from './PaperBacking';
/** Material and content geometry are separate; all materials share the same tight bounds. */
@Component
export struct ReadingBacking {
  @Prop blend:string='paper';
  @Prop ink:string='#262824';
  @Prop tint:string='#E8D6B0';
  @Prop edge:string='';
  @Prop hook:number=.2;
  private silhouette():Resource {
    if(this.blend==='bare')return $r('app.media.mica_brush');
    if(this.edge==='left')return $r('app.media.mica_edge_left');if(this.edge==='right')return $r('app.media.mica_edge_right');
    if(this.edge==='top')return $r('app.media.mica_edge_top');if(this.edge==='bottom')return $r('app.media.mica_edge_bottom');
    return this.blend==='space'?$r('app.media.mica_cloud'):$r('app.media.mica_patch');
  }
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
      if(isReadingComposition(this.blend)) {
        if(this.blend==='bare'||this.blend==='sticker'||this.blend==='space') {
          Image(this.silhouette()).width('100%').height('100%').objectFit(ImageFit.Fill).draggable(false)
        } else {
          Column().width('100%').height('100%').backgroundColor('#BDF7F9FC')
            .borderRadius(this.blend==='badge'?999:this.blend==='tag'?12*this.scaleFactor:10*this.scaleFactor)
            .border({width:.6*this.scaleFactor,color:'#70FFFFFF'})
        }
      } else if(this.blend==='paper') {PaperBacking({radius:this.radius,scaleFactor:this.scaleFactor})}
      else if(this.blend!=='halo') {Image(this.texture()).width('100%').height('100%').objectFit(ImageFit.Fill).draggable(false)}
    }.width('100%').height('100%').hitTestBehavior(HitTestMode.None)
  }
}
