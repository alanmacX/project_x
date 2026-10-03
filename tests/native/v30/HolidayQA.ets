import { fileIo } from '@kit.CoreFileKit';
import { taskpool } from '@kit.ArkTS';
import { importHolidayFile } from '../../model/HolidayFiles';
import { CapBlock } from '../../model/CardSchema';
import { CalendarRulesDialog } from '../../views/CalendarRulesDialog';
@Entry
@Component
struct HolidayQA {
  @State result:string='验证原生 HolidayManager…';
  cap:CapBlock={k:'timetable',semester:'2026-08-31',courses:[{id:'math',name:'数学',room:'101',day:4,start:'09:00',end:'10:00',firstWeek:1,lastWeek:20,parity:0}],teachingDays:[{date:'2026-10-10',sourceDate:'2026-10-08'}]};
  dialog:CustomDialogController=new CustomDialogController({builder:CalendarRulesDialog({cap:this.cap,onSave:(cap:CapBlock)=>{this.result='规则已保存 '+JSON.stringify(cap);}}),customStyle:true});
  aboutToAppear():void {this.check();}
  async check():Promise<void>{
    try{const dir=getContext(this).cacheDir,path=dir+'/qa_holiday.ics';const file=await fileIo.open(path,fileIo.OpenMode.CREATE|fileIo.OpenMode.READ_WRITE|fileIo.OpenMode.TRUNC);
      await fileIo.write(file.fd,'BEGIN:VCALENDAR\r\nVERSION:2.0\r\nBEGIN:VEVENT\r\nUID:holiday-test\r\nDTSTART;VALUE=DATE:20261001\r\nDTEND;VALUE=DATE:20261008\r\nSUMMARY:学校假期\r\nEND:VEVENT\r\nEND:VCALENDAR\r\n');fileIo.closeSync(file.fd);
      this.result=await taskpool.execute(new taskpool.Task(importHolidayFile,path,dir)) as string;await fileIo.unlink(path);
    }catch(e){this.result='FAILED '+(e as Error).message;}
  }
  build(){Column({space:24}){Text('Holiday native QA').fontSize(26).fontColor('#262824');Text(this.result).fontSize(16).fontColor('#262824');Button('查看假期与调课').onClick(()=>this.dialog.open());}.padding(24).width('100%').height('100%').backgroundColor('#FFFFFF')}
}
