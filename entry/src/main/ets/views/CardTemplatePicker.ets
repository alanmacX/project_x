import { CARD_TEMPLATES, TemplateDefinition } from '../model/CardTemplate';
import { FridgeCard } from '../model/CardSchema';
import { makeTemplateCards } from '../model/TemplateFactory';
import { CAPABILITY_CATALOG, CapabilityDescriptor } from '../model/CapabilityCatalog';
import { TemplateFace } from './TemplateFace';
import { SettingsSegmented } from './SettingsSegmented';
import { AppDesign } from '../model/AppDesign';
@Component
export struct CardTemplatePicker {
  @Prop appDark:boolean=false;
  onChoose:(id:string)=>void=()=>{};
  onCreative:()=>void=()=>{};
  @State tab:number=0;
  @State category:string='clock';
  @State gridWidth:number=300;
  private tick:number=Date.now();
  private columns():number{return this.gridWidth>=860?4:this.gridWidth>=620?3:2;}
  private thumbnailSize():number{return Math.max(48,Math.min(180,(this.gridWidth-(this.columns()-1)*8)/this.columns()-16));}
  private card(id:string):FridgeCard {return makeTemplateCards(id,1,()=>id,this.tick)[0];}
  private recipe(id:string):FridgeCard[]{let index=0;return makeTemplateCards(id,1,()=>id+String(++index),this.tick);}
  private items():TemplateDefinition[]{return CARD_TEMPLATES.filter(item=>item.kind===this.category);}
  build(){
    Column({space:16}){
      Row(){Text('添加卡片').fontSize(20).fontWeight(FontWeight.Medium).fontColor(AppDesign.text(this.appDark)).layoutWeight(1);Blank().width(48)}.height(44).width('100%')
      SettingsSegmented({labels:['模板','创作'],selectedIndex:this.tab,appDark:this.appDark,onSelect:(i:number)=>{this.tab=i;}})
      Swiper(){
        Column({space:16}){
          Scroll(){Row({space:8}){ForEach(CAPABILITY_CATALOG,(item:CapabilityDescriptor)=>{Button(item.name,{type:ButtonType.Capsule,buttonStyle:ButtonStyleMode.NORMAL}).height(34).fontSize(13).fontColor(this.category===item.key?AppDesign.background(this.appDark):AppDesign.text(this.appDark)).backgroundColor(this.category===item.key?AppDesign.text(this.appDark):AppDesign.control(this.appDark)).onClick(()=>{this.category=item.key;})});Button('组合',{type:ButtonType.Capsule,buttonStyle:ButtonStyleMode.NORMAL}).height(34).fontSize(13).fontColor(this.category==='ensemble'?AppDesign.background(this.appDark):AppDesign.text(this.appDark)).backgroundColor(this.category==='ensemble'?AppDesign.text(this.appDark):AppDesign.control(this.appDark)).onClick(()=>{this.category='ensemble';})}}.scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off).width('100%')
          Grid(){ForEach(this.items(),(item:TemplateDefinition)=>{GridItem(){Button({type:ButtonType.ROUNDED_RECTANGLE,buttonStyle:ButtonStyleMode.NORMAL}){Column({space:8}){
            Stack({alignContent:Alignment.TopStart}){if(item.kind==='ensemble'){ForEach(this.recipe(item.id),(card:FridgeCard)=>{TemplateFace({card:card,scaleFactor:this.thumbnailSize()/344,tick:this.tick}).width(card.w*this.thumbnailSize()/344).height(card.h*this.thumbnailSize()/344).position({x:card.x*this.thumbnailSize()/344,y:card.y*this.thumbnailSize()/470}).clip(true)})}else{TemplateFace({card:this.card(item.id),scaleFactor:this.thumbnailSize()/260,tick:this.tick})}}.width(this.thumbnailSize()).height(this.thumbnailSize()).borderRadius(20).clip(true)
            Text(item.name).fontSize(14).fontColor(AppDesign.text(this.appDark))
          }.padding(8).width('100%')}.backgroundColor(Color.Transparent).onClick(()=>this.onChoose(item.id))}} ,(item:TemplateDefinition)=>item.id)}.columnsTemplate(this.columns()===4?'1fr 1fr 1fr 1fr':this.columns()===3?'1fr 1fr 1fr':'1fr 1fr').columnsGap(8).rowsGap(12).layoutWeight(1).width('100%').onAreaChange((_before:Area,after:Area)=>{this.gridWidth=Number(after.width);})
        }.width('100%').height('100%')
        Column({space:24}){
          Blank()
          SymbolGlyph($r('sys.symbol.plus')).fontSize(54).fontColor([AppDesign.text(this.appDark)])
          Text('从一张空白卡片开始').fontSize(20).fontColor(AppDesign.text(this.appDark))
          Button('自由创作',{type:ButtonType.Capsule}).height(48).padding({left:28,right:28}).fontColor(AppDesign.background(this.appDark)).backgroundColor(AppDesign.text(this.appDark)).onClick(()=>this.onCreative())
          Blank()
        }.width('100%').height('100%')
      }.index(this.tab).indicator(false).loop(false).onChange((i:number)=>{this.tab=i;}).layoutWeight(1)
    }.padding(20).width('100%').height('100%').backgroundColor(AppDesign.background(this.appDark))
  }
}
