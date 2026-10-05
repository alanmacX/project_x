import { readingHalo } from '../model/CapabilityPresentation';
import { cityReading, clockOffset, lunarReading } from '../model/TimeCapabilities';
import { SummaryCapability } from './SummaryCapability';
import { holidayName, holidayMarker } from '../model/HolidayCalendar';
import { CapBlock, typeLabel, contrastingInk } from '../model/CardSchema';
import { capabilityMinimum, compactCapability, capabilityFits } from '../model/CapabilityMetrics';
import { TimetableCapability } from './TimetableCapability';
import { BatteryCapability } from './BatteryCapability';
export { typeLabel } from '../model/CardSchema';
export function daysLeftOf(date: string): number {
  const target = new Date(date + 'T00:00:00'), now = new Date();
  return isNaN(target.getTime()) ? 0 : Math.round((target.getTime() - new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime()) / 86400000);
}
export function calendarCells(now: Date): number[] {
  const first = new Date(now.getFullYear(), now.getMonth(), 1).getDay();
  const count = new Date(now.getFullYear(), now.getMonth() + 1, 0).getDate();
  const cells: number[] = [];
  for (let i = 0; i < Math.ceil((first + count) / 7) * 7; i++) cells.push(i >= first && i < first + count ? i - first + 1 : 0);
  return cells;
}
export function progressOf(k: string, now: Date): number {
  if (k === 'dayprogress') return (now.getHours() * 60 + now.getMinutes()) / 1440;
  const start = new Date(now.getFullYear(), 0, 1), end = new Date(now.getFullYear() + 1, 0, 1);
  return (now.getTime() - start.getTime()) / (end.getTime() - start.getTime());
}
@Component
export struct CapabilityView {
  @Prop cap: CapBlock = { k: 'clock' };
  @Prop ink: string = '#262824';
  @Prop readingHaloEnabled: boolean = false;
  @Prop scaleFactor: number = 1;
  @Prop contentWidth: number = 150;
  @Prop contentHeight: number = 140;
  @Prop tick: number = 0;
  private compact(): boolean { return compactCapability(this.cap, this.contentWidth, this.contentHeight); }
  private calendarDate(): Date { const now = this.now(); return new Date(now.getFullYear(), now.getMonth() + (this.cap.calendarOffset ?? 0), 1); }
  private weekDays(): number[] {
    const now = this.now(), start = new Date(now.getFullYear(), now.getMonth(), now.getDate() - now.getDay());
    const days: number[] = []; for (let i = 0; i < 7; i++) days.push(new Date(start.getFullYear(), start.getMonth(), start.getDate() + i).getDate()); return days;
  }
  private now(): Date { return new Date(this.tick > 0 ? this.tick : Date.now()); }
  private unit(): number {
    const min = capabilityMinimum(this.cap, this.compact(), this.contentWidth);
    return Math.min(1, this.contentWidth / min.w, this.contentHeight / min.h) * this.scaleFactor;
  }
  private undersized(): boolean { return !capabilityFits(this.cap,this.contentWidth,this.contentHeight); }
  private lunarFont():number {
    const count=lunarReading(this.now().getTime()).date.replace(/\s/g,'').length+.35;
    return Math.min(this.compact()?18:26,Math.max(16,this.contentWidth/count))*this.unit();
  }
  private counterFont(): number {
    const digits = (Math.abs(daysLeftOf(this.cap.date ?? '')) + '').length;
    return Math.max(16*this.unit(),Math.min((this.compact() ? 24 : 44) * this.unit(), (this.contentWidth * this.scaleFactor - 32 * this.unit()) / (digits * .6)));
  }
  build() {
    Column({ space: 4 * this.unit() }) {
      if (this.undersized()) {
        Text('放大卡片').fontSize(12*this.scaleFactor).fontColor(this.ink).textShadow(readingHalo(this.ink, this.unit(), this.readingHaloEnabled,this.cap.readingBlend)).maxLines(2).textOverflow({overflow:TextOverflow.Ellipsis}).width('100%').textAlign(TextAlign.Center)
      } else if (this.cap.k === 'clock') {
        TextClock().format('HH:mm').fontSize(((this.compact() ? 24 : 42) * this.unit()) + 'vp').fontWeight(FontWeight.Medium).fontColor(this.ink).textShadow(readingHalo(this.ink, this.unit(), this.readingHaloEnabled,this.cap.readingBlend))
      } else if (this.cap.k === 'worldclock') {
        Text(cityReading(this.cap.zone??'',this.now().getTime()).city).fontSize((12*this.unit())+'vp').fontColor(this.ink).textShadow(readingHalo(this.ink, this.unit(), this.readingHaloEnabled,this.cap.readingBlend)).opacity(this.readingHaloEnabled?1:.65).maxLines(1)
        ForEach([clockOffset(this.cap.zone??'',this.now().getTime())],(offset:number)=>{
          Column({space:4*this.unit()}) {
            TextClock({timeZoneOffset:offset}).format('HH:mm').fontSize(((this.compact()?28:40)*this.unit())+'vp').fontWeight(FontWeight.Medium).fontColor(this.ink).textShadow(readingHalo(this.ink, this.unit(), this.readingHaloEnabled,this.cap.readingBlend))
            TextClock({timeZoneOffset:offset}).format('M月d日 · EEE').fontSize((11*this.unit())+'vp').fontColor(this.ink).textShadow(readingHalo(this.ink, this.unit(), this.readingHaloEnabled,this.cap.readingBlend))
          }
        },(offset:number)=>String(offset))
        if(!this.compact()) {Text(cityReading(this.cap.zone??'',this.now().getTime()).difference).fontSize((11*this.unit())+'vp').fontColor(this.ink).textShadow(readingHalo(this.ink, this.unit(), this.readingHaloEnabled,this.cap.readingBlend)).opacity(this.readingHaloEnabled?1:.65).maxLines(1)}
      } else if (this.cap.k === 'lunar') {
        Text('农历').fontSize((12*this.unit())+'vp').fontColor(this.ink).textShadow(readingHalo(this.ink, this.unit(), this.readingHaloEnabled,this.cap.readingBlend)).opacity(this.readingHaloEnabled?1:.65)
        Text(lunarReading(this.now().getTime()).date).fontSize(this.lunarFont()+'vp').fontWeight(FontWeight.Medium).fontColor(this.ink).textShadow(readingHalo(this.ink, this.unit(), this.readingHaloEnabled,this.cap.readingBlend)).maxLines(1)
        Text(lunarReading(this.now().getTime()).year).fontSize((12*this.unit())+'vp').fontColor(this.ink).textShadow(readingHalo(this.ink, this.unit(), this.readingHaloEnabled,this.cap.readingBlend)).opacity(this.readingHaloEnabled?1:.65).maxLines(1)
      } else if (this.cap.k === 'date') {
        TextClock().format('dd').fontSize(((this.compact() ? 24 : 54) * this.unit()) + 'vp').fontWeight(FontWeight.Medium).fontColor(this.ink).textShadow(readingHalo(this.ink, this.unit(), this.readingHaloEnabled,this.cap.readingBlend))
        Text(holidayName(this.now()) || (this.now().getFullYear()+'年'+(this.now().getMonth()+1)+'月 · '+['周日','周一','周二','周三','周四','周五','周六'][this.now().getDay()]+(holidayMarker(this.now())==='班'?' · 班':''))).fontSize((12 * this.unit()) + 'vp').fontColor(this.ink).textShadow(readingHalo(this.ink, this.unit(), this.readingHaloEnabled,this.cap.readingBlend)).opacity(this.readingHaloEnabled?1:0.65).maxLines(1).textOverflow({overflow:TextOverflow.Ellipsis})
      } else if (this.cap.k === 'calendar' && this.compact() && (this.cap.calendarOffset ?? 0) === 0) {
        Text((this.now().getMonth() + 1) + '月 · 本周').fontSize((12 * this.unit()) + 'vp').fontColor(this.ink).textShadow(readingHalo(this.ink, this.unit(), this.readingHaloEnabled,this.cap.readingBlend))
        Row() {
          ForEach(this.weekDays(), (day: number, index: number) => {
            Column({ space: 2 * this.unit() }) {
              Text(['日', '一', '二', '三', '四', '五', '六'][index]).fontSize((10 * this.unit()) + 'vp').fontColor(this.ink).textShadow(readingHalo(this.ink, this.unit(), this.readingHaloEnabled,this.cap.readingBlend)).opacity(this.readingHaloEnabled?1:.6)
              Text('' + day).fontSize((12 * this.unit()) + 'vp').fontColor(day === this.now().getDate() && (this.cap.calendarOffset ?? 0) === 0 ? contrastingInk(this.ink) : this.ink)
                .width('100%').height(20 * this.unit()).textAlign(TextAlign.Center)
                .backgroundColor(day === this.now().getDate() && (this.cap.calendarOffset ?? 0) === 0 ? this.ink : Color.Transparent).borderRadius(4)
            Text(holidayMarker(new Date(this.now().getFullYear(),this.now().getMonth(),this.now().getDate()-this.now().getDay()+index))).fontSize((7*this.unit())+'vp').fontColor(this.ink).textShadow(readingHalo(this.ink, this.unit(), this.readingHaloEnabled,this.cap.readingBlend)).height(8*this.unit()).opacity(this.readingHaloEnabled?1:.65)
            }.layoutWeight(1)
          }, (day: number, index: number) => index + ':' + day)
        }.width('100%')
      } else if (this.cap.k === 'calendar' && this.compact()) {
        Text((this.calendarDate().getFullYear()) + '年').fontSize((12 * this.unit()) + 'vp').fontColor(this.ink).textShadow(readingHalo(this.ink, this.unit(), this.readingHaloEnabled,this.cap.readingBlend)).opacity(this.readingHaloEnabled?1:.65)
        Text((this.calendarDate().getMonth() + 1) + '月').fontSize((28 * this.unit()) + 'vp').fontColor(this.ink).textShadow(readingHalo(this.ink, this.unit(), this.readingHaloEnabled,this.cap.readingBlend))
        Text('点按查看月历').fontSize((10 * this.unit()) + 'vp').fontColor(this.ink).textShadow(readingHalo(this.ink, this.unit(), this.readingHaloEnabled,this.cap.readingBlend)).opacity(this.readingHaloEnabled?1:.6)
      } else if (this.cap.k === 'calendar') {
        Text(this.calendarDate().getFullYear() + '年' + (this.calendarDate().getMonth() + 1) + '月').fontSize((14 * this.unit()) + 'vp').minFontSize(10*this.unit()).maxFontSize(14*this.unit()).maxLines(1).fontWeight(FontWeight.Medium).fontColor(this.ink).textShadow(readingHalo(this.ink, this.unit(), this.readingHaloEnabled,this.cap.readingBlend)).height(44*this.unit()).width('100%').padding({left:44*this.unit(),right:44*this.unit()}).textAlign(TextAlign.Center)
        Row() {
          ForEach(['日', '一', '二', '三', '四', '五', '六'], (day: string) => {
            Text(day).fontSize((10 * this.unit()) + 'vp').fontColor(this.ink).textShadow(readingHalo(this.ink, this.unit(), this.readingHaloEnabled,this.cap.readingBlend)).opacity(this.readingHaloEnabled?1:0.5).layoutWeight(1).textAlign(TextAlign.Center)
          }, (day: string) => day)
        }.width('100%')
        Grid() {
          ForEach(calendarCells(this.calendarDate()), (day: number, index: number) => {
            GridItem() {
              Stack({alignContent:Alignment.TopEnd}) {
              Text(day > 0 ? '' + day : '').fontSize((12 * this.unit()) + 'vp')
                .fontColor(day === this.now().getDate() && (this.cap.calendarOffset ?? 0) === 0 ? contrastingInk(this.ink) : this.ink)
                .width('100%').height(20 * this.unit()).textAlign(TextAlign.Center)
                .backgroundColor(day === this.now().getDate() && (this.cap.calendarOffset ?? 0) === 0 ? this.ink : Color.Transparent).borderRadius(4)
              Text(day>0?holidayMarker(new Date(this.calendarDate().getFullYear(),this.calendarDate().getMonth(),day)):'').fontSize((6*this.unit())+'vp').fontColor(this.ink).textShadow(readingHalo(this.ink, this.unit(), this.readingHaloEnabled,this.cap.readingBlend)).opacity(this.readingHaloEnabled?1:.65)
              }.width('100%')
            }
          }, (day: number, index: number) => this.now().getFullYear() + ':' + this.now().getMonth() + ':' + this.now().getDate() + ':' + index + ':' + day)
        }.columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr').rowsGap(2 * this.unit()).width('100%')
          .height(Math.ceil(calendarCells(this.calendarDate()).length / 7) * (20 * this.unit() + 2 * this.unit()))
      } else if (this.cap.k === 'countdown' || this.cap.k === 'anniversary') {
        Text(this.cap.title || typeLabel(this.cap.k)).fontSize((12 * this.unit()) + 'vp').fontColor(this.ink).textShadow(readingHalo(this.ink, this.unit(), this.readingHaloEnabled,this.cap.readingBlend)).width('100%').textAlign(TextAlign.Center).maxLines(this.compact() ? 1 : 2).textOverflow({ overflow: TextOverflow.Ellipsis })
        Row({ space: 3 * this.unit() }) {
          Text(Math.abs(daysLeftOf(this.cap.date ?? '')) + '').fontSize((this.counterFont()) + 'vp').maxLines(1).fontWeight(FontWeight.Medium).fontColor(this.ink).textShadow(readingHalo(this.ink, this.unit(), this.readingHaloEnabled,this.cap.readingBlend))
          Text(this.cap.k === 'anniversary' ? (daysLeftOf(this.cap.date ?? '') > 0 ? '天后' : '天') : (daysLeftOf(this.cap.date ?? '') < 0 ? '天前' : '天'))
            .fontSize((12 * this.unit()) + 'vp').fontColor(this.ink).textShadow(readingHalo(this.ink, this.unit(), this.readingHaloEnabled,this.cap.readingBlend))
        }.width('100%').justifyContent(FlexAlign.Center).alignItems(VerticalAlign.Bottom)
        if (!this.compact()) { Text(this.cap.date ?? '').fontSize((10 * this.unit()) + 'vp').fontColor(this.ink).textShadow(readingHalo(this.ink, this.unit(), this.readingHaloEnabled,this.cap.readingBlend)).opacity(this.readingHaloEnabled?1:0.6) }
      } else if(this.cap.k==='battery') {
        BatteryCapability({cap:this.cap,ink:this.ink,readingHaloEnabled:this.readingHaloEnabled,unit:this.unit(),compact:this.compact()})
      } else if(this.cap.k==='timetable') {
        TimetableCapability({cap:this.cap,ink:this.ink,readingHaloEnabled:this.readingHaloEnabled,contentWidth:this.contentWidth,contentHeight:this.contentHeight,scaleFactor:this.scaleFactor,tick:this.tick})
      } else if(this.cap.k==='agenda') {
        SummaryCapability({cap:this.cap,ink:this.ink,readingHaloEnabled:this.readingHaloEnabled,contentWidth:this.contentWidth,contentHeight:this.contentHeight,scaleFactor:this.scaleFactor,tick:this.tick})
      } else {
        Text(typeLabel(this.cap.k)).fontSize((12 * this.unit()) + 'vp').fontColor(this.ink).textShadow(readingHalo(this.ink, this.unit(), this.readingHaloEnabled,this.cap.readingBlend)).opacity(this.readingHaloEnabled?1:0.65)
        Text(Math.floor(progressOf(this.cap.k, this.now()) * 100) + '%').fontSize(((this.compact() ? 24 : 38) * this.unit()) + 'vp').fontColor(this.ink).textShadow(readingHalo(this.ink, this.unit(), this.readingHaloEnabled,this.cap.readingBlend))
        Stack({ alignContent: Alignment.Start }) {
          Row().width('100%').height(4 * this.unit()).backgroundColor(this.ink).opacity(0.12)
          Row().width((progressOf(this.cap.k, this.now()) * 100) + '%').height(4 * this.unit()).backgroundColor(this.ink)
        }.width('100%').height(4 * this.unit()).borderRadius(2).clip(true)
      }
    }.width('100%').height('100%').justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
  }
}
