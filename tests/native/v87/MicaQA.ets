import { FridgeCard, CapBlock } from '../model/CardSchema';
import { CardFace } from '../views/CardFace';
import { HookPlacement } from '../views/HookPlacement';
@Entry
@Component
struct MicaQA {
 @State dynamic:boolean=false;
 @State turn:number=0;
 @State hook:number=.5;
 private timer:number=-1;
 private labels:string[]=['笔触云母 · 时间','圆形徽章 · 电量','自适应贴片 · 台历','负空间 · 世界时钟','边缘挂签 · 倒计时','信息 Dock · 日程'];
 private kinds:string[]=['clock','battery','calendar','worldclock','countdown','agenda'];
 private styles:string[]=['bare','badge','sticker','space','tag','dock'];
 aboutToDisappear():void {if(this.timer>=0)clearInterval(this.timer);}
 private card(i:number):FridgeCard {
  const c=new FridgeCard();c.id='mica-'+i;c.w=240;c.h=240;c.shape='blob';c.paper='#E6B949';c.ink='#202629';c.capFree=true;
  const now=Date.now();const cap:CapBlock={k:this.kinds[i],readingStyle:'surface',readingBlend:this.styles[i],readingHook:this.hook,readingEdge:i===2?'left':'',percent:this.turn%2?100:67,charging:true,zone:'Asia/Shanghai',date:'2026-12-01',title:this.turn%2?'新的旅行计划':'周末旅行',events:this.turn%2?[]:[{id:'a',allDay:false,title:'设计评审',location:'工作室',start:now+3600000,end:now+7200000},{id:'b',allDay:false,title:'取书',location:'图书馆',start:now+10800000,end:now+14400000}]};
  c.capability=cap;c.capBox.x=i===3?-.23:i===5?.5:0;c.capBox.y=.3;c.capBox.w=i===2?.94:i===5?.82:.82;c.capBox.h=i===2?.7:i===5?.64:.6;
  return c;
 }
 @Builder sample(i:number) {
  Column({space:6}) {
   Stack(){CardFace({card:this.card(i),scaleFactor:.5,tick:Date.now()}).width(120).height(120).translate({x:i===5?-20:i===3?14:0})}.width(156).height(160).backgroundColor('#EAE3D7').borderRadius(18)
   Text(this.labels[i]).fontSize(13).fontColor('#222629').maxLines(1)
  }.width(156)
 }
 build() {
  Scroll(){Column({space:16}) {
   Text('云白云母 · 六种内容融合').fontSize(21).fontWeight(FontWeight.Medium).fontColor('#202629')
   Row({space:12}){Button(this.dynamic?'停止内容变化':'测试内容变化').onClick(()=>{this.dynamic=!this.dynamic;if(this.dynamic)this.timer=setInterval(()=>this.turn++,1500);else clearInterval(this.timer);});Text('第 '+this.turn+' 次').fontSize(14)}
   Row({space:12}){this.sample(0);this.sample(1)}
   Row({space:12}){this.sample(2);this.sample(3)}
   Row({space:12}){this.sample(4);this.sample(5)}
   HookPlacement({hookLocation:this.hook,onChoose:(p:number)=>this.hook=p}).width(320)
  }.padding({top:50,bottom:30,left:10,right:10}).width('100%')}.width('100%').height('100%').backgroundColor('#F6F2E9').expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.TOP,SafeAreaEdge.BOTTOM])
 }
}
