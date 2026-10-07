import { HookPlacement } from './HookPlacement';
import { READING_COMPOSITIONS, READING_COMPOSITION_LABELS, READING_COMPOSITION_NOTES, compositionSuggestion, isReadingComposition, readingStyles } from '../model/ReadingComposition';
import { settingsDialogOpen, settingsReveal } from '../model/SettingsMotion';
import { FridgeCard, materialColors } from '../model/CardSchema';
import { readingWarning } from '../model/CapabilityPresentation';
import { capabilityDescriptor } from '../model/CapabilityCatalog';
import { chromeMaterial } from '../model/ChromeMaterial';
import { AppDesign } from '../model/AppDesign';
import { ColorSetting } from './ColorSetting';
import { SettingsSegmented } from './SettingsSegmented';
import { SettingsSelect } from './SettingsSelect';
/** All capabilities use this inspector. Data-specific controls never redefine appearance or gestures. */
@Component
export struct CapabilityAppearance {
  @Prop card:FridgeCard=new FridgeCard();
  @Prop appDark:boolean=false;
  @State readingExpanded:boolean=true;
  onChoose:()=>void=()=>{};
  onCompare:()=>void=()=>{};
  onHook:(position:number)=>void=()=>{};
  onBlend:(blend:string)=>void=()=>{};
  onArrange:(anchor:string)=>void=()=>{};
  onStyle:(style:string)=>void=()=>{};
  onColor:()=>void=()=>{};
  onColorPick:(color:string,key:string)=>void=()=>{};
  private styles():string[] {return readingStyles(this.card.capability?.k??'');}
  private labels():string[] {return this.styles().map((s:string)=>READING_COMPOSITION_LABELS[READING_COMPOSITIONS.indexOf(s)]);}
  private ink():string {return this.card.shape==='subject'&&this.card.subjectPhoto&&!this.card.ink?this.card.subjectInk:materialColors(this.card.material,this.card.paper,this.card.ink)[1];}
  build() {
    Column({space:12}) {
      Row({space:12}) {
        Column({space:4}) {
          Text(capabilityDescriptor(this.card.capability?.k??'none').name).fontSize(16).fontWeight(FontWeight.Medium).fontColor(AppDesign.text(this.appDark)).width('100%').maxLines(1).textOverflow({overflow:TextOverflow.Ellipsis})
          Text(capabilityDescriptor(this.card.capability?.k??'none').summary).fontSize(12).fontColor(AppDesign.muted(this.appDark)).width('100%').maxLines(2).textOverflow({overflow:TextOverflow.Ellipsis})
        }.layoutWeight(1)
        Button('更换',{type:ButtonType.Capsule,buttonStyle:ButtonStyleMode.NORMAL}).height(44).fontSize(13).backgroundColor(AppDesign.control(this.appDark)).fontColor(AppDesign.text(this.appDark)).onClick(()=>this.onChoose())
      }.width('100%')
      ColorSetting({label:'内容颜色',color:this.ink(),automatic:!this.card.ink,sourceKey:this.card.id+':ink:',appDark:this.appDark,
        onPick:(color:string,key:string)=>this.onColorPick(color,key),onFallback:()=>this.onColor()})
      if(this.card.capability?.k!=='album') {Text('在预览中拖动内容，用角落手柄放大；可自由摆放到卡片外；贴片与负空间靠近边框时只吸附最近一边。').fontSize(12).fontColor(AppDesign.muted(this.appDark)).width('100%')}
      if(this.card.capability?.k!=='album') {Button({type:ButtonType.Capsule,buttonStyle:ButtonStyleMode.NORMAL}) {
        Row(){Text('排版与可读性').fontSize(14).maxLines(1).layoutWeight(1).fontColor(AppDesign.text(this.appDark));Blank();SymbolGlyph($r('sys.symbol.chevron_down')).fontSize(14).fontColor([AppDesign.muted(this.appDark)]).rotate({angle:this.readingExpanded?180:0})}.width('100%').padding({left:12,right:12})
      }.width('100%').height(44).padding(0).backgroundColor(AppDesign.control(this.appDark)).onClick(()=>this.getUIContext().animateTo(settingsDialogOpen(),()=>this.readingExpanded=!this.readingExpanded))
      if(this.readingExpanded) {
      Column({space:12}) {
      Row({space:12}) {
        Text('位置').fontSize(14).fontColor(AppDesign.text(this.appDark)).width(48)
        SettingsSelect({labels:['靠上','居中','靠下'],selectedIndex:-1,valueLabel:'位置预设',appDark:this.appDark,
          onSelect:(index:number)=>this.onArrange(['top','center','bottom'][index])}).layoutWeight(1)
      }.width('100%')
      if(!isReadingComposition(this.card.capability?.readingBlend??'')) {Row({space:12}) {
        Text('衬底').fontSize(14).fontColor(AppDesign.text(this.appDark)).width(48)
        SettingsSelect({labels:['自动','融入底板','始终显示'],selectedIndex:Math.max(0,['auto','plain','surface'].indexOf(this.card.capability?.readingStyle??'auto')),appDark:this.appDark,
          onSelect:(index:number)=>this.onStyle(['auto','plain','surface'][index])}).layoutWeight(1)
      }.width('100%')}
      Row({space:12}) {
        Text('样式').fontSize(14).fontColor(AppDesign.text(this.appDark)).width(48)
        SettingsSelect({labels:this.labels(),selectedIndex:this.styles().indexOf(this.card.capability?.readingBlend??''),valueLabel:READING_COMPOSITIONS.includes(this.card.capability?.readingBlend??'')?'':'选择融合方式',appDark:this.appDark,
          onSelect:(index:number)=>this.onBlend(this.styles()[index])}).layoutWeight(1)
      }.width('100%')
      Text('建议：'+READING_COMPOSITION_LABELS[READING_COMPOSITIONS.indexOf(compositionSuggestion(this.card.capability?.k??''))]+' · 已筛选适合此能力的样式').fontSize(12).fontColor(AppDesign.muted(this.appDark)).width('100%')
      Text(READING_COMPOSITION_NOTES[Math.max(0,READING_COMPOSITIONS.indexOf(this.card.capability?.readingBlend??''))]).fontSize(12).fontColor(AppDesign.muted(this.appDark)).width('100%')
      if(['tag','dock'].includes(this.card.capability?.readingBlend??'')) {HookPlacement({hookLocation:this.card.capability?.readingHook??.2,appDark:this.appDark,onChoose:(p:number)=>this.onHook(p)})}
      Button('对比融合方案',{type:ButtonType.Capsule,buttonStyle:ButtonStyleMode.NORMAL}).height(44).width('100%').fontColor(AppDesign.text(this.appDark)).backgroundColor(AppDesign.control(this.appDark)).onClick(()=>this.onCompare())
      }.width('100%').transition(settingsReveal())
      }
      } else {Text('专辑保留专用封面与智能多色底板，不叠加信息衬底。').fontSize(12).fontColor(AppDesign.muted(this.appDark)).width('100%')}
      if(readingWarning(this.card)) {Text(readingWarning(this.card)).fontSize(12).fontColor(AppDesign.muted(this.appDark)).width('100%')}
    }.width('100%').padding(16).backgroundColor(AppDesign.surface(this.appDark)).borderRadius(AppDesign.sectionRadius)
  }
}
