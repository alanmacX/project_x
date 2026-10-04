import { CapBlock } from '../model/CardSchema';
import { CLOCK_CITIES, clockZone, clockCity } from '../model/TimeCapabilities';
import { AppDesign } from '../model/AppDesign';
/** Native city selection; shareable configuration contains only an IANA time zone. */
@Component
export struct TimeCapabilitySettings {
  @Prop cap:CapBlock={k:'worldclock'};
  @Prop appDark:boolean=false;
  onUpdate:(next:CapBlock)=>void=()=>{};
  build() {
    Column({space:12}) {
      Row({space:12}) {
        Text('城市').fontSize(14).fontColor(AppDesign.text(this.appDark)).layoutWeight(1)
        Select(CLOCK_CITIES.map((city):SelectOption=>({value:city.value})))
          .selected(CLOCK_CITIES.findIndex((city)=>city.zone===clockZone(this.cap.zone??'')))
          .value(clockCity(this.cap.zone??'')).font({size:14}).fontColor(AppDesign.text(this.appDark))
          .optionFont({size:14}).optionFontColor(AppDesign.text(this.appDark)).optionBgColor(AppDesign.surface(this.appDark))
          .selectedOptionFontColor(AppDesign.onSelected(this.appDark)).selectedOptionBgColor(AppDesign.selected(this.appDark))
          .backgroundColor(AppDesign.control(this.appDark)).borderRadius(12).controlSize(ControlSize.NORMAL)
          .onSelect((index:number)=>{if(CLOCK_CITIES[index]) {const cap=JSON.parse(JSON.stringify(this.cap)) as CapBlock;cap.zone=CLOCK_CITIES[index].zone;this.onUpdate(cap);}})
      }.width('100%')
      Text('夏令时自动切换；无需联网或位置权限。').fontSize(12).fontColor(AppDesign.muted(this.appDark)).width('100%')
    }.width('100%')
  }
}
