/** Hollow sculpted mineral bevel. Borders only: no full-canvas blur/shadow render target. */
@Component
export struct CanvasFrame {
  @Prop square:boolean=false;
  @Prop style:string='auto';
  private body():ResourceColor{return this.style==='light'?'#FFFAFAF8':this.style==='dark'?'#FF42464B':$r('app.color.transparent_frame_surface');}
  build(){
    Stack(){
      if(this.style!=='none'){
        // Outer cut face, broad translucent body, recessed inner cut face.
        Column().width('100%').height('100%').borderRadius(this.square?0:24)
          .border({width:12,color:this.body()})
        Column().width('100%').height('100%').borderRadius(this.square?0:24)
          .border({width:1.8,color:{top:'#FFFFFFFF',left:'#FFFDFDFC',right:'#FFC3C5C7',bottom:'#FFB8BBBE'}})
        Column().width('calc(100% - 8vp)').height('calc(100% - 8vp)').borderRadius(this.square?0:20)
          .border({width:3,color:{top:'#FFFFFFFF',left:'#FFF5F5F2',right:'#FFE0E1E0',bottom:'#FFD5D7D8'}})
        Column().width('calc(100% - 24vp)').height('calc(100% - 24vp)').borderRadius(this.square?0:12)
          .border({width:1.6,color:{top:'#FFA8ADB1',left:'#FFBDC1C4',right:'#FFFFFFFF',bottom:'#FFFFFFFF'}})
      }
    }.width('100%').height('100%').hitTestBehavior(HitTestMode.None)
  }
}
