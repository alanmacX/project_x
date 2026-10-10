import { AlbumSettings } from './AlbumSettings';
import { SettingsAction } from './SettingsAction';
import { applyTimetableImport } from '../model/TimetableImport';
import { TimetableDialog } from './TimetableDialog';
import { mondayDate } from '../model/WakeUpImport';
import { CalendarRulesDialog } from './CalendarRulesDialog';
import { CapBlock, CourseItem, AgendaItem } from '../model/CardSchema';
import { eventWhen } from '../model/CapabilityData';
import { readCapability, hasWholeCalendarAccess } from '../model/CapabilityService';
import { importScheduleFile } from '../model/ScheduleFiles';
import { AppDesign } from '../model/AppDesign';
import { SettingsSegmented } from './SettingsSegmented';
import { settingsDialogOpen, settingsDialogClose } from '../model/SettingsMotion';
import { taskpool } from '@kit.ArkTS';
import { picker } from '@kit.CoreFileKit';
import { CourseEditor } from './CourseEditor';
import { WakeUpImportDialog } from './WakeUpImportDialog';
@Component
export struct CapabilitySettings {
  @Prop @Watch('inputChanged') cap:CapBlock={k:'battery'};
  @Prop @Watch('inputChanged') cardId:string='';
  @Prop appDark:boolean=false;
  @Prop section:string='all';
  @Prop tick:number=0;
  onUpdate:(id:string,cap:CapBlock)=>void=()=>{};
  onReuseTimetable:(id:string)=>void=()=>{};
  @State busy:boolean=false;
  @State wholeCalendarAccess:boolean=false;
  @State message:string='';
  private dialog:CustomDialogController|null=null;
  private alive:boolean=true;
  private generation:number=0;
  private inputKey:string='';
  private inputChanged():void {
    const key=this.cardId+'|'+this.cap.k;
    if(key===this.inputKey)return;this.inputKey=key;this.generation++;this.busy=false;this.message='';
  }
  aboutToAppear():void {
    this.alive=true;this.inputChanged();const context=this.getUIContext().getHostContext();
    if(context)hasWholeCalendarAccess(context).then((available:boolean)=>{if(this.alive)this.wholeCalendarAccess=available;}).catch(()=>{});
  }
  aboutToDisappear():void {this.alive=false;this.generation++;this.dialog?.close();}
  private text():string{return AppDesign.text(this.appDark);}
  private control():string{return AppDesign.control(this.appDark);}
  private copy():CapBlock {return JSON.parse(JSON.stringify(this.cap)) as CapBlock;}
  private change(next:CapBlock):void {this.generation++;this.busy=false;this.message='';this.onUpdate(this.cardId,next);}
  private async refresh():Promise<void> {
    const context=this.getUIContext().getHostContext();if(!context||this.busy)return;
    const token=++this.generation,cap=this.copy(),id=this.cardId;this.busy=true;
    try{const next=await readCapability(cap,context);if(this.alive&&token===this.generation){this.message=next.refreshState==='failed'?next.desc??'更新失败':'';this.onUpdate(id,next);}}finally{if(token===this.generation)this.busy=false;}
  }
  private async readSystemAgenda():Promise<void> {
    const context=this.getUIContext().getHostContext();if(!context||this.busy)return;
    const token=++this.generation,next=this.copy(),id=this.cardId;next.agendaSource='system';this.busy=true;
    try {const result=await readCapability(next,context);if(!this.alive||token!==this.generation)return;
      if(result.refreshState==='failed')this.message=result.desc??'系统日历尚未授权';else this.onUpdate(id,result);
    }finally{if(token===this.generation)this.busy=false;}
  }
  private editCourse(course?:CourseItem):void {
    const id=this.cardId;
    this.dialog=new CustomDialogController({builder:CourseEditor({course:course??{id:'',name:'',room:'',day:1,start:'08:00',end:'09:40',firstWeek:1,lastWeek:16,parity:0},appDark:this.appDark,onDelete:()=>{if(!this.alive||this.cardId!==id||!course)return;const next=this.copy();next.courses=(next.courses??[]).filter((c)=>c.id!==course.id);next.courseChanges=(next.courseChanges??[]).filter((c)=>c.courseId!==course.id);this.change(next);},onSave:(value:CourseItem)=>{
      if(!this.alive||this.cardId!==id)return;const next=this.copy(),courses=(next.courses??[]).filter((c)=>c.id!==value.id);courses.push(value);next.courses=courses;this.change(next);
    }}),customStyle:true,openAnimation:settingsDialogOpen(),closeAnimation:settingsDialogClose(),alignment:DialogAlignment.Center,autoCancel:true});this.dialog.open();
  }
  private calendarRules():void {
    const id=this.cardId;
    this.dialog=new CustomDialogController({builder:CalendarRulesDialog({cap:this.copy(),appDark:this.appDark,onSave:(cap:CapBlock)=>{
      if(this.alive&&this.cardId===id&&this.cap.k==='timetable')this.change(cap);
    }}),customStyle:true,openAnimation:settingsDialogOpen(),closeAnimation:settingsDialogClose(),autoCancel:true});this.dialog.open();
  }
  private semesterDate():void {
    const id=this.cardId,initial=new Date((this.cap.semester??'')+'T12:00:00');
    this.getUIContext().showDatePickerDialog({selected:isNaN(initial.getTime())?new Date():initial,onAccept:(v:DatePickerResult)=>{
      if(!this.alive||this.cardId!==id||this.cap.k!=='timetable'||v.year===undefined||v.month===undefined||v.day===undefined)return;
      const next=this.copy();next.semester=mondayDate(v.year+'-'+('0'+((v.month??0)+1)).slice(-2)+'-'+('0'+v.day).slice(-2));this.change(next);
    }});
  }
  private async importSchedule():Promise<void> {
    const context=this.getUIContext().getHostContext();if(!context||this.busy||this.cap.k!=='agenda')return;const token=++this.generation,id=this.cardId,cap=this.copy();this.busy=true;
    try{
      const options=new picker.DocumentSelectOptions();options.maxSelectNumber=1;options.fileSuffixFilters=['日历|.ics'];
      const files=await new picker.DocumentViewPicker(context).select(options);if(!files.length)return;
      const json=await taskpool.execute(new taskpool.Task(importScheduleFile,files[0],cap.k)) as string;
      if(!this.alive||token!==this.generation)return;
      cap.events=JSON.parse(json) as AgendaItem[];cap.agendaSource='imported';cap.updatedAt=Date.now();cap.refreshState='done';
      this.onUpdate(id,cap);this.message='已导入，请检查预览';
    }catch(e){if(this.alive)this.message=(e as Error).message;}finally{if(token===this.generation)this.busy=false;}
  }
  private importTimetable():void {
    const id=this.cardId;
    this.dialog=new CustomDialogController({builder:WakeUpImportDialog({appDark:this.appDark,existingCount:(this.cap.courses??[]).length,onImport:(semester:string,courses:CourseItem[],replace:boolean,keepCalendar:boolean)=>{
      if(!this.alive||this.cardId!==id||this.cap.k!=='timetable')return;
      this.change(applyTimetableImport(this.cap,semester,courses,replace,keepCalendar));
    }}),customStyle:true,openAnimation:settingsDialogOpen(),closeAnimation:settingsDialogClose(),alignment:DialogAlignment.Center,autoCancel:true});this.dialog.open();
  }
  private showTimetable():void {
    const id=this.cardId;
    this.dialog=new CustomDialogController({builder:TimetableDialog({cap:this.copy(),appDark:this.appDark,onCourse:(c:CourseItem)=>{
      if(this.alive&&this.cardId===id)this.editCourse(c);
    }}),customStyle:true,openAnimation:settingsDialogOpen(),closeAnimation:settingsDialogClose(),autoCancel:true});this.dialog.open();
  }
  build() {
    Column({space:12}) {
      if(this.cap.k==='album') {AlbumSettings({section:this.section,showPresentation:false,tick:this.tick,cap:this.cap,cardId:this.cardId,appDark:this.appDark,onUpdate:this.onUpdate})}
      if(this.cap.k==='battery') {

        SettingsAction({label:this.busy?'更新中':'更新电量',onPress:()=>this.refresh(),appDark:this.appDark,isEnabled:!this.busy,fillWidth:true})
      }
      if(this.cap.k==='agenda') {
        if(this.wholeCalendarAccess) {SettingsAction({label:'读取系统日历',onPress:()=>this.readSystemAgenda(),appDark:this.appDark,isEnabled:!this.busy,fillWidth:true})}
        SettingsAction({label:'导入日历文件 .ics',onPress:()=>this.importSchedule(),appDark:this.appDark,isEnabled:!this.busy,fillWidth:true})
        if(this.cap.agendaSource==='imported'){Text('本地日历副本；原文件修改后需要重新导入').fontSize(12).fontColor(AppDesign.muted(this.appDark)).width('100%')}
      }
      if(this.cap.k==='timetable') {
        if(this.section==='all'||this.section==='display') {

        Text('卡片展示').fontSize(13).fontColor(AppDesign.muted(this.appDark)).width('100%')
        SettingsSegmented({labels:['下一课','每日概览'],selectedIndex:this.cap.timetableMode==='day'?1:0,appDark:this.appDark,
          onSelect:(index:number)=>{const next=this.copy();next.timetableMode=index===1?'day':'next';this.change(next);}})

        }
        if(this.section==='all'||this.section==='courses') {
        Row() {
          Text('学期课表').fontSize(14).fontWeight(FontWeight.Medium).fontColor(this.text()).layoutWeight(1)
          Button('添加课程',{type:ButtonType.Capsule, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL}).height(44).fontSize(13).fontColor(this.text()).backgroundColor(this.control()).onClick(()=>this.editCourse())
        }.width('100%')
        SettingsAction({label:'使用已保存课表',onPress:()=>this.onReuseTimetable(this.cardId),appDark:this.appDark,isEnabled:!this.busy,fillWidth:true})
        SettingsAction({label:'查看周课表 · '+(this.cap.courses??[]).length+' 条安排',onPress:()=>this.showTimetable(),appDark:this.appDark,isEnabled:!this.busy,fillWidth:true})
        Row({space:8}) {
          Button('导入课表',{type:ButtonType.Capsule, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL}).height(44).layoutWeight(1).fontSize(14).fontColor(this.text()).backgroundColor(this.control()).onClick(()=>this.importTimetable())
          if(this.section==='all') {Button('假期与调课',{type:ButtonType.Capsule, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL}).height(44).layoutWeight(1).fontSize(14).fontColor(this.text()).backgroundColor(this.control()).onClick(()=>this.calendarRules())}
        }.width('100%')
        }
        if(this.section==='all'||this.section==='calendar') {
        SettingsAction({label:'假期与调课',onPress:()=>this.calendarRules(),appDark:this.appDark,isEnabled:!this.busy,fillWidth:true})
        SettingsAction({label:'第一周周一  '+(this.cap.semester??'选择开学日期'),onPress:()=>this.semesterDate(),appDark:this.appDark,isEnabled:!this.busy,fillWidth:true})
        }
      }
      if(this.message || this.cap.refreshState==='failed') {Text(this.message||this.cap.desc||'更新失败，保留上次结果').fontSize(12).fontColor(AppDesign.muted(this.appDark)).width('100%')}
    }.width('100%')
  }
}
