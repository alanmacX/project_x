import { edgeStudyPath } from '../model/ReadingEdgeStudy';
/** Native Path only: stable silhouette on resize and drag, no Canvas clear/redraw handoff. */
@Component
export struct ReadingEdgeBacking {
 @Prop kind:number=0;
 @Prop surfaceWidth:number=200;
 @Prop surfaceHeight:number=100;
 @Prop scaleFactor:number=1;
 private path():string {return edgeStudyPath(this.kind,vp2px(this.surfaceWidth),vp2px(this.surfaceHeight),vp2px(this.scaleFactor));}
 build() {
  Stack() {
   Path().commands(this.path()).fill('#249C8B6C').stroke(Color.Transparent).antiAlias(true).width('100%').height('100%').translate({y:2*this.scaleFactor})
   Path().commands(this.path()).fill('#E6FAF4E3').stroke('#FFFDF6').strokeWidth(1.1*this.scaleFactor).antiAlias(true).width('100%').height('100%')
  }.width(this.surfaceWidth).height(this.surfaceHeight).hitTestBehavior(HitTestMode.None)
 }
}
