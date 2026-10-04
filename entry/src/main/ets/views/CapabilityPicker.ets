import { CAPABILITY_CATALOG, CAPABILITY_GROUPS, CapabilityDescriptor } from '../model/CapabilityCatalog';
import { AppDesign } from '../model/AppDesign';
@CustomDialog
export struct CapabilityPicker {
  controller: CustomDialogController;
  selected: string = 'none';
  appDark: boolean = false;
  onChoose: (key:string)=>void = ()=>{};
  @State group: string = '时间';
  @State query:string='';
  private items():CapabilityDescriptor[] {const query=this.query.trim().toLowerCase();return CAPABILITY_CATALOG.filter((item)=>query?(item.name+' '+item.summary+' '+item.source).toLowerCase().includes(query):item.group===this.group);}
  aboutToAppear():void { this.group = CAPABILITY_CATALOG.find((item)=>item.key===this.selected)?.group ?? '时间'; }
  private choose(key:string):void { this.onChoose(key); this.controller.close(); }
  build() {
    Column({space:16}) {
      Row() {
        Text('选择卡片能力').fontSize(20).fontWeight(FontWeight.Medium).fontColor(AppDesign.text(this.appDark)).layoutWeight(1)
        Button('关闭',{type:ButtonType.Capsule}).height(44).fontSize(14).fontColor(AppDesign.text(this.appDark)).backgroundColor(AppDesign.control(this.appDark)).onClick(()=>this.controller.close())
      }.width('100%')
      TextInput({placeholder:'搜索能力',text:this.query}).height(44).fontSize(15).fontColor(AppDesign.text(this.appDark)).placeholderColor(AppDesign.muted(this.appDark)).backgroundColor(AppDesign.control(this.appDark)).borderRadius(12).cancelButton({style:CancelButtonStyle.INPUT}).onChange((value:string)=>this.query=value)
      Row({space:8}) {
        ForEach(CAPABILITY_GROUPS,(group:string)=>{
          Button(group,{type:ButtonType.Capsule}).height(44).layoutWeight(1).fontSize(14).backgroundColor(AppDesign.choice(this.appDark,this.group===group)).fontColor(AppDesign.choiceText(this.appDark,this.group===group)).onClick(()=>{this.group=group;this.query='';})
        },(group:string)=>group)
      }.width('100%')
      Scroll() {
        Column({space:8}) {
          ForEach(this.items(),(item:CapabilityDescriptor)=>{
            Button({type:ButtonType.ROUNDED_RECTANGLE}) {
              Row({space:12}) {
                Column({space:4}) {
                  Text(item.name).fontSize(16).fontWeight(FontWeight.Medium).fontColor(AppDesign.text(this.appDark)).width('100%')
                  Text(item.summary).fontSize(12).fontColor(AppDesign.muted(this.appDark)).width('100%').maxLines(2)
                  if(this.selected===item.key) {Text(item.source).fontSize(12).fontColor(AppDesign.muted(this.appDark)).width('100%').maxLines(2)}
                }.layoutWeight(1).alignItems(HorizontalAlign.Start)
                Text(this.selected===item.key?'已选':item.source.includes('联网')?'联网':'本地').fontSize(12).fontColor(AppDesign.muted(this.appDark))
              }.width('100%').padding(14)
            }.width('100%').backgroundColor(AppDesign.control(this.appDark)).border({width:this.selected===item.key?1.5:0,color:AppDesign.text(this.appDark)}).borderRadius(14).onClick(()=>this.choose(item.key))
          },(item:CapabilityDescriptor)=>item.key)
          if(this.items().length===0) {Text('没有匹配的能力，试试其他关键词').fontSize(14).fontColor(AppDesign.muted(this.appDark)).padding(24).width('100%').textAlign(TextAlign.Center)}
        }.width('100%')
      }.width('100%').layoutWeight(1).align(Alignment.Top).scrollBar(BarState.Off)
      Button('纯创作 · 不添加能力',{type:ButtonType.ROUNDED_RECTANGLE}).width('100%').height(48).fontSize(14).backgroundColor(AppDesign.control(this.appDark)).fontColor(AppDesign.text(this.appDark)).borderRadius(14).onClick(()=>this.choose('none'))
    }.padding(20).width('92%').constraintSize({maxWidth:520}).height('78%').backgroundColor(AppDesign.surface(this.appDark)).borderRadius(24)
  }
}
