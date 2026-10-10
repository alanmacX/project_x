import { CAPABILITY_CATALOG, CAPABILITY_GROUPS, CapabilityDescriptor } from '../model/CapabilityCatalog';
import { AppDesign } from '../model/AppDesign';
import { SettingsSegmented } from './SettingsSegmented';
import { LengthMetrics } from '@kit.ArkUI';
@Component
export struct CapabilityPicker {
  @Prop selected: string = 'none';
  @Prop appDark: boolean = false;
  onClose:()=>void=()=>{};
  onChoose: (key:string)=>void = ()=>{};
  private searchController:SearchController=new SearchController();
  private listScroller:Scroller=new Scroller();
  private searchEditing:boolean=false;
  private dismissSearch():void {if(this.searchEditing){this.searchEditing=false;this.searchController.stopEditing();}}
  @State group: string = '时间';
  @State query:string='';
  private items():CapabilityDescriptor[] {const query=this.query.trim().toLowerCase();return CAPABILITY_CATALOG.filter((item)=>query?(item.name+' '+item.summary+' '+item.source).toLowerCase().includes(query):item.group===this.group);}
  aboutToAppear():void { this.group = CAPABILITY_CATALOG.find((item)=>item.key===this.selected)?.group ?? '时间'; }
  private choose(key:string):void { this.dismissSearch();this.onChoose(key); this.onClose(); }
  build() {
    Column({space:12}) {
      Row() {
        Text('选择卡片能力').fontSize(20).fontWeight(FontWeight.Medium).fontColor(AppDesign.text(this.appDark)).layoutWeight(1)
        Blank().width(48)
      }.width('100%')
      Search({placeholder:'搜索能力',value:this.query,controller:this.searchController}).height(44).textFont({size:15}).fontColor(AppDesign.text(this.appDark)).placeholderColor(AppDesign.muted(this.appDark)).backgroundColor(AppDesign.control(this.appDark)).borderRadius(12).cancelButton({style:CancelButtonStyle.INPUT}).onEditChange((editing:boolean)=>{this.searchEditing=editing;}).onSubmit(()=>this.dismissSearch()).onChange((value:string)=>{this.query=value;this.listScroller.scrollTo({xOffset:0,yOffset:0});})
      SettingsSegmented({labels:CAPABILITY_GROUPS,selectedIndex:CAPABILITY_GROUPS.indexOf(this.group),appDark:this.appDark,onSelect:(index:number)=>{this.dismissSearch();this.group=CAPABILITY_GROUPS[index];this.query='';this.listScroller.scrollTo({xOffset:0,yOffset:0});}})
      List({space:8,scroller:this.listScroller}) {
          ForEach(this.items(),(item:CapabilityDescriptor)=>{
            ListItem() {Button({type:ButtonType.ROUNDED_RECTANGLE, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL}) {
              Row({space:12}) {
                Column({space:4}) {
                  Text(item.name).fontSize(16).fontWeight(FontWeight.Medium).fontColor(AppDesign.text(this.appDark)).width('100%')
                  Text(item.summary).fontSize(12).fontColor(AppDesign.muted(this.appDark)).width('100%').maxLines(2)
                  if(this.selected===item.key) {Text(item.source).fontSize(12).fontColor(AppDesign.muted(this.appDark)).width('100%').maxLines(2)}
                }.layoutWeight(1).alignItems(HorizontalAlign.Start)
                if(this.selected===item.key){SymbolGlyph($r('sys.symbol.checkmark')).fontSize(18).fontColor([AppDesign.text(this.appDark)])}else{SymbolGlyph($r('sys.symbol.chevron_right')).fontSize(14).fontColor([AppDesign.muted(this.appDark)])}
              }.width('100%').padding({left:12,right:12,top:10,bottom:10})
            }.width('100%').constraintSize({minHeight:72}).backgroundColor(AppDesign.surface(this.appDark)).borderRadius(AppDesign.sectionRadius).onClick(()=>this.choose(item.key))}.width('100%')
          },(item:CapabilityDescriptor)=>item.key)
          if(this.items().length===0) {ListItem(){Text('没有匹配的能力，试试其他关键词').fontSize(14).fontColor(AppDesign.muted(this.appDark)).padding(24).width('100%').textAlign(TextAlign.Center)}}
      }.width('100%').layoutWeight(1).scrollBar(BarState.Auto).edgeEffect(EdgeEffect.Spring).fadingEdge(true,{fadingEdgeLength:LengthMetrics.vp(12)}).onWillScroll((_offset:number,_state:ScrollState,source:ScrollSource)=>{if(source===ScrollSource.DRAG)this.dismissSearch();})
    }.padding({left:20,right:20,top:16,bottom:16}).width('100%').height('100%').backgroundColor(AppDesign.background(this.appDark))
  }
}
