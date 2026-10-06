import { AppDesign } from '../model/AppDesign';
import { SettingsSegmented } from './SettingsSegmented';
@CustomDialog
export struct EnhancementPreview {
  controller?:CustomDialogController;
  original:string='';enhanced:string='';appDark:boolean=false;previewWidth:number=300;
  onUse:()=>void=()=>{};onDiscard:()=>void=()=>{};
  @State selected:number=1;
  private accepted:boolean=false;
  aboutToDisappear():void {if(!this.accepted)this.onDiscard();}
  build() {
    Column({space:16}) {
      Text('提升清晰度').fontSize(20).fontColor(AppDesign.text(this.appDark))
      SettingsSegmented({labels:['原图','增强后'],selectedIndex:this.selected,appDark:this.appDark,onSelect:(i:number)=>this.selected=i})
      Image(this.selected===0?this.original:this.enhanced).width(this.previewWidth).height(this.previewWidth).objectFit(ImageFit.Contain).draggable(false)
        .backgroundColor(AppDesign.background(this.appDark)).borderRadius(20).clip(true)
      Text('检查线条与细节；照片可能变得更平滑。原文件不会覆盖。').fontSize(13).fontColor(AppDesign.muted(this.appDark))
      Row({space:12}) {
        Button('保留原图',{type:ButtonType.Capsule}).layoutWeight(1).height(44).fontColor(AppDesign.text(this.appDark)).backgroundColor(AppDesign.control(this.appDark)).onClick(()=>this.controller?.close())
        Button('使用增强',{type:ButtonType.Capsule}).layoutWeight(1).height(44).onClick(()=>{this.accepted=true;this.onUse();this.controller?.close();})
      }.width('100%')
    }.padding(20).width(this.previewWidth+40).backgroundColor(AppDesign.surface(this.appDark)).borderRadius(24)
  }
}
