import { CourseItem, CourseChange } from '../model/CardSchema';
import { dateKey, validDay } from '../model/HolidayCalendar';
import { semesterWeek } from '../model/CapabilityData';
import { SettingsSelect } from './SettingsSelect';
import { AppDesign } from '../model/AppDesign';
@CustomDialog
export struct LessonExceptionEditor {
  controller:CustomDialogController;
  courses:CourseItem[]=[];
  semester:string='';
  appDark:boolean=false;
  onSave:(change:CourseChange)=>void=()=>{};
  @State index:number=0;
  @State date:string='';
  @State target:string='';
  @State cancel:boolean=false;
  @State start:string='08:00';
  @State end:string='09:40';
  @State room:string='';
  @State error:string='';
  aboutToAppear():void {this.date=dateKey(new Date());this.target=this.date;this.choose(0);}
  private choose(index:number):void {this.index=index;const course=this.courses[index];if(course){this.start=course.start;this.end=course.end;this.room=course.room;}}
  private day(target:boolean):void {
    this.getUIContext().showDatePickerDialog({selected:new Date((target?this.target:this.date)+'T12:00:00'),onAccept:(value:DatePickerResult)=>{
      const key=dateKey(new Date(value.year??2026,value.month??0,value.day??1));if(target)this.target=key;else this.date=key;
    }});
  }
  private time(start:boolean):void {
    const date=new Date('2000-01-01T'+(start?this.start:this.end)+':00');
    this.getUIContext().showTimePickerDialog({selected:date,useMilitaryTime:true,onAccept:(value:TimePickerResult)=>{const time=('0'+value.hour).slice(-2)+':'+('0'+value.minute).slice(-2);if(start)this.start=time;else this.end=time;}});
  }
  private save():void {
    const course=this.courses[this.index],date=new Date(this.date+'T12:00:00'),week=semesterWeek(this.semester,date.getTime());
    if(!course||!validDay(this.date)||!validDay(this.target)){this.error='请选择课程与日期';return;}
    if((date.getDay()||7)!==course.day||week<course.firstWeek||week>course.lastWeek||(course.parity===1&&week%2===0)||(course.parity===2&&week%2!==0)) {this.error='原日期没有这节常规课程，请核对周次和星期';return;}
    if(!this.cancel&&this.end<=this.start){this.error='结束时间须晚于开始时间';return;}
    this.onSave({id:'change_'+Date.now(),courseId:course.id,date:this.date,targetDate:this.cancel?'':this.target,start:this.start,end:this.end,room:this.room});this.controller.close();
  }
  build() {
    Column({space:16}) {
      Text('单次停课／调课').fontSize(20).fontWeight(FontWeight.Medium).fontColor(AppDesign.text(this.appDark)).width('100%')
      Scroll() {Column({space:12}) {
        SettingsSelect({labels:this.courses.map((c:CourseItem)=>c.name+' · 周'+['一','二','三','四','五','六','日'][c.day-1]+' '+c.start),selectedIndex:this.index,
          valueLabel:this.courses[this.index]?.name??'',placeholder:'选择课程',appDark:this.appDark,onSelect:(index:number)=>this.choose(index)})
        Button('原上课日期  '+this.date,{type:ButtonType.Capsule,buttonStyle:ButtonStyleMode.NORMAL}).width('100%').height(44).backgroundColor(AppDesign.control(this.appDark)).fontColor(AppDesign.text(this.appDark)).onClick(()=>this.day(false))
        Row() {Text('取消这一次课程').fontSize(14).fontColor(AppDesign.text(this.appDark));Blank();Toggle({type:ToggleType.Switch,isOn:this.cancel}).onChange((value:boolean)=>this.cancel=value)}.width('100%').height(44)
        if(!this.cancel) {
          Button('改到  '+this.target,{type:ButtonType.Capsule,buttonStyle:ButtonStyleMode.NORMAL}).width('100%').height(44).backgroundColor(AppDesign.control(this.appDark)).fontColor(AppDesign.text(this.appDark)).onClick(()=>this.day(true))
          Row({space:8}) {Button('开始 '+this.start,{type:ButtonType.Capsule, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL}).layoutWeight(1).height(44).backgroundColor(AppDesign.control(this.appDark)).fontColor(AppDesign.text(this.appDark)).onClick(()=>this.time(true));Button('结束 '+this.end,{type:ButtonType.Capsule, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL}).layoutWeight(1).height(44).backgroundColor(AppDesign.control(this.appDark)).fontColor(AppDesign.text(this.appDark)).onClick(()=>this.time(false))}.width('100%')
          TextInput({text:this.room,placeholder:'教室 / 地点'}).height(44).borderRadius(12).backgroundColor(AppDesign.control(this.appDark)).fontColor(AppDesign.text(this.appDark)).placeholderColor(AppDesign.muted(this.appDark)).onChange((value:string)=>this.room=value)
        }
        Text('只影响指定日期，其他周次保持原安排。明确补课可以安排在假期；整天停课规则优先。').fontSize(12).fontColor(AppDesign.muted(this.appDark)).width('100%')
      }.width('100%')}.width('100%').layoutWeight(1).scrollBar(BarState.Off)
      if(this.error){Text(this.error).fontSize(12).fontColor('#C43A35').width('100%')}
      Row({space:12}) {Button('取消',{type:ButtonType.Capsule, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL}).layoutWeight(1).height(44).backgroundColor(AppDesign.control(this.appDark)).fontColor(AppDesign.text(this.appDark)).onClick(()=>this.controller.close());Button('保存',{type:ButtonType.Capsule, buttonStyle:ButtonStyleMode.EMPHASIZED, role:ButtonRole.NORMAL}).layoutWeight(1).height(44).backgroundColor(AppDesign.selected(this.appDark)).fontColor(AppDesign.onSelected(this.appDark)).onClick(()=>this.save())}.width('100%')
    }.width('92%').height('80%').constraintSize({maxWidth:520,maxHeight:530}).padding(20).borderRadius(24).backgroundColor(AppDesign.surface(this.appDark))
  }
}
