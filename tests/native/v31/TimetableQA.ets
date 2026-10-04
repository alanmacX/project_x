import { WakeUpImportDialog } from '../../views/WakeUpImportDialog';
import { WakeImport, WakeCourse } from '../../model/WakeUpImport';
import { CapBlock, CourseItem, FridgeCard } from '../../model/CardSchema';
import { CapabilityView } from '../../views/CapBlockView';
import { CapabilitySettings } from '../../views/CapabilitySettings';
import { WeekTimetable } from '../../views/WeekTimetable';
import { TimetableDialog } from '../../views/TimetableDialog';
import { CardCanvas } from '../../views/CardCanvas';
import { capabilityMinimum } from '../../model/CapabilityMetrics';
import { ensureCapabilitySize } from '../../model/CanvasLayout';
@Entry
@Component
struct TimetableQA {
  @State mode:string='next';
  @State dark:boolean=false;
  @State cap:CapBlock={k:'timetable',semester:'2026-08-31',timetableMode:'next',courses:[
    {id:'1',name:'高等数学 · 微积分与解析几何',room:'教学楼 A302',day:1,start:'08:00',end:'09:00',firstWeek:1,lastWeek:16,parity:0},
    {id:'2',name:'大学英语',room:'东区教学楼 403',day:1,start:'09:00',end:'10:00',firstWeek:1,lastWeek:16,parity:0},
    {id:'3',name:'计算机科学导论',room:'实验楼 B102',day:1,start:'10:00',end:'11:00',firstWeek:1,lastWeek:16,parity:0},
    {id:'4',name:'线性代数',room:'A301',day:1,start:'11:00',end:'12:00',firstWeek:1,lastWeek:16,parity:0},
    {id:'5',name:'中国近现代史纲要',room:'第二教学楼 C201',day:1,start:'13:00',end:'14:00',firstWeek:1,lastWeek:16,parity:0},
    {id:'6',name:'大学物理',room:'A402',day:1,start:'14:00',end:'15:00',firstWeek:1,lastWeek:16,parity:0},
    {id:'7',name:'程序设计实践',room:'机房 201',day:1,start:'15:00',end:'16:00',firstWeek:1,lastWeek:16,parity:0},
    {id:'8',name:'体育',room:'体育场',day:1,start:'16:00',end:'17:00',firstWeek:1,lastWeek:16,parity:0}
  ]};
  private importPreview():void {
    const parsed=new WakeImport();parsed.name='本地课表预览';parsed.semester='2026-08-31';parsed.courses=(this.cap.courses??[]).map((c:CourseItem):WakeCourse=>({name:c.name,room:c.room,day:c.day,firstWeek:c.firstWeek,lastWeek:c.lastWeek,parity:c.parity,firstNode:0,lastNode:0,start:c.start,end:c.end}));
    this.dialog=new CustomDialogController({builder:WakeUpImportDialog({appDark:this.dark,stage:true,parsed:parsed,semester:parsed.semester,previewCap:this.cap,previewReady:true}),customStyle:true});this.dialog.open();
  }
  private tick:number=new Date('2026-09-07T08:30:00').getTime();
  private brief():CapBlock {const cap=JSON.parse(JSON.stringify(this.cap)) as CapBlock;cap.timetableMode='day';return cap;}
  private holiday():CapBlock {const cap=JSON.parse(JSON.stringify(this.cap)) as CapBlock;cap.timetableMode='next';return cap;}
  private card():FridgeCard {const card=new FridgeCard();card.id='qa';card.w=192;card.h=192;card.shape='blob';card.material='cream';card.capability=this.brief();ensureCapabilitySize(card);return card;}
  private dialog:CustomDialogController|undefined=undefined;
  private week():void {this.dialog=new CustomDialogController({builder:TimetableDialog({cap:this.cap,appDark:this.dark}),customStyle:true});this.dialog.open();}
  build() {
    Column({space:16}) {
      Text('v31 课程与尺寸 QA').fontSize(20).fontColor(this.dark?'#FFFFFF':'#262824').margin({top:50})
      Row({space:4}) {ForEach(['next','day','week','settings','shape'],(mode:string)=>{Button(mode,{type:ButtonType.Capsule}).height(44).fontSize(12).onClick(()=>this.mode=mode)},(mode:string)=>mode)}
      Row({space:8}) {Button('日夜').onClick(()=>this.dark=!this.dark);Button('周课表弹窗').onClick(()=>this.week());Button('导入预览').onClick(()=>this.importPreview());}
      Scroll() {
        Column({space:16}) {
          if(this.mode==='next') {
            Text('最小尺寸 128×116').fontColor(this.dark?'#FFFFFF':'#262824')
            CapabilityView({cap:this.cap,contentWidth:128,contentHeight:116,tick:this.tick}).width(128).height(116).padding(0).backgroundColor('#F6F2E9').borderRadius(16)
            Text('假期中不显示远期课程').fontColor(this.dark?'#FFFFFF':'#262824')
            CapabilityView({cap:this.holiday(),contentWidth:180,contentHeight:116,tick:new Date('2026-10-01T10:00:00').getTime()}).width(180).height(116).backgroundColor('#F6F2E9').borderRadius(16)
          } else if(this.mode==='day') {
            Text('八节课 · 最小尺寸 192×258').fontColor(this.dark?'#FFFFFF':'#262824')
            CapabilityView({cap:this.brief(),contentWidth:192,contentHeight:258,tick:this.tick}).width(192).height(258).backgroundColor('#F6F2E9').borderRadius(16)
            Text('三列宽布局').fontColor(this.dark?'#FFFFFF':'#262824')
            CapabilityView({cap:this.brief(),contentWidth:300,contentHeight:210,tick:this.tick}).width(300).height(210).backgroundColor('#F6F2E9').borderRadius(16)
          } else if(this.mode==='week') {
            WeekTimetable({cap:this.cap,appDark:this.dark,initialWeek:2,heightLimit:380})
          } else if(this.mode==='settings') {
            CapabilitySettings({cap:this.cap,cardId:'qa',appDark:this.dark,onUpdate:(_id:string,cap:CapBlock)=>this.cap=cap}).padding(16).backgroundColor(this.dark?'#25231F':'#F6F2E9').borderRadius(20)
          } else {
            CardCanvas({card:this.card(),tick:this.tick}).width(this.card().w).height(this.card().h)
          }
        }.width('100%')
      }.layoutWeight(1).width('100%').scrollBar(BarState.Off)
    }.padding(16).width('100%').height('100%').backgroundColor(this.dark?'#101113':'#FFFFFF')
  }
}
