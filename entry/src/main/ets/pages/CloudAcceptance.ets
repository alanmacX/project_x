import preferences from '@ohos.data.preferences';
import { updateWidget } from '../model/WidgetSync';
import { common } from '@kit.AbilityKit';
import { AppDesign } from '../model/AppDesign';
import { CapBlock, FridgeCard, typeLabel, defaultState, BOARD_H, BOARD_W } from '../model/CardSchema';
import { FridgeStore } from '../model/FridgeModel';
import { CLOUD_ACCEPTANCE_GROUPS, CLOUD_ACCEPTANCE_TICK, cloudAcceptanceCard } from '../model/CloudAcceptanceFixtures';
import { CardFace } from '../views/CardFace';
import { SettingsSegmented } from '../views/SettingsSegmented';
import { immersiveChrome } from '../model/ChromeMaterial';
/** Acceptance uses the production CardFace → CardCanvas → capability renderers, not painted mock content. */
@Entry
@Component
struct CloudAcceptance {
 @StorageLink('appDark') dark:boolean=false;
 @StorageLink('safeTop') safeTop:number=24;
 @StorageLink('safeBottom') safeBottom:number=20;
 @State group:number=0;
 @State compact:boolean=false;
 @State empty:boolean=false;
 @State widget:boolean=false;
 @State pageWidth:number=390;
 @State album:CapBlock|null=null;
 @State delivery:string='';
 private store:FridgeStore=new FridgeStore();
 private testForms:Record<string,string>={};
 aboutToAppear():void {
  const store=this.store;store.init(this.getUIContext().getHostContext() as common.UIAbilityContext).then(()=>{this.album=store.state.cards.find((c)=>c.capability?.k==='album')?.capability??null;}).catch(()=>{});
 }
 // Hidden QA route: deliver transient fixtures without writing user canvases.
 private async sendToDesktop(restore:boolean=false):Promise<void> {
  try {
   if(restore){for(const id of Object.keys(this.testForms)){const original=await this.store.canvasSnapshot(this.testForms[id]);await updateWidget(id,JSON.stringify(original),'4*4');}this.testForms={};this.delivery='桌面已恢复';return;}
   const ctx=this.getUIContext().getHostContext() as common.UIAbilityContext;
   await preferences.removePreferencesFromCache(ctx,'fridge_store');
   const prefs=await preferences.getPreferences(ctx,'fridge_store');
   const dims=JSON.parse(await prefs.get('fridge_form_dims_json','{}') as string) as Record<string,string>;
   const bindings=JSON.parse(await prefs.get('fridge_form_bindings_json','{}') as string) as Record<string,string>;
   const keys=Object.keys(dims);if(!keys.length){this.delivery='请先添加桌面组件';return;}
   const kind=this.group===0?'calendar':this.group===1?'anniversary':this.group===2?'timetable':'battery-cloud';
   const state=defaultState(),card=this.card(kind);state.canvasAspect=1;state.background.color='#EEE7D9';
   card.x=(BOARD_W-card.w)/2;card.y=(BOARD_W-card.h)/2/BOARD_W*BOARD_H;state.cards=[card];
   for(const id of keys){this.testForms[id]=bindings[id]||this.store.state.canvasId;await updateWidget(id,JSON.stringify(state),dims[id]);}
   this.delivery='已发送：'+kind;
  }catch(_){this.delivery='桌面验收发送失败';}
 }
 private tileWidth():number {return this.pageWidth>=720?(this.pageWidth-80)/4:this.pageWidth-32;}
 private card(kind:string):FridgeCard {return cloudAcceptanceCard(kind,this.compact,this.empty,this.album);}
 private sampleScale(card:FridgeCard):number {return Math.min(1,(this.tileWidth()-40)/(card.w+72),230/(card.h+72));}
 @Builder
 sample(kind:string) {
  Column({space:10}) {
   Text(kind==='timetable-next'?'课程表 · 下一课':kind==='battery-cloud'?'电量 · 云朵':typeLabel(kind)).fontSize(16).fontWeight(FontWeight.Medium).fontColor(AppDesign.text(this.dark)).width('100%')
   Stack() {CardFace({card:this.card(kind),scaleFactor:this.sampleScale(this.card(kind)),tick:CLOUD_ACCEPTANCE_TICK,widget:this.widget}).width(this.card(kind).w*this.sampleScale(this.card(kind))).height(this.card(kind).h*this.sampleScale(this.card(kind)))}
    .width('100%').height(270).backgroundColor('#EEE7D9').borderRadius(18)
   Text(this.compact?'可读尺寸下限':'完整显示').fontSize(12).fontColor(AppDesign.muted(this.dark)).width('100%')
  }.padding(12).width(this.tileWidth()).backgroundColor(AppDesign.surface(this.dark)).borderRadius(22)
 }
 build() {
  Column({space:12}) {
   Row({space:12}) {
    Button({type:ButtonType.Circle,buttonStyle:ButtonStyleMode.NORMAL}) {SymbolGlyph($r('sys.symbol.chevron_left')).fontSize(20).fontColor([AppDesign.text(this.dark)])}.width(44).height(44).backgroundColor(AppDesign.control(this.dark)).attributeModifier(immersiveChrome(this.dark)).onClick(()=>this.getUIContext().getRouter().back())
    Text('柔软云朵 · 全能力验收').fontSize(20).fontWeight(FontWeight.Medium).fontColor(AppDesign.text(this.dark))
   }.width('100%').padding({left:16,right:16})
   SettingsSegmented({labels:['时间与日历','计划与进度','日程与课程','电量与专辑'],selectedIndex:this.group,appDark:this.dark,onSelect:(i:number)=>this.group=i}).padding({left:16,right:16})
   Row({space:14}) {
    Text('小尺寸').fontSize(12).fontColor(AppDesign.text(this.dark));Toggle({type:ToggleType.Switch,isOn:this.compact}).onChange((v:boolean)=>this.compact=v)
    Text('空内容').fontSize(12).fontColor(AppDesign.text(this.dark));Toggle({type:ToggleType.Switch,isOn:this.empty}).onChange((v:boolean)=>this.empty=v)
    Text('组件渲染').fontSize(12).fontColor(AppDesign.text(this.dark));Toggle({type:ToggleType.Switch,isOn:this.widget}).onChange((v:boolean)=>this.widget=v)
   }.width('100%').padding({left:20,right:20})
   Row({space:12}) {Button('发送桌面验收',{type:ButtonType.Capsule}).onClick(()=>this.sendToDesktop());Button('恢复桌面',{type:ButtonType.Capsule}).onClick(()=>this.sendToDesktop(true));Text(this.delivery).fontSize(12).fontColor(AppDesign.muted(this.dark))}.padding({left:20,right:20}).width('100%')
   Scroll() {
    if(this.pageWidth>=720){Row({space:16}){ForEach(CLOUD_ACCEPTANCE_GROUPS[this.group],(kind:string)=>{this.sample(kind)},(kind:string)=>kind)}.padding(16)}
    else {Column({space:16}){ForEach(CLOUD_ACCEPTANCE_GROUPS[this.group],(kind:string)=>{this.sample(kind)},(kind:string)=>kind)}.padding(16)}
   }.layoutWeight(1).width('100%').scrollBar(BarState.Off)
  }.width('100%').height('100%').padding({top:this.safeTop+12,bottom:this.safeBottom}).backgroundColor(AppDesign.background(this.dark))
   .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.TOP,SafeAreaEdge.BOTTOM]).onAreaChange((_:Area,a:Area)=>this.pageWidth=Number(a.width))
 }
}
