import { FridgeCard, materialColors } from '../model/CardSchema';
import { readingWarning } from '../model/CapabilityPresentation';
import { capabilityDescriptor } from '../model/CapabilityCatalog';
import { chromeMaterial } from '../model/ChromeMaterial';
import { AppDesign } from '../model/AppDesign';
import { ColorSetting } from './ColorSetting';
import { SettingsSegmented } from './SettingsSegmented';
/** All capabilities use this inspector. Data-specific controls never redefine appearance or gestures. */
@Component
export struct CapabilityAppearance {
  @Prop card:FridgeCard=new FridgeCard();
  @Prop appDark:boolean=false;
  @State readingExpanded:boolean=false;
  onChoose:()=>void=()=>{};
  onCompare:()=>void=()=>{};
  onBlend:(blend:string)=>void=()=>{};
  onArrange:(anchor:string)=>void=()=>{};
  onStyle:(style:string)=>void=()=>{};
  onColor:()=>void=()=>{};
  onColorPick:(color:string,key:string)=>void=()=>{};
  private ink():string {return this.card.shape==='subject'&&this.card.subjectPhoto&&!this.card.ink?this.card.subjectInk:materialColors(this.card.material,this.card.paper,this.card.ink)[1];}
  build() {
    Column({space:12}) {
      Row({space:12}) {
        Column({space:4}) {
          Text(capabilityDescriptor(this.card.capability?.k??'none').name).fontSize(16).fontWeight(FontWeight.Medium).fontColor(AppDesign.text(this.appDark)).width('100%')
          Text(capabilityDescriptor(this.card.capability?.k??'none').summary).fontSize(12).fontColor(AppDesign.muted(this.appDark)).width('100%')
        }.layoutWeight(1)
        Button('更换',{type:ButtonType.Capsule,buttonStyle:ButtonStyleMode.NORMAL}).height(44).fontSize(13).backgroundColor(AppDesign.control(this.appDark)).fontColor(AppDesign.text(this.appDark)).onClick(()=>this.onChoose())
      }.width('100%')
      ColorSetting({label:'内容颜色',color:this.ink(),automatic:!this.card.ink,sourceKey:this.card.id+':ink:',appDark:this.appDark,
        onPick:(color:string,key:string)=>this.onColorPick(color,key),onFallback:()=>this.onColor()})
      Button({type:ButtonType.Capsule,buttonStyle:ButtonStyleMode.NORMAL}) {
        Row(){Text('排版与可读性').fontSize(14).fontColor(AppDesign.text(this.appDark));Blank();SymbolGlyph($r('sys.symbol.chevron_down')).fontSize(14).fontColor([AppDesign.muted(this.appDark)]).rotate({angle:this.readingExpanded?180:0})}.width('100%')
      }.width('100%').height(44).backgroundColor(AppDesign.control(this.appDark)).onClick(()=>this.getUIContext().animateTo({duration:180,curve:Curve.EaseOut},()=>this.readingExpanded=!this.readingExpanded))
      if(this.readingExpanded) {
      Button('位置预设',{type:ButtonType.Capsule,buttonStyle:ButtonStyleMode.NORMAL}).height(44).width('100%').fontColor(AppDesign.text(this.appDark)).backgroundColor(AppDesign.control(this.appDark)).onClick(()=>{
        this.getUIContext().getPromptAction().showActionMenu({systemMaterial:chromeMaterial(),title:'内容位置',buttons:[{text:'靠上',color:AppDesign.text(this.appDark)},{text:'居中',color:AppDesign.text(this.appDark)},{text:'靠下',color:AppDesign.text(this.appDark)}]})
          .then((result)=>this.onArrange(['top','center','bottom'][result.index])).catch(()=>{});
      })
      Text('阅读衬底').fontSize(13).fontColor(AppDesign.muted(this.appDark)).width('100%')
      SettingsSegmented({labels:['自动','融入底板','始终显示'],selectedIndex:Math.max(0,['auto','plain','surface'].indexOf(this.card.capability?.readingStyle??'auto')),appDark:this.appDark,
        onSelect:(index:number)=>this.onStyle(['auto','plain','surface'][index])})
      SettingsSegmented({labels:['柔光','衬光','描光'],selectedIndex:Math.max(0,['feather','scrim','halo'].indexOf(this.card.capability?.readingBlend??'feather')),appDark:this.appDark,
        onSelect:(index:number)=>this.onBlend(['feather','scrim','halo'][index])})
      Button('对比融合方案',{type:ButtonType.Capsule,buttonStyle:ButtonStyleMode.NORMAL}).height(44).width('100%').fontColor(AppDesign.text(this.appDark)).backgroundColor(AppDesign.control(this.appDark)).onClick(()=>this.onCompare())
      }
      if(readingWarning(this.card)) {Text(readingWarning(this.card)).fontSize(12).fontColor(AppDesign.muted(this.appDark)).width('100%')}
    }.width('100%').padding(16).backgroundColor(AppDesign.surface(this.appDark)).borderRadius(AppDesign.sectionRadius)
  }
}
