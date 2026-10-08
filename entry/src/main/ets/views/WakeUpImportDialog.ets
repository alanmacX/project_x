import { SettingsSegmented } from './SettingsSegmented';
import { SettingsAction } from './SettingsAction';
import { WeekTimetable } from './WeekTimetable';
import { CapBlock } from '../model/CardSchema';
import { AppDesign } from '../model/AppDesign';
import { CourseItem } from '../model/CardSchema';
import { WakeImport, WakeSlot, WakeCourse, resolveWakeUp, mondayDate } from '../model/WakeUpImport';
import { importScheduleFile, parseWakeUpText, importCalendarFiles } from '../model/ScheduleFiles';
import { taskpool } from '@kit.ArkTS';
import { picker } from '@kit.CoreFileKit';
@CustomDialog
export struct WakeUpImportDialog {
  controller:CustomDialogController;
  appDark:boolean=false;
  existingCount:number=0;
  onImport:(semester:string,courses:CourseItem[],replace:boolean,keepCalendar:boolean)=>void=()=>{};
  @State text:string='';
  @State calendarFile:boolean=false;
  @State parsed:WakeImport=new WakeImport();
  @State slots:WakeSlot[]=[];
  @State semester:string='';
  @State previewCap:CapBlock={k:'timetable'};
  @State previewReady:boolean=false;
  @State stage:boolean=false;
  @State periods:boolean=false;
  @State replace:boolean=false;
  @State keepCalendar:boolean=false;
  @State busy:boolean=false;
  @State error:string='';
  private alive:boolean=true;
  aboutToDisappear():void {this.alive=false;}
  private accept(json:string):void {
    if(!this.alive)return;this.parsed=JSON.parse(json) as WakeImport;this.slots=this.parsed.slots;this.semester=this.parsed.semester;this.stage=true;this.periods=this.slots.some((s)=>!s.start||!s.end);this.error='';this.refreshPreview();
  }
  private async parseText():Promise<void> {
    if(this.busy)return;this.busy=true;this.error='';
    try {this.calendarFile=false;this.accept(await taskpool.execute(new taskpool.Task(parseWakeUpText,this.text)) as string);}catch(e){if(this.alive)this.error=(e as Error).message.replace(/^Error:\s*/,'');}finally{if(this.alive)this.busy=false;}
  }
  private async file(ics:boolean=true):Promise<void> {
    const context=this.getUIContext().getHostContext();if(!context||this.busy)return;this.busy=true;this.error='';
    try {const options=new picker.DocumentSelectOptions();options.maxSelectNumber=ics?32:1;options.fileSuffixFilters=ics?['课程日历|.ics']:['WakeUp 课表|.wakeup_schedule,.json,.txt'];const files=await new picker.DocumentViewPicker(context).select(options);if(!files.length)return;
      const json=await taskpool.execute(ics?new taskpool.Task(importCalendarFiles,files):new taskpool.Task(importScheduleFile,files[0],'timetable')) as string;this.calendarFile=ics;this.accept(json);
    }catch(e){if(this.alive)this.error=(e as Error).message.replace(/^Error:\s*/,'');}finally{if(this.alive)this.busy=false;}
  }
  private date():void {
    this.getUIContext().showDatePickerDialog({selected:this.semester?new Date(this.semester+'T12:00:00'):new Date(),onAccept:(v:DatePickerResult)=>{
      if(this.alive){this.semester=mondayDate(v.year+'-'+('0'+((v.month??0)+1)).slice(-2)+'-'+('0'+v.day).slice(-2));this.refreshPreview();}
    }});
  }
  private time(node:number,start:boolean):void {
    const s=this.slots.find((v)=>v.node===node),value=(start?s?.start:s?.end)||'08:00',d=new Date();d.setHours(Number(value.slice(0,2)),Number(value.slice(3)),0,0);
    this.getUIContext().showTimePickerDialog({selected:d,useMilitaryTime:true,onAccept:(v:TimePickerResult)=>{
      if(!this.alive)return;const value=('0'+v.hour).slice(-2)+':'+('0'+v.minute).slice(-2);
      this.slots=this.slots.map((s:WakeSlot):WakeSlot=>({node:s.node,start:s.node===node&&start?value:s.start,end:s.node===node&&!start?value:s.end}));this.refreshPreview();
    }});
  }
  private slotTime(node:number,start:boolean):string {const slot=this.slots.find((value)=>value.node===node);return (start?slot?.start:slot?.end)||(start?'开始':'结束');}
  private refreshPreview():void {
    try {const courses=resolveWakeUp(this.parsed,this.semester,this.slots);courses.forEach((c:CourseItem,i:number)=>c.id='preview_'+i);
      this.previewCap={k:'timetable',semester:mondayDate(this.semester),courses:courses,skipHolidays:false};this.previewReady=true;
    }catch(_){this.previewReady=false;}
  }
  private confirm():void {
    try {const courses=resolveWakeUp(this.parsed,this.semester,this.slots);this.onImport(mondayDate(this.semester),courses,this.replace,this.keepCalendar);this.controller.close();}catch(e){this.error=(e as Error).message;}
  }
  build() {
    Scroll() {
    Column({space:14}) {
      Text(this.stage?'确认课程表':'导入课程表').fontSize(20).fontWeight(FontWeight.Medium).fontColor(AppDesign.text(this.appDark)).width('100%')
      if(!this.stage) {
        Text('导入一次即可保存在本机，之后新建课程表卡片无需重复导入。支持本地 ICS 课程日历。').fontSize(13).fontColor(AppDesign.muted(this.appDark)).width('100%')
        SettingsAction({label:'选择课程日历 .ics',onPress:()=>this.file(),appDark:this.appDark,isEnabled:!this.busy,emphasis:true})
        Column({space:8}) {
          Text('如何从 WakeUp 导入').fontSize(15).fontWeight(FontWeight.Medium).fontColor(AppDesign.text(this.appDark))
          Text('1  在鸿蒙 WakeUp 中选学校、登录教务并核对课表，再点分享 → 导出到日历。\n2  系统日历 → 查看全部日程，长按一门课程选“多选”，勾选本学期的课程后点分享。\n3  将格式改为日历日程（.ics），另存为；回到这里选择文件，核对周课表后确认。').fontSize(13).fontColor(AppDesign.muted(this.appDark)).width('100%')
          Text('已在鸿蒙 WakeUp 6.1.90 与系统日历核对批量分享路径。仅勾选课程，避免混入私人日程或全天节日；分开导出的文件也可一次多选（最多 32 个）。离线副本不会自动同步调课，更新后请重新导入。').fontSize(12).fontColor(AppDesign.muted(this.appDark)).width('100%')
        }.padding(16).width('100%').borderRadius(AppDesign.sectionRadius).backgroundColor(AppDesign.control(this.appDark))
        SettingsAction({label:'已有 WakeUp 备份文件',onPress:()=>this.file(false),appDark:this.appDark,isEnabled:!this.busy})
        TextArea({text:this.text,placeholder:'也可以粘贴 WakeUp 导出的课表文本（不是分享口令）'}).height(160).maxLength(262144).fontColor(AppDesign.text(this.appDark)).placeholderColor(AppDesign.muted(this.appDark)).backgroundColor(AppDesign.control(this.appDark)).borderRadius(16).onChange((v:string)=>this.text=v)
        SettingsAction({label:this.busy?'读取中':'预览粘贴的课表',onPress:()=>this.parseText(),appDark:this.appDark,isEnabled:!this.busy&&this.text.trim().length>0})
        Text('支持 .wakeup_schedule、JSON 或导出文本。节次作息、单双周与不连续周次会在导入预览中核对。').fontSize(12).fontColor(AppDesign.muted(this.appDark)).width('100%')
      } else {
        Text(this.parsed.name+' · '+this.parsed.courses.length+' 条上课安排').fontSize(13).fontColor(AppDesign.muted(this.appDark)).maxLines(1).textOverflow({overflow:TextOverflow.Ellipsis}).width('100%')
        SettingsAction({label:(this.calendarFile?'日历首周  ':'第一周周一  ')+(this.semester||'选择开学日期'),onPress:()=>this.date(),appDark:this.appDark,isEnabled:!this.busy&&!this.calendarFile})
        if(this.calendarFile){Text('按导出的实际日期排课，不会猜测节次或补齐空周。日历有变更时请重新导入。').fontSize(12).fontColor(AppDesign.muted(this.appDark)).width('100%')}
        SettingsSegmented({labels:['课程',this.slots.some((s)=>!s.start||!s.end)?'作息 · 待补全':'作息'],selectedIndex:this.periods?1:0,appDark:this.appDark,onSelect:(index:number)=>this.periods=index===1})
        Scroll() {
          Column({space:10}) {
            if(this.periods) {
              if(!this.slots.length){Text('所有课程已包含实际时间，无需配置节次。').fontSize(13).fontColor(AppDesign.muted(this.appDark))}
              ForEach(this.slots,(s:WakeSlot)=>{
                Row({space:8}) {Text('第 '+s.node+' 节').fontSize(14).fontColor(AppDesign.text(this.appDark)).layoutWeight(1);SettingsAction({label:this.slotTime(s.node,true),onPress:()=>this.time(s.node,true),appDark:this.appDark,isEnabled:!this.busy});SettingsAction({label:this.slotTime(s.node,false),onPress:()=>this.time(s.node,false),appDark:this.appDark,isEnabled:!this.busy})}.width('100%').padding(10).borderRadius(14).backgroundColor(AppDesign.control(this.appDark))
              },(s:WakeSlot)=>String(s.node))
            } else {
              if(this.previewReady) {WeekTimetable({cap:this.previewCap,appDark:this.appDark,initialWeek:1,heightLimit:230,editable:false})}
              else {Text('选择开学日期并补全作息后，即可预览周课表。').fontSize(13).fontColor(AppDesign.muted(this.appDark)).width('100%')}
            }
          }.width('100%')
        }.width('100%').height(this.periods?230:310).scrollBar(BarState.Off).align(Alignment.Top)
        if(this.existingCount>0) {Row({space:12}) {Text(this.replace?'替换现有 '+this.existingCount+' 条课程':'追加到现有课程').fontSize(13).fontColor(AppDesign.text(this.appDark)).layoutWeight(1);Toggle({type:ToggleType.Switch,isOn:this.replace}).onChange((v:boolean)=>this.replace=v)}.width('100%')}
        if(this.existingCount>0 && this.replace) {
          Row({space:12}) {Text('保留当前课表的校历').fontSize(13).fontColor(AppDesign.text(this.appDark)).layoutWeight(1);Toggle({type:ToggleType.Switch,isOn:this.keepCalendar}).onChange((v:boolean)=>this.keepCalendar=v)}.width('100%')
          Text('换学校或学期时建议关闭；仅更新同一课表时，可保留原停课和整天调课安排。单次课程变动会清除。').fontSize(12).fontColor(AppDesign.muted(this.appDark)).width('100%')
        }
      }
      if(this.error){Text(this.error).fontSize(12).fontColor('#B34735').width('100%').maxLines(3).textOverflow({overflow:TextOverflow.Ellipsis})}
      Row({space:10}) {SettingsAction({label:'取消',onPress:():void=>{this.controller.close();},appDark:this.appDark,isEnabled:!this.busy});if(this.stage){SettingsAction({label:'重新选择',onPress:()=>{this.stage=false;this.error='';},appDark:this.appDark,isEnabled:!this.busy});Button('确认导入',{type:ButtonType.Capsule, buttonStyle:ButtonStyleMode.EMPHASIZED, role:ButtonRole.NORMAL}).height(44).fontSize(14).layoutWeight(1).backgroundColor(AppDesign.selected(this.appDark)).fontColor(AppDesign.onSelected(this.appDark)).onClick(()=>this.confirm());}}
    }.padding(20).width('100%')
    }.width('92%').constraintSize({maxWidth:560,maxHeight:'90%'}).scrollBar(BarState.Off).borderRadius(24).backgroundColor(AppDesign.surface(this.appDark))
  }
}
