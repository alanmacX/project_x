import { FridgeCard, CapBlock, ElementBox, ShapePoint } from '../model/CardSchema';
import { EditorLayerMotion } from '../model/EditorLayerMotion';
import { edgeAttachment } from '../model/EdgeAttachment';
import { CardFace } from '../views/CardFace';
import { TimetableCapability } from '../views/TimetableCapability';
@Entry
@Component
struct EdgeQA {
 @State motion:EditorLayerMotion=new EditorLayerMotion();
 @State card:FridgeCard=this.makeCard();
 private startY:number=.25;
 private irregular:boolean=false;
 private makeCard():FridgeCard {const c=new FridgeCard();c.id='edge';c.w=220;c.h=280;c.shape=this.irregular?'subject':'round';if(this.irregular){const loop:ShapePoint[]=[];for(let i=0;i<80;i++){const a=i*Math.PI*2/80,rad=.43+.055*Math.cos(a*5);loop.push({x:.5+rad*Math.cos(a),y:.5+rad*Math.sin(a)});}c.outline=[loop];c.subjectBorder=true;c.subjectPhoto=true;c.cutout='resource://RAWFILE/edgeqa_subject.svg';}c.paper='#E6B949';c.capFree=true;c.capability={k:'countdown',date:'2026-12-01',title:'旅行计划',readingStyle:'surface',readingBlend:'sticker',readingEdge:'left'};c.capBox={x:.1,y:.25,w:.55,h:.4,rot:0,opacity:1};return c;}
 private setContact(side:string,outer:boolean):void {const c=this.makeCard();c.capability!.readingEdge=side;c.capability!.readingOutside=outer;const a=edgeAttachment(c,c.capBox,side,outer);c.capBox.x=a.box.x;c.capBox.y=a.box.y;this.card=c;}
 private lessons:CapBlock={k:'timetable',semester:'2026-08-31',timetableMode:'day',readingBlend:'tag',readingStyle:'surface',courses:[{id:'a',name:'软件工程',room:'教学楼 301',day:1,start:'14:00',end:'15:30',firstWeek:1,lastWeek:20,parity:0},{id:'b',name:'计算机网络',room:'教学楼 205',day:1,start:'16:00',end:'17:30',firstWeek:1,lastWeek:20,parity:0},{id:'c',name:'健身',room:'体育馆',day:1,start:'19:00',end:'20:00',firstWeek:1,lastWeek:20,parity:0}]};
 build() {
  Scroll(){Column({space:16}) {
   Text('左右轮廓 · 内外贴合').fontSize(22).fontWeight(FontWeight.Medium)
   Row({space:8}){Button('左内').onClick(()=>this.setContact('left',false));Button('左外').onClick(()=>this.setContact('left',true));Button('右内').onClick(()=>this.setContact('right',false));Button('右外').onClick(()=>this.setContact('right',true))}
   Button('椭圆 / 异形').onClick(()=>{this.irregular=!this.irregular;this.setContact(this.card.capability?.readingEdge||'left',this.card.capability?.readingOutside===true);})
   Stack(){CardFace({card:this.card,layerMotion:this.motion,scaleFactor:.8}).width(176).height(224)}.width(340).height(280).backgroundColor('#EAE3D7').borderRadius(20)
    .gesture(PanGesture({direction:PanDirection.Vertical,distance:1}).onActionStart(()=>{this.startY=this.card.capBox.y;this.motion.update('capability',this.card.capBox);}).onActionUpdate((e:GestureEvent)=>{const b=new ElementBox();b.x=this.card.capBox.x;b.y=this.startY+e.offsetY/224;b.w=this.card.capBox.w;b.h=this.card.capBox.h;const a=edgeAttachment(this.card,b,this.card.capability?.readingEdge||'left',this.card.capability?.readingOutside===true);b.x=a.box.x;b.y=a.box.y;this.motion.update('capability',b);}).onActionEnd(()=>{const c=this.makeCard();c.capability!.readingEdge=this.card.capability?.readingEdge;c.capability!.readingOutside=this.card.capability?.readingOutside;c.capBox=this.motion.box;this.card=c;this.motion.clear();}))
   Text('上下拖动，贴合侧始终跟随轮廓').fontSize(13)
   TimetableCapability({cap:this.lessons,contentBackingEnabled:true,contentWidth:240,contentHeight:196,scaleFactor:1,tick:new Date('2026-10-12T13:00:00').getTime()}).width(280).height(236)
   Text('课程表 · 时间、名称、地点；下一节突出显示').fontSize(13)
  }.padding({top:50,bottom:30}).width('100%')}.width('100%').height('100%').backgroundColor('#F6F2E9').expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.TOP,SafeAreaEdge.BOTTOM])
 }
}
