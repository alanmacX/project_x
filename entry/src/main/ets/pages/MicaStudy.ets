import { common } from '@kit.AbilityKit';
import { taskpool } from '@kit.ArkTS';
import { AppDesign } from '../model/AppDesign';
import { FridgeStore } from '../model/FridgeModel';
import { cardSource } from '../model/BackgroundInputs';
import { sampleMicaStudyTint } from '../model/MicaStudyWorker';
import { MICA_STUDY_LABELS, MICA_STUDY_NOTES } from '../model/MicaMaterialStudy';
import { ReadingBacking } from '../views/ReadingBacking';
import { ReadingHook } from '../views/ReadingHook';
import { immersiveChrome } from '../model/ChromeMaterial';
/** Read-only native material comparison on a controlled yellow shape or the same local photograph. */
@Entry
@Component
struct MicaStudy {
 @StorageLink('appDark') dark:boolean=false;
 @StorageLink('safeTop') safeTop:number=24;
 @StorageLink('safeBottom') safeBottom:number=20;
 @State source:string='';
 @State tint:string='#E8D6B0';
 @State pageWidth:number=390;
 @State message:string='';
 @State localPhoto:boolean=false;
 private sampleTint():string {return this.localPhoto?this.tint:'#EDC03E';}
 private subjectPath():string {const u=vp2px(1);return `M ${54*u} ${8*u} C ${115*u} ${-8*u} ${177*u} ${15*u} ${174*u} ${70*u} C ${199*u} ${120*u} ${175*u} ${159*u} ${129*u} ${158*u} C ${90*u} ${172*u} ${35*u} ${147*u} ${31*u} ${104*u} C ${-3*u} ${67*u} ${17*u} ${24*u} ${54*u} ${8*u} Z`;}
 private alive:boolean=true;
 aboutToAppear():void {this.load();}
 aboutToDisappear():void {this.alive=false;}
 private async load():Promise<void> {
  let src=AppStorage.get<string>('micaStudySource')??'';AppStorage.delete('micaStudySource');
  if(!src) {
   const store=new FridgeStore();
   try {await store.init(this.getUIContext().getHostContext() as common.UIAbilityContext);src=store.state.cards.map((c)=>cardSource(c)).find((s:string)=>s.startsWith('file://'))??'';}catch(_){}
  }
  if(!this.alive)return;
  if(!src){this.message='请从带本地照片的卡片进入材质对比';return;}
  try {const tint=await taskpool.execute(new taskpool.Task(sampleMicaStudyTint,src)) as string;if(this.alive){this.tint=tint;this.source=src;}}catch(_){this.message='本地照片暂时无法读取';}
 }
 private tileWidth():number {return this.pageWidth>=720?(this.pageWidth-64)/3:this.pageWidth-32;}
 @Builder
 specimen(variant:number,blend:string,label:string) {
  Column({space:8}) {
   Text(label).fontSize(14).fontWeight(FontWeight.Medium).fontColor(AppDesign.text(this.dark)).width('100%')
   Stack() {
    if(this.localPhoto) {Image(this.source).width('100%').height('100%').objectFit(ImageFit.Cover).draggable(false)}
    else {
     Path().commands(this.subjectPath()).fill('#EBC13F').stroke('#FFFEF6').strokeWidth(3).antiAlias(true)
      .width(196).height(170).scale({x:.82,y:.82})
     Ellipse().width(100).height(88).fill('#26FFF4B2').translate({x:-12,y:8})
    }
    if(blend==='bare') {
     Stack() {
      ReadingBacking({blend:'bare',study:variant,tint:this.sampleTint(),surfaceWidth:178,surfaceHeight:74,scaleFactor:1}).width('100%').height('100%')
      Text('20:45').fontSize(42).fontWeight(FontWeight.Medium).fontColor('#10100C')
     }.width(178).height(74)
    } else {
     Stack({alignContent:Alignment.TopStart}) {
      ReadingBacking({blend:'tag',study:variant,tint:this.sampleTint(),hook:.25,surfaceWidth:172,surfaceHeight:112,scaleFactor:1}).width('100%').height('100%')
      Column({space:2}) {
       Text('周末旅行').fontSize(15).fontWeight(FontWeight.Medium).fontColor('#10100C')
       Row({space:4}) {Text('55').fontSize(42).fontWeight(FontWeight.Medium).fontColor('#10100C');Text('天').fontSize(16).fontColor('#10100C')}.alignItems(VerticalAlign.Bottom)
      }.width('100%').padding({top:26,left:10,right:10,bottom:8})
      ReadingHook({hook:.25,scaleFactor:1})
     }.width(172).height(112).rotate({angle:-6})
    }
   }.width('100%').height(150).backgroundColor('#EEE7D9').borderRadius(18).clip(true)
  }.width('100%')
 }
 @Builder
 variant(index:number) {
  Column({space:10}) {
   Text(MICA_STUDY_LABELS[index]).fontSize(19).fontWeight(FontWeight.Medium).fontColor(AppDesign.text(this.dark)).width('100%')
   Text(MICA_STUDY_NOTES[index]).fontSize(12).fontColor(AppDesign.muted(this.dark)).width('100%')
   this.specimen(index,'bare','笔触')
   this.specimen(index,'tag','挂钩')
  }.width(this.tileWidth()).padding(16).backgroundColor(AppDesign.surface(this.dark)).borderRadius(22)
 }
 build() {
  Column({space:16}) {
   Row({space:12}) {
    Button({type:ButtonType.Circle,buttonStyle:ButtonStyleMode.NORMAL}) {SymbolGlyph($r('sys.symbol.chevron_left')).fontSize(20).fontColor([AppDesign.text(this.dark)])}
     .width(44).height(44).backgroundColor(AppDesign.control(this.dark)).attributeModifier(immersiveChrome(this.dark)).onClick(()=>this.getUIContext().getRouter().back())
    Column({space:3}) {Text('衬底材质 · 实际渲染').fontSize(20).fontWeight(FontWeight.Medium).fontColor(AppDesign.text(this.dark));Text('原生材质分层 · 不保存到画布').fontSize(12).fontColor(AppDesign.muted(this.dark))}.alignItems(HorizontalAlign.Start)
   }.width('100%').padding({left:16,right:16})
   Row({space:8}) {
    Button('黄色异形底板',{type:ButtonType.Capsule}).fontColor(this.localPhoto?'#45443E':'#FFFFFF').backgroundColor(this.localPhoto?'#EFEADD':'#45443E').onClick(()=>this.localPhoto=false)
    Button('本地照片对照',{type:ButtonType.Capsule}).fontColor(this.localPhoto?'#FFFFFF':'#45443E').backgroundColor(this.localPhoto?'#45443E':'#EFEADD').onClick(()=>this.localPhoto=true)
   }.padding({left:16,right:16}).width('100%')
   Button('试边缘轮廓',{type:ButtonType.Capsule}).fontColor(AppDesign.text(this.dark)).backgroundColor(AppDesign.surface(this.dark)).onClick(()=>this.getUIContext().getRouter().pushUrl({url:'pages/ReadingEdgeStudy'}))
   Scroll() {
    if(!this.localPhoto||this.source) {
     if(this.pageWidth>=720){Row({space:16}){ForEach([1,2,3],(i:number)=>{this.variant(i)},(i:number)=>String(i))}.padding(16)}
     else {Column({space:16}){ForEach([1,2,3],(i:number)=>{this.variant(i)},(i:number)=>String(i))}.padding(16)}
    } else {Text(this.message).fontColor(AppDesign.muted(this.dark)).padding(24)}
   }.layoutWeight(1).width('100%').scrollBar(BarState.Off)
  }.width('100%').height('100%').padding({top:this.safeTop+12,bottom:this.safeBottom}).backgroundColor(AppDesign.background(this.dark))
   .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.TOP,SafeAreaEdge.BOTTOM]).onAreaChange((_:Area,a:Area)=>this.pageWidth=Number(a.width))
 }
}
