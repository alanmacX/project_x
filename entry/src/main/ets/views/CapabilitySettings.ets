import { ValuePicker } from './ValuePicker';
import { CapBlock, ParcelItem, CourseItem, AgendaItem } from '../model/CardSchema';
import { ValueField, pickupCandidates, pendingParcels, eventWhen } from '../model/CapabilityData';
import { fetchValueFields, recognizePickup } from '../model/CapabilityWorker';
import { readCapability } from '../model/CapabilityService';
import { importScheduleFile } from '../model/ScheduleFiles';
import { AppDesign } from '../model/AppDesign';
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
  @State message:string='';
  @State code:string=''; @State place:string='';
  private dialog:CustomDialogController|null=null;
  private alive:boolean=true;
  private generation:number=0;
  private inputKey:string='';
  private inputChanged():void {
    const key=this.cardId+'|'+this.cap.k+'|'+(this.cap.url??'');
    if(key===this.inputKey)return;this.inputKey=key;this.generation++;this.busy=false;this.message='';this.code='';this.place='';
  }
  aboutToAppear():void {this.alive=true;this.inputChanged();}
  aboutToDisappear():void {this.alive=false;this.generation++;}
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
      }}),customStyle:true,alignment:DialogAlignment.Center,autoCancel:true});this.dialog.open();
    }catch(e){if(this.alive)this.message=(e as Error).message;}finally{if(token===this.generation)this.busy=false;}
  }
  private async pickScreenshot():Promise<void> {
    if(this.busy)return;const token=++this.generation;this.busy=true;
    try{
      const options=new photoAccessHelper.PhotoSelectOptions();options.maxSelectNumber=1;options.MIMEType=photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
      const result=await new photoAccessHelper.PhotoViewPicker().select(options);if(!result.photoUris.length)return;
      const candidates=pickupCandidates(await taskpool.execute(new taskpool.Task(recognizePickup,result.photoUris[0])) as string);
      if(!this.alive||token!==this.generation)return;
      if(!candidates.length){this.message='未找到明确的取件码，请手动填写；识别结果不会自动加入';return;}
      this.dialog=new CustomDialogController({builder:ValuePicker({choices:candidates.map((c:ParcelItem):ValueField=>({path:c.code,value:c.place})),title:'校对取件码',appDark:this.appDark,onChoose:(value:ValueField)=>{
        if(!this.alive||token!==this.generation)return;this.code=value.path;this.place=value.value;
      }}),customStyle:true,alignment:DialogAlignment.Center,autoCancel:true});this.dialog.open();
    }catch(e){if(this.alive)this.message=(e as Error).message;}finally{if(token===this.generation)this.busy=false;}
  }
  private addParcel():void {
    const code=this.code.trim();if(!code){this.message='请填写取件码';return;}
    const next=this.copy(),list=next.parcels??[];if(list.some((p)=>!p.picked&&p.code===code&&p.place===this.place.trim())){this.message='这个取件码已经在列表中';return;}
    list.unshift({id:'p'+Date.now(),code:code.slice(0,24),place:this.place.trim().slice(0,80),picked:false});next.parcels=list.slice(0,64);this.change(next);this.code='';this.place='';
  }
  private editCourse(course?:CourseItem):void {
    const id=this.cardId;
    this.dialog=new CustomDialogController({builder:CourseEditor({course:course??{id:'',name:'',room:'',day:1,start:'08:00',end:'09:40',firstWeek:1,lastWeek:16,parity:0},appDark:this.appDark,onSave:(value:CourseItem)=>{
      if(!this.alive||this.cardId!==id)return;const next=this.copy(),courses=(next.courses??[]).filter((c)=>c.id!==value.id);courses.push(value);next.courses=courses;this.change(next);
    }}),customStyle:true,alignment:DialogAlignment.Center,autoCancel:true});this.dialog.open();
  }
  private semesterDate():void {
    this.getUIContext().showDatePickerDialog({selected:new Date((this.cap.semester??'')+'T00:00:00'),onAccept:(v:DatePickerResult)=>{
      const next=this.copy();next.semester=v.year+'-'+('0'+((v.month??0)+1)).slice(-2)+'-'+('0'+v.day).slice(-2);this.change(next);
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
    this.dialog=new CustomDialogController({builder:WakeUpImportDialog({appDark:this.appDark,existingCount:(this.cap.courses??[]).length,onImport:(semester:string,courses:CourseItem[],replace:boolean)=>{
      if(!this.alive||this.cardId!==id||this.cap.k!=='timetable')return;
      const next=this.copy(),list=replace?[]:(next.courses??[]).slice();
      if(!replace&&list.length&&next.semester!==semester)throw new Error('开学日期不同，请选择替换或先建立另一张课程卡');
      for(const c of courses)if(!list.some((v)=>v.name===c.name&&v.room===c.room&&v.day===c.day&&v.start===c.start&&v.end===c.end&&v.firstWeek===c.firstWeek&&v.lastWeek===c.lastWeek&&v.parity===c.parity))list.push(c);
      if(list.length>128)throw new Error('合并后超过 128 条，请分成两张课程卡');
      next.semester=semester;next.courses=list;this.change(next);
    }}),customStyle:true,alignment:DialogAlignment.Center,autoCancel:true});this.dialog.open();
  }
  @Builder
  action(label:string,action:()=>void) {
    Button(label,{type:ButtonType.Capsule}).height(44).width('100%').fontSize(14).fontColor(this.text()).backgroundColor(this.control()).border({width:.5,color:AppDesign.border(this.appDark)}).enabled(!this.busy).onClick(action)
  }
  build() {
    Column({space:12}) {
      if(this.cap.k==='battery') {
        Text('本机电量与充电状态，前台响应系统变化；桌面由系统周期刷新。').fontSize(12).fontColor(AppDesign.muted(this.appDark)).width('100%')
        this.action(this.busy?'更新中':'更新电量',()=>this.refresh())
      }
      if(this.cap.k==='fetch') {
        TextInput({text:this.cap.title??'',placeholder:'名称，例如空气质量 / 剩余配额'}).height(44).fontColor(this.text()).backgroundColor(this.control()).borderRadius(14).onChange((v:string)=>{const next=this.copy();next.title=v;this.change(next);})
        TextInput({text:this.cap.url??'',placeholder:'https://… JSON 或纯文本接口'}).height(44).fontColor(this.text()).backgroundColor(this.control()).borderRadius(14).onChange((v:string)=>{const next=this.copy();next.url=v.trim();next.value='';next.attemptedAt=0;next.field='';next.sourceConfigured=false;this.change(next);})
        this.action(this.busy?'读取中':this.cap.value?'重新选择内容':'读取并选择内容',()=>this.chooseURLField())
        if(this.cap.value) {Text('内容：'+(this.cap.field||'正文')).fontSize(12).fontColor(AppDesign.muted(this.appDark)).width('100%'); this.action('立即刷新',()=>this.refresh())}
        TextInput({text:this.cap.unit??'',placeholder:'单位（可留空）'}).height(44).fontColor(this.text()).backgroundColor(this.control()).borderRadius(14).onChange((v:string)=>{const next=this.copy();next.unit=v;this.change(next);})
        Row({space:8}) {ForEach([30,60,180],(v:number)=>{Button(v+' 分钟',{type:ButtonType.Capsule}).height(44).fontSize(12).layoutWeight(1).fontColor(this.text()).backgroundColor(this.control()).border({width:(this.cap.interval??60)===v?1.5:0,color:AppDesign.border(this.appDark)}).onClick(()=>{const next=this.copy();next.interval=v;this.change(next);})},(v:number)=>String(v))}.width('100%')
        Text('只读取所选内容，失败时保留上次结果。桌面更新受系统调度限制。').fontSize(12).fontColor(AppDesign.muted(this.appDark)).width('100%')
      }
      if(this.cap.k==='parcel') {
        this.action(this.busy?'识别中':'从截图识别取件码',()=>this.pickScreenshot())
        TextInput({text:this.code,placeholder:'确认取件码'}).height(44).maxLength(24).fontColor(this.text()).backgroundColor(this.control()).borderRadius(14).onChange((v:string)=>this.code=v)
        TextInput({text:this.place,placeholder:'驿站 / 取件地点'}).height(44).maxLength(80).fontColor(this.text()).backgroundColor(this.control()).borderRadius(14).onChange((v:string)=>this.place=v)
        this.action('加入待取',()=>this.addParcel())
        ForEach(pendingParcels(this.cap),(p:ParcelItem)=>{
          Row({space:12}) {Column({space:4}) {Text(p.code).fontSize(16).fontColor(this.text());Text(p.place).fontSize(12).fontColor(AppDesign.muted(this.appDark)).maxLines(1)}.layoutWeight(1).alignItems(HorizontalAlign.Start);Button('已取',{type:ButtonType.Capsule}).height(44).fontColor(this.text()).backgroundColor(this.control()).onClick(()=>{const next=this.copy();for(const item of next.parcels??[])if(item.id===p.id)item.picked=true;this.change(next);})}.width('100%')
        },(p:ParcelItem)=>p.id)
        Text('照片只用于本机识别，不保存原截图。加入前请校对；已取状态由你确认。').fontSize(12).fontColor(AppDesign.muted(this.appDark)).width('100%')
      }
      if(this.cap.k==='agenda') {
        this.action('读取系统日历',()=>this.readSystemAgenda())
        this.action('导入日历文件 .ics',()=>this.importSchedule())
        Text(this.cap.agendaSource==='system'?'系统日历：需要受限权限资格和用户授权':this.cap.agendaSource==='imported'?'本地日历副本；原文件修改后需要重新导入':'显示接下来三项安排，缩小时保留下一项').fontSize(12).fontColor(AppDesign.muted(this.appDark)).width('100%')
      }
      if(this.cap.k==='timetable') {
        this.action('学期第一周周一  '+(this.cap.semester??''),()=>this.semesterDate())
        this.action('添加课程',()=>this.editCourse())
        ForEach(this.cap.courses??[],(c:CourseItem)=>{
          Row({space:8}) {Button(c.name+' · 周'+['一','二','三','四','五','六','日'][c.day-1]+' '+c.start,{type:ButtonType.Capsule}).height(44).layoutWeight(1).fontSize(12).fontColor(this.text()).backgroundColor(this.control()).onClick(()=>this.editCourse(c));Button('删除',{type:ButtonType.Capsule}).height(44).fontSize(12).fontColor('#C43A35').backgroundColor(this.control()).onClick(()=>{const next=this.copy();next.courses=(next.courses??[]).filter((v)=>v.id!==c.id);this.change(next);})}.width('100%')
        },(c:CourseItem)=>c.id)
        this.action('导入课程表',()=>this.importTimetable())
        Text('按周次、单双周和时间自动显示下一课及后续安排。桌面展示单个能力，不挤入完整微缩课表。').fontSize(12).fontColor(AppDesign.muted(this.appDark)).width('100%')
      }
      if(this.message || this.cap.refreshState==='failed') {Text(this.message||this.cap.desc||'更新失败，保留上次结果').fontSize(12).fontColor(AppDesign.muted(this.appDark)).width('100%')}
    }.width('100%')
  }
}
