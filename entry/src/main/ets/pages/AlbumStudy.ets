import { AlbumCapability } from '../views/AlbumCapability';
import { AppDesign } from '../model/AppDesign';
import { FridgeStore } from '../model/FridgeModel';
import { CapBlock } from '../model/CardSchema';
import { fileIo } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { SettingsSegmented } from '../views/SettingsSegmented';
@Entry
@Component
struct AlbumStudy {
 @StorageLink('appDark') dark:boolean=false;
 @StorageLink('safeTop') safeTop:number=24;
 @StorageLink('safeBottom') safeBottom:number=20;
 @State pageWidth:number=390;
 @State cap:CapBlock={k:'album'};
 @State content:number=0;
 private ctx():common.UIAbilityContext {return this.getUIContext().getHostContext() as common.UIAbilityContext;}
 aboutToAppear():void {this.content=AppStorage.get<number>('albumStudyContent')??0;this.load();}
 private async load():Promise<void> {
  const ctx=this.ctx();
  if(await fileIo.access(ctx.cacheDir+'/album_study_cover.jpg')) {
   this.cap={k:'album',albumCover:'file://'+ctx.cacheDir+'/album_study_cover.jpg',albumBackground:'file://'+ctx.cacheDir+'/album_study_background.png',title:'Dangerously in Love',artist:'Beyoncé'};return;
  }
  const store=new FridgeStore();await store.init(ctx);
  const current=store.state.cards.find((card)=>card.capability?.k==='album')?.capability;
  if(current?.albumCover)this.cap=JSON.parse(JSON.stringify(current)) as CapBlock;
 }
 private sampleCap():CapBlock {return {k:'album',albumCover:this.cap.albumCover,albumBackground:this.cap.albumBackground,title:this.content===1?'A Very Long Album Name · 很长的专辑名称测试':this.content===2?'':this.cap.title,artist:this.content===1?'多位歌手与合作音乐人 / Featured Artists':this.content===2?'':this.cap.artist};}
 private sampleSize():number {return this.pageWidth>760?Math.min(244,(this.pageWidth-160)/4):Math.min(250,(this.pageWidth-64)/2);}
 @Builder sample(style:string,label:string,note:string) {
  Column({space:12}) {
   Stack() {
    AlbumCapability({cap:this.sampleCap(),cardWidth:style==='row'?280:208,cardHeight:style==='row'?180:208,scaleFactor:this.sampleSize()/(style==='row'?280:208),presentation:style})
     .width(this.sampleSize()).height(style==='row'?this.sampleSize()*180/280:this.sampleSize()).borderRadius(20*this.sampleSize()/(style==='row'?280:208)).clip(true).shadow({radius:12,color:'#20000000',offsetY:5})
   }.width(this.sampleSize()).height(this.sampleSize())
   Text(label).fontSize(16).fontWeight(FontWeight.Medium).fontColor(AppDesign.text(this.dark)).width(this.sampleSize())
   Text(note).fontSize(12).fontColor(AppDesign.muted(this.dark)).width(this.sampleSize()).maxLines(3)
  }.padding(12).borderRadius(20).backgroundColor(AppDesign.surface(this.dark))
 }
 build() {
  Column({space:16}) {
   Text('专辑样式 · 原生渲染对比').fontSize(22).fontWeight(FontWeight.Medium).fontColor(AppDesign.text(this.dark)).width('100%')
   SettingsSegmented({labels:['正常内容','长名称','未填写'],selectedIndex:this.content,appDark:this.dark,onSelect:(i:number)=>this.content=i})
   Scroll() {Flex({wrap:FlexWrap.Wrap,justifyContent:FlexAlign.Center}) {
    this.sample('cover','A · 现有纯封面','保持 4.9% 留边和当前圆角')
    this.sample('classic','B · 经典信息款','左上小封面，名称与歌手在下方')
    this.sample('portrait','C · 大封面信息款','封面优先，文字收在底部')
    this.sample('row','D · 并排紧凑款','封面与文字并列，适合横向卡')
   }}.layoutWeight(1).width('100%').scrollBar(BarState.Off)
   Text('候选页不修改现有卡片；最终仅保留纯封面＋你选的信息款。').fontSize(12).fontColor(AppDesign.muted(this.dark))
  }.width('100%').height('100%').padding({left:16,right:16,top:this.safeTop+12,bottom:this.safeBottom+12}).backgroundColor(AppDesign.background(this.dark)).onAreaChange((_o:Area,a:Area)=>this.pageWidth=Number(a.width))
 }
}
