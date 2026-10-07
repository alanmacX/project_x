import { hookReserve } from '../model/MicaGeometry';
import { ReadingHook } from './ReadingHook';
import { ReadingBacking } from './ReadingBacking';
import { readingHalo } from '../model/CapabilityPresentation';
import { CapBlock } from '../model/CardSchema';
import { batteryLevel, batteryStatus, batteryTint, batteryRingPath, batteryArcLabel, batteryPaperArcMask, BatteryArcGlyph } from '../model/BatteryPresentation';
@Component
export struct BatteryCapability {
  @Prop cap:CapBlock={k:'battery'};
  @Prop ink:string='#262824';
  @Prop readingHaloEnabled:boolean=false;
  @Prop contentBackingEnabled:boolean=false;
  @Prop backingTint:string='#E8D6B0';
  @Prop backingEdge:string='';
  @Prop unit:number=1;
  @Prop compact:boolean=false;
  private diameter():number {return (this.compact?48:72)*this.unit;}
  private labelFont():number {return (this.compact?10:14)*this.unit;}
  private label():string {return batteryLevel(this.cap)<0?'—':String(batteryLevel(this.cap));}
  private glyph(index:number):BatteryArcGlyph {return batteryArcLabel(this.diameter(),this.label(),this.labelFont())[index];}
  private paperDiameter():number {return this.diameter()*.88+(this.compact?3.5:5)*this.unit+4*this.unit;}
  private paperMask():string {return batteryPaperArcMask(vp2px(this.paperDiameter()),vp2px(Math.max(0,this.diameter()*.44-(this.compact?3.5:5)*this.unit/2-2*this.unit)),126,288);}
  private labelPaperDiameter():number {return this.diameter()*.88+this.labelFont()*1.25+4*this.unit;}
  private labelPaperMask():string {
    const half=(this.labelFont()*(.62*(this.label().length-1)+1.1)+4*this.unit)/2/(this.diameter()*.44)*180/Math.PI;
    return batteryPaperArcMask(vp2px(this.labelPaperDiameter()),vp2px(Math.max(0,this.diameter()*.44-this.labelFont()*.625-2*this.unit)),90-half,half*2);
  }
  build() {
    Column() {
      Stack({alignContent:Alignment.TopStart}) {
        if(this.contentBackingEnabled&&['badge','tag','dock'].includes(this.cap.readingBlend??'')) {
          ReadingBacking({blend:this.cap.readingBlend??'badge',tint:this.backingTint,edge:this.backingEdge,hook:this.cap.readingHook??.2,ink:this.ink,scaleFactor:this.unit}).width(this.labelPaperDiameter()).height(this.labelPaperDiameter()+hookReserve(this.cap.readingBlend??'')*this.unit).position({x:(this.diameter()-this.labelPaperDiameter())/2,y:(this.diameter()-this.labelPaperDiameter())/2-hookReserve(this.cap.readingBlend??'')*this.unit})
        } else if(this.contentBackingEnabled) {
          ReadingBacking({blend:this.cap.readingBlend??'feather',tint:this.backingTint,edge:this.backingEdge,hook:this.cap.readingHook??.2,ink:this.ink,radius:999,scaleFactor:this.unit}).width(this.paperDiameter()).height(this.paperDiameter())
            .clip(new Path().commands(this.paperMask())).position({x:(this.diameter()-this.paperDiameter())/2,y:(this.diameter()-this.paperDiameter())/2})
          ReadingBacking({blend:this.cap.readingBlend??'feather',tint:this.backingTint,edge:this.backingEdge,hook:this.cap.readingHook??.2,ink:this.ink,radius:999,scaleFactor:this.unit}).width(this.labelPaperDiameter()).height(this.labelPaperDiameter())
            .clip(new Path().commands(this.labelPaperMask())).position({x:(this.diameter()-this.labelPaperDiameter())/2,y:(this.diameter()-this.labelPaperDiameter())/2})
          if(this.cap.charging||this.cap.chargeState==='full') {
            ReadingBacking({blend:this.cap.readingBlend??'feather',tint:this.backingTint,edge:this.backingEdge,hook:this.cap.readingHook??.2,ink:this.ink,radius:999,scaleFactor:this.unit}).width((this.compact?19:26)*this.unit).height((this.compact?19:26)*this.unit)
              .position({x:(this.diameter()-(this.compact?19:26)*this.unit)/2,y:(this.diameter()-(this.compact?19:26)*this.unit)/2})
          }
        }
        if(this.contentBackingEnabled&&['tag','dock'].includes(this.cap.readingBlend??'')){ReadingHook({hook:this.cap.readingHook??.2,scaleFactor:this.unit}).width(this.labelPaperDiameter()).height(this.labelPaperDiameter()+hookReserve(this.cap.readingBlend??'')*this.unit).position({x:(this.diameter()-this.labelPaperDiameter())/2,y:(this.diameter()-this.labelPaperDiameter())/2-hookReserve(this.cap.readingBlend??'')*this.unit})}
        Path().commands(batteryRingPath(vp2px(this.diameter()))).fill(Color.Transparent).stroke(this.ink)
          .strokeWidth((this.compact?3.5:5)*this.unit).strokeLineCap(LineCapStyle.Round).opacity(.14)
          .width(this.diameter()).height(this.diameter())
        if(batteryLevel(this.cap)>0) {
          Path().commands(batteryRingPath(vp2px(this.diameter()),batteryLevel(this.cap))).fill(Color.Transparent).stroke(batteryTint(this.cap,this.ink))
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
      }.width(this.diameter()).height(this.diameter()+8*this.unit).translate({y:hookReserve(this.cap.readingBlend??'')*this.unit/2})
    }.width('100%').height('100%').justifyContent(FlexAlign.Center)
      .accessibilityText(batteryStatus(this.cap)+' '+(batteryLevel(this.cap)<0?'':batteryLevel(this.cap)+'%'))
  }
}
