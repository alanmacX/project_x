import { FrameNode, FrameCallback } from '@kit.ArkUI';
import { FridgeCard, CanvasBackground } from '../model/CardSchema';
import { CardTemplate } from '../model/CardTemplate';
import { cardViewSnapshot } from '../model/CardViewSnapshot';
import { templateColors } from '../model/TemplateScene';
import { PhotoCameraGesture, PhotoGesturePoint, PhotoSamples, PHOTO_CLOCK_POSITIONS, photoControlRegion, photoCompositionViewport, recommendPhotoClock } from '../model/TemplatePhotoComposition';
import { readPhotoSamples } from '../model/TemplatePhotoAnalysis';
import { AppDesign } from '../model/AppDesign';
import { navigationChrome } from '../model/NavigationChrome';
import { CardFace } from './CardFace';
import { SettingsSegmented } from './SettingsSegmented';
import { HdsNavigation, HdsNavigationTitleMode, TextStyleMode } from '@kit.UIDesignKit';
class PhotoLayoutReady extends FrameCallback {
 private action:()=>void;
 constructor(action:()=>void){super();this.action=action;}
 onFrame(_time:number):void{setTimeout(()=>this.action(),0);}
}
/** A dedicated composition surface. No embedded sheet, invisible hit portal or writes during a gesture. */
@Component
export struct TemplatePhotoEditor {
 @Prop card:FridgeCard=new FridgeCard();
 @Prop sceneBackground:CanvasBackground=new CanvasBackground();
 @Prop appDark:boolean=false;
 @Prop viewportWidth:number=400;
 @Prop viewportHeight:number=800;
 @Prop safeTop:number=0;
 @Prop safeBottom:number=0;
 @Prop tick:number=0;
 onDone:(template:CardTemplate)=>void=()=>{};
 onCancel:()=>void=()=>{};
 @State draft:FridgeCard=new FridgeCard();
 @State tab:number=0;
 @State titleInset:number=0;
 @State stageW:number=300;
 @State stageH:number=400;
 @State analysisReady:boolean=false;
 private subject:PhotoSamples=new PhotoSamples();
 private original:PhotoSamples=new PhotoSamples();
 private camera:PhotoCameraGesture=new PhotoCameraGesture();
 private live:FridgeCard=new FridgeCard();
 private alive:boolean=false;
 private repaintTimer:number=-1;
 aboutToAppear():void{this.alive=true;this.live=cardViewSnapshot(this.card);this.publish();this.analyze();this.getUIContext().postFrameCallback(new PhotoLayoutReady(()=>this.measureTitle()));}
 aboutToDisappear():void{this.alive=false;if(this.repaintTimer>=0)clearTimeout(this.repaintTimer);this.repaintTimer=-1;}
 private async analyze():Promise<void>{const photo=this.live.elements.find(e=>e.kind==='image'&&!!e.src);if(!photo)return;
  const results=await Promise.allSettled([readPhotoSamples(photo.depthForeground),readPhotoSamples(photo.src)]);if(!this.alive)return;
  if(results[0].status==='fulfilled')this.subject=(results[0] as PromiseFulfilledResult<PhotoSamples>).value;
  if(results[1].status==='fulfilled')this.original=(results[1] as PromiseFulfilledResult<PhotoSamples>).value;this.analysisReady=this.subject.width>0||this.original.width>0;if(this.live.template?.clockAuto)this.recommend();
 }
 private publish():void{if(this.repaintTimer>=0)clearTimeout(this.repaintTimer);this.repaintTimer=-1;this.draft=cardViewSnapshot(this.live);}
 private repaint():void{if(this.repaintTimer>=0)return;this.repaintTimer=setTimeout(()=>{this.repaintTimer=-1;if(this.alive)this.publish();},16);}
 private compact():boolean{return this.viewportHeight-this.safeTop-this.safeBottom<420;}
 private wide():boolean{return this.viewportWidth>=480&&this.viewportWidth>this.viewportHeight;}
 private photoScale():number{return Math.max(.001,Math.min(Math.max(1,this.stageW-32)/this.draft.w,Math.max(1,this.stageH-32)/this.draft.h));}
 private hasSubject():boolean{return this.draft.elements.some(e=>e.kind==='image'&&e.depthEnabled&&!!e.depthForeground);}
 private portrait():boolean{return this.draft.template?.id==='portrait';}
 private change(key:string,value:string|number|boolean):void{const t=this.live.template;if(!t)return;this.camera.reset();
  if(key==='mode'){t.photoMode=String(value);t.zoom=1;t.offsetX=0;t.offsetY=0;t.photoFraming=value==='photo'?'cover':'fit';}
  if(key==='depth')t.depth=value===true;
  if(key==='zoom')t.zoom=Number(value);
  if(key==='position'){t.clockPosition=String(value);t.clockAuto=false;}
  if(key==='reset'){t.zoom=1;t.offsetX=0;t.offsetY=0;}
  if(t.clockAuto)this.recommend(false);this.publish();
 }
 private recommend(publish:boolean=true):void{if(!this.live.template)return;const choice=recommendPhotoClock(this.live,this.subject,this.original,templateColors(this.live)[0]);this.live.template.clockPosition=choice.position;this.live.template.clockInk=choice.ink;this.live.template.clockAuto=true;if(publish)this.publish();}
 private touch(event:TouchEvent):void{
  event.stopPropagation();const t=this.live.template;if(!t)return;
  if(event.type===TouchType.Cancel){this.camera.reset();this.publish();return;}
  const excluded=event.type===TouchType.Up?event.changedTouches.map(p=>p.id):[];
  const viewport=photoCompositionViewport(this.live,this.photoScale()),points:PhotoGesturePoint[]=event.touches.filter(p=>!excluded.includes(p.id)).map((p:TouchObject):PhotoGesturePoint=>({id:p.id,x:(p.x-viewport.offsetX)/viewport.unit,y:(p.y-viewport.offsetY)/viewport.unit}));
  const pose=this.camera.update(points,t,photoControlRegion(this.live));t.zoom=pose.zoom;t.offsetX=pose.offsetX;t.offsetY=pose.offsetY;
  if(event.type===TouchType.Up){if(t.clockAuto)this.recommend(false);this.publish();}else this.repaint();
 }
 private finish():void{this.publish();if(this.live.template)this.onDone(this.live.template);}
 private measureTitle():void {
  if(!this.alive)return;const root=this.getUIContext().getFrameNodeById('photoCompositionNav');if(!root)return;
  const pending:FrameNode[]=[root];let visited=0;
  while(pending.length&&visited++<256){const node=pending.shift()!;if(node.getId()==='HdsTitleBar'){
    const height=this.getUIContext().px2vp(node.getMeasuredSize().height);if(height>0&&Math.abs(height-this.titleInset)>.1)this.titleInset=height;return;
   }let child=node.getFirstChild();while(child){pending.push(child);child=child.getNextSibling();}
  }
 }
 @Builder
 stage(){
  Stack({alignContent:Alignment.Center}){
   Stack({alignContent:Alignment.TopStart}){
    CardFace({card:this.draft,templateBackground:this.sceneBackground,tick:this.tick,scaleFactor:this.photoScale()}).width('100%').height('100%').hitTestBehavior(HitTestMode.None)
    Column().width('100%').height('100%').backgroundColor(Color.Transparent).hitTestBehavior(HitTestMode.Block).onTouch((event:TouchEvent)=>this.touch(event)).accessibilityText('照片：单指拖动，双指缩放')
   }.id('photoCompositionTouch').width(this.draft.w*this.photoScale()).height(this.draft.h*this.photoScale()).backgroundColor('#01000000').clip(true)
  }.id('photoCompositionStage').width('100%').height('100%').onAreaChange((_old:Area,next:Area)=>{if(this.stageW!==Number(next.width)||this.stageH!==Number(next.height))this.camera.reset();this.stageW=Number(next.width);this.stageH=Number(next.height);})
 }
 @Builder
 controls(){
  Scroll(){Column({space:this.compact()?8:12}){
   if(this.portrait()){SettingsSegmented({labels:['照片','时间'],selectedIndex:this.tab,appDark:this.appDark,onSelect:(index:number)=>this.tab=index})}
   if(this.tab===0){
    if(this.portrait()&&this.hasSubject()){SettingsSegmented({labels:['抠图主体','原图景深'],selectedIndex:this.draft.template?.photoMode==='photo'?1:0,appDark:this.appDark,onSelect:(index:number)=>this.change('mode',index===1?'photo':'subject')})}
    Row({space:12}){
     if(this.hasSubject()){Text(this.portrait()?'景深':'只用主体').fontSize(15).fontColor(AppDesign.text(this.appDark));Toggle({type:ToggleType.Switch,isOn:this.draft.template?.depth!==false}).onChange((value:boolean)=>this.change('depth',value))}
     Blank();Button('复位',{type:ButtonType.Capsule,buttonStyle:ButtonStyleMode.NORMAL}).height(40).fontSize(14).backgroundColor(AppDesign.control(this.appDark)).fontColor(AppDesign.text(this.appDark)).onClick(()=>this.change('reset',true))
    }.width('100%').height(40)
    Row({space:12}){SymbolGlyph($r('sys.symbol.minus')).fontSize(14).fontColor([AppDesign.text(this.appDark)]);Slider({value:this.draft.template?.zoom??1,min:.25,max:4,step:.01}).layoutWeight(1).onChange((value:number)=>this.change('zoom',value));SymbolGlyph($r('sys.symbol.plus')).fontSize(14).fontColor([AppDesign.text(this.appDark)])}.width('100%').height(40)
   }else{
    Row(){Button('智能选位',{type:ButtonType.Capsule,buttonStyle:ButtonStyleMode.NORMAL}).height(40).fontSize(14).fontColor(this.draft.template?.clockAuto?AppDesign.background(this.appDark):AppDesign.text(this.appDark)).backgroundColor(this.draft.template?.clockAuto?AppDesign.text(this.appDark):AppDesign.control(this.appDark)).enabled(this.analysisReady).onClick(()=>this.recommend());Blank();
     Button('浅色',{type:ButtonType.Capsule,buttonStyle:ButtonStyleMode.NORMAL}).height(40).fontSize(13).backgroundColor('#EEEEEE').fontColor('#202222').onClick(()=>{this.live.template!.clockAuto=false;this.live.template!.clockInk='#FFFFFF';this.publish();})
     Button('深色',{type:ButtonType.Capsule,buttonStyle:ButtonStyleMode.NORMAL}).height(40).fontSize(13).backgroundColor('#202222').fontColor('#FFFFFF').onClick(()=>{this.live.template!.clockAuto=false;this.live.template!.clockInk='#202222';this.publish();})
    }.width('100%')
    Row({space:6}){ForEach(PHOTO_CLOCK_POSITIONS,(position:string,index:number)=>{
     Button(['左上','上方','右上','左下','下方','右下'][index],{type:ButtonType.ROUNDED_RECTANGLE,buttonStyle:ButtonStyleMode.NORMAL}).layoutWeight(1).height(44).padding({left:0,right:0}).fontSize(12).fontColor(this.draft.template?.clockPosition===position&&!this.draft.template?.clockAuto?AppDesign.background(this.appDark):AppDesign.text(this.appDark)).backgroundColor(this.draft.template?.clockPosition===position&&!this.draft.template?.clockAuto?AppDesign.text(this.appDark):AppDesign.control(this.appDark)).onClick(()=>this.change('position',position))
    })}.width('100%')
   }
   if(!this.compact()){Text('拖动照片 · 双指缩放').fontSize(13).fontColor(AppDesign.muted(this.appDark)).height(24)}
  }.width('100%').padding(this.compact()?12:16)
  }.width('100%').height(this.portrait()?(this.compact()?232:296):(this.compact()?128:180)).align(Alignment.TopStart).scrollBar(BarState.Off).backgroundColor(AppDesign.surface(this.appDark)).borderRadius(24).clip(true)
 }
 build(){
  Column(){
   HdsNavigation(){
    Column(){
    if(this.wide()){
     Row({space:16}){Column(){this.stage()}.layoutWeight(1).height('100%');Column(){Blank();this.controls();Blank()}.width(Math.min(380,this.viewportWidth*.42)).height('100%')}.width('100%').height('100%').padding({left:16,right:16,bottom:this.safeBottom+12})
    }else{Column({space:12}){Column(){this.stage()}.layoutWeight(1).width('100%');this.controls()}.width('100%').height('100%').padding({left:12,right:12,bottom:this.safeBottom+12})}
    }.width('100%').height('100%').padding({top:this.titleInset}).opacity(this.titleInset>0?1:0)
   }.id('photoCompositionNav').onAreaChange(()=>this.measureTitle()).titleMode(HdsNavigationTitleMode.MINI).titleBar({content:{title:{mainTitle:'照片构图'},backIcon:{label:'取消',type:TextStyleMode.NORMAL,action:()=>this.onCancel()},menu:{maxCount:1,value:[{content:{label:'完成',type:TextStyleMode.NORMAL,action:()=>this.finish()}}]}},style:navigationChrome(this.appDark,true)})
     .hideToolBar(true).mode(NavigationMode.Stack).width('100%').height('100%').backgroundColor(Color.Transparent)
  }.width('100%').height('100%').padding({top:this.safeTop+4}).backgroundColor(AppDesign.background(this.appDark))
 }
}
