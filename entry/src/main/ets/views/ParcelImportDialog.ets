import { ParcelItem } from '../model/CardSchema';
import { parsePickupNotice } from '../model/ParcelIntake';
import { AppDesign } from '../model/AppDesign';
import { pasteboard } from '@kit.BasicServicesKit';
@CustomDialog
export struct ParcelImportDialog {
  controller:CustomDialogController;
  appDark:boolean=false;
  initialText:string='';
  defaultPlace:string='';
  onImport:(items:ParcelItem[])=>void=()=>{};
  @State notice:string='';
  @State candidates:ParcelItem[]=[];
  @State chosen:string[]=[];
  @State message:string='';
  private alive:boolean=true;
  aboutToAppear():void {this.alive=true;this.notice=this.initialText;this.parse();}
  aboutToDisappear():void {this.alive=false;this.notice='';}
  private parse():void {
    this.candidates=parsePickupNotice(this.notice).map((p:ParcelItem):ParcelItem=>({id:p.id,code:p.code,place:p.place||this.defaultPlace,picked:false}));
    this.chosen=this.candidates.map((p)=>p.id);this.message='';
  }
  private async paste():Promise<void> {
    try {const data=await pasteboard.getSystemPasteboard().getData();if(this.alive){this.notice=(data.getPrimaryText()??'').slice(0,16384);this.parse();}}
    catch(_){if(this.alive)this.message='未能读取文字，可在输入框中粘贴';}
  }
  private confirm():void {
    try{const selected=this.candidates.filter((p)=>this.chosen.includes(p.id));if(!selected.length||selected.some((p)=>!p.code.trim()))throw new Error('请补全所选取件码');this.onImport(selected);this.controller.close();}
    catch(e){this.message=(e as Error).message;}
  }
  build() {
    Column({space:16}) {
      Row() {
        Text('导入取件通知').fontSize(20).fontWeight(FontWeight.Medium).fontColor(AppDesign.text(this.appDark)).layoutWeight(1)
        Button('取消',{type:ButtonType.Capsule, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL}).height(44).fontSize(14).backgroundColor(AppDesign.control(this.appDark)).fontColor(AppDesign.text(this.appDark)).onClick(()=>this.controller.close())
      }.width('100%')
      Scroll() {
        Column({space:12}) {
          Row() {
            Text('粘贴通知文字，或校对截图识别结果').fontSize(12).fontColor(AppDesign.muted(this.appDark)).layoutWeight(1)
            PasteButton({text:PasteDescription.PASTE,buttonType:ButtonType.Capsule}).height(44).fontSize(14).fontColor(AppDesign.text(this.appDark)).backgroundColor(AppDesign.control(this.appDark))
              .onClick((_:ClickEvent,result:PasteButtonOnClickResult)=>{if(result===PasteButtonOnClickResult.SUCCESS)this.paste();})
          }.width('100%')
          TextArea({text:this.notice,placeholder:'取件码：2-1234，包裹在…驿站'}).height(112).maxLength(16384).fontSize(14).fontColor(AppDesign.text(this.appDark)).placeholderColor(AppDesign.muted(this.appDark)).backgroundColor(AppDesign.control(this.appDark)).borderRadius(12).onChange((value:string)=>{this.notice=value;this.parse();})
          if(!this.candidates.length) { Text(this.notice?'没有识别到明确的取件码，可修改文字或手动添加':'只在本机处理；通知原文不会保存').fontSize(12).fontColor(AppDesign.muted(this.appDark)).width('100%') }
          ForEach(this.candidates,(p:ParcelItem)=>{
            Column({space:8}) {
              Row({space:8}) {
                Checkbox({name:p.id}).select(this.chosen.includes(p.id)).selectedColor(AppDesign.selected(this.appDark)).onChange((value:boolean)=>{this.chosen=value?this.chosen.includes(p.id)?this.chosen:this.chosen.concat([p.id]):this.chosen.filter((id)=>id!==p.id);})
                TextInput({text:p.code,placeholder:'取件码'}).height(44).maxLength(24).fontSize(18).fontColor(AppDesign.text(this.appDark)).backgroundColor(AppDesign.control(this.appDark)).layoutWeight(1).onChange((value:string)=>p.code=value)
              }.width('100%')
              TextInput({text:p.place,placeholder:'取件地点'}).height(44).maxLength(80).fontSize(14).fontColor(AppDesign.text(this.appDark)).backgroundColor(AppDesign.control(this.appDark)).borderRadius(12).onChange((value:string)=>p.place=value)
            }.width('100%').padding(12).backgroundColor(AppDesign.control(this.appDark)).borderRadius(14)
          },(p:ParcelItem)=>p.id)
          if(this.message) {Text(this.message).fontSize(12).fontColor(AppDesign.muted(this.appDark)).width('100%')}
        }.width('100%')
      }.width('100%').layoutWeight(1).align(Alignment.Top).scrollBar(BarState.Off)
      Button('加入待取 · '+this.chosen.length,{type:ButtonType.Capsule, buttonStyle:ButtonStyleMode.EMPHASIZED, role:ButtonRole.NORMAL}).width('100%').height(48).fontSize(15).fontColor(AppDesign.onSelected(this.appDark)).backgroundColor(AppDesign.selected(this.appDark)).enabled(this.chosen.length>0).onClick(()=>this.confirm())
    }.padding(20).width('92%').constraintSize({maxWidth:520}).height('80%').backgroundColor(AppDesign.surface(this.appDark)).borderRadius(24)
  }
}
