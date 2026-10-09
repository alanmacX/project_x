/** A hollow beveled frame: no fill and no backdrop blur. */
@Component
export struct CanvasFrame {
  @Prop style: string = 'auto';
  private surface():ResourceColor {return this.style==='light'?'#F4F0E8':this.style==='dark'?'#292B2D':$r('app.color.transparent_frame_surface');}
  build() {
    Stack() {
      if(this.style!=='none') {
        Column().width('100%').height('100%').borderRadius(24)
          .border({width:4.5,color:this.surface()})
          .shadow({radius:8,color:'#260A0805',offsetY:2})
        Column().width('100%').height('100%').borderRadius(24)
          .border({width:.65,color:{top:'#99FFFFFF',left:'#66FFFFFF',right:'#35000000',bottom:'#50000000'}})
        Column().width('100%').height('100%').borderRadius(20).scale({x:.988,y:.988})
          .border({width:.6,color:{top:'#33000000',left:'#22000000',right:'#55FFFFFF',bottom:'#88FFFFFF'}})
      }
    }.width('100%').height('100%').hitTestBehavior(HitTestMode.None)
  }
}
