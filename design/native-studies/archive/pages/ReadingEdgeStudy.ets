import { AppDesign } from '../model/AppDesign';
import { EDGE_STUDY_NAMES, edgeStudyInset } from '../model/ReadingEdgeStudy';
import { ReadingEdgeBacking } from '../views/ReadingEdgeBacking';
import { immersiveChrome } from '../model/ChromeMaterial';
@Entry
@Component
struct ReadingEdgeStudy {
 @StorageLink('appDark') dark:boolean=false;
 @StorageLink('safeTop') safeTop:number=24;
 @StorageLink('safeBottom') safeBottom:number=20;
 @State pageWidth:number=390;
 @State compact:boolean=false;
 private w():number {return this.compact?160:210;}
 private h(brief:boolean):number {return brief?(this.compact?148:166):(this.compact?90:106);}
 private tileWidth():number {return this.pageWidth>=720?(this.pageWidth-64)/3:this.pageWidth-32;}
 @Builder
 sample(kind:number,brief:boolean) {
  Stack() {
   // Same restrained colour/material for all samples; only the contour changes.
   Rect().width(130).height('90%').fill('#E9BB46').radius(25).rotate({angle:-9}).translate({x:-24})
   Stack() {
    ReadingEdgeBacking({kind:kind,surfaceWidth:this.w(),surfaceHeight:this.h(brief)})
    if(brief) {
     Column({space:6}) {
      Row({space:6}) {Text('课程表').fontSize(this.compact?12:14).lineHeight(this.compact?16:18).fontWeight(FontWeight.Medium);Text('10.8').fontSize(this.compact?12:14).lineHeight(this.compact?16:18).fontColor('#8B826C')}.width('100%')
      ForEach(['14:00  软件工程','16:00  计算机网络','19:00  健身'],(item:string,i:number)=>{
       Text(item).fontSize(this.compact?11:13).lineHeight(this.compact?14:17).fontColor('#302D25').width('100%').padding({left:7,top:4,bottom:4}).backgroundColor(i===0?'#70EBC455':'#50FFFFFF').borderRadius(8)
      },(item:string)=>item)
     }.padding(edgeStudyInset(this.w(),this.h(brief))).width(this.w())
    } else {
     Column({space:2}) {Text('20:45').fontSize(this.compact?30:38).fontWeight(FontWeight.Medium).fontColor('#302D25');Text('北京 · 周四').fontSize(this.compact?10:12).fontColor('#756B56')}
    }
   }.width(this.w()).height(this.h(brief)).rotate({angle:brief?-3:0})
  }.width('100%').height(brief?190:136).backgroundColor('#EDE7DA').borderRadius(18)
 }
 @Builder
 tile(kind:number) {
  Column({space:12}) {
   Text(EDGE_STUDY_NAMES[kind]).fontSize(19).fontWeight(FontWeight.Medium).fontColor(AppDesign.text(this.dark)).width('100%')
   Text(kind===0?'大弧度云瓣，轮廓柔软':kind===1?'微幅起伏，保留手工质感':'少量不对称，更安静克制').fontSize(12).fontColor(AppDesign.muted(this.dark)).width('100%')
   this.sample(kind,false)
   this.sample(kind,true)
  }.padding(16).width(this.tileWidth()).backgroundColor(AppDesign.surface(this.dark)).borderRadius(22)
 }
 build() {
  Column({space:12}) {
   Row({space:12}) {
    Button({type:ButtonType.Circle,buttonStyle:ButtonStyleMode.NORMAL}) {SymbolGlyph($r('sys.symbol.chevron_left')).fontSize(20).fontColor([AppDesign.text(this.dark)])}
     .width(44).height(44).backgroundColor(AppDesign.control(this.dark)).attributeModifier(immersiveChrome(this.dark)).onClick(()=>this.getUIContext().getRouter().back())
    Column({space:3}) {Text('衬底轮廓 · 原生对比').fontSize(20).fontWeight(FontWeight.Medium).fontColor(AppDesign.text(this.dark));Text('统一材质，先看形状 · 不保存到画布').fontSize(12).fontColor(AppDesign.muted(this.dark))}.alignItems(HorizontalAlign.Start)
   }.width('100%').padding({left:16,right:16})
   Row({space:12}) {Text('小尺寸检验').fontSize(14).fontColor(AppDesign.text(this.dark));Toggle({type:ToggleType.Switch,isOn:this.compact}).onChange((value:boolean)=>this.compact=value)}.width('100%').padding({left:20,right:20})
   Scroll() {
    if(this.pageWidth>=720){Row({space:16}) {ForEach([0,1,2],(kind:number)=>{this.tile(kind)},(kind:number)=>String(kind))}.padding(16)}
    else {Column({space:16}) {ForEach([0,1,2],(kind:number)=>{this.tile(kind)},(kind:number)=>String(kind))}.padding(16)}
   }.layoutWeight(1).width('100%').scrollBar(BarState.Off)
  }.width('100%').height('100%').padding({top:this.safeTop+12,bottom:this.safeBottom}).backgroundColor(AppDesign.background(this.dark))
   .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.TOP,SafeAreaEdge.BOTTOM]).onAreaChange((_:Area,a:Area)=>this.pageWidth=Number(a.width))
 }
}
