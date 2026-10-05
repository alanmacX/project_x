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
  @Prop scaleFactor: number = 1;
  @State presentation: SummaryPresentation = new SummaryPresentation();
  aboutToAppear(): void { this.refresh(); }
  private refresh(): void { this.presentation = summaryPresentation(this.cap, this.contentHeight / this.contentScale(), this.tick || Date.now()); }
  private contentScale(): number { return Math.max(.001,capabilityContentScale(this.cap,this.contentWidth,this.contentHeight)); }
  private s(): number { return this.scaleFactor*this.contentScale(); }
  build() {
    Column({space:8*this.s()}) {
      Row() {
        Text(this.presentation.heading).fontSize(11*this.s()).fontColor(this.ink).textShadow(readingHalo(this.ink, this.s(), this.readingHaloEnabled)).opacity(.65).maxLines(1).textOverflow({overflow:TextOverflow.Ellipsis}).layoutWeight(1)
        if(this.presentation.remaining>0) { Text('+'+this.presentation.remaining).fontSize(11*this.s()).fontColor(this.ink).textShadow(readingHalo(this.ink, this.s(), this.readingHaloEnabled)).opacity(.65) }
      }.width('100%').height(16*this.s())
      if(!this.presentation.events.length) {
        Text(this.presentation.empty).fontSize(16*this.s()).fontWeight(FontWeight.Medium).fontColor(this.ink).textShadow(readingHalo(this.ink, this.s(), this.readingHaloEnabled)).maxLines(2).textOverflow({overflow:TextOverflow.Ellipsis}).width('100%')
      }
      ForEach(this.presentation.events,(e:AgendaItem)=>{
        Column({space:3*this.s()}) {
          Text(e.title).fontSize(16*this.s()).minFontSize(14*this.s()).maxFontSize(16*this.s()).maxLines(1).textOverflow({overflow:TextOverflow.Ellipsis}).fontWeight(FontWeight.Medium).fontColor(this.ink).textShadow(readingHalo(this.ink, this.s(), this.readingHaloEnabled)).width('100%')
          Text(eventWhen(e,this.tick||Date.now())+(e.location?' · '+e.location:'')).fontSize(11*this.s()).fontColor(this.ink).textShadow(readingHalo(this.ink, this.s(), this.readingHaloEnabled)).opacity(.65).maxLines(1).textOverflow({overflow:TextOverflow.Ellipsis}).width('100%')
        }.width('100%').height(40*this.s()).alignItems(HorizontalAlign.Start)
      },(e:AgendaItem)=>e.id)
    }.width('100%').height('100%').justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Start)
  }
}
