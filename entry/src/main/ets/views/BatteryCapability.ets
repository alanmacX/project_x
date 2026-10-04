import { readingHalo } from '../model/CapabilityPresentation';
import { CapBlock } from '../model/CardSchema';
import { batteryLevel, batteryStatus, batteryTint } from '../model/BatteryPresentation';
@Component
export struct BatteryCapability {
  @Prop cap:CapBlock={k:'battery'};
  @Prop ink:string='#262824';
  @Prop readingHaloEnabled: boolean = false;
  @Prop unit:number=1;
  @Prop compact:boolean=false;
  @Builder
  cell(width:number,height:number) {
    Row({space:2*this.unit}) {
      Stack({alignContent:Alignment.Start}) {
        Row().width('100%').height('100%').backgroundColor(this.ink).opacity(.06)
        Row().width(Math.max(0,batteryLevel(this.cap))+'%').height('100%').backgroundColor(batteryTint(this.cap,this.ink)).opacity(this.cap.refreshState==='failed'?.35:.9)
      }.width(width*this.unit).height(height*this.unit).padding(3*this.unit).border({width:1.3*this.unit,color:this.ink}).borderRadius(5*this.unit).clip(true)
      Row().width(3*this.unit).height(8*this.unit).borderRadius(2*this.unit).backgroundColor(this.ink).opacity(.4)
    }.height(height*this.unit)
  }
  @Builder
  percentage(font:number) {
    Row({space:1*this.unit}) {
      Text(batteryLevel(this.cap)<0?'—':String(batteryLevel(this.cap))).fontSize(font*this.unit).fontWeight(FontWeight.Medium).fontColor(this.ink).textShadow(readingHalo(this.ink, this.unit, this.readingHaloEnabled)).maxLines(1)
      if(batteryLevel(this.cap)>=0){Text('%').fontSize((this.compact?10:12)*this.unit).fontColor(this.ink).textShadow(readingHalo(this.ink, this.unit, this.readingHaloEnabled)).opacity(.55).margin({bottom:4*this.unit})}
    }.alignItems(VerticalAlign.Bottom)
  }
  build() {
    Column({space:5*this.unit}) {
      if(this.compact) {
        Row({space:6*this.unit}) {this.cell(26,18);this.percentage(22)}.justifyContent(FlexAlign.Center)
      } else {
        this.percentage(34)
        this.cell(100,24)
      }
      Text(batteryStatus(this.cap)).fontSize((this.compact?10:11)*this.unit).fontColor(this.ink).textShadow(readingHalo(this.ink, this.unit, this.readingHaloEnabled)).opacity(.6).maxLines(1)
    }.width('100%').height('100%').justifyContent(FlexAlign.Center)
  }
}
