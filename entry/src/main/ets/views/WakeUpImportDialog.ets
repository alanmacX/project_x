import { SchoolImportDialog } from './SchoolImportDialog';
import { AppDesign } from '../model/AppDesign';
import { CourseItem } from '../model/CardSchema';
import { WakeImport, WakeSlot, WakeCourse, resolveWakeUp, mondayDate } from '../model/WakeUpImport';
import { importScheduleFile, parseWakeUpText } from '../model/ScheduleFiles';
import { taskpool } from '@kit.ArkTS';
import { picker } from '@kit.CoreFileKit';
@CustomDialog
export struct WakeUpImportDialog {
  controller:CustomDialogController;
  appDark:boolean=false;
  existingCount:number=0;
  onImport:(semester:string,courses:CourseItem[],replace:boolean)=>void=()=>{};
  @State text:string='';
  @State other:boolean=false;
  @State parsed:WakeImport=new WakeImport();
  @State slots:WakeSlot[]=[];
  @State semester:string='';
  @State stage:boolean=false;
  @State periods:boolean=false;
  @State replace:boolean=false;
  @State busy:boolean=false;
  @State error:string='';
  private alive:boolean=true;
  private schoolDialog:CustomDialogController|undefined=undefined;
  private school():void {this.schoolDialog=new CustomDialogController({builder:SchoolImportDialog({appDark:this.appDark,onRead:(json:string)=>this.accept(json)}),customStyle:true,autoCancel:false,alignment:DialogAlignment.Center});this.schoolDialog.open();}
  aboutToDisappear():void {this.alive=false;this.schoolDialog?.close();}
  private accept(json:string):void {
    if(!this.alive)return;this.parsed=JSON.parse(json) as WakeImport;this.slots=this.parsed.slots;this.semester=this.parsed.semester;this.stage=true;this.periods=this.slots.some((s)=>!s.start||!s.end);this.error='';
  }
  private async parseText():Promise<void> {
    if(this.busy)return;this.busy=true;this.error='';
    try {this.accept(await taskpool.execute(new taskpool.Task(parseWakeUpText,this.text)) as string);}catch(e){if(this.alive)this.error=(e as Error).message.replace(/^Error:\s*/,'');}finally{if(this.alive)this.busy=false;}
  }
  private async file():Promise<void> {
    const context=this.getUIContext().getHostContext();if(!context||this.busy)return;this.busy=true;this.error='';
    try {const options=new picker.DocumentSelectOptions();options.maxSelectNumber=1;options.fileSuffixFilters=['WakeUp 课表|.wakeup_schedule,.json,.txt'];const files=await new picker.DocumentViewPicker(context).select(options);if(!files.length)return;
      this.accept(await taskpool.execute(new taskpool.Task(importScheduleFile,files[0],'timetable')) as string);
    }catch(e){if(this.alive)this.error=(e as Error).message.replace(/^Error:\s*/,'');}finally{if(this.alive)this.busy=false;}
  }
  private date():void {
    this.getUIContext().showDatePickerDialog({selected:this.semester?new Date(this.semester+'T12:00:00'):new Date(),onAccept:(v:DatePickerResult)=>{
      if(this.alive)this.semester=mondayDate(v.year+'-'+('0'+((v.month??0)+1)).slice(-2)+'-'+('0'+v.day).slice(-2));
    }});
  }
  private time(node:number,start:boolean):void {
    const s=this.slots.find((v)=>v.node===node),value=(start?s?.start:s?.end)||'08:00',d=new Date();d.setHours(Number(value.slice(0,2)),Number(value.slice(3)),0,0);
    this.getUIContext().showTimePickerDialog({selected:d,useMilitaryTime:true,onAccept:(v:TimePickerResult)=>{
      if(!this.alive)return;const value=('0'+v.hour).slice(-2)+':'+('0'+v.minute).slice(-2);
      this.slots=this.slots.map((s:WakeSlot):WakeSlot=>({node:s.node,start:s.node===node&&start?value:s.start,end:s.node===node&&!start?value:s.end}));
    }});
  }
  private courseTime(c:WakeCourse):string {
    const a=c.start||this.slots.find((s)=>s.node===c.firstNode)?.start,b=c.end||this.slots.find((s)=>s.node===c.lastNode)?.end;
    return a&&b?a+'–'+b:'第 '+c.firstNode+'–'+c.lastNode+' 节 · 待补作息';
  }
  private confirm():void {
    try {const courses=resolveWakeUp(this.parsed,this.semester,this.slots);this.onImport(mondayDate(this.semester),courses,this.replace);this.controller.close();}catch(e){this.error=(e as Error).message;}
  }
  @Builder
  action(label:string,run:()=>void,emphasis:boolean=false) {
    Button(label,{type:ButtonType.Capsule}).height(44).fontSize(14).fontColor(AppDesign.choiceText(this.appDark,emphasis)).backgroundColor(AppDesign.choice(this.appDark,emphasis)).enabled(!this.busy).onClick(run)
  }
  build() {
    Scroll() {
    Column({space:14}) {
      Text(this.stage?'确认课程表':'导入课程表').fontSize(20).fontWeight(FontWeight.Medium).fontColor(AppDesign.text(this.appDark)).width('100%')
      if(!this.stage) {
        this.action('从学校教务导入',()=>this.school(),true)
        Text('在 App 内选学校、登录教务并读取个人课表；也可导入已有的课表备份。').fontSize(13).fontColor(AppDesign.muted(this.appDark)).width('100%')
        this.action(this.other?'收起其他方式':'导入已有课表备份',()=>this.other=!this.other)
        if(this.other) {
        this.action('选择 WakeUp 文件',()=>this.file())
        TextArea({text:this.text,placeholder:'长按粘贴导出文本'}).height(160).maxLength(262144).fontColor(AppDesign.text(this.appDark)).placeholderColor(AppDesign.muted(this.appDark)).backgroundColor(AppDesign.control(this.appDark)).borderRadius(16).onChange((v:string)=>this.text=v)
        this.action(this.busy?'读取中':'预览粘贴的课表',()=>this.parseText())
        Text('支持 WakeUp 备份作为可选迁移方式，无需安装其他课程表 App。').fontSize(12).fontColor(AppDesign.muted(this.appDark)).width('100%')
        }
      } else {
        Text(this.parsed.name+' · '+this.parsed.courses.length+' 条上课安排').fontSize(13).fontColor(AppDesign.muted(this.appDark)).maxLines(1).textOverflow({overflow:TextOverflow.Ellipsis}).width('100%')
        this.action('第一周周一  '+(this.semester||'选择开学日期'),()=>this.date())
        Row({space:10}) {this.action('课程',()=>this.periods=false,!this.periods);this.action('作息'+(this.slots.some((s)=>!s.start||!s.end)?' · 待补全':''),()=>this.periods=true,this.periods)}.width('100%')
        Scroll() {
          Column({space:10}) {
            if(this.periods) {
              if(!this.slots.length){Text('所有课程已包含实际时间，无需配置节次。').fontSize(13).fontColor(AppDesign.muted(this.appDark))}
              ForEach(this.slots,(s:WakeSlot)=>{
                Row({space:8}) {Text('第 '+s.node+' 节').fontSize(14).fontColor(AppDesign.text(this.appDark)).layoutWeight(1);this.action(s.start||'开始',()=>this.time(s.node,true));this.action(s.end||'结束',()=>this.time(s.node,false))}.width('100%').padding(10).borderRadius(14).backgroundColor(AppDesign.control(this.appDark))
              },(s:WakeSlot)=>String(s.node))
            } else {
              ForEach(this.parsed.courses,(c:WakeCourse,i:number)=>{
                Column({space:5}) {
                  Text(c.name).fontSize(15).fontWeight(FontWeight.Medium).fontColor(AppDesign.text(this.appDark)).maxLines(2).textOverflow({overflow:TextOverflow.Ellipsis}).width('100%')
                  Text('周'+['一','二','三','四','五','六','日'][c.day-1]+' · '+this.courseTime(c)+(c.room?' · '+c.room:'')).fontSize(12).fontColor(AppDesign.muted(this.appDark)).width('100%')
                  Text('第 '+c.firstWeek+'–'+c.lastWeek+' 周 · '+['每周','单周','双周'][c.parity]).fontSize(12).fontColor(AppDesign.muted(this.appDark)).width('100%')
                }.width('100%').padding(14).borderRadius(16).backgroundColor(AppDesign.control(this.appDark))
              },(c:WakeCourse,i:number)=>String(i))
            }
          }.width('100%')
        }.width('100%').height(230).scrollBar(BarState.Off).align(Alignment.Top)
        if(this.existingCount>0) {Row({space:12}) {Text(this.replace?'替换现有 '+this.existingCount+' 条课程':'追加到现有课程').fontSize(13).fontColor(AppDesign.text(this.appDark)).layoutWeight(1);Toggle({type:ToggleType.Switch,isOn:this.replace}).onChange((v:boolean)=>this.replace=v)}.width('100%')}
      }
      if(this.error){Text(this.error).fontSize(12).fontColor('#B34735').width('100%').maxLines(3).textOverflow({overflow:TextOverflow.Ellipsis})}
      Row({space:10}) {this.action('取消',():void=>{this.controller.close();});if(this.stage){this.action('重新选择',()=>{this.stage=false;this.error='';});Button('确认导入',{type:ButtonType.Capsule}).height(44).fontSize(14).layoutWeight(1).backgroundColor(AppDesign.selected(this.appDark)).fontColor(AppDesign.onSelected(this.appDark)).onClick(()=>this.confirm());}}
    }.padding(20).width('100%')
    }.width('92%').constraintSize({maxWidth:560,maxHeight:'90%'}).scrollBar(BarState.Off).borderRadius(24).backgroundColor(AppDesign.surface(this.appDark))
  }
}
