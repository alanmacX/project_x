import { hookReserve } from '../model/MicaGeometry';
import { ReadingHook } from './ReadingHook';
import { compositionPadding } from '../model/ReadingComposition';
import { ReadingBacking } from './ReadingBacking';
import { paperTextWidth } from '../model/PaperTextWidth';
import { holidayKnown, dateKey } from '../model/HolidayCalendar';
import { readingHalo } from '../model/CapabilityPresentation';
import { CapBlock, AgendaItem } from '../model/CardSchema';
import { timetableDisplay, TimetableDisplay, timeText } from '../model/CapabilityData';
import { briefColumns, LESSON_CELL_HEIGHT, BRIEF_HEADER_HEIGHT } from '../model/TimetableLayout';
import { capabilityFits, capabilityContentScale, compactCapability } from '../model/CapabilityMetrics';
@Component
export struct TimetableCapability {
  @Prop @Watch('update') cap: CapBlock = {k:'timetable'};
  @Prop @Watch('update') tick: number = 0;
  @Prop ink: string = '#262824';
  @Prop readingHaloEnabled: boolean = false;
  @Prop contentBackingEnabled:boolean=false;
  @Prop backingTint:string='#E8D6B0';
  @Prop backingEdge:string='';
  @Prop backingProfile:number[]=[];
  @Prop backingLeft:boolean=true;
  @Prop backingGutter:number=0;
  @Prop contentWidth: number = 192;
  @Prop contentHeight: number = 150;
  @Prop scaleFactor: number = 1;
  @State display: TimetableDisplay = new TimetableDisplay();
  aboutToAppear(): void { this.update(); }
  private update(): void { this.display = timetableDisplay(this.cap, this.tick > 0 ? this.tick : Date.now()); }
  private contentScale(): number {return Math.min(1,capabilityContentScale(this.cap,this.contentWidth,this.contentHeight));}
  private s(): number { return this.scaleFactor*this.contentScale(); }
  private calendarPending():boolean {const date=new Date(this.display.date),key=dateKey(date);return this.cap.skipHolidays!==false&&!holidayKnown(date.getFullYear())&&!(this.cap.teachingDays??[]).some((d)=>d.date===key)&&!(this.cap.holidayDates??[]).some((d)=>d.date===key);}
  private dateLabel(): string { const d = new Date(this.display.date); return (d.getMonth()+1)+'.'+d.getDate(); }
  private columns(): number { return briefColumns(this.contentWidth/Math.max(.001,this.contentScale())+.01); }
  private compactUpcoming():boolean {return this.cap.timetableMode!=='day' && compactCapability(this.cap,this.contentWidth,this.contentHeight);}
  private fits(): boolean { return capabilityFits(this.cap,this.contentWidth,this.contentHeight); }
  private backingWidth():number {
    if(this.backingProfile.length)return (this.contentWidth+2*compositionPadding(this.cap.readingBlend??'')+this.backingGutter)*this.scaleFactor;
    const s=this.s(),measure=(text:string,font:number):number=>paperTextWidth(text,font);
    let width=measure(this.calendarPending()?'假期待确认':this.display.heading,10*s)+measure(this.dateLabel(),8.5*s)+18*s;
    if(!this.display.lessons.length)width=Math.max(width,measure(this.display.empty,11.5*s));
    else {
      let cell=0;for(const lesson of this.display.lessons)cell=Math.max(cell,measure(lesson.title,11.5*s),measure(lesson.location||'地点待定',8.5*s));
      width=Math.max(width,(cell+44*s)*(this.cap.timetableMode==='day'?this.columns():1));
    }
    return Math.min((this.contentWidth+2*compositionPadding(this.cap.readingBlend??''))*this.scaleFactor,Math.ceil(width)+2*compositionPadding(this.cap.readingBlend??'')*s);
  }
  private dayCellHeight():number {return LESSON_CELL_HEIGHT*this.s();}
  private highlighted(e:AgendaItem):boolean {return e.id===this.display.lessons.find(lesson=>lesson.end>(this.tick||Date.now()))?.id;}
  @Builder private readingBackground() {if(this.contentBackingEnabled){ReadingBacking({blend:this.cap.readingBlend??'feather',tint:this.backingTint,edge:this.backingEdge,profile:this.backingProfile,contactLeft:this.backingLeft,surfaceWidth:this.backingWidth(),surfaceHeight:(this.contentHeight+2*compositionPadding(this.cap.readingBlend??''))*this.scaleFactor,hook:this.cap.readingHook??.2,ink:this.ink,radius:8*this.s(),scaleFactor:this.s()})}}
  @Builder
  heading() {
    Row({space:3*this.s()}) {
      Text(this.calendarPending()?'假期待确认':this.display.heading).fontSize(10*this.s()).fontWeight(FontWeight.Medium).fontColor(this.ink).maxLines(1).textOverflow({overflow:TextOverflow.Ellipsis}).layoutWeight(1)
      Text(this.dateLabel()).fontSize(8.5*this.s()).fontColor(this.ink).opacity(.6).maxLines(1)
      SymbolGlyph($r('sys.symbol.calendar')).fontSize(10*this.s()).fontColor([this.ink]).accessibilityLevel('no')
    }.width('100%').height(BRIEF_HEADER_HEIGHT*this.s())
  }
  /** Both modes share the same course tile, typography and complete two-line time. */
  @Builder private lessonRow(e:AgendaItem) {
    Row({space:4*this.s()}) {
      Column({space:0}) {
        Text(timeText(e.start)).fontSize(9.5*this.s()).minFontSize(8.5*this.s()).maxFontSize(9.5*this.s()).heightAdaptivePolicy(TextHeightAdaptivePolicy.MIN_FONT_SIZE_FIRST).fontWeight(FontWeight.Medium).fontColor(this.ink).height(12*this.s()).width('100%').maxLines(1)
        Text(timeText(e.end)).fontSize(8.5*this.s()).minFontSize(7.5*this.s()).maxFontSize(8.5*this.s()).heightAdaptivePolicy(TextHeightAdaptivePolicy.MIN_FONT_SIZE_FIRST).fontColor(this.ink).opacity(.6).height(11*this.s()).width('100%').maxLines(1)
      }.width(30*this.s()).alignItems(HorizontalAlign.Start)
      Column({space:1*this.s()}) {
        Text(e.title).fontSize(11.5*this.s()).minFontSize(10.5*this.s()).maxFontSize(11.5*this.s()).fontWeight(FontWeight.Medium).fontColor(this.ink).maxLines(1).textOverflow({overflow:TextOverflow.Ellipsis}).width('100%')
        if(e.location){Text(e.location).fontSize(8.5*this.s()).fontColor(this.ink).opacity(.6).maxLines(1).textOverflow({overflow:TextOverflow.Ellipsis}).width('100%')}
      }.layoutWeight(1).alignItems(HorizontalAlign.Start)
    }.width('100%').height(this.dayCellHeight()-3*this.s()).padding({left:5*this.s(),right:5*this.s()}).backgroundColor(this.highlighted(e)?'#45F5C94B':'#16A69A7C').borderRadius(7*this.s())
  }
  @Builder private readingHook() {if(this.contentBackingEnabled&&['tag','dock'].includes(this.cap.readingBlend??'')){ReadingHook({hook:this.cap.readingHook??.2,scaleFactor:this.s()})}}
  @State private backingHeight:number=0;
  build() {
    Column() {
    Stack({alignContent:Alignment.TopStart}) {
      if(this.contentBackingEnabled){Column(){this.readingBackground()}.width(this.backingWidth()).height(this.backingHeight).position({x:0,y:0}).hitTestBehavior(HitTestMode.None)}
    Column() {
    Column() {
      this.heading()
      if (!this.fits()) {
        Text('放大卡片以显示课程').fontSize(12*this.s()).fontColor(this.ink).textShadow(readingHalo(this.ink, this.scaleFactor, this.readingHaloEnabled,this.cap.readingBlend)).layoutWeight(this.contentBackingEnabled?0:1).width('100%').maxLines(2).textOverflow({overflow:TextOverflow.Ellipsis})
      } else if (!this.display.lessons.length) {
        Column({space:3*this.s()}) {
          Text(this.display.empty).fontSize(11.5*this.s()).fontWeight(FontWeight.Medium).fontColor(this.ink).textShadow(readingHalo(this.ink, this.scaleFactor, this.readingHaloEnabled,this.cap.readingBlend)).maxLines(1).textOverflow({overflow:TextOverflow.Ellipsis}).width('100%')
          if(this.contentHeight>=70){Text((this.cap.courses??[]).length?(this.cap.timetableMode==='day'?'查看周课表安排':'开课前一晚显示下一课'):'导入或添加你的课程').fontSize(11*this.s()).fontColor(this.ink).textShadow(readingHalo(this.ink, this.scaleFactor, this.readingHaloEnabled,this.cap.readingBlend)).opacity(this.readingHaloEnabled?1:.55).maxLines(1).textOverflow({overflow:TextOverflow.Ellipsis}).width('100%')}
        }.layoutWeight(this.contentBackingEnabled?0:1).width('100%').alignItems(HorizontalAlign.Start).justifyContent(FlexAlign.Center)
      } else if (this.cap.timetableMode === 'day') {
        Grid() {
          ForEach(this.display.lessons,(e:AgendaItem)=>{
            GridItem() {
              this.lessonRow(e)
            }
          },(e:AgendaItem)=>e.id)
        }.columnsTemplate(this.columns()===3?'1fr 1fr 1fr':this.columns()===2?'1fr 1fr':'1fr').width('100%')
          .height(Math.ceil(this.display.lessons.length/this.columns())*this.dayCellHeight()).scrollBar(BarState.Off)
      } else {
        Column(){this.lessonRow(this.display.lessons[0])}.width('100%').height(this.dayCellHeight())
      }
    }.width(this.contentBackingEnabled?Math.max(1,this.backingWidth()-2*compositionPadding(this.cap.readingBlend??'')*this.s()-this.backingGutter*this.scaleFactor):'100%').constraintSize({maxHeight:this.contentBackingEnabled?Math.max(1,this.contentHeight*this.scaleFactor):undefined}).clip(this.contentBackingEnabled)
    }.width(this.contentBackingEnabled?this.backingWidth():'100%').height(this.backingProfile.length?'100%':this.contentBackingEnabled?undefined:'100%').padding({left:this.contentBackingEnabled?compositionPadding(this.cap.readingBlend??'')*this.s()+(this.backingLeft?this.backingGutter*this.scaleFactor:0):0,right:this.contentBackingEnabled?compositionPadding(this.cap.readingBlend??'')*this.s()+(!this.backingLeft?this.backingGutter*this.scaleFactor:0):0,bottom:this.contentBackingEnabled?compositionPadding(this.cap.readingBlend??'')*this.s():0,top:this.contentBackingEnabled?compositionPadding(this.cap.readingBlend??'')*this.s()+hookReserve(this.cap.readingBlend??'')*this.s():0})
      .onSizeChange((_:SizeOptions,size:SizeOptions)=>{const h=Number(size.height);if(h>0&&Math.abs(h-this.backingHeight)>.01)this.backingHeight=h;}).alignItems(HorizontalAlign.Start)
      if(this.contentBackingEnabled&&['tag','dock'].includes(this.cap.readingBlend??'')){Column(){this.readingHook()}.width(this.backingWidth()).height(this.backingHeight).position({x:0,y:0}).hitTestBehavior(HitTestMode.None)}
    }.width(this.contentBackingEnabled?this.backingWidth():'100%').height(this.backingProfile.length?'100%':this.contentBackingEnabled?undefined:'100%')
    }.width('100%').height('100%').justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
  }
}
