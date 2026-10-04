import { CapabilityAppearance } from '../../views/CapabilityAppearance';
import { CapabilityView } from '../../views/CapBlockView';
import { CapabilityPicker } from '../../views/CapabilityPicker';
import { CapabilitySettings } from '../../views/CapabilitySettings';
import { CapabilityDetails } from '../../views/CapabilityDetails';
import { ParcelImportDialog } from '../../views/ParcelImportDialog';
import { AppDesign } from '../../model/AppDesign';
import { CapBlock, FridgeCard, ParcelItem } from '../../model/CardSchema';
import { CardFace } from '../../views/CardFace';
import { capabilityPreset, ensureCapabilitySize } from '../../model/CanvasLayout';
@Entry
@Component
struct CardFrameworkQA {
  @State dark:boolean=false;
  @State mode:string='summary';
  @State place:string='center';
  @State cap:CapBlock={k:'parcel',readingStyle:'surface',parcelPlace:'东门菜鸟驿站',parcels:[
    {id:'1',code:'2-1234',place:'东门菜鸟驿站',picked:false},
    {id:'2',code:'9-4567',place:'西门丰巢快递柜',picked:false},
    {id:'3',code:'88-9900',place:'大学城三号取件点',picked:false},
    {id:'4',code:'A2-7788',place:'中央教学楼自提点',picked:false},
    {id:'5',code:'8-6677',place:'南门菜鸟驿站',picked:false}
  ]};
  private dialog:CustomDialogController|undefined=undefined;
  private tick:number=new Date('2026-10-04T09:00:00').getTime();
  private choose():void {this.dialog=new CustomDialogController({builder:CapabilityPicker({appDark:this.dark,selected:this.cap.k,onChoose:(key:string)=>{this.cap={k:key};}}),customStyle:true});this.dialog.open();}
  private notice():void {this.dialog=new CustomDialogController({builder:ParcelImportDialog({appDark:this.dark,initialText:'请到东门菜鸟驿站，取件码【２－１２３４】。请至西门丰巢快递柜，取件码 9-4567。',onImport:(items:ParcelItem[])=>{this.cap={k:'parcel',parcels:items};}}),customStyle:true});this.dialog.open();}
  private card():FridgeCard {const card=new FridgeCard();card.id='qa';card.shape='blob';card.material='cream';card.w=240;card.h=280;card.capability=this.cap;ensureCapabilitySize(card);card.capBox=capabilityPreset(card,this.place);return card;}
  build() {
    Column({space:16}) {
      Text('v32 卡片框架 QA').fontSize(20).fontColor(AppDesign.text(this.dark)).margin({top:50})
      Row({space:8}) {ForEach(['summary','settings','details'],(mode:string)=>{Button(mode,{type:ButtonType.Capsule}).height(44).fontSize(12).onClick(()=>this.mode=mode)},(mode:string)=>mode)}
      Row({space:8}) {Button('日夜',{type:ButtonType.Capsule}).height(44).onClick(()=>this.dark=!this.dark);Button('选择能力',{type:ButtonType.Capsule}).height(44).onClick(()=>this.choose());Button('通知导入',{type:ButtonType.Capsule}).height(44).onClick(()=>this.notice());}
      Scroll() {
        Column({space:16}) {
          if(this.mode==='summary') {
            Text('最小阅读区域 120×82').fontColor(AppDesign.text(this.dark))
            CapabilityView({cap:this.cap,contentWidth:120,contentHeight:82,tick:this.tick}).width(120).height(82).backgroundColor('#F6F2E9').borderRadius(12)
            Text('更大空间显示更多包裹 · 164×136').fontColor(AppDesign.text(this.dark))
            CapabilityView({cap:this.cap,contentWidth:164,contentHeight:136,tick:this.tick}).width(164).height(136).backgroundColor('#F6F2E9').borderRadius(12)
            CardFace({card:this.card(),tick:this.tick}).width(240).height(280)
          } else if(this.mode==='settings') {
            Column() {CapabilitySettings({cap:this.cap,cardId:'qa',appDark:this.dark,onUpdate:(_:string,cap:CapBlock)=>this.cap=cap})}.width('100%').padding(16).backgroundColor(AppDesign.surface(this.dark)).borderRadius(20)
            CapabilityAppearance({card:this.card(),appDark:this.dark,onArrange:(anchor:string)=>{this.place=anchor;},onStyle:(style:string)=>{const cap=JSON.parse(JSON.stringify(this.cap)) as CapBlock;cap.readingStyle=style;this.cap=cap;}})
          } else {
            CapabilityDetails({cap:this.cap,appDark:this.dark,tick:this.tick,onUpdate:(cap:CapBlock)=>this.cap=cap})
          }
        }.width('100%').padding(16)
      }.width('100%').layoutWeight(1).align(Alignment.Top).scrollBar(BarState.Off)
    }.width('100%').height('100%').padding({bottom:24}).backgroundColor(AppDesign.background(this.dark))
  }
}
