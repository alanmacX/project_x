import { common } from '@kit.AbilityKit';
import { FridgeCard } from '../model/CardSchema';
import { cardViewSnapshot, cardRenderSnapshot } from '../model/CardViewSnapshot';
import { prepareSubjectDepth } from '../model/SubjectDepthCache';
import { AppDesign } from '../model/AppDesign';
import { CardFace } from './CardFace';
import { SettingsSegmented } from './SettingsSegmented';
@Component
export struct ReadingComparison {
  @Prop card:FridgeCard=new FridgeCard();
  @Prop appDark:boolean=false;
  @State sample:FridgeCard=new FridgeCard();
  @State selected:number=0;
  @State panelWidth:number=320;
  @State panelHeight:number=420;
  private tick:number=Date.now();
  private alive:boolean=true;
  private prepareTimer:number=-1;
  private generation:number=0;
  aboutToAppear():void {this.choose(0);}
  aboutToDisappear():void {this.alive=false;this.generation++;if(this.prepareTimer>=0)clearTimeout(this.prepareTimer);}
  private choose(index:number):void {
    this.selected=index;
    const sample=cardViewSnapshot(this.card);
    if(sample.capability){sample.capability.readingStyle='surface';sample.capability.readingBlend=['paper','feather','scrim','halo'][index];}
    this.sample=cardRenderSnapshot(sample);
    this.queueDepth();
  }
  private queueDepth():void {
    const generation=++this.generation;
    if(this.prepareTimer>=0)clearTimeout(this.prepareTimer);
    if(this.sample.shape!=='subject')return;
    // Wait for sheet measurement / resize to settle; do not bake an initial guessed size.
    this.prepareTimer=setTimeout(()=>{
      this.prepareTimer=-1;
      const ctx=this.getUIContext().getHostContext() as common.UIAbilityContext;
      if(!ctx||!this.alive)return;
      prepareSubjectDepth([this.sample],this.sampleScale(),ctx.cacheDir,this.getUIContext().vp2px(1)).then(()=>{
        if(this.alive&&generation===this.generation)this.sample=cardRenderSnapshot(this.sample);
      }).catch(()=>{});
    },32);
  }
  private previewHeight():number {return Math.max(90,Math.min(250,this.panelHeight-180));}
  private sampleScale():number {return Math.max(.05,Math.min((this.panelWidth-64)/this.sample.w,(this.previewHeight()-24)/this.sample.h));}
  build() {
    Scroll() {
    Column({space:12}) {
      Text('融合方案对比').fontSize(20).fontWeight(FontWeight.Medium).fontColor(AppDesign.text(this.appDark)).width('100%').padding({right:40})
      SettingsSegmented({labels:['薄纸','柔光','衬光','描光'],selectedIndex:this.selected,appDark:this.appDark,onSelect:(index:number)=>this.choose(index)})
      Stack() {CardFace({card:this.sample,scaleFactor:this.sampleScale(),tick:this.tick}).width(this.sample.w*this.sampleScale()).height(this.sample.h*this.sampleScale())}
        .width('100%').height(this.previewHeight()).backgroundColor(AppDesign.surface(this.appDark)).borderRadius(20)
      Text(['半透米白薄纸与轻纸纹，透出底图色彩','柔化文字周围的纹理，保留较多底图','提高文字附近的对比，适合杂乱照片','保留底图，用细描光托住文字'][this.selected]).fontSize(13).fontColor(AppDesign.muted(this.appDark)).width('100%').maxLines(2)
    }.width('100%').padding({left:20,right:20,top:16,bottom:24})
    }.width('100%').height('100%').align(Alignment.Top).scrollBar(BarState.Off)
      .onAreaChange((_:Area,area:Area)=>{const width=Number(area.width),height=Number(area.height);if(width!==this.panelWidth||height!==this.panelHeight){this.panelWidth=width;this.panelHeight=height;this.queueDepth();}})
  }
}
