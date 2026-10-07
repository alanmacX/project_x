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
  @Prop scaleFactor: number = 1;
  @State presentation: SummaryPresentation = new SummaryPresentation();
  aboutToAppear(): void { this.refresh(); }
  private refresh(): void { this.presentation = summaryPresentation(this.cap, this.contentHeight / this.contentScale(), this.tick || Date.now()); }
  private contentScale(): number { return Math.max(.001,capabilityContentScale(this.cap,this.contentWidth,this.contentHeight)); }
  private s(): number { return this.scaleFactor*this.contentScale(); }
  private backingWidth():number {
    const s=this.s(),measure=(text:string,font:number):number=>paperTextWidth(this.getUIContext(),text,font);
    let width=measure(this.presentation.heading,11*s)+(this.presentation.remaining?measure('+'+this.presentation.remaining,11*s)+8*s:0);
    if(!this.presentation.events.length)width=Math.max(width,measure(this.presentation.empty,16*s));
    for(const event of this.presentation.events)width=Math.max(width,measure(event.title,16*s),measure(eventWhen(event,this.tick||Date.now())+(event.location?' · '+event.location:''),11*s));
    return Math.min((this.contentWidth+8)*this.scaleFactor,Math.ceil(width)+8*s);
  }
  @Builder private readingBackground() {if(this.contentBackingEnabled){ReadingBacking({blend:this.cap.readingBlend??'feather',ink:this.ink,radius:8*this.s(),scaleFactor:this.scaleFactor})}}
  build() {
    Column() {
    Column({space:8*this.s()}) {
      Row() {
        Text(this.presentation.heading).fontSize(11*this.s()).fontColor(this.ink).textShadow(readingHalo(this.ink, this.s(), this.readingHaloEnabled,this.cap.readingBlend)).opacity(this.readingHaloEnabled?1:.65).maxLines(1).textOverflow({overflow:TextOverflow.Ellipsis}).layoutWeight(1)
        if(this.presentation.remaining>0) { Text('+'+this.presentation.remaining).fontSize(11*this.s()).fontColor(this.ink).textShadow(readingHalo(this.ink, this.s(), this.readingHaloEnabled,this.cap.readingBlend)).opacity(this.readingHaloEnabled?1:.65) }
      }.width('100%').height(16*this.s())
      if(!this.presentation.events.length) {
        Text(this.presentation.empty).fontSize(16*this.s()).fontWeight(FontWeight.Medium).fontColor(this.ink).textShadow(readingHalo(this.ink, this.s(), this.readingHaloEnabled,this.cap.readingBlend)).maxLines(2).textOverflow({overflow:TextOverflow.Ellipsis}).width('100%')
      }
      ForEach(this.presentation.events,(e:AgendaItem)=>{
        Column({space:3*this.s()}) {
          Text(e.title).fontSize(16*this.s()).minFontSize(14*this.s()).maxFontSize(16*this.s()).maxLines(1).textOverflow({overflow:TextOverflow.Ellipsis}).fontWeight(FontWeight.Medium).fontColor(this.ink).textShadow(readingHalo(this.ink, this.s(), this.readingHaloEnabled,this.cap.readingBlend)).width('100%')
          Text(eventWhen(e,this.tick||Date.now())+(e.location?' · '+e.location:'')).fontSize(11*this.s()).fontColor(this.ink).textShadow(readingHalo(this.ink, this.s(), this.readingHaloEnabled,this.cap.readingBlend)).opacity(this.readingHaloEnabled?1:.65).maxLines(1).textOverflow({overflow:TextOverflow.Ellipsis}).width('100%')
        }.width('100%').height(this.contentBackingEnabled?undefined:40*this.s()).alignItems(HorizontalAlign.Start)
      },(e:AgendaItem)=>e.id)
    }.width(this.contentBackingEnabled?this.backingWidth():'100%').height(this.contentBackingEnabled?undefined:'100%').padding(this.contentBackingEnabled?4*this.s():0)
      .background(this.readingBackground).justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Start)
    }.width('100%').height('100%').justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
  }
}
