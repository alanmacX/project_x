import { CapBlock, TeachingDay, CourseChange } from '../model/CardSchema';
import { dateKey, daysBetween, holidayKnown, HolidayDate } from '../model/HolidayCalendar';
import { importHolidayFile } from '../model/HolidayFiles';
import { AppDesign } from '../model/AppDesign';
import { taskpool } from '@kit.ArkTS';
import { picker } from '@kit.CoreFileKit';
import { LessonExceptionEditor } from './LessonExceptionEditor';
@CustomDialog
export struct CalendarRulesDialog {
  controller:CustomDialogController;
  cap:CapBlock={k:'timetable'};
  appDark:boolean=false;
  onSave:(cap:CapBlock)=>void=()=>{};
  @State draft:CapBlock={k:'timetable'};
  @State busy:boolean=false;
  @State error:string='';
  private alive:boolean=true;
  private lessonDialog:CustomDialogController|null=null;
  aboutToAppear():void {this.draft=JSON.parse(JSON.stringify(this.cap)) as CapBlock;}
  aboutToDisappear():void {this.alive=false;this.lessonDialog?.close();}
  private update():void {this.draft=JSON.parse(JSON.stringify(this.draft)) as CapBlock;}
  private day(run:(date:string)=>void,initial:string=dateKey(new Date())):void {
    this.getUIContext().showDatePickerDialog({selected:new Date(initial+'T12:00:00'),onAccept:(value:DatePickerResult)=>{
      const key=dateKey(new Date(value.year??2026,value.month??0,value.day??1));setTimeout(()=>{if(this.alive)run(key);},100);
    }});
  }
  private setDays(rules:TeachingDay[]):void {
    const next=(this.draft.teachingDays??[]).filter((d:TeachingDay)=>!rules.some((r:TeachingDay)=>r.date===d.date)).concat(rules);
    if(next.length>512){this.error='校历最多设置 512 天，请先移除旧规则';return;}
    this.draft.teachingDays=next.sort((a:TeachingDay,b:TeachingDay)=>a.date.localeCompare(b.date));this.update();
  }
  private addDay():void {
    this.getUIContext().getPromptAction().showActionMenu({title:'学校教学安排',buttons:[{text:'停课一段时间',color:AppDesign.text(this.appDark)},{text:'把某天课程移到另一天',color:AppDesign.text(this.appDark)},{text:'指定日期照常上课',color:AppDesign.text(this.appDark)}]}).then((result)=>{
      if(!this.alive)return;
      if(result.index===0)this.day((first:string)=>this.day((last:string)=>{try{this.setDays(daysBetween(first,last).map((date:string):TeachingDay=>({date:date,sourceDate:''})));}catch(e){this.error=(e as Error).message;}},first));
      if(result.index===1)this.day((source:string)=>this.day((target:string)=>this.setDays([{date:target,sourceDate:source}]),source));
      if(result.index===2)this.day((date:string)=>this.setDays([{date:date,sourceDate:date}]));
    }).catch(()=>{});
  }
  private lesson():void {
    if(!(this.draft.courses??[]).length){this.error='请先导入或添加课程';return;}
    this.lessonDialog=new CustomDialogController({builder:LessonExceptionEditor({courses:this.draft.courses??[],semester:this.draft.semester??'',appDark:this.appDark,onSave:(change:CourseChange)=>{
      if(!this.alive)return;
      const changes=(this.draft.courseChanges??[]).filter((c:CourseChange)=>!(c.courseId===change.courseId&&c.date===change.date));
      if(changes.length>=256){this.error='单次调课最多 256 条';return;}
      this.draft.courseChanges=changes.concat([change]);this.update();
    }}),customStyle:true,autoCancel:true});this.lessonDialog.open();
  }
  private async importDays():Promise<void> {
    const context=this.getUIContext().getHostContext();if(!context||this.busy)return;this.busy=true;this.error='';
    try {
      const options=new picker.DocumentSelectOptions();options.maxSelectNumber=1;options.fileSuffixFilters=['全天假期日历|.ics'];
      const files=await new picker.DocumentViewPicker(context).select(options);if(!files.length||!this.alive)return;
      const dates=JSON.parse(await taskpool.execute(new taskpool.Task(importHolidayFile,files[0],context.cacheDir)) as string) as HolidayDate[];
      if(!this.alive)return;this.draft.holidayDates=dates;this.update();
    }catch(e){if(this.alive)this.error=(e as Error).message;}finally{if(this.alive)this.busy=false;}
  }
  @Builder
  action(label:string,run:()=>void) {Button(label,{type:ButtonType.Capsule, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL}).height(44).width('100%').fontSize(14).backgroundColor(AppDesign.control(this.appDark)).fontColor(AppDesign.text(this.appDark)).enabled(!this.busy).onClick(run)}
  build() {
    Column({space:16}) {
      Text('假期与调课').fontSize(20).fontWeight(FontWeight.Medium).fontColor(AppDesign.text(this.appDark)).width('100%')
      Scroll() {Column({space:20}) {
        Column({space:12}) {
          Row() {Text('国内假期停课').fontSize(15).fontColor(AppDesign.text(this.appDark));Blank();Toggle({type:ToggleType.Switch,isOn:this.draft.skipHolidays!==false}).onChange((value:boolean)=>{this.draft.skipHolidays=value;this.update();})}.width('100%').height(44)
          Text('内置 2025–2026 年官方放假日期，离线可用。补班日只做标记，补哪天的课按学校安排设置。').fontSize(12).fontColor(AppDesign.muted(this.appDark)).width('100%')
          if(!holidayKnown(Number((this.draft.semester??'').slice(0,4)))||Number((this.draft.semester??'').slice(0,4))>=2026){Text('2027 年及以后尚无预置放假安排，可导入校历或手动设置。').fontSize(12).fontColor(AppDesign.muted(this.appDark)).width('100%')}
          this.action(this.busy?'读取中':'导入假期日历 .ics',()=>this.importDays())
          if((this.draft.holidayDates??[]).length) {
            Text('已导入 '+this.draft.holidayDates!.length+' 个假期日期；保存后生效。').fontSize(12).fontColor(AppDesign.muted(this.appDark)).width('100%')
            this.action('移除导入的假期',()=>{this.draft.holidayDates=[];this.update();})
          }
        }.width('100%')
        Column({space:12}) {
          Text('学校校历').fontSize(16).fontWeight(FontWeight.Medium).fontColor(AppDesign.text(this.appDark)).width('100%')
          this.action('设置停课／整天调课',()=>this.addDay())
          ForEach(this.draft.teachingDays??[],(day:TeachingDay)=>{
            Row({space:8}) {Text(day.date+' · '+(day.sourceDate===''?'停课':day.sourceDate===day.date?'照常上课':'上 '+day.sourceDate+' 的课')).fontSize(13).fontColor(AppDesign.text(this.appDark)).layoutWeight(1);Button('移除',{type:ButtonType.Capsule, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.ERROR}).height(44).fontSize(12).backgroundColor(AppDesign.control(this.appDark)).fontColor('#C43A35').onClick(()=>{this.draft.teachingDays=this.draft.teachingDays!.filter((d:TeachingDay)=>d.date!==day.date);this.update();})}.width('100%')
          },(day:TeachingDay)=>day.date)
        }.width('100%')
        Column({space:12}) {
          Text('单次课程变动').fontSize(16).fontWeight(FontWeight.Medium).fontColor(AppDesign.text(this.appDark)).width('100%')
          this.action('取消一节课／单次调课',()=>this.lesson())
          ForEach(this.draft.courseChanges??[],(change:CourseChange)=>{
            Row({space:8}) {Column({space:4}) {Text(this.draft.courses?.find((c)=>c.id===change.courseId)?.name??'课程').fontSize(14).fontColor(AppDesign.text(this.appDark)).width('100%');Text(change.date+' → '+(change.targetDate?change.targetDate+' '+change.start:'取消')).fontSize(12).fontColor(AppDesign.muted(this.appDark)).width('100%')}.layoutWeight(1);Button('移除',{type:ButtonType.Capsule, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.ERROR}).height(44).fontSize(12).backgroundColor(AppDesign.control(this.appDark)).fontColor('#C43A35').onClick(()=>{this.draft.courseChanges=this.draft.courseChanges!.filter((c:CourseChange)=>c.id!==change.id);this.update();})}.width('100%')
          },(change:CourseChange)=>change.id)
          Text('变动只在本机保存，不会修改学校教务。替换课表默认清除旧校历与单次变动；仅更新同一课表时，可在导入页选择保留校历。').fontSize(12).fontColor(AppDesign.muted(this.appDark)).width('100%')
        }.width('100%')
      }.width('100%')}.width('100%').layoutWeight(1).scrollBar(BarState.Off)
      if(this.error){Text(this.error).fontSize(12).fontColor('#C43A35').width('100%').maxLines(3)}
      Row({space:12}) {Button('取消',{type:ButtonType.Capsule, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL}).height(44).layoutWeight(1).backgroundColor(AppDesign.control(this.appDark)).fontColor(AppDesign.text(this.appDark)).onClick(()=>this.controller.close());Button('保存',{type:ButtonType.Capsule, buttonStyle:ButtonStyleMode.EMPHASIZED, role:ButtonRole.NORMAL}).height(44).layoutWeight(1).enabled(!this.busy).backgroundColor(AppDesign.selected(this.appDark)).fontColor(AppDesign.onSelected(this.appDark)).onClick(()=>{this.onSave(this.draft);this.controller.close();})}.width('100%')
    }.width('94%').height('85%').constraintSize({maxWidth:620,maxHeight:640}).padding(20).borderRadius(24).backgroundColor(AppDesign.surface(this.appDark))
  }
}
