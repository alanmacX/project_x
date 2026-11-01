/** Direct manipulation of a template's photo camera. No card geometry or child layer is exposed. */
@Component
export struct TemplatePhotoGesture {
  onStart:()=>void=()=>{};
  onPan:(x:number,y:number)=>void=()=>{};
  onZoom:(scale:number)=>void=()=>{};
  onEnd:()=>void=()=>{};
  build(){
    Column().width('100%').height('100%').backgroundColor(Color.Transparent)
      .gesture(GestureGroup(GestureMode.Exclusive,
        PanGesture({fingers:1,distance:1}).onActionStart(()=>this.onStart()).onActionUpdate((e:GestureEvent)=>this.onPan(e.offsetX,e.offsetY)).onActionEnd(()=>this.onEnd()).onActionCancel(()=>this.onEnd()),
        PinchGesture({fingers:2,distance:1}).onActionStart(()=>this.onStart()).onActionUpdate((e:GestureEvent)=>this.onZoom(e.scale)).onActionEnd(()=>this.onEnd()).onActionCancel(()=>this.onEnd())
      )).accessibilityText('拖动照片，双指缩放')
  }
}
