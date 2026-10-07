import { readingSurfaceColor } from '../model/CapabilityPresentation';
import { compositionTone, compositionPath, isReadingComposition } from '../model/ReadingComposition';
import { PaperBacking } from './PaperBacking';
/** Material and content geometry are separate; all materials share the same tight bounds. */
@Component
export struct ReadingBacking {
  @Prop blend:string='paper';
  @Prop ink:string='#262824';
  @Prop tint:string='#E8D6B0';
  @State surfaceWidth:number=1;
  @State surfaceHeight:number=1;
  private tone():string {return compositionTone(this.tint);}
  private silhouette():string {return compositionPath(this.blend,this.getUIContext().vp2px(this.surfaceWidth),this.getUIContext().vp2px(this.surfaceHeight));}
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
      if(isReadingComposition(this.blend)&&this.blend!=='bare') {
        if(this.blend==='sticker'||this.blend==='space') {
          Path().commands(this.silhouette()).width('100%').height('100%').fill('#DB'+this.tone().slice(1))
            .stroke('#CFFFFFFF').strokeWidth(1.5*this.scaleFactor)
            .shadow({radius:3*this.scaleFactor,color:'#20000000',offsetY:1.5*this.scaleFactor})
        } else {
          Column().width('100%').height('100%').backgroundColor('#EA'+this.tone().slice(1))
            .borderRadius(this.blend==='badge'?999:this.blend==='tag'?12*this.scaleFactor:10*this.scaleFactor)
            .border({width:1.2*this.scaleFactor,color:'#DDFFFFFF'})
            .shadow({radius:3*this.scaleFactor,color:'#22000000',offsetY:2*this.scaleFactor})
        }
        if(this.blend==='tag'||this.blend==='dock') {
          Circle().width(9*this.scaleFactor).height(9*this.scaleFactor).fill(this.tone()).stroke('#A78E63').strokeWidth(2*this.scaleFactor)
            .position({x:9*this.scaleFactor,y:-4*this.scaleFactor})
        }
      } else if(this.blend==='paper') {PaperBacking({radius:this.radius,scaleFactor:this.scaleFactor})}
      else if(this.blend!=='halo') {Image(this.texture()).width('100%').height('100%').objectFit(ImageFit.Fill).draggable(false)}
    }.width('100%').height('100%').hitTestBehavior(HitTestMode.None).onAreaChange((_:Area,a:Area)=>{const w=Number(a.width),h=Number(a.height);if(w!==this.surfaceWidth||h!==this.surfaceHeight){this.surfaceWidth=w;this.surfaceHeight=h;}})
  }
}
