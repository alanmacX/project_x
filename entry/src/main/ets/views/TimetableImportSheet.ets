import { SchoolImportDialog } from './SchoolImportDialog';
import { SettingsSegmented } from './SettingsSegmented';
import { SettingsAction } from './SettingsAction';
import { WeekTimetable } from './WeekTimetable';
import { CapBlock, CourseItem } from '../model/CardSchema';
import { AppDesign } from '../model/AppDesign';
import { WakeImport, WakeSlot, resolveWakeUp, mondayDate } from '../model/WakeUpImport';
@Component
export struct TimetableImportSheet {
  @Prop appDark:boolean=false;
  @Prop existingCount:number=0;
  onClose:()=>void=()=>{};
  onImport:(semester:string,courses:CourseItem[],replace:boolean,keepCalendar:boolean)=>void=()=>{};
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
  aboutToDisappear():void{this.alive=false;}
  private accept(json:string):void {
    if(!this.alive)return;this.parsed=JSON.parse(json) as WakeImport;this.slots=this.parsed.slots;this.semester=this.parsed.semester;this.stage=true;this.periods=this.slots.some((s)=>!s.start||!s.end);this.error='';this.refreshPreview();
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
    try {const courses=resolveWakeUp(this.parsed,this.semester,this.slots);this.onImport(mondayDate(this.semester),courses,this.replace,this.keepCalendar);this.onClose();}catch(e){this.error=(e as Error).message;}
  }
  build(){
    Column(){
      if(!this.stage){SchoolImportDialog({appDark:this.appDark,onClose:this.onClose,onRead:(json:string)=>this.accept(json)})}
      else{
        Row(){
          SettingsAction({label:'返回',appDark:this.appDark,onPress:()=>{this.stage=false;this.error='';}})
          Text('确认课程').fontSize(20).fontWeight(FontWeight.Medium).fontColor(AppDesign.text(this.appDark)).layoutWeight(1).margin({left:12})
          SettingsAction({label:'导入课程',appDark:this.appDark,emphasis:true,isEnabled:this.previewReady,onPress:()=>this.confirm()})
        }.width('100%').padding({left:20,right:20,top:12,bottom:12})
        Scroll(){Column({space:14}){
        Text(this.parsed.name+' · '+this.parsed.courses.length+' 条上课安排').fontSize(13).fontColor(AppDesign.muted(this.appDark)).maxLines(1).textOverflow({overflow:TextOverflow.Ellipsis}).width('100%')
        SettingsAction({label:'第一周周一  '+(this.semester||'选择开学日期'),onPress:()=>this.date(),appDark:this.appDark,isEnabled:!this.busy})

        SettingsSegmented({labels:['课程',this.slots.some((s)=>!s.start||!s.end)?'作息 · 待补全':'作息'],selectedIndex:this.periods?1:0,appDark:this.appDark,onSelect:(index:number)=>this.periods=index===1})
        if ((this.periods && this.slots.length > 0) || (!this.periods && this.previewReady)) {
        Scroll() {
          Column({space:10}) {
            if(this.periods) {

              ForEach(this.slots,(s:WakeSlot)=>{
                Row({space:8}) {Text('第 '+s.node+' 节').fontSize(14).fontColor(AppDesign.text(this.appDark)).layoutWeight(1);SettingsAction({label:this.slotTime(s.node,true),onPress:()=>this.time(s.node,true),appDark:this.appDark,isEnabled:!this.busy});SettingsAction({label:this.slotTime(s.node,false),onPress:()=>this.time(s.node,false),appDark:this.appDark,isEnabled:!this.busy})}.width('100%').padding(10).borderRadius(14).backgroundColor(AppDesign.control(this.appDark))
              },(s:WakeSlot)=>String(s.node))
            } else {
              if(this.previewReady) {WeekTimetable({cap:this.previewCap,appDark:this.appDark,initialWeek:1,heightLimit:230,editable:false})}

            }
          }.width('100%')
        }.width('100%').height(this.periods?230:310).scrollBar(BarState.Off).align(Alignment.Top)
        }
        if(this.existingCount>0) {Row({space:12}) {Text(this.replace?'替换现有 '+this.existingCount+' 条课程':'追加到现有课程').fontSize(13).fontColor(AppDesign.text(this.appDark)).layoutWeight(1);Toggle({type:ToggleType.Switch,isOn:this.replace}).onChange((v:boolean)=>this.replace=v)}.width('100%')}
        if(this.existingCount>0 && this.replace) {
          Row({space:12}) {Text('保留当前课表的校历').fontSize(13).fontColor(AppDesign.text(this.appDark)).layoutWeight(1);Toggle({type:ToggleType.Switch,isOn:this.keepCalendar}).onChange((v:boolean)=>this.keepCalendar=v)}.width('100%')

        }

          if(this.error){Text(this.error).fontSize(12).fontColor('#B34735').width('100%')}
        }.width('100%').padding(20)}.width('100%').layoutWeight(1).scrollBar(BarState.Auto)
      }
    }.width('100%').height('100%').backgroundColor(AppDesign.surface(this.appDark))
  }
}
