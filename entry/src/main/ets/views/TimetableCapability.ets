import { readingHalo } from '../model/CapabilityPresentation';
import { CapBlock, AgendaItem } from '../model/CardSchema';
import { timetableDisplay, TimetableDisplay, timeText } from '../model/CapabilityData';
import { briefColumns, briefHeight, LESSON_CELL_HEIGHT, BRIEF_HEADER_HEIGHT } from '../model/TimetableLayout';
@Component
export struct TimetableCapability {
  @Prop @Watch('update') cap: CapBlock = {k:'timetable'};
  @Prop @Watch('update') tick: number = 0;
  @Prop ink: string = '#262824';
  @Prop readingHaloEnabled: boolean = false;
  @Prop contentWidth: number = 192;
  @Prop contentHeight: number = 150;
  @Prop scaleFactor: number = 1;
  @State display: TimetableDisplay = new TimetableDisplay();
  aboutToAppear(): void { this.update(); }
  private update(): void { this.display = timetableDisplay(this.cap, this.tick > 0 ? this.tick : Date.now()); }
  private s(): number { return this.scaleFactor; }
  private dateLabel(): string { const d = new Date(this.display.date); return (d.getMonth()+1)+'.'+d.getDate(); }
  private columns(): number { return briefColumns(this.contentWidth); }
  private fits(): boolean { return this.cap.timetableMode === 'day' ? this.contentHeight + .1 >= briefHeight(this.display.lessons.length, this.columns()) : this.contentWidth >=127.9 && this.contentHeight >=115.9; }
  @Builder
  heading() {
    Row({space:4*this.s()}) {
      Text(this.display.heading).fontSize(11*this.s()).fontWeight(FontWeight.Medium).fontColor(this.ink).textShadow(readingHalo(this.ink, this.scaleFactor, this.readingHaloEnabled)).opacity(.65).layoutWeight(1).maxLines(1).textOverflow({overflow:TextOverflow.Ellipsis})
      Text(this.dateLabel()).fontSize(10*this.s()).fontColor(this.ink).textShadow(readingHalo(this.ink, this.scaleFactor, this.readingHaloEnabled)).opacity(.5)
    }.width('100%').height(BRIEF_HEADER_HEIGHT*this.s()).alignItems(VerticalAlign.Top)
  }
  build() {
    Column() {
      this.heading()
      if (!this.fits()) {
        Text('放大卡片以显示课程').fontSize(12*this.s()).fontColor(this.ink).textShadow(readingHalo(this.ink, this.scaleFactor, this.readingHaloEnabled)).layoutWeight(1).width('100%').maxLines(2).textOverflow({overflow:TextOverflow.Ellipsis})
      } else if (!this.display.lessons.length) {
        Column({space:6*this.s()}) {
          Text(this.display.empty).fontSize(17*this.s()).fontWeight(FontWeight.Medium).fontColor(this.ink).textShadow(readingHalo(this.ink, this.scaleFactor, this.readingHaloEnabled)).maxLines(2).textOverflow({overflow:TextOverflow.Ellipsis}).width('100%')
          Text((this.cap.courses??[]).length?(this.cap.timetableMode==='day'?'查看周课表安排':'开课前一晚显示下一课'):'导入或添加你的课程').fontSize(11*this.s()).fontColor(this.ink).textShadow(readingHalo(this.ink, this.scaleFactor, this.readingHaloEnabled)).opacity(.55).maxLines(1).textOverflow({overflow:TextOverflow.Ellipsis}).width('100%')
        }.layoutWeight(1).width('100%').alignItems(HorizontalAlign.Start).justifyContent(FlexAlign.Center)
      } else if (this.cap.timetableMode === 'day') {
        Grid() {
          ForEach(this.display.lessons,(e:AgendaItem)=>{
            GridItem() {
              Column({space:3*this.s()}) {
                Text(e.title).fontSize(14*this.s()).minFontSize(12*this.s()).maxFontSize(14*this.s()).height(34*this.s()).align(Alignment.TopStart).fontWeight(FontWeight.Medium).fontColor(this.ink).textShadow(readingHalo(this.ink, this.scaleFactor, this.readingHaloEnabled)).maxLines(2).textOverflow({overflow:TextOverflow.Ellipsis}).width('100%')
                Text(e.location||'地点待定').fontSize(11*this.s()).fontColor(this.ink).textShadow(readingHalo(this.ink, this.scaleFactor, this.readingHaloEnabled)).opacity(.6).maxLines(1).textOverflow({overflow:TextOverflow.Ellipsis}).width('100%')
              }.width('100%').height(LESSON_CELL_HEIGHT*this.s()).padding({right:8*this.s(),bottom:6*this.s()}).alignItems(HorizontalAlign.Start)
            }
          },(e:AgendaItem)=>e.id)
        }.columnsTemplate(this.columns()===3?'1fr 1fr 1fr':this.columns()===2?'1fr 1fr':'1fr').width('100%')
          .height((briefHeight(this.display.lessons.length,this.columns())-BRIEF_HEADER_HEIGHT)*this.s()).scrollBar(BarState.Off)
      } else {
        Column({space:5*this.s()}) {
          Text(this.display.lessons[0].title).fontSize(20*this.s()).minFontSize(16*this.s()).maxFontSize(20*this.s()).height(48*this.s()).align(Alignment.TopStart).fontWeight(FontWeight.Medium).fontColor(this.ink).textShadow(readingHalo(this.ink, this.scaleFactor, this.readingHaloEnabled)).width('100%').maxLines(2).textOverflow({overflow:TextOverflow.Ellipsis})
          Row({space:6*this.s()}) {
            Text(timeText(this.display.lessons[0].start)+'–'+timeText(this.display.lessons[0].end)).fontSize(11*this.s()).fontColor(this.ink).textShadow(readingHalo(this.ink, this.scaleFactor, this.readingHaloEnabled)).opacity(.65)
          }.width('100%')
          Text(this.display.lessons[0].location||'地点待定').fontSize(12*this.s()).fontColor(this.ink).textShadow(readingHalo(this.ink, this.scaleFactor, this.readingHaloEnabled)).opacity(.75).maxLines(1).textOverflow({overflow:TextOverflow.Ellipsis}).width('100%')
        }.width('100%').layoutWeight(1).alignItems(HorizontalAlign.Start).justifyContent(FlexAlign.Center)
      }
    }.width('100%').height('100%').alignItems(HorizontalAlign.Start)
  }
}
