import { readingMaterialVariant } from '../model/MicaMaterialStudy';
import { hookReserve } from '../model/MicaGeometry';
import { ReadingHook } from './ReadingHook';
import { compositionPadding } from '../model/ReadingComposition';
import { ReadingBacking } from './ReadingBacking';
import { paperTextWidth } from '../model/PaperTextWidth';
import { readingHalo } from '../model/CapabilityPresentation';
import { CapBlock, AgendaItem } from '../model/CardSchema';
import { capabilityContentScale } from '../model/CapabilityMetrics';
import { eventWhen } from '../model/CapabilityData';
import { SummaryPresentation, summaryPresentation } from '../model/CapabilityPresentation';
/** Shared by the app, desktop and exports. Row count follows space; text keeps a legible hierarchy. */
@Component
export struct SummaryCapability {
  @Prop @Watch('refresh') cap: CapBlock = {k:'agenda'};
  @Prop @Watch('refresh') contentWidth: number = 164;
  @Prop @Watch('refresh') contentHeight: number = 136;
  @Prop @Watch('refresh') tick: number = 0;
  @Prop ink: string = '#262824';
  @Prop readingHaloEnabled: boolean = false;
  @Prop contentBackingEnabled:boolean=false;
  @Prop backingTint:string='#E8D6B0';
  @Prop backingEdge:string='';
  @Prop backingProfile:number[]=[];
  @Prop backingLeft:boolean=true;
  @Prop backingGutter:number=0;
  @Prop scaleFactor: number = 1;
  @State presentation: SummaryPresentation = new SummaryPresentation();
  aboutToAppear(): void { this.refresh(); }
  private refresh(): void { this.presentation = summaryPresentation(this.cap, this.contentHeight / this.contentScale(), this.tick || Date.now(),this.contentWidth / this.contentScale()); }
  private contentScale(): number { return Math.max(.001,capabilityContentScale(this.cap,this.contentWidth,this.contentHeight)); }
  private s(): number { return this.scaleFactor*this.contentScale(); }
  private backingWidth():number {
    if(this.presentation.columns>1)return (this.contentWidth+2*compositionPadding(this.cap.readingBlend??'')+this.backingGutter)*this.scaleFactor;
    if(this.backingProfile.length)return (this.contentWidth+2*compositionPadding(this.cap.readingBlend??'')+this.backingGutter)*this.scaleFactor;
    const s=this.s(),measure=(text:string,font:number):number=>paperTextWidth(text,font);
    let width=measure(this.presentation.heading,11*s)+(this.presentation.remaining?measure('+'+this.presentation.remaining,11*s)+8*s:0);
    if(!this.presentation.events.length)width=Math.max(width,measure(this.presentation.empty,16*s));
    for(const event of this.presentation.events)width=Math.max(width,measure(event.title,16*s),measure(eventWhen(event,this.tick||Date.now())+(event.location?' · '+event.location:''),11*s));
    return Math.min((this.contentWidth+2*compositionPadding(this.cap.readingBlend??''))*this.scaleFactor,Math.ceil(width)+2*compositionPadding(this.cap.readingBlend??'')*s);
  }
  @Builder private readingBackground() {if(this.contentBackingEnabled){ReadingBacking({study:readingMaterialVariant(this.cap.readingMaterialStudy,this.cap.readingMaterial),blend:this.cap.readingBlend??'feather',tint:this.backingTint,edge:this.backingEdge,profile:this.backingProfile,contactLeft:this.backingLeft,surfaceWidth:this.backingWidth(),surfaceHeight:(this.contentHeight+2*compositionPadding(this.cap.readingBlend??''))*this.scaleFactor,hook:this.cap.readingHook??.2,ink:this.ink,radius:8*this.s(),scaleFactor:this.s()})}}
  @Builder private readingHook() {if(this.contentBackingEnabled&&['tag','dock'].includes(this.cap.readingBlend??'')){ReadingHook({hook:this.cap.readingHook??.2,scaleFactor:this.s()})}}
  @State private backingHeight:number=0;
  build() {
    Column() {
    Stack({alignContent:Alignment.TopStart}) {
      if(this.contentBackingEnabled){Column(){this.readingBackground()}.width(this.backingWidth()).height(this.backingHeight).position({x:0,y:0}).hitTestBehavior(HitTestMode.None)}
    Column() {
    Column({space:8*this.s()}) {
      Row() {
        Text(this.presentation.heading).fontSize(11*this.s()).minFontScale(1).maxFontScale(1).fontColor(this.ink).textShadow(readingHalo(this.ink, this.s(), this.readingHaloEnabled,this.cap.readingBlend)).opacity(this.readingHaloEnabled?1:.65).maxLines(1).textOverflow({overflow:TextOverflow.Ellipsis}).layoutWeight(1)
        if(this.presentation.remaining>0) { Text('+'+this.presentation.remaining).fontSize(11*this.s()).minFontScale(1).maxFontScale(1).fontColor(this.ink).textShadow(readingHalo(this.ink, this.s(), this.readingHaloEnabled,this.cap.readingBlend)).opacity(this.readingHaloEnabled?1:.65) }
      }.width('100%').height(16*this.s())
      if(!this.presentation.events.length) {
        Text(this.presentation.empty).fontSize(16*this.s()).fontWeight(FontWeight.Medium).minFontScale(1).maxFontScale(1).fontColor(this.ink).textShadow(readingHalo(this.ink, this.s(), this.readingHaloEnabled,this.cap.readingBlend)).maxLines(2).textOverflow({overflow:TextOverflow.Ellipsis}).width('100%')
      }
      Grid() {
      ForEach(this.presentation.events,(e:AgendaItem)=>{
        GridItem() {Column({space:3*this.s()}) {
          Text(e.title).fontSize(16*this.s()).minFontSize(14*this.s()).maxFontSize(16*this.s()).maxLines(1).textOverflow({overflow:TextOverflow.Ellipsis}).fontWeight(FontWeight.Medium).minFontScale(1).maxFontScale(1).fontColor(this.ink).textShadow(readingHalo(this.ink, this.s(), this.readingHaloEnabled,this.cap.readingBlend)).width('100%')
          Text(eventWhen(e,this.tick||Date.now())+(e.location?' · '+e.location:'')).fontSize(11*this.s()).minFontScale(1).maxFontScale(1).fontColor(this.ink).textShadow(readingHalo(this.ink, this.s(), this.readingHaloEnabled,this.cap.readingBlend)).opacity(this.readingHaloEnabled?1:.65).maxLines(1).textOverflow({overflow:TextOverflow.Ellipsis}).width('100%')
        }.width('100%').height(40*this.s()).alignItems(HorizontalAlign.Start)}
      },(e:AgendaItem)=>e.id)
      }.columnsTemplate(this.presentation.columns===2?'1fr 1fr':'1fr').columnsGap(12*this.s()).rowsGap(8*this.s()).width('100%')
        .height(Math.max(0,Math.ceil(this.presentation.events.length/this.presentation.columns)*48-8)*this.s()).scrollBar(BarState.Off)
    }.width(this.contentBackingEnabled?Math.max(1,this.backingWidth()-2*compositionPadding(this.cap.readingBlend??'')*this.s()-this.backingGutter*this.scaleFactor):'100%')
    }.width(this.contentBackingEnabled?this.backingWidth():'100%').height(this.backingProfile.length?'100%':this.contentBackingEnabled?undefined:'100%').padding({left:this.contentBackingEnabled?compositionPadding(this.cap.readingBlend??'')*this.s()+(this.backingLeft?this.backingGutter*this.scaleFactor:0):0,right:this.contentBackingEnabled?compositionPadding(this.cap.readingBlend??'')*this.s()+(!this.backingLeft?this.backingGutter*this.scaleFactor:0):0,bottom:this.contentBackingEnabled?compositionPadding(this.cap.readingBlend??'')*this.s():0,top:this.contentBackingEnabled?compositionPadding(this.cap.readingBlend??'')*this.s()+hookReserve(this.cap.readingBlend??'')*this.s():0})
      .onSizeChange((_:SizeOptions,size:SizeOptions)=>{const h=Number(size.height);if(h>0&&Math.abs(h-this.backingHeight)>.01)this.backingHeight=h;}).justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Start)
      if(this.contentBackingEnabled&&['tag','dock'].includes(this.cap.readingBlend??'')){Column(){this.readingHook()}.width(this.backingWidth()).height(this.backingHeight).position({x:0,y:0}).hitTestBehavior(HitTestMode.None)}
    }.width(this.contentBackingEnabled?this.backingWidth():'100%').height(this.backingProfile.length?'100%':this.contentBackingEnabled?undefined:'100%')
    }.width('100%').height('100%').justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
  }
}
