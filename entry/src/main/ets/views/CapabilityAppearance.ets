import { FridgeCard, materialColors } from '../model/CardSchema';
import { readingWarning } from '../model/CapabilityPresentation';
import { AppDesign } from '../model/AppDesign';
/** All capabilities use this inspector. Data-specific controls never redefine appearance or gestures. */
@Component
export struct CapabilityAppearance {
  @Prop card:FridgeCard=new FridgeCard();
  @Prop appDark:boolean=false;
  onArrange:(anchor:string)=>void=()=>{};
  onStyle:(style:string)=>void=()=>{};
  onColor:()=>void=()=>{};
  private ink():string {return this.card.shape==='subject'&&this.card.subjectPhoto&&!this.card.ink?this.card.subjectInk:materialColors(this.card.material,this.card.paper,this.card.ink)[1];}
  build() {
    Column({space:12}) {
      Text('能力排版').fontSize(16).fontWeight(FontWeight.Medium).fontColor(AppDesign.text(this.appDark)).width('100%')
      Text('在预览中拖动、缩放；字号与信息量自动适配').fontSize(12).fontColor(AppDesign.muted(this.appDark)).width('100%')
      Row({space:8}) {
        ForEach(['top','center','bottom'],(anchor:string,index:number)=>{
          Button(['靠上','居中','靠下'][index],{type:ButtonType.Capsule}).height(44).layoutWeight(1).fontSize(13).backgroundColor(AppDesign.control(this.appDark)).fontColor(AppDesign.text(this.appDark)).onClick(()=>this.onArrange(anchor))
        },(anchor:string)=>anchor)
      }.width('100%')
      Text('阅读衬底').fontSize(13).fontColor(AppDesign.muted(this.appDark)).width('100%')
      Row({space:8}) {
        ForEach(['auto','plain','surface'],(style:string,index:number)=>{
          Button(['自动','融入底板','始终显示'][index],{type:ButtonType.Capsule}).height(44).layoutWeight(1).fontSize(13)
            .backgroundColor(AppDesign.choice(this.appDark,(this.card.capability?.readingStyle??'auto')===style)).fontColor(AppDesign.choiceText(this.appDark,(this.card.capability?.readingStyle??'auto')===style)).onClick(()=>this.onStyle(style))
        },(style:string)=>style)
      }.width('100%')
      Button({type:ButtonType.ROUNDED_RECTANGLE}) {
        Row({space:12}) {
          Text('内容颜色').fontSize(14).fontColor(AppDesign.text(this.appDark)).layoutWeight(1)
          Text(this.card.ink?'自定义':'自动').fontSize(12).fontColor(AppDesign.muted(this.appDark))
          Column().width(28).height(28).backgroundColor(this.ink()).border({width:.5,color:AppDesign.border(this.appDark)}).borderRadius(8)
        }.width('100%').padding({left:12,right:12})
      }.width('100%').height(48).backgroundColor(AppDesign.control(this.appDark)).borderRadius(12).accessibilityText('选择内容颜色').onClick(()=>this.onColor())
      if(readingWarning(this.card)) {Text(readingWarning(this.card)).fontSize(12).fontColor(AppDesign.muted(this.appDark)).width('100%')}
    }.width('100%').padding(16).backgroundColor(AppDesign.surface(this.appDark)).borderRadius(AppDesign.sectionRadius)
  }
}
