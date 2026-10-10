import { READING_COMPOSITIONS, READING_COMPOSITION_LABELS, compositionPlacement, compositionOverflow, readingStyles } from '../model/ReadingComposition';
import { MICA_STUDY_NOTES } from '../model/MicaMaterialStudy';
import { sampleMicaStudyTint } from '../model/MicaStudyWorker';
import { cardSource } from '../model/BackgroundInputs';
import { taskpool } from '@kit.ArkTS';
import { common } from '@kit.AbilityKit';
import { FridgeCard } from '../model/CardSchema';
import { cardViewSnapshot, cardRenderSnapshot } from '../model/CardViewSnapshot';
import { prepareSubjectDepth } from '../model/SubjectDepthCache';
import { AppDesign } from '../model/AppDesign';
import { CardFace } from './CardFace';
import { SettingsSelect } from './SettingsSelect';
@Component
export struct ReadingComparison {
  @Prop card:FridgeCard=new FridgeCard();
  @Prop appDark:boolean=false;
  @State sample:FridgeCard=new FridgeCard();
  @State selected:number=0;
  @State materialStudy:number=5;
  private sampledTint:string='';
  @State panelWidth:number=320;
  @State panelHeight:number=420;
  private tick:number=Date.now();
  private alive:boolean=true;
  private prepareTimer:number=-1;
  private generation:number=0;
  aboutToAppear():void {
    this.choose(Math.max(0,this.styles().indexOf(this.card.capability?.readingBlend??'')));
    const src=cardSource(this.card);
    if(src.startsWith('file://'))taskpool.execute(new taskpool.Task(sampleMicaStudyTint,src)).then((value:Object)=>{
      if(!this.alive)return;this.sampledTint=String(value);this.updateMaterial();
    }).catch(()=>{});
  }
  private updateMaterial():void {
    const sample=cardViewSnapshot(this.sample);
    if(sample.capability){sample.capability.readingMaterialStudy=this.materialStudy;if(this.sampledTint)sample.capability.readingTint=this.sampledTint;}
    this.sample=cardRenderSnapshot(sample);
  }
  aboutToDisappear():void {this.alive=false;this.generation++;if(this.prepareTimer>=0)clearTimeout(this.prepareTimer);}
  private styles():string[] {return readingStyles(this.card.capability?.k??'');}
  private labels():string[] {return this.styles().map((s:string)=>READING_COMPOSITION_LABELS[READING_COMPOSITIONS.indexOf(s)]);}
  private choose(index:number):void {
    this.selected=index;
    const sample=cardViewSnapshot(this.card);
    if(sample.capability){sample.capability.readingStyle='surface';sample.capability.readingBlend=this.styles()[index];sample.capability.readingMaterialStudy=this.materialStudy;if(this.sampledTint)sample.capability.readingTint=this.sampledTint;}
    sample.capFree=true;if(sample.capability)sample.capBox=compositionPlacement(sample,sample.capBox,sample.capability.readingBlend??'');this.sample=cardRenderSnapshot(sample);
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
  private previewHeight():number {return Math.max(90,Math.min(250,this.panelHeight-260));}
  private sampleScale():number {const o=compositionOverflow(this.sample,1);return Math.max(.05,Math.min((this.panelWidth-64)/(this.sample.w+o.left+o.right),(this.previewHeight()-24)/(this.sample.h+o.top+o.bottom)));}
  build() {
    Scroll() {
    Column({space:12}) {
      Text('融合方案对比').fontSize(20).fontWeight(FontWeight.Medium).fontColor(AppDesign.text(this.appDark)).width('100%').padding({right:40})
      SettingsSelect({labels:this.labels(),selectedIndex:this.selected,appDark:this.appDark,onSelect:(index:number)=>this.choose(index)})
      SettingsSelect({labels:['现有','轻透磨砂','暖白细纸'],selectedIndex:this.materialStudy===0?0:this.materialStudy-3,appDark:this.appDark,onSelect:(index:number)=>{this.materialStudy=index===0?0:index+3;this.updateMaterial();}})
      Text(MICA_STUDY_NOTES[this.materialStudy]).fontSize(12).fontColor(AppDesign.muted(this.appDark)).width('100%')
      Stack() {CardFace({card:this.sample,scaleFactor:this.sampleScale(),tick:this.tick}).width(this.sample.w*this.sampleScale()).height(this.sample.h*this.sampleScale()).translate({x:(compositionOverflow(this.sample,1).left-compositionOverflow(this.sample,1).right)*this.sampleScale()/2,y:(compositionOverflow(this.sample,1).top-compositionOverflow(this.sample,1).bottom)*this.sampleScale()/2})}
        .width('100%').height(this.previewHeight()).backgroundColor(AppDesign.surface(this.appDark)).borderRadius(20)
    }.width('100%').padding({left:20,right:20,top:16,bottom:24})
    }.width('100%').height('100%').align(Alignment.Top).scrollBar(BarState.Off)
      .onAreaChange((_:Area,area:Area)=>{const width=Number(area.width),height=Number(area.height);if(width!==this.panelWidth||height!==this.panelHeight){this.panelWidth=width;this.panelHeight=height;this.queueDepth();}})
  }
}
