import { CourseItem } from '../model/CardSchema';
import { AppDesign } from '../model/AppDesign';
@CustomDialog
export struct CourseEditor {
  controller: CustomDialogController;
  course: CourseItem = {id:'',name:'',room:'',day:1,start:'08:00',end:'09:40',firstWeek:1,lastWeek:16,parity:0};
  appDark: boolean = false;
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
      Text(this.course.id?'编辑课程':'添加课程').fontSize(20).fontColor(AppDesign.text(this.appDark)).width('100%')
      TextInput({text:this.name,placeholder:'课程名称'}).height(44).borderRadius(14).fontColor(AppDesign.text(this.appDark)).backgroundColor(AppDesign.control(this.appDark)).onChange((v:string)=>this.name=v)
      TextInput({text:this.room,placeholder:'教室 / 地点'}).height(44).borderRadius(14).fontColor(AppDesign.text(this.appDark)).backgroundColor(AppDesign.control(this.appDark)).onChange((v:string)=>this.room=v)
      Flex({wrap:FlexWrap.Wrap}) {
        ForEach(['一','二','三','四','五','六','日'],(v:string,i:number)=>{
          Button(v,{type:ButtonType.Circle}).width(40).height(40).margin({right:4,bottom:4}).backgroundColor(this.day===i+1?AppDesign.text(this.appDark):AppDesign.control(this.appDark)).fontColor(this.day===i+1?AppDesign.background(this.appDark):AppDesign.text(this.appDark)).onClick(()=>this.day=i+1)
        },(v:string)=>v)
      }.width('100%')
      Row({space:12}) {
        Button('开始 '+this.start,{type:ButtonType.Capsule}).height(44).layoutWeight(1).backgroundColor(AppDesign.control(this.appDark)).fontColor(AppDesign.text(this.appDark)).onClick(()=>this.pickTime(true))
        Button('结束 '+this.end,{type:ButtonType.Capsule}).height(44).layoutWeight(1).backgroundColor(AppDesign.control(this.appDark)).fontColor(AppDesign.text(this.appDark)).onClick(()=>this.pickTime(false))
      }.width('100%')
      Row({space:8}) {Text('第').fontColor(AppDesign.text(this.appDark));TextInput({text:this.first}).type(InputType.Number).layoutWeight(1).height(44).borderRadius(14).onChange((v:string)=>this.first=v);Text('至').fontColor(AppDesign.text(this.appDark));TextInput({text:this.last}).type(InputType.Number).layoutWeight(1).height(44).borderRadius(14).onChange((v:string)=>this.last=v);Text('周').fontColor(AppDesign.text(this.appDark));}.width('100%')
      Row({space:8}) {ForEach(['每周','单周','双周'],(v:string,i:number)=>{Button(v,{type:ButtonType.Capsule}).height(44).layoutWeight(1).backgroundColor(AppDesign.control(this.appDark)).fontColor(AppDesign.text(this.appDark)).border({width:this.parity===i?1.5:0,color:AppDesign.border(this.appDark)}).onClick(()=>this.parity=i)},(v:string)=>v)}.width('100%')
      if(this.error) {Text(this.error).fontSize(12).fontColor('#C43A35')}
      Row({space:12}) {Button('取消',{type:ButtonType.Capsule}).height(44).layoutWeight(1).backgroundColor(AppDesign.control(this.appDark)).fontColor(AppDesign.text(this.appDark)).onClick(()=>this.controller.close());Button('保存',{type:ButtonType.Capsule}).height(44).layoutWeight(1).onClick(()=>this.save());}.width('100%')
    }.padding(20).width('90%').constraintSize({maxWidth:480}).borderRadius(24).backgroundColor(AppDesign.surface(this.appDark))
  }
}
