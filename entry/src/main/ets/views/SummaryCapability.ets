import { CapBlock, AgendaItem, ParcelItem } from '../model/CardSchema';
import { eventWhen } from '../model/CapabilityData';
import { SummaryPresentation, summaryPresentation } from '../model/CapabilityPresentation';
/** Shared by the app, desktop and exports. Row count follows space; text keeps a legible hierarchy. */
@Component
export struct SummaryCapability {
  @Prop @Watch('refresh') cap: CapBlock = {k:'parcel'};
  @Prop @Watch('refresh') contentHeight: number = 136;
  @Prop @Watch('refresh') tick: number = 0;
  @Prop ink: string = '#262824';
  @Prop scaleFactor: number = 1;
  @State presentation: SummaryPresentation = new SummaryPresentation();
  aboutToAppear(): void { this.refresh(); }
  private refresh(): void { this.presentation = summaryPresentation(this.cap, this.contentHeight, this.tick || Date.now()); }
  build() {
    Column({space:8*this.scaleFactor}) {
      Row() {
        Text(this.presentation.heading).fontSize(11*this.scaleFactor).fontColor(this.ink).opacity(.65).maxLines(1).textOverflow({overflow:TextOverflow.Ellipsis}).layoutWeight(1)
        if(this.presentation.remaining>0) { Text('+'+this.presentation.remaining).fontSize(11*this.scaleFactor).fontColor(this.ink).opacity(.65) }
      }.width('100%').height(16*this.scaleFactor)
      if(!this.presentation.parcels.length && !this.presentation.events.length) {
        Text(this.presentation.empty).fontSize(16*this.scaleFactor).fontWeight(FontWeight.Medium).fontColor(this.ink).maxLines(2).textOverflow({overflow:TextOverflow.Ellipsis}).width('100%')
      }
      ForEach(this.presentation.parcels,(p:ParcelItem)=>{
        Column({space:3*this.scaleFactor}) {
          Text(p.code).fontSize(22*this.scaleFactor).minFontSize(16*this.scaleFactor).maxFontSize(22*this.scaleFactor).maxLines(1).textOverflow({overflow:TextOverflow.Ellipsis}).fontWeight(FontWeight.Medium).fontColor(this.ink).width('100%')
          Text(p.place||'未填写地点').fontSize(11*this.scaleFactor).fontColor(this.ink).opacity(.65).maxLines(1).textOverflow({overflow:TextOverflow.Ellipsis}).width('100%')
        }.width('100%').height(40*this.scaleFactor).alignItems(HorizontalAlign.Start)
      },(p:ParcelItem)=>p.id)
      ForEach(this.presentation.events,(e:AgendaItem)=>{
        Column({space:3*this.scaleFactor}) {
          Text(e.title).fontSize(16*this.scaleFactor).minFontSize(14*this.scaleFactor).maxFontSize(16*this.scaleFactor).maxLines(1).textOverflow({overflow:TextOverflow.Ellipsis}).fontWeight(FontWeight.Medium).fontColor(this.ink).width('100%')
          Text(eventWhen(e,this.tick||Date.now())+(e.location?' · '+e.location:'')).fontSize(11*this.scaleFactor).fontColor(this.ink).opacity(.65).maxLines(1).textOverflow({overflow:TextOverflow.Ellipsis}).width('100%')
        }.width('100%').height(40*this.scaleFactor).alignItems(HorizontalAlign.Start)
      },(e:AgendaItem)=>e.id)
    }.width('100%').height('100%').justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Start)
  }
}
