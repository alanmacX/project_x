import { CapBlock, CourseItem } from '../model/CardSchema';
import { AppDesign } from '../model/AppDesign';
import { WeekTimetable } from './WeekTimetable';
@CustomDialog
export struct TimetableDialog {
  controller:CustomDialogController;
  cap:CapBlock={k:'timetable'};
  appDark:boolean=false;
  @State calendarHeight:number=260;
  onCourse:(course:CourseItem)=>void=()=>{};
  build() {
    Column({space:16}) {
      Row() {
        Text('课程表').fontSize(20).fontWeight(FontWeight.Medium).fontColor(AppDesign.text(this.appDark)).layoutWeight(1)
        Button('完成',{type:ButtonType.Capsule}).height(44).fontColor(AppDesign.text(this.appDark)).backgroundColor(AppDesign.control(this.appDark)).onClick(()=>this.controller.close())
      }.width('100%')
      WeekTimetable({cap:this.cap,appDark:this.appDark,heightLimit:this.calendarHeight,onCourse:(c:CourseItem)=>{this.controller.close();this.onCourse(c);}})
      Text('横向查看一周，纵向查看时间；假期与调课按校历显示。').fontSize(12).fontColor(AppDesign.muted(this.appDark)).width('100%').maxLines(2).textOverflow({overflow:TextOverflow.Ellipsis})
    }.width('94%').height('85%').constraintSize({maxWidth:820,maxHeight:650}).padding(20).onAreaChange((_old:Area,area:Area)=>{const height=Math.max(140,Number(area.height)-200);if(Math.abs(height-this.calendarHeight)>1)this.calendarHeight=height;}).backgroundColor(AppDesign.surface(this.appDark)).borderRadius(24)
  }
}
