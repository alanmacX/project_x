import { CapBlock } from '../model/CardSchema';
import { CLOCK_CITIES, clockZone, clockCity } from '../model/TimeCapabilities';
import { SettingsSelect } from './SettingsSelect';
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
        SettingsSelect({labels:CLOCK_CITIES.map((city)=>city.value),selectedIndex:CLOCK_CITIES.findIndex((city)=>city.zone===clockZone(this.cap.zone??'')),
          valueLabel:clockCity(this.cap.zone??''),appDark:this.appDark,onSelect:(index:number)=>{if(CLOCK_CITIES[index]){const cap=JSON.parse(JSON.stringify(this.cap)) as CapBlock;cap.zone=CLOCK_CITIES[index].zone;this.onUpdate(cap);}}}).layoutWeight(1)
      }.width('100%')
      Text('夏令时自动切换；无需联网或位置权限。').fontSize(12).fontColor(AppDesign.muted(this.appDark)).width('100%')
    }.width('100%')
  }
}
