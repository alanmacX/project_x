import { CapBlock, AgendaItem } from '../model/CardSchema';
import { eventWhen } from '../model/CapabilityData';
import { AppDesign } from '../model/AppDesign';
/** Reading/doing surface, separate from artwork editing. Desktop links land here. */
@Component
export struct CapabilityDetails {
  @Prop cap:CapBlock={k:'agenda'};
  @Prop appDark:boolean=false;
  @Prop tick:number=0;
  onUpdate:(cap:CapBlock)=>void=()=>{};



  private events():AgendaItem[] {return (this.cap.events??[]).filter((e)=>e.end>(this.tick||Date.now())).slice().sort((a,b)=>a.start-b.start);}
  build() {
    Column({space:12}) {
      if(this.cap.k==='agenda') {
        if(!this.events().length) {Text('暂无日程').fontSize(20).fontColor(AppDesign.text(this.appDark)).width('100%').padding(16)}
        ForEach(this.events(),(e:AgendaItem)=>{
          Column({space:8}) {
            Text(eventWhen(e,this.tick||Date.now())).fontSize(12).fontColor(AppDesign.muted(this.appDark)).width('100%')
            Text(e.title).fontSize(18).fontWeight(FontWeight.Medium).fontColor(AppDesign.text(this.appDark)).maxLines(3).width('100%')
            if(e.location) {Text(e.location).fontSize(14).fontColor(AppDesign.muted(this.appDark)).maxLines(2).width('100%')}
          }.padding(16).width('100%').backgroundColor(AppDesign.surface(this.appDark)).borderRadius(20)
        },(e:AgendaItem)=>e.id)
      }
    }.width('100%')
  }
}
