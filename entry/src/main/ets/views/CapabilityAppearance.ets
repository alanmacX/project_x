import { FridgeCard, materialColors } from '../model/CardSchema';
import { readingWarning } from '../model/CapabilityPresentation';
import { AppDesign } from '../model/AppDesign';
import { ColorSetting } from './ColorSetting';
import { SettingsSegmented } from './SettingsSegmented';
/** All capabilities use this inspector. Data-specific controls never redefine appearance or gestures. */
@Component
export struct CapabilityAppearance {
  @Prop card:FridgeCard=new FridgeCard();
  @Prop appDark:boolean=false;
  onCompare:()=>void=()=>{};
  onBlend:(blend:string)=>void=()=>{};
  onArrange:(anchor:string)=>void=()=>{};
  onStyle:(style:string)=>void=()=>{};
  onColor:()=>void=()=>{};
  onColorPick:(color:string,key:string)=>void=()=>{};
  private ink():string {return this.card.shape==='subject'&&this.card.subjectPhoto&&!this.card.ink?this.card.subjectInk:materialColors(this.card.material,this.card.paper,this.card.ink)[1];}
  build() {
    Column({space:12}) {
      Text('能力排版').fontSize(16).fontWeight(FontWeight.Medium).fontColor(AppDesign.text(this.appDark)).width('100%')
      Text('在预览中拖动、缩放；字号与信息量自动适配').fontSize(12).fontColor(AppDesign.muted(this.appDark)).width('100%')
      Row({space:8}) {
        ForEach(['top','center','bottom'],(anchor:string,index:number)=>{
          Button(['靠上','居中','靠下'][index],{type:ButtonType.Capsule, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL}).height(44).layoutWeight(1).fontSize(13).backgroundColor(AppDesign.control(this.appDark)).fontColor(AppDesign.text(this.appDark)).onClick(()=>this.onArrange(anchor))
        },(anchor:string)=>anchor)
      }.width('100%')
      Text('阅读衬底').fontSize(13).fontColor(AppDesign.muted(this.appDark)).width('100%')
      SettingsSegmented({labels:['自动','融入底板','始终显示'],selectedIndex:Math.max(0,['auto','plain','surface'].indexOf(this.card.capability?.readingStyle??'auto')),appDark:this.appDark,
        onSelect:(index:number)=>this.onStyle(['auto','plain','surface'][index])})
      SettingsSegmented({labels:['柔光','衬光','描光'],selectedIndex:Math.max(0,['feather','scrim','halo'].indexOf(this.card.capability?.readingBlend??'feather')),appDark:this.appDark,
        onSelect:(index:number)=>this.onBlend(['feather','scrim','halo'][index])})
      Button('对比融合方案',{type:ButtonType.Capsule,buttonStyle:ButtonStyleMode.NORMAL}).height(44).width('100%').fontColor(AppDesign.text(this.appDark)).backgroundColor(AppDesign.control(this.appDark)).onClick(()=>this.onCompare())
      ColorSetting({label:'内容颜色',color:this.ink(),automatic:!this.card.ink,sourceKey:this.card.id+':ink:',appDark:this.appDark,
        onPick:(color:string,key:string)=>this.onColorPick(color,key),onFallback:()=>this.onColor()})
      if(readingWarning(this.card)) {Text(readingWarning(this.card)).fontSize(12).fontColor(AppDesign.muted(this.appDark)).width('100%')}
    }.width('100%').padding(16).backgroundColor(AppDesign.surface(this.appDark)).borderRadius(AppDesign.sectionRadius)
  }
}
