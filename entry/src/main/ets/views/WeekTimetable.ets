import { CapBlock, CourseItem } from '../model/CardSchema';
import { semesterWeek, timeText } from '../model/CapabilityData';
import { WeekLesson, weekLessons, weekStart, minuteOf } from '../model/TimetableLayout';
import { AppDesign } from '../model/AppDesign';
/** Scrollable weekly calendar; spatial position represents actual lesson time. */
@Component
export struct WeekTimetable {
  @Prop @Watch('refresh') cap: CapBlock = {k:'timetable'};
  @Prop appDark: boolean = false;
  @Prop editable: boolean = true;
  @Prop initialWeek: number = 0;
  @Prop heightLimit: number = 360;
  onCourse: (course: CourseItem) => void = () => {};
  @State week: number = 1;
  @State items: WeekLesson[] = [];
  @State hourHeight: number = 64;
  @State firstHour: number = 8;
  @State lastHour: number = 20;
  aboutToAppear(): void {
    this.week = Math.max(1, Math.min(60, this.initialWeek || semesterWeek(this.cap.semester??'',Date.now()))); this.refresh();
  }
  private refresh(): void {
    this.items = weekLessons(this.cap,this.week);
    const shortest = Math.min(45,...this.items.map((i)=>(i.event.end-i.event.start)/60000));
    this.hourHeight = Math.max(64,48*60/Math.max(1,shortest));
    this.firstHour = Math.min(8,...this.items.map((i)=>Math.floor(minuteOf(i.event.start)/60)));
    this.lastHour = Math.max(18,...this.items.map((i)=>Math.ceil(minuteOf(i.event.end)/60)));
  }
  private move(delta: number): void { this.week=Math.max(1,Math.min(60,this.week+delta));this.refresh(); }
  private hours(): number[] { const out:number[]=[];for(let h=this.firstHour;h<=this.lastHour;h++)out.push(h);return out; }
  private dayText(day:number): string {
    const date=new Date(weekStart(this.cap.semester??'',this.week));date.setDate(date.getDate()+day-1);
    return isNaN(date.getTime())?'':(date.getMonth()+1)+'.'+date.getDate();
  }
  private cellHeight(i:WeekLesson): number {return Math.max(44,(i.event.end-i.event.start)/60000/60*this.hourHeight-3);}
  private open(item: WeekLesson): void {const course=(this.cap.courses??[]).find((c)=>c.id===item.event.courseId);if(course&&this.editable)this.onCourse(course);}
  build() {
    Column({space:12}) {
      Row({space:10}) {
        Button('‹',{type:ButtonType.Circle}).width(44).height(44).fontSize(24).fontColor(AppDesign.text(this.appDark)).backgroundColor(AppDesign.control(this.appDark)).enabled(this.week>1).onClick(()=>this.move(-1))
        Column({space:2}) {
          Text('第 '+this.week+' 周').fontSize(16).fontWeight(FontWeight.Medium).fontColor(AppDesign.text(this.appDark))
          Text(this.items.length?this.items.length+' 项课程 · '+(this.editable?'点按编辑':'预览'):'本周无课').fontSize(11).fontColor(AppDesign.muted(this.appDark))
        }.layoutWeight(1)
        Button('›',{type:ButtonType.Circle}).width(44).height(44).fontSize(24).fontColor(AppDesign.text(this.appDark)).backgroundColor(AppDesign.control(this.appDark)).enabled(this.week<60).onClick(()=>this.move(1))
      }.width('100%')
      Scroll() {
        Column() {
          Row() {
            Text('时间').fontSize(11).fontColor(AppDesign.muted(this.appDark)).width(42).textAlign(TextAlign.Center)
            ForEach([1,2,3,4,5,6,7],(day:number)=>{
              Column({space:3}) {
                Text(['一','二','三','四','五','六','日'][day-1]).fontSize(13).fontWeight(FontWeight.Medium).fontColor(AppDesign.text(this.appDark))
                Text(this.dayText(day)).fontSize(10).fontColor(AppDesign.muted(this.appDark))
              }.width(88).height(46).justifyContent(FlexAlign.Center)
            },(day:number)=>String(day))
          }.width(658)
          Scroll() {
            Stack({alignContent:Alignment.TopStart}) {
              Column() {
                ForEach(this.hours().slice(0,-1),(hour:number)=>{
                  Row({space:4}) {
                    Text(('0'+hour).slice(-2)+':00').fontSize(10).fontColor(AppDesign.muted(this.appDark)).width(38).align(Alignment.TopStart)
                    Row().height(.5).width(616).backgroundColor(AppDesign.border(this.appDark))
                  }.width(658).height(this.hourHeight).alignItems(VerticalAlign.Top)
                },(h:number)=>String(h))
              }.width(658)
              ForEach(this.items,(i:WeekLesson)=>{
                Button({type:ButtonType.ROUNDED_RECTANGLE}) {
                  Column({space:3}) {
                    Text(i.event.title).fontSize(12).fontWeight(FontWeight.Medium).fontColor(AppDesign.text(this.appDark)).width('100%').maxLines(Math.max(1,Math.min(3,Math.floor((this.cellHeight(i)-28)/15)))).textOverflow({overflow:TextOverflow.Ellipsis})
                    Text(i.event.location||'地点待定').fontSize(10).fontColor(AppDesign.muted(this.appDark)).width('100%').maxLines(1).textOverflow({overflow:TextOverflow.Ellipsis})
                    if(this.cellHeight(i)>82) {Text(timeText(i.event.start)+'–'+timeText(i.event.end)).fontSize(9).fontColor(AppDesign.muted(this.appDark)).maxLines(1).textOverflow({overflow:TextOverflow.Ellipsis}).width('100%')}
                  }.width('100%').padding(7).alignItems(HorizontalAlign.Start)
                }.width(86/i.lanes-2).height(this.cellHeight(i)).backgroundColor(AppDesign.surface(this.appDark)).border({width:.5,color:AppDesign.border(this.appDark)}).borderRadius(10).clip(true)
                  .position({x:43+(i.day-1)*88+i.lane*86/i.lanes,y:(minuteOf(i.event.start)-this.firstHour*60)/60*this.hourHeight})
                  .onClick(()=>this.open(i))
              },(i:WeekLesson)=>i.event.id)
            }.width(658).height((this.lastHour-this.firstHour)*this.hourHeight)
          }.width(658).height(this.heightLimit-46).scrollBar(BarState.Off)
        }.width(658)
      }.width('100%').height(this.heightLimit).scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off).backgroundColor(AppDesign.control(this.appDark)).borderRadius(16).clip(true)
    }.width('100%')
  }
}
