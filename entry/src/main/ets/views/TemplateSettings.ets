import { compositionSlot, compositionDefinition } from '../model/CompositionCatalog';
import { FridgeCard } from '../model/CardSchema';
import { templateColors } from '../model/TemplateScene';
import { CARD_TEMPLATES, TemplateDefinition, newCardTemplate } from '../model/CardTemplate';
import { AppDesign } from '../model/AppDesign';
import { SettingsSegmented } from './SettingsSegmented';
@Component
export struct TemplateSettings {
  @Prop card:FridgeCard=new FridgeCard();
  @Prop appDark:boolean=false;
  @Prop processing:boolean=false;
  onDesign:(id:string)=>void=()=>{};
  onPalette:(value:string)=>void=()=>{};
  onFill:(value:boolean)=>void=()=>{};
  onBackground:(value:string)=>void=()=>{};
  onPhoto:()=>void=()=>{};
  onPhotoEdit:()=>void=()=>{};
  onCutout:()=>void=()=>{};
  private photographic():boolean{return ['portrait','anniversary-photo','face-memory-photo','mix-memory'].includes(this.card.template?.id??'');}
  private supportsDepth():boolean{return ['portrait','face-memory-photo','mix-memory'].includes(this.card.template?.id??'');}
  private hasPhoto():boolean{return this.card.elements.some(e=>e.kind==='image'&&e.src.length>0);}
  private hasSubject():boolean{return this.card.elements.some(e=>e.kind==='image'&&e.depthEnabled&&e.depthForeground.length>0);}
  private paletteColors(p:string):string[]{const card=new FridgeCard();card.template=newCardTemplate(this.card.template?.id??'');card.template.palette=p;return templateColors(card);}
  build(){
    Column({space:18}){
      if(compositionDefinition(this.card.template?.id??'')||compositionSlot(this.card.template?.id??'')){
        Text(compositionDefinition(this.card.template?.id??'')?.name??compositionSlot(this.card.template?.id??'')?.role??'').fontSize(16).fontColor(AppDesign.text(this.appDark)).width('100%')
      }else{
        Scroll(){Row({space:8}){ForEach(CARD_TEMPLATES.filter(t=>t.kind===this.card.capability?.k),(item:TemplateDefinition)=>{
          Button(item.name,{type:ButtonType.Capsule,buttonStyle:ButtonStyleMode.NORMAL}).height(38).fontSize(14).fontColor(this.card.template?.id===item.id?AppDesign.background(this.appDark):AppDesign.text(this.appDark)).backgroundColor(this.card.template?.id===item.id?AppDesign.text(this.appDark):AppDesign.control(this.appDark)).onClick(()=>this.onDesign(item.id))
        })}}.width('100%').scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off)
      }
      if(this.photographic()){
        Row({space:12}){
          Button(this.hasPhoto()?'更换照片':'选择照片',{type:ButtonType.Capsule,buttonStyle:ButtonStyleMode.NORMAL}).fontColor(AppDesign.text(this.appDark)).backgroundColor(AppDesign.control(this.appDark)).enabled(!this.processing).onClick(()=>this.onPhoto())
          if(this.processing){LoadingProgress().width(20).height(20);Text('处理主体中').fontSize(13).fontColor(AppDesign.text(this.appDark))}
          else if(this.supportsDepth()&&this.hasPhoto()&&!this.hasSubject()){Button('提取主体',{type:ButtonType.Capsule,buttonStyle:ButtonStyleMode.NORMAL}).fontColor(AppDesign.text(this.appDark)).backgroundColor(AppDesign.control(this.appDark)).onClick(()=>this.onCutout())}
        }.width('100%')
        if(this.supportsDepth()&&this.hasPhoto()){Button(this.card.template?.id==='portrait'?'调整照片与时间':'调整照片',{type:ButtonType.Capsule,buttonStyle:ButtonStyleMode.NORMAL}).fontColor(AppDesign.text(this.appDark)).backgroundColor(AppDesign.control(this.appDark)).enabled(!this.processing).onClick(()=>this.onPhotoEdit())}
      }
      Row({space:12}){Text('配色').fontSize(15).fontColor(AppDesign.text(this.appDark));ForEach(['','cream','cobalt','ink'],(p:string,index:number)=>{
        Button({type:ButtonType.Circle,buttonStyle:ButtonStyleMode.NORMAL}){if((this.card.template?.palette??'')===p){SymbolGlyph($r('sys.symbol.checkmark')).fontSize(14).fontColor([this.paletteColors(p)[1]])}}
          .width(38).height(38).backgroundColor(this.paletteColors(p)[0]).border({width:1,color:'#40808080'}).accessibilityText(['原色','奶油','钴蓝','墨色'][index]).onClick(()=>this.onPalette(p))
      })}.width('100%')
      if(!compositionSlot(this.card.template?.id??'')){
        Row(){Text('铺满画布').fontSize(15).fontColor(AppDesign.text(this.appDark)).layoutWeight(1);Toggle({type:ToggleType.Switch,isOn:this.card.template?.fill===true}).onChange((v:boolean)=>this.onFill(v))}.width('100%')
        if(this.card.template?.fill){SettingsSegmented({labels:['模板底色','智能多色'],selectedIndex:this.card.template?.background==='smart'?1:0,appDark:this.appDark,onSelect:(i:number)=>this.onBackground(i===1?'smart':'template')})}
      }

    }.width('100%').padding(16).backgroundColor(AppDesign.surface(this.appDark)).borderRadius(20)
  }
}
