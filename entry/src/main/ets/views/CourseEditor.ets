import { CourseItem } from '../model/CardSchema';
import { AppDesign } from '../model/AppDesign';
import { SettingsSegmented } from './SettingsSegmented';
@CustomDialog
export struct CourseEditor {
  controller: CustomDialogController;
  course: CourseItem = {id:'',name:'',room:'',day:1,start:'08:00',end:'09:40',firstWeek:1,lastWeek:16,parity:0};
  appDark: boolean = false;
  onDelete:()=>void=()=>{};
  onSave: (course:CourseItem)=>void = ()=>{};
  @State name:string=''; @State room:string=''; @State day:number=1; @State start:string='08:00'; @State end:string='09:40';
  @State first:string='1'; @State last:string='16'; @State parity:number=0; @State error:string='';
  aboutToAppear():void {this.name=this.course.name;this.room=this.course.room;this.day=this.course.day;this.start=this.course.start;this.end=this.course.end;this.first=String(this.course.firstWeek);this.last=String(this.course.lastWeek);this.parity=this.course.parity;}
  private pickTime(start:boolean):void {
    const value=start?this.start:this.end,d=new Date();d.setHours(Number(value.slice(0,2)),Number(value.slice(3)));
    this.getUIContext().showTimePickerDialog({selected:d,useMilitaryTime:true,onAccept:(v:TimePickerResult)=>{const text=('0'+v.hour).slice(-2)+':'+('0'+v.minute).slice(-2);if(start)this.start=text;else this.end=text;}});
  }
  private save():void {
    const first=Number(this.first),last=Number(this.last);
    if(!this.name.trim()||this.end<=this.start||!Number.isInteger(first)||!Number.isInteger(last)||first<1||last<first||last>60){this.error='请填写课程名称、正确起止时间和 1–60 周范围';return;}
    this.onSave({id:this.course.id||'course_'+Date.now(),name:this.name.trim(),room:this.room.trim(),day:this.day,start:this.start,end:this.end,firstWeek:first,lastWeek:last,parity:this.parity});this.controller.close();
  }
  build() {
    Column({space:12}) {
      Text(this.course.id?'编辑课程':'添加课程').fontSize(20).fontWeight(FontWeight.Medium).fontColor(AppDesign.text(this.appDark)).width('100%')
      Scroll() {
      Column({space:12}) {
      TextInput({text:this.name,placeholder:'课程名称'}).height(44).borderRadius(14).fontColor(AppDesign.text(this.appDark)).placeholderColor(AppDesign.muted(this.appDark)).backgroundColor(AppDesign.control(this.appDark)).onChange((v:string)=>this.name=v)
      TextInput({text:this.room,placeholder:'教室 / 地点'}).height(44).borderRadius(14).fontColor(AppDesign.text(this.appDark)).placeholderColor(AppDesign.muted(this.appDark)).backgroundColor(AppDesign.control(this.appDark)).onChange((v:string)=>this.room=v)
      Text('上课日期').fontSize(13).fontColor(AppDesign.muted(this.appDark)).width('100%')
      Select(['周一','周二','周三','周四','周五','周六','周日'].map((value:string):SelectOption=>({value:value})))
        .selected(this.day-1).value(['周一','周二','周三','周四','周五','周六','周日'][this.day-1]).width('100%').height(44)
        .font({size:14}).fontColor(AppDesign.text(this.appDark)).optionFontColor(AppDesign.text(this.appDark)).optionBgColor(AppDesign.surface(this.appDark))
        .selectedOptionFontColor(AppDesign.onSelected(this.appDark)).selectedOptionBgColor(AppDesign.selected(this.appDark))
        .backgroundColor(AppDesign.control(this.appDark)).borderRadius(12).controlSize(ControlSize.NORMAL).onSelect((index:number)=>this.day=index+1)
      Row({space:12}) {
        Button('开始 '+this.start,{type:ButtonType.Capsule, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL}).height(44).layoutWeight(1).backgroundColor(AppDesign.control(this.appDark)).fontColor(AppDesign.text(this.appDark)).onClick(()=>this.pickTime(true))
        Button('结束 '+this.end,{type:ButtonType.Capsule, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL}).height(44).layoutWeight(1).backgroundColor(AppDesign.control(this.appDark)).fontColor(AppDesign.text(this.appDark)).onClick(()=>this.pickTime(false))
      }.width('100%')
      Row({space:8}) {Text('第').fontColor(AppDesign.text(this.appDark));TextInput({text:this.first}).type(InputType.Number).layoutWeight(1).height(44).borderRadius(14).fontColor(AppDesign.text(this.appDark)).placeholderColor(AppDesign.muted(this.appDark)).backgroundColor(AppDesign.control(this.appDark)).onChange((v:string)=>this.first=v);Text('至').fontColor(AppDesign.text(this.appDark));TextInput({text:this.last}).type(InputType.Number).layoutWeight(1).height(44).borderRadius(14).fontColor(AppDesign.text(this.appDark)).placeholderColor(AppDesign.muted(this.appDark)).backgroundColor(AppDesign.control(this.appDark)).onChange((v:string)=>this.last=v);Text('周').fontColor(AppDesign.text(this.appDark));}.width('100%')
      SettingsSegmented({labels:['每周','单周','双周'],selectedIndex:this.parity,appDark:this.appDark,onSelect:(index:number)=>this.parity=index})
      }.width('100%')
      }.width('100%').layoutWeight(1).scrollBar(BarState.Off)
      if(this.course.id) {Button('删除这门课程',{type:ButtonType.Capsule, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.ERROR}).height(44).width('100%').fontColor('#B34735').backgroundColor(AppDesign.control(this.appDark)).onClick(()=>{this.onDelete();this.controller.close();})}
      if(this.error) {Text(this.error).fontSize(12).fontColor('#C43A35')}
      Row({space:12}) {Button('取消',{type:ButtonType.Capsule, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL}).height(44).layoutWeight(1).backgroundColor(AppDesign.control(this.appDark)).fontColor(AppDesign.text(this.appDark)).onClick(()=>this.controller.close());Button('保存',{type:ButtonType.Capsule, buttonStyle:ButtonStyleMode.EMPHASIZED, role:ButtonRole.NORMAL}).height(44).layoutWeight(1).backgroundColor(AppDesign.selected(this.appDark)).fontColor(AppDesign.onSelected(this.appDark)).onClick(()=>this.save());}.width('100%')
    }.padding(20).width('90%').height('85%').constraintSize({maxWidth:480,maxHeight:560}).borderRadius(24).backgroundColor(AppDesign.surface(this.appDark))
  }
}
