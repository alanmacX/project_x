import { readingHalo } from '../model/CapabilityPresentation';
import { CapBlock } from '../model/CardSchema';
import { batteryLevel, batteryStatus, batteryTint, batteryRingPath, batteryArcLabel, BatteryArcGlyph } from '../model/BatteryPresentation';
@Component
export struct BatteryCapability {
  @Prop cap:CapBlock={k:'battery'};
  @Prop ink:string='#262824';
  @Prop readingHaloEnabled:boolean=false;
  @Prop unit:number=1;
  @Prop compact:boolean=false;
  private diameter():number {return (this.compact?48:72)*this.unit;}
  private labelFont():number {return (this.compact?10:14)*this.unit;}
  private label():string {return batteryLevel(this.cap)<0?'—':String(batteryLevel(this.cap));}
  private glyph(index:number):BatteryArcGlyph {return batteryArcLabel(this.diameter(),this.label(),this.labelFont())[index];}
  build() {
    Column() {
      Stack({alignContent:Alignment.TopStart}) {
        Path().commands(batteryRingPath(this.getUIContext().vp2px(this.diameter()))).fill(Color.Transparent).stroke(this.ink)
          .strokeWidth((this.compact?3.5:5)*this.unit).strokeLineCap(LineCapStyle.Round).opacity(.14)
          .width(this.diameter()).height(this.diameter())
        if(batteryLevel(this.cap)>0) {
          Path().commands(batteryRingPath(this.getUIContext().vp2px(this.diameter()),batteryLevel(this.cap))).fill(Color.Transparent).stroke(batteryTint(this.cap,this.ink))
            .strokeWidth((this.compact?3.5:5)*this.unit).strokeLineCap(LineCapStyle.Round).opacity(this.cap.refreshState==='failed'?.45:1)
            .width(this.diameter()).height(this.diameter())
        }
        Stack() {
          SymbolGlyph($r('sys.symbol.bolt_fill')).fontSize((this.compact?15:22)*this.unit).fontColor([batteryTint(this.cap,this.ink)])
            .visibility(this.cap.charging||this.cap.chargeState==='full'?Visibility.Visible:Visibility.Hidden)
        }.width(this.diameter()).height(this.diameter()).hitTestBehavior(HitTestMode.None)
        ForEach([0,1,2],(index:number)=>{
          if(index<this.label().length) {
          Text(this.label().charAt(index)).fontSize(this.labelFont()).fontWeight(FontWeight.Medium).fontColor(this.ink)
            .textShadow(readingHalo(this.ink,this.unit,this.readingHaloEnabled,this.cap.readingBlend)).maxLines(1)
            .width(this.labelFont()*1.1).height(this.labelFont()*1.25).textAlign(TextAlign.Center)
            .rotate({angle:this.glyph(index).angle}).position({x:this.glyph(index).x-this.labelFont()*.55,y:this.glyph(index).y-this.labelFont()*.625})
            .accessibilityLevel('no')
          }
        },(index:number)=>String(index))
      }.width(this.diameter()).height(this.diameter()+8*this.unit)
    }.width('100%').height('100%').justifyContent(FlexAlign.Center)
      .accessibilityText(batteryStatus(this.cap)+' '+(batteryLevel(this.cap)<0?'':batteryLevel(this.cap)+'%'))
  }
}
