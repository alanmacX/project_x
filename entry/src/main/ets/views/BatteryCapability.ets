import { readingHalo } from '../model/CapabilityPresentation';
import { CapBlock } from '../model/CardSchema';
import { batteryLevel, batteryStatus, batteryTint, batteryRingPath } from '../model/BatteryPresentation';
@Component
export struct BatteryCapability {
  @Prop cap:CapBlock={k:'battery'};
  @Prop ink:string='#262824';
  @Prop readingHaloEnabled:boolean=false;
  @Prop unit:number=1;
  @Prop compact:boolean=false;
  private diameter():number {return (this.compact?48:72)*this.unit;}
  private symbolSize():number {return (this.compact?15:22)*this.unit;}
  build() {
    Column({space:2*this.unit}) {
      Stack({alignContent:Alignment.TopStart}) {
        Path().commands(batteryRingPath(this.getUIContext().vp2px(this.diameter()))).fill(Color.Transparent).stroke(this.ink)
          .strokeWidth((this.compact?3.5:5)*this.unit).strokeLineCap(LineCapStyle.Round).opacity(.14)
          .width(this.diameter()).height(this.diameter())
        if(batteryLevel(this.cap)>0) {
          Path().commands(batteryRingPath(this.getUIContext().vp2px(this.diameter()),batteryLevel(this.cap))).fill(Color.Transparent).stroke(batteryTint(this.cap,this.ink))
            .strokeWidth((this.compact?3.5:5)*this.unit).strokeLineCap(LineCapStyle.Round).opacity(this.cap.refreshState==='failed'?.45:1)
            .width(this.diameter()).height(this.diameter())
        }
        SymbolGlyph($r('sys.symbol.bolt_fill')).fontSize((this.compact?15:22)*this.unit).fontColor([batteryTint(this.cap,this.ink)])
          .visibility(this.cap.charging||this.cap.chargeState==='full'?Visibility.Visible:Visibility.Hidden)
          .width(this.symbolSize()).height(this.symbolSize()).position({x:(this.diameter()-this.symbolSize())/2,y:this.diameter()*.34-this.symbolSize()/2}).hitTestBehavior(HitTestMode.None)
        Text(batteryLevel(this.cap)<0?'—':String(batteryLevel(this.cap))+'%').fontSize((this.compact?12:17)*this.unit).fontWeight(FontWeight.Medium)
          .fontColor(this.ink).textShadow(readingHalo(this.ink,this.unit,this.readingHaloEnabled,this.cap.readingBlend))
          .maxLines(1).width(this.diameter()).textAlign(TextAlign.Center).position({x:0,y:this.diameter()*.75})
      }.width(this.diameter()).height(this.diameter()+3*this.unit)
      if(!this.compact) {
        Text(batteryStatus(this.cap)).fontSize(11*this.unit).fontColor(this.ink)
          .textShadow(readingHalo(this.ink,this.unit,this.readingHaloEnabled,this.cap.readingBlend)).opacity(this.readingHaloEnabled?1:.65).maxLines(1)
      }
    }.width('100%').height('100%').justifyContent(FlexAlign.Center)
      .accessibilityText(batteryStatus(this.cap)+' '+(batteryLevel(this.cap)<0?'':batteryLevel(this.cap)+'%'))
  }
}
