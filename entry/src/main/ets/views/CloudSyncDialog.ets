import { CloudRevision } from '../model/CloudSyncProtocol';
import { AppDesign } from '../model/AppDesign';
import { SettingsAction } from './SettingsAction';
@CustomDialog
export struct CloudSyncDialog {
  controller:CustomDialogController;
  appDark:boolean=false;
  onSync:(status:(message:string)=>void)=>Promise<string>=async()=>'';
  onArchives:()=>Promise<CloudRevision[]>=async()=>[];
  onRestore:(id:string)=>Promise<string>=async()=>'';
  @State archives:CloudRevision[]=[];
  @State busy:boolean=false;
  @State message:string='';
  private alive:boolean=true;
  aboutToAppear():void{this.alive=true;this.onArchives().then((records:CloudRevision[])=>{if(this.alive)this.archives=records;}).catch(()=>{});}
  aboutToDisappear():void{this.alive=false;}
  private async sync():Promise<void>{
    if(this.busy)return;this.busy=true;this.message='检查系统云空间';
    try{const result=await this.onSync((message:string)=>{if(this.alive)this.message=message;});if(this.alive){this.message=result;this.archives=await this.onArchives();}}
    catch(e){if(this.alive)this.message=(e as Error).message;}
    finally{if(this.alive)this.busy=false;}
  }
  private restore(record:CloudRevision):void{
    this.getUIContext().showAlertDialog({title:'恢复保留的数据？',message:record.kind==='timetable'?'将这份数据设为已保存课表，现有课程卡保持原样。':'将使用这份定时设置。现有画布保留。',primaryButton:{value:'取消',action:()=>{}},secondaryButton:{value:'恢复',action:()=>{this.busy=true;this.onRestore(record.revision).then((message:string)=>{if(this.alive)this.message=message;}).catch((e:Error)=>{if(this.alive)this.message=e.message;}).finally(()=>{if(this.alive)this.busy=false;});}}});
  }
  build(){
    Scroll(){
    Column({space:18}){
      Row(){Text('华为云空间').fontSize(22).fontWeight(FontWeight.Medium).fontColor(AppDesign.text(this.appDark)).layoutWeight(1)
        Button('完成',{type:ButtonType.Capsule}).height(44).enabled(!this.busy).onClick(()=>this.controller.close())}.width('100%')
      Text('同一华为账号，让作品在设备间相见。').fontSize(16).fontColor(AppDesign.text(this.appDark)).width('100%')
      Text('先在系统设置 → 云空间中开启本应用同步。点击下方按钮，会同步全部画布、素材、定时场景和已保存课表，包括课表与倒计日等私人内容。桌面组件的绑定留在各自设备。').fontSize(14).fontColor(AppDesign.muted(this.appDark)).width('100%')
      Text('由华为系统传输，无需另建账号。另一台设备也需打开本页同步；网络或系统条件可能延迟完成。离线修改发生冲突时保留副本，不直接覆盖。切换华为账号后，请先确认当前账号再同步。').fontSize(13).fontColor(AppDesign.muted(this.appDark)).width('100%')
      SettingsAction({label:this.busy?'同步中':'确认当前账号，立即同步',appDark:this.appDark,isEnabled:!this.busy,emphasis:true,fillWidth:true,onPress:()=>this.sync()})
      if(this.archives.length){Text('本机保留的数据版本').fontSize(15).fontColor(AppDesign.text(this.appDark)).width('100%');ForEach(this.archives,(record:CloudRevision)=>{SettingsAction({label:record.name+' · 恢复',appDark:this.appDark,isEnabled:!this.busy,fillWidth:true,onPress:()=>this.restore(record)})},(record:CloudRevision)=>record.revision)}
      if(this.message){Text(this.message).fontSize(13).fontColor(AppDesign.text(this.appDark)).width('100%')}
    }.padding(24).width('94%').backgroundColor(AppDesign.surface(this.appDark))
    }.width('94%').constraintSize({maxWidth:540,maxHeight:'85%'}).borderRadius(28).clip(true).backgroundColor(AppDesign.surface(this.appDark))
  }
}
