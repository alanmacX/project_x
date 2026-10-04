import { ValueField } from '../model/CapabilityData';
import { AppDesign } from '../model/AppDesign';
@CustomDialog
export struct ValuePicker {
  controller:CustomDialogController;
  choices:ValueField[]=[];
  title:string='选择内容';
  appDark:boolean=false;
  onChoose:(value:ValueField)=>void=()=>{};
  build() {
    Column({space:16}) {
      Text(this.title).fontSize(20).fontColor(AppDesign.text(this.appDark)).width('100%')
      Scroll() {
        Column({space:8}) {
          ForEach(this.choices,(v:ValueField)=>{
            Button({type:ButtonType.ROUNDED_RECTANGLE, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL}) {
              Column({space:6}) {Text(v.path||'正文').fontSize(14).fontColor(AppDesign.text(this.appDark)).maxLines(2).textOverflow({overflow:TextOverflow.Ellipsis}).width('100%');Text(v.value).fontSize(12).fontColor(AppDesign.muted(this.appDark)).maxLines(2).textOverflow({overflow:TextOverflow.Ellipsis}).width('100%')}.width('100%')
            }.width('100%').padding(14).backgroundColor(AppDesign.control(this.appDark)).onClick(()=>{this.onChoose(v);this.controller.close();})
          },(v:ValueField)=>v.path)
        }.width('100%')
      }.width('100%').height(280).scrollBar(BarState.Off)
      Button('取消',{type:ButtonType.Capsule, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL}).height(44).width('100%').fontColor(AppDesign.text(this.appDark)).backgroundColor(AppDesign.control(this.appDark)).onClick(()=>this.controller.close())
    }.width('90%').constraintSize({maxWidth:520}).padding(20).borderRadius(24).backgroundColor(AppDesign.surface(this.appDark))
  }
}
