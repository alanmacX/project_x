import { readingMaterialVariant } from '../model/MicaMaterialStudy';
import { daysLeftOf, calendarCells, progressOf, detailedCalendar, calendarDetails } from '../model/CapabilityCalendar';
import { hookReserve } from '../model/MicaGeometry';
import { ReadingHook } from './ReadingHook';
import { compositionPadding } from '../model/ReadingComposition';
import { ReadingBacking } from './ReadingBacking';
import { paperTextWidth } from '../model/PaperTextWidth';
import { readingHalo } from '../model/CapabilityPresentation';
import { cityReading, clockOffset, lunarReading } from '../model/TimeCapabilities';
import { SummaryCapability } from './SummaryCapability';
import { holidayName, holidayMarker } from '../model/HolidayCalendar';
import { CapBlock, typeLabel, contrastingInk } from '../model/CardSchema';
import { capabilityMinimum, compactCapability, capabilityFits, boundedReadoutFont, capabilityVisualHeight } from '../model/CapabilityMetrics';
import { TimetableCapability } from './TimetableCapability';
import { BatteryCapability } from './BatteryCapability';
export { typeLabel } from '../model/CardSchema';
export { daysLeftOf, calendarCells, progressOf } from '../model/CapabilityCalendar';
@Component
export struct CapabilityView {
  @Prop cap: CapBlock = { k: 'clock' };
  @Prop ink: string = '#262824';
  @Prop readingHaloEnabled: boolean = false;
  @Prop contentBackingEnabled:boolean=false;
  @Prop backingTint:string='#E8D6B0';
  @Prop backingEdge:string='';
  @Prop backingProfile:number[]=[];
  @Prop backingLeft:boolean=true;
  @Prop backingGutter:number=0;
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
    return Math.min(this.cap.k==='calendar'?1:2, this.contentWidth / min.w, this.contentHeight / Math.max(min.h,capabilityVisualHeight(this.cap,this.compact()))) * this.scaleFactor;
  }
  private dateCaption():string {
    const now=this.now(), holiday=holidayName(now);
    if(holiday)return holiday;
    return (this.compact()?'':now.getFullYear()+'年')+(now.getMonth()+1)+'月 · '+['周日','周一','周二','周三','周四','周五','周六'][now.getDay()]+(holidayMarker(now)==='班'?' · 班':'');
  }
  private dateFont():number {return boundedReadoutFont((this.compact()?24:54)*this.unit(),this.contentWidth*this.scaleFactor,2.8);}
  private clockFont(world: boolean = false): number {
    const nominal = world ? (this.compact()?28:40) : (this.compact()?24:42);
    // Four digits plus colon, with room for the widest system font glyphs.
    return boundedReadoutFont(nominal*this.unit(), this.contentWidth*this.scaleFactor, 3.2);
  }
  private undersized(): boolean { return !capabilityFits(this.cap,this.contentWidth,this.contentHeight); }
  private lunarFont():number {
    const count=lunarReading(this.now().getTime()).date.replace(/\s/g,'').length+.35;
    return boundedReadoutFont((this.compact()?18:26)*this.unit(),this.contentWidth*this.scaleFactor,count);
  }
  private counterFont(): number {
    const digits = (Math.abs(daysLeftOf(this.cap.date ?? '')) + '').length;
    return Math.max(0,Math.min((this.compact() ? 24 : 44) * this.unit(), (this.contentWidth * this.scaleFactor - 32 * this.unit()) / Math.max(1,digits * .7)));
  }
  private detailedMonth():boolean {return !this.compact()&&this.contentHeight*this.scaleFactor>=(Math.ceil(calendarCells(this.calendarDate()).length/7)*36+(this.ownBacking()?46:70))*this.unit()&&detailedCalendar(this.contentWidth,this.contentHeight,Math.ceil(calendarCells(this.calendarDate()).length/7),this.ownBacking());}
  private monthRowHeight():number {return this.detailedMonth()?34:22;}
  private ownBacking():boolean {return this.contentBackingEnabled&&!['battery','timetable','agenda'].includes(this.cap.k);}
  private measured(text:string,font:number,weight:number=400):number {return paperTextWidth(text,font,weight);}
  private backingWidth():number {
    if(this.cap.k==='calendar'&&this.detailedMonth())return (this.contentWidth+2*compositionPadding(this.cap.readingBlend??'')+this.backingGutter)*this.scaleFactor;
    if(this.backingProfile.length)return (this.contentWidth+2*compositionPadding(this.cap.readingBlend??'')+this.backingGutter)*this.scaleFactor;
    const u=this.unit(),max=this.contentWidth*this.scaleFactor;let width=max;
    if(this.cap.k==='clock')width=this.measured('88:88',this.clockFont(),500);
    else if(this.cap.k==='worldclock') {const city=cityReading(this.cap.zone??'',this.now().getTime());width=Math.max(this.measured(city.city,12*u),this.measured('88:88',this.clockFont(true),500),this.measured('12月31日 · 周三',11*u),this.compact()?0:this.measured(city.difference,11*u));}
    else if(this.cap.k==='lunar') {const lunar=lunarReading(this.now().getTime());width=Math.max(this.measured('农历',12*u),this.measured(lunar.date,this.lunarFont(),500),this.measured(lunar.year,12*u));}
    else if(this.cap.k==='date')width=Math.max(this.measured('88日',this.dateFont(),500),this.measured(this.dateCaption(),12*u));
    else if(this.cap.k==='calendar')width=max;
    else if(this.cap.k==='countdown'||this.cap.k==='anniversary')width=Math.max(this.measured(this.cap.title||typeLabel(this.cap.k),12*u),this.measured(String(Math.abs(daysLeftOf(this.cap.date??''))),this.counterFont(),500)+this.measured(this.cap.k==='anniversary'?(daysLeftOf(this.cap.date??'')>0?'天后':'天'):(daysLeftOf(this.cap.date??'')<0?'天前':'天'),12*u)+3*u,this.compact()?0:this.measured(this.cap.date??'',10*u));
    else if(this.cap.k==='dayprogress'||this.cap.k==='yearprogress')width=Math.max(64*u,this.measured(typeLabel(this.cap.k),12*u),this.measured('100%',(this.compact()?24:38)*u));
    return Math.min((this.contentWidth+2*compositionPadding(this.cap.readingBlend??''))*this.scaleFactor,Math.ceil(width)+2*compositionPadding(this.cap.readingBlend??'')*u);
  }
  @Builder private readingBackground() {if(this.ownBacking()){ReadingBacking({study:readingMaterialVariant(this.cap.readingMaterialStudy,this.cap.readingMaterial),blend:this.cap.readingBlend??'feather',tint:this.backingTint,edge:this.backingEdge,profile:this.backingProfile,contactLeft:this.backingLeft,surfaceWidth:this.backingWidth(),surfaceHeight:(this.contentHeight+2*compositionPadding(this.cap.readingBlend??''))*this.scaleFactor,hook:this.cap.readingHook??.2,ink:this.ink,radius:Math.min(8*this.unit(),this.backingWidth()*.12),scaleFactor:this.unit()})}}
  @Builder private readingHook() {if(this.ownBacking()&&['tag','dock'].includes(this.cap.readingBlend??'')){ReadingHook({hook:this.cap.readingHook??.2,scaleFactor:this.unit()})}}
  @State private backingHeight:number=0;
  build() {
    Column() {
    Stack({alignContent:Alignment.TopStart}) {
      if(this.ownBacking()){Column(){this.readingBackground()}.width(this.backingWidth()).height(this.backingHeight).position({x:0,y:0}).hitTestBehavior(HitTestMode.None)}
    Column() {
    Column({ space: 4 * this.unit() }) {
      if (this.undersized()) {
        Text('空间不足').fontSize(Math.min(12*this.scaleFactor,this.contentHeight*this.scaleFactor/1.5,this.contentWidth*this.scaleFactor/4.2)).minFontScale(1).maxFontScale(1).fontColor(this.ink).textShadow(readingHalo(this.ink, this.unit(), this.readingHaloEnabled,this.cap.readingBlend)).maxLines(1).width('100%').textAlign(TextAlign.Center)
      } else if (this.cap.k === 'clock') {
        TextClock().format('HH:mm').fontSize(this.clockFont() + 'vp').height(this.clockFont()*1.35).fontWeight(FontWeight.Medium).fontColor(this.ink).textShadow(readingHalo(this.ink, this.unit(), this.readingHaloEnabled,this.cap.readingBlend))
      } else if (this.cap.k === 'worldclock') {
        Text(cityReading(this.cap.zone??'',this.now().getTime()).city).fontSize((12*this.unit())+'vp').minFontScale(1).maxFontScale(1).fontColor(this.ink).textShadow(readingHalo(this.ink, this.unit(), this.readingHaloEnabled,this.cap.readingBlend)).opacity(this.readingHaloEnabled?1:.65).maxLines(1)
        ForEach([clockOffset(this.cap.zone??'',this.now().getTime())],(offset:number)=>{
          Column({space:4*this.unit()}) {
            TextClock({timeZoneOffset:offset}).format('HH:mm').fontSize(this.clockFont(true)+'vp').height(this.clockFont(true)*1.35).fontWeight(FontWeight.Medium).fontColor(this.ink).textShadow(readingHalo(this.ink, this.unit(), this.readingHaloEnabled,this.cap.readingBlend))
            TextClock({timeZoneOffset:offset}).format('M月d日 · EEE').fontSize(boundedReadoutFont(11*this.unit(),this.contentWidth*this.scaleFactor,9)+'vp').fontColor(this.ink).textShadow(readingHalo(this.ink, this.unit(), this.readingHaloEnabled,this.cap.readingBlend))
          }
        },(offset:number)=>String(offset))
        if(!this.compact()) {Text(cityReading(this.cap.zone??'',this.now().getTime()).difference).fontSize((11*this.unit())+'vp').minFontScale(1).maxFontScale(1).fontColor(this.ink).textShadow(readingHalo(this.ink, this.unit(), this.readingHaloEnabled,this.cap.readingBlend)).opacity(this.readingHaloEnabled?1:.65).maxLines(1)}
      } else if (this.cap.k === 'lunar') {
        Text('农历').fontSize((12*this.unit())+'vp').minFontScale(1).maxFontScale(1).fontColor(this.ink).textShadow(readingHalo(this.ink, this.unit(), this.readingHaloEnabled,this.cap.readingBlend)).opacity(this.readingHaloEnabled?1:.65)
        Text(lunarReading(this.now().getTime()).date).fontSize(this.lunarFont()+'vp').fontWeight(FontWeight.Medium).minFontScale(1).maxFontScale(1).fontColor(this.ink).textShadow(readingHalo(this.ink, this.unit(), this.readingHaloEnabled,this.cap.readingBlend)).maxLines(1)
        Text(lunarReading(this.now().getTime()).year).fontSize((12*this.unit())+'vp').minFontScale(1).maxFontScale(1).fontColor(this.ink).textShadow(readingHalo(this.ink, this.unit(), this.readingHaloEnabled,this.cap.readingBlend)).opacity(this.readingHaloEnabled?1:.65).maxLines(1)
      } else if (this.cap.k === 'date') {
        TextClock().format('dd').fontSize(this.dateFont() + 'vp').height(this.dateFont()*1.35).width(Math.min(this.contentWidth*this.scaleFactor,this.measured('88日',this.dateFont(),500))).fontWeight(FontWeight.Medium).fontColor(this.ink).textShadow(readingHalo(this.ink, this.unit(), this.readingHaloEnabled,this.cap.readingBlend))
        Text(this.dateCaption()).fontSize((12 * this.unit()) + 'vp').minFontScale(1).maxFontScale(1).fontColor(this.ink).textShadow(readingHalo(this.ink, this.unit(), this.readingHaloEnabled,this.cap.readingBlend)).opacity(this.readingHaloEnabled?1:0.65).maxLines(1).textOverflow({overflow:TextOverflow.Ellipsis})
      } else if (this.cap.k === 'calendar' && this.compact() && (this.cap.calendarOffset ?? 0) === 0) {
        Text((this.now().getMonth() + 1) + '月 · 本周').fontSize((12 * this.unit()) + 'vp').minFontScale(1).maxFontScale(1).fontColor(this.ink).textShadow(readingHalo(this.ink, this.unit(), this.readingHaloEnabled,this.cap.readingBlend))
        Row() {
          ForEach(this.weekDays(), (day: number, index: number) => {
            Column({ space: 2 * this.unit() }) {
              Text(['日', '一', '二', '三', '四', '五', '六'][index]).fontSize((10 * this.unit()) + 'vp').minFontScale(1).maxFontScale(1).fontColor(this.ink).textShadow(readingHalo(this.ink, this.unit(), this.readingHaloEnabled,this.cap.readingBlend)).opacity(this.readingHaloEnabled?1:.6)
              Text('' + day).fontSize((12 * this.unit()) + 'vp').minFontScale(1).maxFontScale(1).fontColor(day === this.now().getDate() && (this.cap.calendarOffset ?? 0) === 0 ? contrastingInk(this.ink) : this.ink)
                .width('100%').height(20 * this.unit()).textAlign(TextAlign.Center)
                .backgroundColor(day === this.now().getDate() && (this.cap.calendarOffset ?? 0) === 0 ? this.ink : Color.Transparent).borderRadius(4)
            Text(holidayMarker(new Date(this.now().getFullYear(),this.now().getMonth(),this.now().getDate()-this.now().getDay()+index))).fontSize((7*this.unit())+'vp').minFontScale(1).maxFontScale(1).fontColor(this.ink).textShadow(readingHalo(this.ink, this.unit(), this.readingHaloEnabled,this.cap.readingBlend)).height(8*this.unit()).opacity(this.readingHaloEnabled?1:.65)
            }.layoutWeight(1)
          }, (day: number, index: number) => index + ':' + day)
        }.width('100%')
      } else if (this.cap.k === 'calendar' && this.compact()) {
        Text((this.calendarDate().getFullYear()) + '年').fontSize((12 * this.unit()) + 'vp').minFontScale(1).maxFontScale(1).fontColor(this.ink).textShadow(readingHalo(this.ink, this.unit(), this.readingHaloEnabled,this.cap.readingBlend)).opacity(this.readingHaloEnabled?1:.65)
        Text((this.calendarDate().getMonth() + 1) + '月').fontSize((28 * this.unit()) + 'vp').minFontScale(1).maxFontScale(1).fontColor(this.ink).textShadow(readingHalo(this.ink, this.unit(), this.readingHaloEnabled,this.cap.readingBlend))
        Text('点按查看月历').fontSize((10 * this.unit()) + 'vp').minFontScale(1).maxFontScale(1).fontColor(this.ink).textShadow(readingHalo(this.ink, this.unit(), this.readingHaloEnabled,this.cap.readingBlend)).opacity(this.readingHaloEnabled?1:.6)
      } else if (this.cap.k === 'calendar') {
        Text(this.calendarDate().getFullYear() + '年' + (this.calendarDate().getMonth() + 1) + '月').fontSize((14 * this.unit()) + 'vp').minFontSize(10*this.unit()).maxFontSize(14*this.unit()).maxLines(1).fontWeight(FontWeight.Medium).minFontScale(1).maxFontScale(1).fontColor(this.ink).textShadow(readingHalo(this.ink, this.unit(), this.readingHaloEnabled,this.cap.readingBlend)).height((this.ownBacking()?20:44)*this.unit()).width('100%').padding({left:(this.ownBacking()?0:44)*this.unit(),right:(this.ownBacking()?0:44)*this.unit()}).textAlign(TextAlign.Center)
        Row() {
          ForEach(['日', '一', '二', '三', '四', '五', '六'], (day: string) => {
            Text(day).fontSize((10 * this.unit()) + 'vp').minFontScale(1).maxFontScale(1).fontColor(this.ink).textShadow(readingHalo(this.ink, this.unit(), this.readingHaloEnabled,this.cap.readingBlend)).opacity(this.readingHaloEnabled?1:0.5).layoutWeight(1).textAlign(TextAlign.Center)
          }, (day: string) => day)
        }.width('100%')
        Grid() {
          ForEach(calendarCells(this.calendarDate()), (day: number, index: number) => {
            GridItem() {
              Column({space:1*this.unit()}) {
              Stack({alignContent:Alignment.TopEnd}) {
              Text(day > 0 ? '' + day : '').fontSize((12 * this.unit()) + 'vp')
                .fontColor(day === this.now().getDate() && (this.cap.calendarOffset ?? 0) === 0 ? contrastingInk(this.ink) : this.ink)
                .width('100%').height(20 * this.unit()).textAlign(TextAlign.Center)
                .backgroundColor(day === this.now().getDate() && (this.cap.calendarOffset ?? 0) === 0 ? this.ink : Color.Transparent).borderRadius(4)
              Text(day>0?holidayMarker(new Date(this.calendarDate().getFullYear(),this.calendarDate().getMonth(),day)):'').fontSize((6*this.unit())+'vp').minFontScale(1).maxFontScale(1).fontColor(this.ink).textShadow(readingHalo(this.ink, this.unit(), this.readingHaloEnabled,this.cap.readingBlend)).opacity(this.readingHaloEnabled?1:.65)
              }.width('100%')
              if(this.detailedMonth()){Text(calendarDetails(this.calendarDate())[index]).fontSize(7*this.unit()).minFontScale(1).maxFontScale(1).fontColor(this.ink).opacity(.6).maxLines(1).textOverflow({overflow:TextOverflow.Ellipsis}).width('100%').height(10*this.unit()).textAlign(TextAlign.Center)}
              }.width('100%')
            }
          }, (day: number, index: number) => this.now().getFullYear() + ':' + this.now().getMonth() + ':' + this.now().getDate() + ':' + index + ':' + day)
        }.columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr 1fr').rowsGap(2 * this.unit()).width('100%')
          .height(Math.ceil(calendarCells(this.calendarDate()).length / 7) * this.monthRowHeight()*this.unit())
      } else if (this.cap.k === 'countdown' || this.cap.k === 'anniversary') {
        Text(this.cap.title || typeLabel(this.cap.k)).fontSize((12 * this.unit()) + 'vp').minFontScale(1).maxFontScale(1).fontColor(this.ink).textShadow(readingHalo(this.ink, this.unit(), this.readingHaloEnabled,this.cap.readingBlend)).width('100%').textAlign(TextAlign.Center).maxLines(this.compact() ? 1 : 2).textOverflow({ overflow: TextOverflow.Ellipsis })
        Row({ space: 3 * this.unit() }) {
          Text(this.cap.date ? Math.abs(daysLeftOf(this.cap.date)) + '' : '—').fontSize((this.counterFont()) + 'vp').maxLines(1).fontWeight(FontWeight.Medium).minFontScale(1).maxFontScale(1).fontColor(this.ink).textShadow(readingHalo(this.ink, this.unit(), this.readingHaloEnabled,this.cap.readingBlend))
          Text(!this.cap.date ? '' : this.cap.k === 'anniversary' ? (daysLeftOf(this.cap.date ?? '') > 0 ? '天后' : '天') : (daysLeftOf(this.cap.date ?? '') < 0 ? '天前' : '天'))
            .fontSize((12 * this.unit()) + 'vp').fontColor(this.ink).textShadow(readingHalo(this.ink, this.unit(), this.readingHaloEnabled,this.cap.readingBlend))
        }.width('100%').justifyContent(FlexAlign.Center).alignItems(VerticalAlign.Bottom)
        if (!this.compact()) { Text(this.cap.date || '设置日期').fontSize((10 * this.unit()) + 'vp').minFontScale(1).maxFontScale(1).fontColor(this.ink).textShadow(readingHalo(this.ink, this.unit(), this.readingHaloEnabled,this.cap.readingBlend)).opacity(this.readingHaloEnabled?1:0.6) }
      } else if(this.cap.k==='battery') {
        BatteryCapability({cap:this.cap,ink:this.ink,readingHaloEnabled:this.readingHaloEnabled,contentBackingEnabled:this.contentBackingEnabled,backingTint:this.backingTint,backingEdge:this.backingEdge,backingProfile:this.backingProfile,backingLeft:this.backingLeft,backingGutter:this.backingGutter,scaleFactor:this.scaleFactor,unit:this.unit(),compact:this.compact()})
      } else if(this.cap.k==='timetable') {
        TimetableCapability({cap:this.cap,ink:this.ink,readingHaloEnabled:this.readingHaloEnabled,contentBackingEnabled:this.contentBackingEnabled,backingTint:this.backingTint,backingEdge:this.backingEdge,backingProfile:this.backingProfile,backingLeft:this.backingLeft,backingGutter:this.backingGutter,contentWidth:this.contentWidth,contentHeight:this.contentHeight,scaleFactor:this.scaleFactor,tick:this.tick})
      } else if(this.cap.k==='agenda') {
        SummaryCapability({cap:this.cap,ink:this.ink,readingHaloEnabled:this.readingHaloEnabled,contentBackingEnabled:this.contentBackingEnabled,backingTint:this.backingTint,backingEdge:this.backingEdge,backingProfile:this.backingProfile,backingLeft:this.backingLeft,backingGutter:this.backingGutter,contentWidth:this.contentWidth,contentHeight:this.contentHeight,scaleFactor:this.scaleFactor,tick:this.tick})
      } else {
        Text(typeLabel(this.cap.k)).fontSize((12 * this.unit()) + 'vp').minFontScale(1).maxFontScale(1).fontColor(this.ink).textShadow(readingHalo(this.ink, this.unit(), this.readingHaloEnabled,this.cap.readingBlend)).opacity(this.readingHaloEnabled?1:0.65)
        Text(Math.floor(progressOf(this.cap.k, this.now()) * 100) + '%').maxLines(1).fontSize(((this.compact() ? 24 : 38) * this.unit()) + 'vp').minFontScale(1).maxFontScale(1).fontColor(this.ink).textShadow(readingHalo(this.ink, this.unit(), this.readingHaloEnabled,this.cap.readingBlend))
        Stack({ alignContent: Alignment.Start }) {
          Row().width('100%').height(4 * this.unit()).backgroundColor(this.ink).opacity(0.12)
          Row().width((progressOf(this.cap.k, this.now()) * 100) + '%').height(4 * this.unit()).backgroundColor(this.ink)
        }.width('100%').height(4 * this.unit()).borderRadius(2).clip(true)
      }
    }.width(this.ownBacking()?Math.max(1,this.backingWidth()-2*compositionPadding(this.cap.readingBlend??'')*this.unit()-this.backingGutter*this.scaleFactor):'100%')
    }.width(this.ownBacking()?this.backingWidth():'100%').height(this.backingProfile.length?'100%':this.ownBacking()?undefined:'100%').padding({left:this.ownBacking()?compositionPadding(this.cap.readingBlend??'')*this.unit()+(this.backingLeft?this.backingGutter*this.scaleFactor:0):0,right:this.ownBacking()?compositionPadding(this.cap.readingBlend??'')*this.unit()+(!this.backingLeft?this.backingGutter*this.scaleFactor:0):0,bottom:this.ownBacking()?compositionPadding(this.cap.readingBlend??'')*this.unit():0,top:this.ownBacking()?compositionPadding(this.cap.readingBlend??'')*this.unit()+hookReserve(this.cap.readingBlend??'')*this.unit():0})
      .onSizeChange((_:SizeOptions,size:SizeOptions)=>{const h=Number(size.height);if(h>0&&Math.abs(h-this.backingHeight)>.01)this.backingHeight=h;}).justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
      if(this.ownBacking()&&['tag','dock'].includes(this.cap.readingBlend??'')){Column(){this.readingHook()}.width(this.backingWidth()).height(this.backingHeight).position({x:0,y:0}).hitTestBehavior(HitTestMode.None)}
    }.width(this.ownBacking()?this.backingWidth():'100%').height(this.backingProfile.length?'100%':this.ownBacking()?undefined:'100%')
    }.width('100%').height('100%').justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
  }
}
