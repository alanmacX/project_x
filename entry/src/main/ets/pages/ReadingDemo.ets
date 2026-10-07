import { READING_COMPOSITIONS, READING_COMPOSITION_LABELS, READING_COMPOSITION_NOTES, compositionPlacement, compositionOverflow } from '../model/ReadingComposition';
import { prepareSubjectDepth } from '../model/SubjectDepthCache';
import { common } from '@kit.AbilityKit';
import { FridgeCard } from '../model/CardSchema';
import { cardViewSnapshot, cardRenderSnapshot } from '../model/CardViewSnapshot';
import { AppDesign } from '../model/AppDesign';
import { CardFace } from '../views/CardFace';
import { immersiveChrome } from '../model/ChromeMaterial';
/** Read-only, same-source comparison. Nothing is saved or applied to the canvas here. */
@Entry
@Component
struct ReadingDemo {
  @StorageLink('appDark') dark:boolean=false;
  @StorageLink('safeTop') safeTop:number=24;
  @StorageLink('safeBottom') safeBottom:number=20;
  @State pageWidth:number=360;
  @State pageHeight:number=720;
  @State samples:FridgeCard[]=[];
  private tick:number=Date.now();
  private pending:FridgeCard[]=[];
  private alive:boolean=true;
  private timer:number=-1;
  aboutToAppear():void {
    const source=AppStorage.get<FridgeCard>('readingDemoCard');
    if(!source?.capability)return;
    this.pending=READING_COMPOSITIONS.map((blend:string)=>{const c=cardViewSnapshot(source);c.outline=[];c.renderContourKey=source.renderContourKey;c.capability!.readingStyle='surface';c.capability!.readingBlend=blend;c.capFree=true;c.capBox=compositionPlacement(c,c.capBox,blend);return cardRenderSnapshot(c);});
    this.timer=setTimeout(()=>{this.timer=-1;this.prepare();},400);
    AppStorage.delete('readingDemoCard');
  }
  aboutToDisappear():void {this.alive=false;if(this.timer>=0)clearTimeout(this.timer);}
  private async prepare():Promise<void> {
    const ctx=this.getUIContext().getHostContext() as common.UIAbilityContext;
    const card=this.pending[0];if(!card)return;
    await prepareSubjectDepth([card],this.sampleScale(card),ctx.cacheDir,this.getUIContext().vp2px(1));
    if(this.alive)this.mount();
  }
  private mount():void {
    if(!this.alive||this.samples.length>=this.pending.length)return;
    this.samples=this.pending.slice(0,this.samples.length+1);
    this.timer=setTimeout(()=>{this.timer=-1;this.mount();},32);
  }
  private landscape():boolean {return this.pageWidth>this.pageHeight;}
  private sampleWidth():number {return this.landscape()?(this.pageWidth-80)/4:this.pageWidth-32;}
  private previewHeight():number {return this.landscape()?Math.max(200,this.pageHeight-this.safeTop-this.safeBottom-230):230;}
  private sampleScale(card:FridgeCard):number {const o=compositionOverflow(card,1);return Math.min((this.sampleWidth()-48)/(card.w+o.left+o.right),(this.previewHeight()-40)/(card.h+o.top+o.bottom));}
  @Builder
  sample(card:FridgeCard,index:number) {
    Column({space:12}) {
      Stack() {CardFace({card:card,scaleFactor:this.sampleScale(card),tick:this.tick}).width(card.w*this.sampleScale(card)).height(card.h*this.sampleScale(card)).translate({x:(compositionOverflow(card,1).left-compositionOverflow(card,1).right)*this.sampleScale(card)/2,y:(compositionOverflow(card,1).top-compositionOverflow(card,1).bottom)*this.sampleScale(card)/2})}
        .width('100%').height(this.previewHeight()).renderGroup(true).backgroundColor(AppDesign.background(this.dark)).borderRadius(16)
      Text(READING_COMPOSITION_LABELS[index]).fontSize(17).fontWeight(FontWeight.Medium).fontColor(AppDesign.text(this.dark)).width('100%')
      Text(READING_COMPOSITION_NOTES[index]).fontSize(13).fontColor(AppDesign.muted(this.dark)).width('100%')
    }.width(this.sampleWidth()).padding(16).backgroundColor(AppDesign.surface(this.dark)).borderRadius(20)
  }
  build() {
    Column({space:16}) {
      Row({space:12}) {
        Button({type:ButtonType.Circle,buttonStyle:ButtonStyleMode.NORMAL}) {SymbolGlyph($r('sys.symbol.chevron_left')).fontSize(20).fontColor([AppDesign.text(this.dark)])}
          .width(44).height(44).backgroundColor(AppDesign.surface(this.dark)).attributeModifier(immersiveChrome(this.dark)).accessibilityText('返回卡片编辑').onClick(()=>this.getUIContext().getRouter().back())
        Column({space:4}) {Text('融合方案对比').fontSize(20).fontWeight(FontWeight.Medium).fontColor(AppDesign.text(this.dark));Text('相同底图与内容 · 比较小字和照片细节').fontSize(12).fontColor(AppDesign.muted(this.dark))}.alignItems(HorizontalAlign.Start).layoutWeight(1)
      }.width('100%').padding({left:16,right:16})
      Scroll() {
        if(this.landscape()) {Row({space:16}) {ForEach(this.samples,(c:FridgeCard,i:number)=>{this.sample(c,i)},(_c:FridgeCard,i:number)=>String(i))}.padding({left:16,right:16,bottom:16})}
        else {Column({space:16}) {ForEach(this.samples,(c:FridgeCard,i:number)=>{this.sample(c,i)},(_c:FridgeCard,i:number)=>String(i))}.padding({left:16,right:16,bottom:16})}
      }.layoutWeight(1).width('100%').scrollBar(BarState.Off).scrollable(this.landscape()?ScrollDirection.Horizontal:ScrollDirection.Vertical)
    }.width('100%').height('100%').padding({top:this.safeTop+12,bottom:this.safeBottom}).backgroundColor(AppDesign.background(this.dark))
      .expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.TOP,SafeAreaEdge.BOTTOM]).onAreaChange((_old:Area,a:Area)=>{this.pageWidth=Number(a.width);this.pageHeight=Number(a.height);})
  }
}
