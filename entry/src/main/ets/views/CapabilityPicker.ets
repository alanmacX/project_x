import { CAPABILITY_CATALOG, CAPABILITY_GROUPS, CapabilityDescriptor } from '../model/CapabilityCatalog';
import { AppDesign } from '../model/AppDesign';
import { SettingsSegmented } from './SettingsSegmented';
import { settingsReveal } from '../model/SettingsMotion';
@Component
export struct CapabilityPicker {
  @Prop selected: string = 'none';
  @Prop appDark: boolean = false;
  onClose:()=>void=()=>{};
  onChoose: (key:string)=>void = ()=>{};
  @State group: string = '时间';
  @State query:string='';
  private items():CapabilityDescriptor[] {const query=this.query.trim().toLowerCase();return CAPABILITY_CATALOG.filter((item)=>query?(item.name+' '+item.summary+' '+item.source).toLowerCase().includes(query):item.group===this.group);}
  aboutToAppear():void { this.group = CAPABILITY_CATALOG.find((item)=>item.key===this.selected)?.group ?? '时间'; }
  private choose(key:string):void { this.onChoose(key); this.onClose(); }
  build() {
    Column({space:16}) {
      Row() {
        Text('选择卡片能力').fontSize(20).fontWeight(FontWeight.Medium).fontColor(AppDesign.text(this.appDark)).layoutWeight(1)
        Blank().width(48)
      }.width('100%')
      TextInput({placeholder:'搜索能力',text:this.query}).height(44).fontSize(15).fontColor(AppDesign.text(this.appDark)).placeholderColor(AppDesign.muted(this.appDark)).backgroundColor(AppDesign.control(this.appDark)).borderRadius(12).cancelButton({style:CancelButtonStyle.INPUT}).onChange((value:string)=>this.query=value)
      SettingsSegmented({labels:CAPABILITY_GROUPS,selectedIndex:CAPABILITY_GROUPS.indexOf(this.group),appDark:this.appDark,onSelect:(index:number)=>{this.group=CAPABILITY_GROUPS[index];this.query='';}})
      Scroll() {
        Column({space:8}) {
          ForEach(this.items(),(item:CapabilityDescriptor)=>{
            Button({type:ButtonType.ROUNDED_RECTANGLE, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL}) {
              Row({space:12}) {
                Column({space:4}) {
                  Text(item.name).fontSize(16).fontWeight(FontWeight.Medium).fontColor(AppDesign.text(this.appDark)).width('100%')
                  Text(item.summary).fontSize(12).fontColor(AppDesign.muted(this.appDark)).width('100%').maxLines(2)
                  if(this.selected===item.key) {Text(item.source).fontSize(12).fontColor(AppDesign.muted(this.appDark)).width('100%').maxLines(2)}
                }.layoutWeight(1).alignItems(HorizontalAlign.Start)
                if(this.selected===item.key){SymbolGlyph($r('sys.symbol.checkmark')).fontSize(18).fontColor([AppDesign.text(this.appDark)])}else{SymbolGlyph($r('sys.symbol.chevron_right')).fontSize(14).fontColor([AppDesign.muted(this.appDark)])}
              }.width('100%').padding(14)
            }.width('100%').backgroundColor(AppDesign.surface(this.appDark)).borderRadius(AppDesign.sectionRadius).onClick(()=>this.choose(item.key)).transition(this.query.trim().length===0?settingsReveal():TransitionEffect.IDENTITY)
          },(item:CapabilityDescriptor)=>item.key)
          if(this.items().length===0) {Text('没有匹配的能力，试试其他关键词').fontSize(14).fontColor(AppDesign.muted(this.appDark)).padding(24).width('100%').textAlign(TextAlign.Center)}
        }.width('100%')
      }.width('100%').layoutWeight(1).align(Alignment.Top).scrollBar(BarState.Off)
      Button('纯创作 · 不添加能力',{type:ButtonType.ROUNDED_RECTANGLE, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL}).width('100%').height(48).fontSize(14).backgroundColor(AppDesign.control(this.appDark)).fontColor(AppDesign.text(this.appDark)).onClick(()=>this.choose('none'))
    }.padding({left:20,right:20,top:24,bottom:24}).width('100%').height('100%').constraintSize({maxWidth:640}).backgroundColor(AppDesign.background(this.appDark))
  }
}
