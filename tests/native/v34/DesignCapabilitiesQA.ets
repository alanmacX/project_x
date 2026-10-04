import { CapabilityView } from '../../views/CapBlockView';
import { CapabilityPicker } from '../../views/CapabilityPicker';
import { TimeCapabilitySettings } from '../../views/TimeCapabilitySettings';
import { AppDesign } from '../../model/AppDesign';
import { CapBlock } from '../../model/CardSchema';
import { common } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
@Entry
@Component
struct DesignCapabilitiesQA {
  @State dark:boolean=true;
  @State landscape:boolean=false;
  @State cap:CapBlock={k:'worldclock',zone:'America/New_York'};
  private dialog:CustomDialogController|undefined=undefined;
  private tick:number=Date.now();
  private switchOrientation():void {
    this.landscape=!this.landscape;
    window.getLastWindow(this.getUIContext().getHostContext() as common.UIAbilityContext).then((win)=>win.setPreferredOrientation(this.landscape?window.Orientation.LANDSCAPE:window.Orientation.PORTRAIT));
  }
  private choose():void {this.dialog=new CustomDialogController({builder:CapabilityPicker({appDark:this.dark,selected:this.cap.k,onChoose:(key:string)=>{this.cap={k:key,zone:'Asia/Shanghai'};}}),customStyle:true});this.dialog.open();}
  @Builder
  example(kind:string,w:number,h:number) {
    Column({space:12}) {
      Text(kind==='lunar'?'农历':'世界时钟').fontSize(14).fontColor(AppDesign.text(this.dark))
      CapabilityView({cap:kind==='worldclock'?this.cap:{k:'lunar'},ink:'#262824',contentWidth:w,contentHeight:h,tick:this.tick}).width(w).height(h).backgroundColor('#F6F2E9').borderRadius(12)
      Text(w+' × '+h).fontSize(12).fontColor(AppDesign.muted(this.dark))
    }.layoutWeight(1)
  }
  build() {
    Column({space:16}) {
      Text('设计与系统时间能力 QA').fontSize(20).fontColor(AppDesign.text(this.dark)).margin({top:50})
      Row({space:8}) {
        Button('日夜',{type:ButtonType.Capsule}).height(44).onClick(()=>this.dark=!this.dark)
        Button('横竖',{type:ButtonType.Capsule}).height(44).onClick(()=>this.switchOrientation())
        Button('选择能力',{type:ButtonType.Capsule}).height(44).onClick(()=>this.choose())
      }
      Scroll() {
        Column({space:20}) {
          Row() {this.example('worldclock',104,76);this.example('worldclock',144,112)}.width('100%')
          Row() {this.example('lunar',112,72);this.example('lunar',160,112)}.width('100%')
          Column({space:16}) {
            Text('城市设置').fontSize(16).fontColor(AppDesign.text(this.dark)).width('100%')
            TimeCapabilitySettings({cap:this.cap,appDark:this.dark,onUpdate:(next:CapBlock)=>this.cap=next})
          }.width('100%').padding(16).backgroundColor(AppDesign.surface(this.dark)).borderRadius(20)
        }.width('100%').padding(16)
      }.width('100%').layoutWeight(1).align(Alignment.Top).scrollBar(BarState.Off)
    }.width('100%').height('100%').padding({bottom:24}).backgroundColor(AppDesign.background(this.dark))
  }
}
