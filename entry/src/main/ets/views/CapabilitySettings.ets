import { applyTimetableImport } from '../model/TimetableImport';
import { ParcelImportDialog } from './ParcelImportDialog';
import { mergePickupParcels } from '../model/ParcelIntake';
import { TimetableDialog } from './TimetableDialog';
import { mondayDate } from '../model/WakeUpImport';
import { CalendarRulesDialog } from './CalendarRulesDialog';
import { ValuePicker } from './ValuePicker';
import { CapBlock, ParcelItem, CourseItem, AgendaItem } from '../model/CardSchema';
import { ValueField, pendingParcels, eventWhen } from '../model/CapabilityData';
import { fetchValueFields, recognizePickup } from '../model/CapabilityWorker';
import { readCapability, hasWholeCalendarAccess } from '../model/CapabilityService';
import { importScheduleFile } from '../model/ScheduleFiles';
import { AppDesign } from '../model/AppDesign';
import { SettingsSegmented } from './SettingsSegmented';
import { settingsReveal, settingsDialogOpen, settingsDialogClose } from '../model/SettingsMotion';
import { taskpool } from '@kit.ArkTS';
import { picker } from '@kit.CoreFileKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { CourseEditor } from './CourseEditor';
import { WakeUpImportDialog } from './WakeUpImportDialog';
@Component
export struct CapabilitySettings {
  @Prop @Watch('inputChanged') cap:CapBlock={k:'battery'};
  @Prop @Watch('inputChanged') cardId:string='';
  @Prop appDark:boolean=false;
  onUpdate:(id:string,cap:CapBlock)=>void=()=>{};
  @State busy:boolean=false;
  @State wholeCalendarAccess:boolean=false;
  @State message:string='';
  @State manualParcel:boolean=false;
  @State code:string=''; @State place:string='';
  private dialog:CustomDialogController|null=null;
  private alive:boolean=true;
  private generation:number=0;
  private inputKey:string='';
  private inputChanged():void {
    const key=this.cardId+'|'+this.cap.k+'|'+(this.cap.url??'');
    if(key===this.inputKey)return;this.inputKey=key;this.generation++;this.busy=false;this.message='';this.code='';this.place='';this.manualParcel=false;
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
  private async chooseURLField():Promise<void> {
    if(this.busy)return;const token=++this.generation,cap=this.copy(),id=this.cardId;this.busy=true;
    try{
      const fields=JSON.parse(await taskpool.execute(new taskpool.Task(fetchValueFields,cap.url??'')) as string) as ValueField[];
      if(!this.alive||token!==this.generation)return;
      this.dialog=new CustomDialogController({builder:ValuePicker({choices:fields,title:'选择要显示的内容',appDark:this.appDark,onChoose:(chosen:ValueField)=>{
        if(!this.alive||token!==this.generation)return;
        cap.field=chosen.path;cap.sourceConfigured=true;cap.value=chosen.value;cap.updatedAt=Date.now();cap.attemptedAt=Date.now();cap.refreshState='done';this.onUpdate(id,cap);
      }}),customStyle:true,openAnimation:settingsDialogOpen(),closeAnimation:settingsDialogClose(),alignment:DialogAlignment.Center,autoCancel:true});this.dialog.open();
    }catch(e){if(this.alive)this.message=(e as Error).message;}finally{if(token===this.generation)this.busy=false;}
  }
  private async pickScreenshot():Promise<void> {
    if(this.busy)return;const token=++this.generation;this.busy=true;
    try{
      const options=new photoAccessHelper.PhotoSelectOptions();options.maxSelectNumber=1;options.MIMEType=photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
      const result=await new photoAccessHelper.PhotoViewPicker().select(options);if(!result.photoUris.length)return;
      const notice=await taskpool.execute(new taskpool.Task(recognizePickup,result.photoUris[0])) as string;
      if(!this.alive||token!==this.generation)return;
      this.importParcels(notice);
    }catch(e){if(this.alive)this.message=(e as Error).message;}finally{if(token===this.generation)this.busy=false;}
  }
  private importParcels(notice:string=''):void {
    const id=this.cardId;
    this.dialog=new CustomDialogController({builder:ParcelImportDialog({appDark:this.appDark,initialText:notice,defaultPlace:this.cap.parcelPlace??'',onImport:(items:ParcelItem[])=>{
      if(!this.alive||this.cardId!==id||this.cap.k!=='parcel')return;
      const next=this.copy();next.parcels=mergePickupParcels(next.parcels??[],items,next.parcelPlace??'',Date.now());this.change(next);
    }}),customStyle:true,openAnimation:settingsDialogOpen(),closeAnimation:settingsDialogClose(),autoCancel:true});this.dialog.open();
  }
  private addParcel():void {
    const code=this.code.trim();if(!code){this.message='请填写取件码';return;}
    const next=this.copy();
    try{next.parcels=mergePickupParcels(next.parcels??[],[{id:'',code:code,place:this.place,picked:false}],next.parcelPlace??'',Date.now());this.change(next);this.code='';this.place='';this.manualParcel=false;}
    catch(e){this.message=(e as Error).message;}
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
  @Builder
  action(label:string,action:()=>void) {
    Button(label,{type:ButtonType.Capsule,buttonStyle:ButtonStyleMode.NORMAL,role:label==='清理已取记录'?ButtonRole.ERROR:ButtonRole.NORMAL}).height(44).width('100%').fontSize(14).fontColor(label==='清理已取记录'?'#C43A35':this.text()).backgroundColor(this.control()).enabled(!this.busy).onClick(action)
  }
  build() {
    Column({space:12}) {
      if(this.cap.k==='battery') {
        Text('本机电量与充电状态，前台响应系统变化；桌面由系统周期刷新。').fontSize(12).fontColor(AppDesign.muted(this.appDark)).width('100%')
        this.action(this.busy?'更新中':'更新电量',()=>this.refresh())
      }
      if(this.cap.k==='fetch') {
        TextInput({text:this.cap.title??'',placeholder:'名称，例如空气质量 / 剩余配额'}).height(44).fontColor(this.text()).placeholderColor(AppDesign.muted(this.appDark)).backgroundColor(this.control()).borderRadius(14).onChange((v:string)=>{const next=this.copy();next.title=v;this.change(next);})
        TextInput({text:this.cap.url??'',placeholder:'https://… JSON 或纯文本接口'}).height(44).fontColor(this.text()).placeholderColor(AppDesign.muted(this.appDark)).backgroundColor(this.control()).borderRadius(14).onChange((v:string)=>{const next=this.copy();next.url=v.trim();next.value='';next.attemptedAt=0;next.field='';next.sourceConfigured=false;this.change(next);})
        this.action(this.busy?'读取中':this.cap.value?'重新选择内容':'读取并选择内容',()=>this.chooseURLField())
        if(this.cap.value) {Text('内容：'+(this.cap.field||'正文')).fontSize(12).fontColor(AppDesign.muted(this.appDark)).width('100%'); this.action('立即刷新',()=>this.refresh())}
        TextInput({text:this.cap.unit??'',placeholder:'单位（可留空）'}).height(44).fontColor(this.text()).placeholderColor(AppDesign.muted(this.appDark)).backgroundColor(this.control()).borderRadius(14).onChange((v:string)=>{const next=this.copy();next.unit=v;this.change(next);})
        Text('刷新间隔').fontSize(13).fontColor(AppDesign.muted(this.appDark)).width('100%')
        SettingsSegmented({labels:['30 分钟','60 分钟','180 分钟'],selectedIndex:Math.max(0,[30,60,180].indexOf(this.cap.interval??60)),appDark:this.appDark,
          onSelect:(index:number)=>{const next=this.copy();next.interval=[30,60,180][index];this.change(next);}})
        Text('只读取所选内容，失败时保留上次结果。桌面更新受系统调度限制。').fontSize(12).fontColor(AppDesign.muted(this.appDark)).width('100%')
      }
      if(this.cap.k==='parcel') {
        Row({space:8}) {
          Button('通知文字',{type:ButtonType.Capsule, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL}).height(44).layoutWeight(1).fontSize(14).fontColor(this.text()).backgroundColor(this.control()).enabled(!this.busy).onClick(()=>this.importParcels())
          Button(this.busy?'识别中':'识别截图',{type:ButtonType.Capsule, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL}).height(44).layoutWeight(1).fontSize(14).fontColor(this.text()).backgroundColor(this.control()).enabled(!this.busy).onClick(()=>this.pickScreenshot())
        }.width('100%')
        Text('常用驿站').fontSize(13).fontColor(AppDesign.muted(this.appDark)).width('100%')
        TextInput({text:this.cap.parcelPlace??'',placeholder:'常用驿站（可留空，仅补全缺失地点）'}).height(44).maxLength(80).fontSize(14).fontColor(this.text()).placeholderColor(AppDesign.muted(this.appDark)).backgroundColor(this.control()).borderRadius(14).onChange((v:string)=>{const next=this.copy();next.parcelPlace=v;this.change(next);})
        Button(this.manualParcel?'收起手动添加':'手动添加',{type:ButtonType.Capsule, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL}).height(44).fontSize(13).fontColor(this.text()).backgroundColor(this.control()).onClick(()=>this.manualParcel=!this.manualParcel)
        if(this.manualParcel) {
          Column({space:12}) {
          TextInput({text:this.code,placeholder:'取件码'}).height(44).maxLength(24).fontColor(this.text()).placeholderColor(AppDesign.muted(this.appDark)).backgroundColor(this.control()).borderRadius(14).onChange((v:string)=>this.code=v)
          TextInput({text:this.place,placeholder:'取件地点（留空使用常用驿站）'}).height(44).maxLength(80).fontColor(this.text()).placeholderColor(AppDesign.muted(this.appDark)).backgroundColor(this.control()).borderRadius(14).onChange((v:string)=>this.place=v)
          this.action('加入待取',()=>this.addParcel())
          }.width('100%').transition(settingsReveal())
        }
        ForEach(pendingParcels(this.cap),(p:ParcelItem)=>{
          Row({space:12}) {Column({space:4}) {Text(p.code).fontSize(18).fontWeight(FontWeight.Medium).fontColor(this.text());Text(p.place||'未填写地点').fontSize(12).fontColor(AppDesign.muted(this.appDark)).maxLines(1).textOverflow({overflow:TextOverflow.Ellipsis})}.layoutWeight(1).alignItems(HorizontalAlign.Start);Button('已取',{type:ButtonType.Capsule, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL}).height(44).fontSize(13).fontColor(this.text()).backgroundColor(this.control()).onClick(()=>{const next=this.copy();for(const item of next.parcels??[])if(item.id===p.id)item.picked=true;this.change(next);})}.width('100%')
        },(p:ParcelItem)=>p.id)
        if((this.cap.parcels??[]).some((p)=>p.picked)) {
          this.action('清理已取记录',()=>{const next=this.copy();next.parcels=(next.parcels??[]).filter((p)=>!p.picked);this.change(next);})
        }
        Text('识别后校对再加入；原通知与截图不保存。常用驿站无需重复输入。').fontSize(12).fontColor(AppDesign.muted(this.appDark)).width('100%')
      }
      if(this.cap.k==='agenda') {
        if(this.wholeCalendarAccess) {this.action('读取系统日历',()=>this.readSystemAgenda())}
        this.action('导入日历文件 .ics',()=>this.importSchedule())
        Text(this.cap.agendaSource==='system'?'系统日历' :this.cap.agendaSource==='imported'?'本地日历副本；原文件修改后需要重新导入':'显示接下来三项安排，缩小时保留下一项').fontSize(12).fontColor(AppDesign.muted(this.appDark)).width('100%')
      }
      if(this.cap.k==='timetable') {
        Text('卡片展示').fontSize(13).fontColor(AppDesign.muted(this.appDark)).width('100%')
        SettingsSegmented({labels:['下一课','每日概览'],selectedIndex:this.cap.timetableMode==='day'?1:0,appDark:this.appDark,
          onSelect:(index:number)=>{const next=this.copy();next.timetableMode=index===1?'day':'next';this.change(next);}})
        Text(this.cap.timetableMode==='day'?'网格展示当天全部课程和地点；最后一课结束后展示明天。卡片会为学期内最忙的一天预留空间。':'下课前 10 分钟切到下一课；只在前一晚 20:00 后预告次日，假期中不提前展示远期课程。').fontSize(12).fontColor(AppDesign.muted(this.appDark)).width('100%')
        Divider().color(AppDesign.border(this.appDark)).margin({top:4,bottom:4})
        Row() {
          Text('学期课表').fontSize(14).fontWeight(FontWeight.Medium).fontColor(this.text()).layoutWeight(1)
          Button('添加课程',{type:ButtonType.Capsule, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL}).height(44).fontSize(13).fontColor(this.text()).backgroundColor(this.control()).onClick(()=>this.editCourse())
        }.width('100%')
        this.action('查看周课表 · '+(this.cap.courses??[]).length+' 条安排',()=>this.showTimetable())
        Row({space:8}) {
          Button('导入课表',{type:ButtonType.Capsule, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL}).height(44).layoutWeight(1).fontSize(14).fontColor(this.text()).backgroundColor(this.control()).onClick(()=>this.importTimetable())
          Button('假期与调课',{type:ButtonType.Capsule, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL}).height(44).layoutWeight(1).fontSize(14).fontColor(this.text()).backgroundColor(this.control()).onClick(()=>this.calendarRules())
        }.width('100%')
        this.action('第一周周一  '+(this.cap.semester??'选择开学日期'),()=>this.semesterDate())
      }
      if(this.message || this.cap.refreshState==='failed') {Text(this.message||this.cap.desc||'更新失败，保留上次结果').fontSize(12).fontColor(AppDesign.muted(this.appDark)).width('100%')}
    }.width('100%')
  }
}
