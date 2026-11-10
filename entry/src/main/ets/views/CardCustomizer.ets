import { AlbumSettings } from './AlbumSettings';
import { albumLibrary, activeAlbum, selectAlbum } from '../model/AlbumRotation';
import { bindDemoPhoto, bindDemoAlbum, filterDemoAssets } from '../demo/DemoMaterialBinding';
import { FrameCallback } from '@kit.ArkUI';
import { SceneRect } from '../model/SceneLayout';
import { motionFrameRate } from '../model/MotionPolicy';
import { CUSTOMIZER_ENTER_DURATION, CUSTOMIZER_EXIT_DURATION, customizerEntrancePose } from '../model/CustomizerTransition';
import { constrainDemoPhoto } from '../demo/DemoPhotoGeometry';
import { readPhotoSamples } from '../model/TemplatePhotoAnalysis';
import { common } from '@kit.AbilityKit';
import { FridgeState, FridgeCard, CanvasElement, CapBlock, ElementBox, AlbumCover } from '../model/CardSchema';
import { CARD_TEMPLATES, TemplateDefinition, templateDefinition, copyCardTemplate } from '../model/CardTemplate';
import { makeTemplateCards } from '../model/TemplateFactory';
import { cardCapabilities, replaceCardCapability } from '../model/TemplateSources';
import { capabilityDescriptor } from '../model/CapabilityCatalog';
import { templateColors } from '../model/TemplateScene';
import { cardViewSnapshot } from '../model/CardViewSnapshot';
import { PhotoCameraGesture, PhotoGesturePoint, photoControlRegion, PHOTO_CLOCK_POSITIONS, recommendPhotoClock, PhotoSamples, photoClockDepthAllowed } from '../model/TemplatePhotoComposition';
import { templatePhotoBox } from '../model/TemplatePhotoGeometry';
import { CardFace } from './CardFace';
import { CapabilitySettings } from './CapabilitySettings';
import { TimeCapabilitySettings } from './TimeCapabilitySettings';
import { DemoAssets, DemoAsset } from '../demo/DemoAssets';
const GREEN:string='#D1F18A';
const INK:string='#24251F';
class CustomizerFrame extends FrameCallback {
  private action:()=>void;
  constructor(action:()=>void){super();this.action=action;}
  onFrame():void{this.action();}
}
@Component
export struct CardCustomizer {
  @Prop initialCard:FridgeCard=new FridgeCard();
  @Prop initialDocument:FridgeState=new FridgeState();
  @Prop libraryMode:boolean=false;
  @Prop libraryPurpose:string='image';
  @Prop animateEntrance:boolean=false;
  @Prop entranceOrigin:SceneRect=new SceneRect();
  @Prop returnOrigin:SceneRect=new SceneRect();
  @Prop @Watch('requestExit') exitRequest:number=0;
  onExitStart:()=>void=()=>{};
  @State exitRunning:boolean=false;
  private previewRect:SceneRect=new SceneRect();
  onEntranceStart:()=>void=()=>{};
  onEntranceEnd:()=>void=()=>{};
  @State entranceX:number=0;
  @State entranceY:number=0;
  @State entranceScale:number=1;
  @State entranceAngle:number=0;
  @State entranceChrome:number=1;
  @State entranceVisible:boolean=true;
  @State entranceRunning:boolean=false;
  private entranceMeasured:boolean=false;
  private entranceGeneration:number=0;
  @Prop viewportW:number=390;
  @Prop viewportH:number=844;
  @Prop safeTop:number=32;
  @Prop safeBottom:number=24;
  onDone:(card:FridgeCard)=>void=()=>{};
  onCancel:()=>void=()=>{};
  onPick:(asset:DemoAsset,subject:boolean)=>void=()=>{};
  @State ready:boolean=false;
  @State assetsReady:boolean=false;
  @State busy:boolean=false;
  @State error:string='';
  @State face:FridgeCard=new FridgeCard();
  @State document:FridgeState=new FridgeState();
  @State assets:DemoAsset[]=[];
  @State assetFilter:string='全部';
  @State editTab:number=0;
  @State photoPanel:string='source';
  @State sheet:boolean=false;
  @State sheetType:string='';
  @State contentIndex:number=0;
  @State toneIndex:number=0;
  @State subjectMaterial:boolean=false;
  @State tick:number=Date.now();
  private context:common.UIAbilityContext|null=null;
  private library:DemoAssets=new DemoAssets();
  private previews:Map<string,FridgeCard>=new Map();
  private camera:PhotoCameraGesture=new PhotoCameraGesture();
  private materialTarget:string='library';
  private materialCapabilityIndex:number=0;
  private materialReturnSheet:string='';
  private materialOwner:string='';
  private screen:string='edit';
  private pulse:number=-1;
  private alive:boolean=false;
  aboutToAppear():void{this.alive=true;this.entranceRunning=this.animateEntrance&&!this.libraryMode;this.entranceChrome=this.entranceRunning?0:1;this.entranceVisible=!this.entranceRunning;this.initialize();this.pulse=setInterval(()=>this.tick=Date.now(),60000);}
  aboutToDisappear():void{this.entranceGeneration++;this.alive=false;this.screen='closed';if(this.pulse>=0)clearInterval(this.pulse);}
  private async initialize():Promise<void>{
    this.context=this.getUIContext().getHostContext() as common.UIAbilityContext;
    this.face=cardViewSnapshot(this.initialCard);this.document=JSON.parse(JSON.stringify(this.initialDocument)) as FridgeState;
    for(const definition of CARD_TEMPLATES){const c=makeTemplateCards(definition.id,1,()=>definition.id)[0];if(c)this.previews.set(definition.id,c);}
    this.ready=true;if(this.libraryMode&&this.libraryPurpose==='album')this.assetFilter='专辑';await this.loadAssets();
  }
  private async loadAssets():Promise<void>{
    if(!this.context)return;this.error='';
    try{await this.library.init(this.context);if(!this.alive)return;
      for(const card of this.document.cards){for(const el of card.elements){if(el.kind==='image'&&el.src)this.library.remember(el);}for(const cap of cardCapabilities(card))this.library.rememberAlbums(cap);}
      const photo=this.currentPhoto();if(photo?.src)this.library.remember(photo);this.assets=this.library.items.slice();this.assetsReady=true;
      const asset=this.library.match(photo?.src??'');this.toneIndex=Math.max(0,asset?.tones.indexOf(photo?.src??'')??0);
    }catch(e){this.error=(e as Error).message;this.toast('素材库读取失败，请重试');}
  }
  private measureEntrance(area:Area):void{
    if(Number(area.width)<=0||Number(area.height)<=0||this.exitRunning)return;
    const target=new SceneRect();target.x=Number(area.globalPosition.x);target.y=Number(area.globalPosition.y);target.w=Number(area.width);target.h=Number(area.height);
    this.previewRect=target;
    if(!this.entranceRunning||this.entranceMeasured)return;
    this.entranceMeasured=true;
    const pose=customizerEntrancePose(this.entranceOrigin,target),generation=++this.entranceGeneration;
    this.entranceX=pose.x;this.entranceY=pose.y;this.entranceScale=pose.scale;this.entranceAngle=pose.angle;
    this.getUIContext().postFrameCallback(new CustomizerFrame(()=>{
      if(!this.alive||generation!==this.entranceGeneration)return;
      this.entranceVisible=true;this.onEntranceStart();
      this.getUIContext().postFrameCallback(new CustomizerFrame(()=>{
        if(!this.alive||generation!==this.entranceGeneration)return;
        this.getUIContext().animateTo({duration:CUSTOMIZER_ENTER_DURATION,curve:Curve.Friction,expectedFrameRateRange:motionFrameRate(),onFinish:()=>{
          if(!this.alive||generation!==this.entranceGeneration)return;
          this.entranceRunning=false;this.onEntranceEnd();
        }},()=>{this.entranceX=0;this.entranceY=0;this.entranceScale=1;this.entranceAngle=0;this.entranceChrome=1;});
      }));
    }));
  }
  private toast(message:string):void{if(this.alive)this.getUIContext().getPromptAction().showToast({message:message});}
  private publishFace():void{this.face=cardViewSnapshot(this.face);}
  private requestExit():void{if(this.sheet){this.closeSheet();return;}if(this.photoPanel==='clock'){this.photoPanel='source';return;}this.cancelFace();}
  private exitFace(save:boolean):void{
    if(this.entranceRunning||this.exitRunning||this.busy||!this.alive)return;
    const next=cardViewSnapshot(this.face);
    if(!this.animateEntrance||this.libraryMode||this.previewRect.w<=0){if(save)this.onDone(next);else this.onCancel();return;}
    this.exitRunning=true;this.screen='leaving';this.sheet=false;
    if(!save)this.face=cardViewSnapshot(this.initialCard);
    const pose=customizerEntrancePose(this.returnOrigin,this.previewRect),generation=++this.entranceGeneration;
    this.onExitStart();
    this.getUIContext().animateTo({duration:CUSTOMIZER_EXIT_DURATION,curve:Curve.Friction,expectedFrameRateRange:motionFrameRate(),onFinish:()=>{
      if(!this.alive||generation!==this.entranceGeneration)return;
      if(save)this.onDone(next);else this.onCancel();
    }},()=>{this.entranceX=pose.x;this.entranceY=pose.y;this.entranceScale=pose.scale;this.entranceAngle=pose.angle;this.entranceChrome=0;});
  }
  private finishFace():void{this.exitFace(true);}
  private cancelFace():void{this.exitFace(false);}
  private materialAlbum():boolean{return this.materialTarget==='album'||this.libraryMode&&this.libraryPurpose==='album';}
  private materialFilters():string[]{return this.libraryMode&&this.libraryPurpose==='image'?['全部','照片','抠图','专辑']:this.materialAlbum()?['专辑','照片']:['照片','抠图'];}
  private openMaterials(target:string,index:number=0):void{
    if(this.busy)return;
    this.materialReturnSheet=this.sheet?this.sheetType:'';this.materialTarget=target;this.materialCapabilityIndex=index;this.materialOwner=this.face.id;
    this.subjectMaterial=false;this.assetFilter=target==='album'?'专辑':'照片';this.sheetType='materials';this.sheet=true;
  }
  private closeSheet():void{
    if(this.busy)return;
    if(this.sheetType==='materials'&&this.materialReturnSheet){this.sheetType=this.materialReturnSheet;this.materialReturnSheet='';return;}
    this.sheet=false;this.materialReturnSheet='';
  }
  private async useMaterial(item:DemoAsset):Promise<void>{
    if(this.busy||!this.assetsReady)return;
    if(this.libraryMode){this.contentIndex=this.assets.findIndex(a=>a.id===item.id);this.sheetType='asset';this.sheet=true;return;}
    if(this.materialOwner!==this.face.id)return;
    const owner=this.face.id,target=this.materialTarget,index=this.materialCapabilityIndex;
    if(target==='album'){
      this.busy=true;
      try{await this.library.prepareAlbum(item);if(!this.alive||this.screen!=='edit'||this.face.id!==owner||this.materialTarget!==target)return;
        if(!bindDemoAlbum(this.face,index,item)){this.toast('封面库最多保留 12 张，请先移除一张');return;}
      }catch(e){this.toast((e as Error).message);return;}finally{this.busy=false;}
    }else{this.attachPhoto(this.face,item,false);this.toneIndex=0;this.camera.reset();this.smartClock();}
    this.assets=this.library.items.slice();this.publishFace();this.closeSheet();
  }
  private async confirmLibraryAsset():Promise<void>{
    const item=this.assets[this.contentIndex];if(!item||this.busy)return;
    this.busy=true;
    try{if(this.libraryPurpose==='album')await this.library.prepareAlbum(item);if(!this.alive)return;this.sheet=false;this.onPick(item,this.libraryPurpose!=='album'&&this.subjectMaterial);}
    catch(e){this.toast((e as Error).message);}finally{this.busy=false;}
  }
  private label(card:FridgeCard):string{return templateDefinition(card.template?.id??'')?.name??(card.capability?capabilityDescriptor(card.capability.k).name:card.elements.some(e=>e.kind==='image')?'照片贴纸':'文字贴纸');}

  private currentPhoto():CanvasElement|undefined{return this.face.elements.find(e=>e.kind==='image');}

  private photoTemplate():boolean{return ['portrait','anniversary-photo','mix-memory'].includes(this.face.template?.id??'');}

  private contentAvailable():boolean{return this.face.elements.length>0||this.photoTemplate()||cardCapabilities(this.face).some(c=>['countdown','anniversary','worldclock','timetable','agenda','album'].includes(c.k));}

  private attachPhoto(card:FridgeCard,item:DemoAsset,subject:boolean):void{bindDemoPhoto(card,item,subject);}
  private async extractCurrentPhoto():Promise<void>{
    const item=this.library.match(this.currentPhoto()?.src??'');if(!item||this.busy)return;
    const owner=this.face.id,src=this.currentPhoto()?.src;this.busy=true;
    try{await this.library.cutout(item.id);if(!this.alive||this.screen!=='edit'||this.face.id!==owner||this.currentPhoto()?.src!==src)return;
      const photo=this.currentPhoto()!;photo.depthForeground=item.subject;photo.depthCrop=JSON.parse(JSON.stringify(item.crop)) as ElementBox;photo.depthSourceAspect=item.aspect;photo.depthEnabled=true;
      this.face.template!.depth=true;this.assets=this.library.items.slice();this.publishFace();await this.smartClock();
    }catch(e){this.toast((e as Error).message);}finally{this.busy=false;}
  }

  private async suggestClock(card:FridgeCard):Promise<void>{
    const photo=card.elements.find(e=>e.kind==='image'),t=card.template;if(!photo||!t||t.id!=='portrait')return;
    try{const subject=photo.depthForeground?await readPhotoSamples(photo.depthForeground):new PhotoSamples(),original=await readPhotoSamples(photo.src),choice=recommendPhotoClock(card,subject,original,templateColors(card)[0]);
      t.clockPosition=choice.position;t.clockInk=choice.ink;t.clockAuto=true;
      t.depth=!!photo.depthForeground;
    }catch(_){t.clockPosition='bottom-left';t.clockInk='#FFFFFF';t.depth=false;}
  }

  private async smartClock():Promise<void>{const id=this.face.id,before=JSON.stringify(this.face),next=cardViewSnapshot(this.face);await this.suggestClock(next);if(this.screen==='edit'&&this.face.id===id&&JSON.stringify(this.face)===before){this.face=next;this.publishFace();}}

  private async importPhoto():Promise<void>{if(this.busy||!this.assetsReady)return;this.busy=true;const target=this.materialTarget,owner=this.materialOwner;
    try{const item=await this.library.importPhoto();if(!this.alive)return;this.assets=this.library.items.slice();this.busy=false;
      if(item&&target===this.materialTarget&&owner===this.materialOwner){if(this.libraryMode){this.assetFilter=this.libraryPurpose==='album'?'照片':'全部';this.useMaterial(item);}else if(target!=='library')await this.useMaterial(item);}}catch(e){this.toast((e as Error).message);}finally{this.busy=false;}
  }

  private async extract():Promise<void>{if(this.busy)return;const asset=this.assets[this.contentIndex];if(!asset)return;this.busy=true;try{await this.library.cutout(asset.id);this.assets=this.library.items.slice();this.toast('主体已存入素材库');}catch(e){this.toast((e as Error).message);}finally{this.busy=false;}}

  private async tone(index:number):Promise<void>{const photo=this.currentPhoto(),asset=this.library.match(photo?.src??'');if(!photo||!asset||this.busy)return;const id=this.face.id;this.busy=true;
    try{const src=await this.library.tone(asset,index);if(this.screen==='edit'&&this.face.id===id&&this.currentPhoto()?.src===photo.src){this.currentPhoto()!.src=src;this.toneIndex=index;this.publishFace();}}catch(e){this.toast((e as Error).message);}finally{this.busy=false;}}

  private variants():TemplateDefinition[]{return CARD_TEMPLATES.filter(t=>t.kind===templateDefinition(this.face.template?.id??'')?.kind&&t.kind!=='ensemble');}

  private changeDesign(id:string):void{if(!this.face.template||id===this.face.template.id)return;const old=this.face.template;this.face.template=copyCardTemplate(old);this.face.template!.id=id;
    this.photoPanel='source';if(id==='portrait'){this.face.template!.photoMode='photo';this.face.template!.photoFraming='cover';}if(!this.contentAvailable()&&this.editTab===2)this.editTab=0;this.publishFace();if(id==='portrait')this.smartClock();}

  private setCap(cap:CapBlock,index:number):void{const old=cardCapabilities(this.face)[index];if(old){replaceCardCapability(this.face,old,cap);this.publishFace();}}

  private setText(value:string):void{const text=this.face.elements.find(e=>e.kind==='text');if(text){text.text=value;this.publishFace();}}

  private setPhotoMode(subject:boolean):void{if(!this.face.template||subject&&!this.currentPhoto()?.depthForeground)return;this.face.template.photoMode=subject?'subject':'photo';this.face.template.photoFraming=subject?'fit':'cover';this.face.template.zoom=1;this.face.template.offsetX=0;this.face.template.offsetY=0;this.camera.reset();this.publishFace();}

  private clampPhoto():void{constrainDemoPhoto(this.face);}

  private photoTouch(event:TouchEvent):void{if(this.editTab!==2||this.face.template?.id!=='portrait')return;event.stopPropagation();const t=this.face.template;if(event.type===TouchType.Cancel){this.camera.reset();return;}const excluded=event.type===TouchType.Up?event.changedTouches.map(p=>p.id):[];
    const unit=this.faceWidth()/300,points:PhotoGesturePoint[]=event.touches.filter(p=>!excluded.includes(p.id)).map((p:TouchObject):PhotoGesturePoint=>({id:p.id,x:p.x/unit,y:p.y/unit}));const pose=this.camera.update(points,t,photoControlRegion(this.face));t.zoom=pose.zoom;t.offsetX=pose.offsetX;t.offsetY=pose.offsetY;this.clampPhoto();this.publishFace();}

  private wideEditor():boolean{return this.viewportW>this.viewportH;}
  private faceWidth():number{return Math.max(72,Math.min(this.wideEditor()?this.viewportW*.5-40:this.viewportW-56,400,(this.viewportH-this.safeTop-this.safeBottom-(this.wideEditor()?100:320))*this.face.w/this.face.h));}

  private filteredAssets():DemoAsset[]{return filterDemoAssets(this.assets,this.assetFilter);}

  @Builder chip(label:string,active:boolean,action:()=>void,dark:boolean=false){
    Button(label,{type:ButtonType.Capsule,buttonStyle:ButtonStyleMode.NORMAL}).height(40).fontSize(14).padding({left:17,right:17}).fontColor(active?(dark?'#182010':'#FFFFFF'):(dark?'#E8E8E4':INK)).backgroundColor(active?(dark?GREEN:INK):(dark?'#242622':'#E8E5DE')).onClick(action)
  }

  @Builder icon(label:string,action:()=>void,dark:boolean=false){Button(label,{type:ButtonType.Circle,buttonStyle:ButtonStyleMode.NORMAL}).width(44).height(44).fontSize(21).fontColor(dark?'#F2F2EC':INK).backgroundColor(dark?'#252722':'#E8E5DE').onClick(action)}

  @Builder materialGrid(picking:boolean){
    Column({space:16}){
      if(this.wideEditor()){
        Row({space:12}){Scroll(){Row({space:8}){ForEach(this.materialFilters(),(label:string)=>{this.chip(label,this.assetFilter===label,()=>{this.assetFilter=label;this.subjectMaterial=label==='抠图';},picking)})}}.scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off).layoutWeight(1);Button('导入照片',{buttonStyle:ButtonStyleMode.NORMAL}).height(40).fontSize(13).fontColor(GREEN).backgroundColor('#242622').enabled(this.assetsReady&&!this.busy).onClick(()=>this.importPhoto())}.width('100%').padding({left:24,right:24})
      }else{
      Scroll(){Row({space:8}){ForEach(this.materialFilters(),(label:string)=>{this.chip(label,this.assetFilter===label,()=>{this.assetFilter=label;this.subjectMaterial=label==='抠图';},picking)})}.padding({left:24,right:24})}.scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off).width('100%')
      }
      if(this.error){Text('素材库读取失败：'+this.error).fontSize(13).fontColor('#D6C5B0').maxLines(3).padding({left:24,right:24});Button('重新读取').fontColor(INK).backgroundColor(GREEN).onClick(()=>this.loadAssets())}
      if(picking&&!this.wideEditor()){Button(this.assetsReady?'从系统相册导入':'正在读取素材',{buttonStyle:ButtonStyleMode.NORMAL}).height(44).fontColor(GREEN).backgroundColor('#242622').enabled(this.assetsReady&&!this.busy).onClick(()=>this.importPhoto())}
      if(this.filteredAssets().length===0){Column({space:12}){Text(this.assetFilter==='专辑'?'还没有专辑封面':this.assetFilter==='抠图'?'还没有提取过的主体':'还没有照片').fontSize(18).fontColor(picking?'#F0F0EA':INK);Text(this.assetFilter==='抠图'?'在照片详情中提取主体后，会显示在这里':'从相册导入，之后可以反复使用').fontSize(13).fontColor('#929389');Button('导入照片').backgroundColor(picking?GREEN:INK).fontColor(picking?INK:'#FFFFFF').enabled(this.assetsReady&&!this.busy).onClick(()=>{this.materialTarget=picking?this.materialTarget:'library';this.importPhoto();})}.layoutWeight(1).justifyContent(FlexAlign.Center)}else{
      Grid(){ForEach(this.filteredAssets(),(asset:DemoAsset)=>{GridItem(){Column({space:9}){Image(this.assetFilter==='抠图'?asset.subject:this.materialAlbum()&&asset.albumCover?asset.albumCover:asset.original).objectFit(this.assetFilter==='抠图'?ImageFit.Contain:ImageFit.Cover).width('100%').aspectRatio(1).borderRadius(18).backgroundColor(picking?'#30322C':'#E5E1D8');Text(asset.name).maxLines(1).textOverflow({overflow:TextOverflow.Ellipsis}).fontSize(14).fontColor(picking?'#ECEDE6':INK).width('100%');Text(asset.category==='专辑'?'专辑封面':asset.subject?'带主体':'照片').fontSize(11).fontColor('#85877D').width('100%')}.onClick(()=>{if(!picking){this.materialTarget='library';this.sheet=true;}this.useMaterial(asset);})}},(asset:DemoAsset)=>asset.id)}.columnsTemplate(this.wideEditor()?'1fr 1fr 1fr 1fr':'1fr 1fr').columnsGap(14).rowsGap(18).layoutWeight(1).padding({left:24,right:24})}
    }.width('100%').layoutWeight(1)
  }

  @Builder editorPreview(){
      Stack(){
        Stack({alignContent:Alignment.TopStart}){CardFace({card:this.face,scaleFactor:this.faceWidth()/this.face.w,tick:this.tick,templateBackground:this.document.background}).width('100%').height('100%').hitTestBehavior(HitTestMode.None)
          if(this.photoTemplate()&&!this.currentPhoto()?.src){Column(){Button('选择照片').fontColor(INK).backgroundColor(GREEN).onClick(()=>this.openMaterials('face'))}.width('100%').height('100%').justifyContent(FlexAlign.Center)}
          if(this.editTab===2){Column().width('100%').height('100%').backgroundColor('#01000000').border({width:1,color:'#A0D1F18A'}).onTouch((e:TouchEvent)=>this.photoTouch(e)).onClick(()=>{if(this.photoTemplate()&&!this.currentPhoto()?.src)this.openMaterials('face');else if(this.face.template?.id!=='portrait')this.openContent();})}
        }.width(this.faceWidth()).height(this.face.h*this.faceWidth()/this.face.w).borderRadius(24).clip(true).onAreaChange((_before:Area,after:Area)=>this.measureEntrance(after)).scale({x:this.entranceScale,y:this.entranceScale}).rotate({angle:this.entranceAngle}).translate({x:this.entranceX,y:this.entranceY}).opacity(this.entranceVisible?1:0)
      }.width('100%').height('100%')
  }
  @Builder editorControls(){
    Column(){
      Text(this.editTab===0?'左右切换外观':this.editTab===1?(this.photoTemplate()?'背景色调 · 保留主体原色':'选择喜欢的配色'):this.face.template?.id==='portrait'?(this.face.template.depth&&!photoClockDepthAllowed(this.face)&&!!this.currentPhoto()?.depthForeground?'遮挡过多，时间自动显示在前':'拖动照片 · 双指缩放'):'轻点画面，修改内容').fontSize(12).fontColor('#969B8B').height(32).opacity(this.entranceChrome)
      Row({space:8}){ForEach(this.contentAvailable()?['外观','色彩','内容']:['外观','色彩'],(label:string,index:number)=>{Button(label,{buttonStyle:ButtonStyleMode.NORMAL}).height(40).layoutWeight(1).fontColor(this.editTab===index?GREEN:'#909787').fontWeight(this.editTab===index?FontWeight.Bold:FontWeight.Normal).backgroundColor(this.editTab===index?'#262C20':Color.Transparent).borderRadius(20).onClick(()=>{this.editTab=index;this.camera.reset();})})}.width('100%').padding({left:44,right:44}).opacity(this.entranceChrome)
      Swiper(){this.styleControls();this.colorControls();if(this.contentAvailable()){this.contentControls()}}.index(this.editTab).loop(false).indicator(false).onChange((index:number)=>{this.editTab=index;this.camera.reset();}).width('100%').height(this.wideEditor()?200:188).opacity(this.entranceChrome)
    }.width('100%')
  }
  @Builder editor(){
    Column(){
      Row(){Button('取消',{buttonStyle:ButtonStyleMode.NORMAL}).width(62).height(44).backgroundColor(Color.Transparent).fontColor('#DBDDD4').onClick(()=>this.cancelFace());Text(this.label(this.face)).fontSize(17).fontWeight(FontWeight.Medium).fontColor('#F1F2EC').layoutWeight(1).textAlign(TextAlign.Center);Button('完成',{buttonStyle:ButtonStyleMode.NORMAL}).width(62).height(44).fontColor('#182010').backgroundColor(GREEN).borderRadius(24).onClick(()=>this.finishFace())}.width('100%').padding({left:16,right:20,top:8}).opacity(this.entranceChrome)
      if(this.wideEditor()){
        Row(){Column(){this.editorPreview()}.width('50%').height('100%');Scroll(){this.editorControls()}.width('50%').height('100%').scrollBar(BarState.Off)}.width('100%').layoutWeight(1)
      }else{Column(){this.editorPreview()}.width('100%').layoutWeight(1);this.editorControls()}
    }.width('100%').height('100%').padding({top:this.safeTop,bottom:this.safeBottom+12}).enabled(!this.entranceRunning&&!this.exitRunning)
  }

  private openContent():void{this.sheetType=this.face.elements.some(e=>e.kind==='text')&&!this.face.template?'text':'content';this.contentIndex=0;this.sheet=true;}

  @Builder styleControls(){
    Column(){
      if(this.face.template&&this.variants().length>0){Scroll(){Row({space:12}){ForEach(this.variants(),(t:TemplateDefinition)=>{Column({space:8}){Stack(){CardFace({card:this.previews.get(t.id)!,scaleFactor:76/this.previews.get(t.id)!.w,tick:this.tick}).width(76).height(76).hitTestBehavior(HitTestMode.None)}.width(86).height(86).borderRadius(17).border({width:this.face.template?.id===t.id?2:0,color:GREEN}).clip(true);Text(t.name).fontSize(11).fontColor(this.face.template?.id===t.id?GREEN:'#ADB4A2')}.onClick(()=>this.changeDesign(t.id))})}.padding({left:24,right:24})}.scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off).width('100%')}
      else if(this.face.template){Text('一张完整的组合画面').fontSize(14).fontColor('#CAD0C0');Text('在内容中修改各个信息来源').fontSize(12).fontColor('#929B85').margin({top:10})}
      else{Row({space:10}){ForEach(['rect','round','pill'],(shape:string,index:number)=>{this.chip(['圆角','圆形','胶囊'][index],this.face.shape===shape,()=>{this.face.shape=shape;this.publishFace();},true)})};Row(){Text('边框').fontSize(14).fontColor('#C9CFBF');Blank();Toggle({type:ToggleType.Switch,isOn:this.face.frame}).selectedColor(GREEN).onChange((value:boolean)=>{this.face.frame=value;this.publishFace();})}.width('100%').padding({left:32,right:32,top:16})}
    }.width('100%').height('100%').justifyContent(FlexAlign.Center)
  }

  @Builder colorControls(){
    Column({space:16}){
      if(this.photoTemplate()&&!this.currentPhoto()?.src){this.chip('选择照片',true,()=>this.openMaterials('face'),true)}
      else if(this.photoTemplate()&&this.currentPhoto()){
        Scroll(){Row({space:10}){ForEach(['自然','暖光','冷蓝','玫瑰','黑白'],(name:string,index:number)=>{Column({space:8}){Button({type:ButtonType.Circle}){}.width(42).height(42).backgroundColor(['#AFBB8D','#CEB293','#A3B8CE','#C59FAF','#858780'][index]).accessibilityText(name+'色调').border({width:this.toneIndex===index?3:0,color:GREEN}).enabled(!this.busy).onClick(()=>this.tone(index));Text(name).fontSize(11).fontColor('#BAC2AE')}.width(54)})}}.scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off).width('100%').padding({left:24,right:24})
      }else{Row({space:18}){ForEach(this.face.template?['','cream','cobalt','ink']:['white','cream','kraft','mint','blue','pink','dark'],(color:string,index:number)=>{Button({type:ButtonType.Circle}){}.width(this.face.template?46:34).height(this.face.template?46:34).backgroundColor(this.face.template?['#CED6C5','#EDE1C8','#2855BC','#202520'][index]:['#FFFFFF','#F2E6C8','#C3A77F','#B8CCAC','#A6C3D9','#DFB8BD','#202520'][index]).accessibilityText(['默认配色','奶油配色','蓝色配色','深色配色'][index]??color).border({width:(this.face.template?this.face.template.palette:this.face.material)===color?3:0,color:GREEN}).onClick(()=>{if(this.face.template)this.face.template.palette=color;else this.face.material=color;this.publishFace();})})}
        Text(this.face.template?'配色应用到整个模板':'底板色彩').fontSize(12).fontColor('#8E9880')}
    }.width('100%').height('100%').justifyContent(FlexAlign.Center)
  }

  @Builder contentControls(){
    Column({space:14}){
      if(this.face.template?.id==='portrait'&&this.photoPanel==='clock'){this.photoClockControls()}
      else if(this.face.template?.id==='portrait'){
        Row({space:8}){this.chip('照片库',false,()=>this.openMaterials('face'),true);this.chip('原图',this.face.template?.photoMode==='photo',()=>this.setPhotoMode(false),true);if(this.currentPhoto()?.depthForeground){this.chip('主体',this.face.template?.photoMode!=='photo',()=>this.setPhotoMode(true),true)}}
        Row({space:8}){this.chip('时间位置',false,()=>{this.photoPanel='clock';},true);Text('景深').fontSize(13).fontColor('#C1C9B3');Toggle({type:ToggleType.Switch,isOn:!!this.currentPhoto()?.depthForeground&&this.face.template?.depth!==false}).enabled(!!this.currentPhoto()?.depthForeground).selectedColor(GREEN).onChange((value:boolean)=>{this.face.template!.depth=value;this.publishFace();})}
        if(this.currentPhoto()?.src&&!this.currentPhoto()?.depthForeground){this.chip('提取主体',false,()=>this.extractCurrentPhoto(),true)}
      }else{
        if(this.face.capability?.k==='album'){this.chip('封面库',false,()=>this.openMaterials('album'),true)}
        if(this.photoTemplate()||this.currentPhoto()){this.chip('照片库',false,()=>this.openMaterials('face'),true)}
        if(this.face.elements.some(e=>e.kind==='text')&&!this.face.template){this.chip('编辑文字',true,()=>{this.sheetType='text';this.sheet=true;},true)}
        if(cardCapabilities(this.face).some(c=>['countdown','anniversary','worldclock','timetable','agenda','album'].includes(c.k))){this.chip('编辑内容',true,()=>{this.contentIndex=0;this.sheetType='content';this.sheet=true;},true)}
      }
    }.width('100%').height('100%').justifyContent(FlexAlign.Center)
  }
  @Builder photoClockControls(){
    Column({space:10}){
      Row(){Button('返回',{buttonStyle:ButtonStyleMode.NORMAL}).height(32).fontSize(13).fontColor(GREEN).backgroundColor(Color.Transparent).onClick(()=>this.photoPanel='source');Blank();Button('智能选位',{buttonStyle:ButtonStyleMode.NORMAL}).height(32).fontSize(13).fontColor(this.face.template?.clockAuto?GREEN:'#DAE2CF').backgroundColor('#242622').onClick(()=>this.smartClock());Button('复位',{buttonStyle:ButtonStyleMode.NORMAL}).height(32).fontSize(13).fontColor('#DAE2CF').backgroundColor(Color.Transparent).onClick(()=>{this.face.template!.zoom=1;this.face.template!.offsetX=0;this.face.template!.offsetY=0;this.publishFace();})}.width('100%')
      Flex({wrap:FlexWrap.Wrap,justifyContent:FlexAlign.SpaceBetween}){ForEach(PHOTO_CLOCK_POSITIONS,(p:string,index:number)=>{Button(['左上','上方','右上','左下','下方','右下'][index],{buttonStyle:ButtonStyleMode.NORMAL}).width('31%').height(32).fontSize(13).margin({bottom:8}).backgroundColor(this.face.template?.clockPosition===p?GREEN:'#242622').fontColor(this.face.template?.clockPosition===p?INK:'#DAE2CF').borderRadius(16).onClick(()=>{this.face.template!.clockPosition=p;this.face.template!.clockAuto=false;this.publishFace();})})}.width('100%')
      Row({space:12}){Button('浅色文字',{buttonStyle:ButtonStyleMode.NORMAL}).height(32).fontSize(13).backgroundColor(this.face.template?.clockInk!=='#202222'?GREEN:'#242622').fontColor(this.face.template?.clockInk!=='#202222'?INK:'#DAE2CF').onClick(()=>{this.face.template!.clockInk='#FFFFFF';this.face.template!.clockAuto=false;this.publishFace();});Button('深色文字',{buttonStyle:ButtonStyleMode.NORMAL}).height(32).fontSize(13).backgroundColor(this.face.template?.clockInk==='#202222'?GREEN:'#242622').fontColor(this.face.template?.clockInk==='#202222'?INK:'#DAE2CF').onClick(()=>{this.face.template!.clockInk='#202222';this.face.template!.clockAuto=false;this.publishFace();})}
    }.width('100%').padding({left:24,right:24})
  }
  private removeAlbum(cap:CapBlock,index:number,id:string):void{
    let next=selectAlbum(cap,activeAlbum(cap,this.tick));next.albumItems=albumLibrary(cap).filter(a=>a.id!==id);
    if(next.albumId===id){next.albumId='';next.albumCover='';next.albumBackground='';next.title='';next.artist='';if(next.albumItems.length)next=selectAlbum(next,next.albumItems[0]);}
    if((next.albumItems??[]).length<2)next.albumRotationMinutes=0;this.setCap(next,index);
  }
  @Builder albumContent(cap:CapBlock,index:number){
    AlbumSettings({section:'metadata',showPresentation:false,cap:cap,cardId:this.face.id,appDark:true,tick:this.tick,onUpdate:(_id:string,next:CapBlock)=>this.setCap(next,index)})
    Row(){Text('轮换封面 · '+albumLibrary(cap).length+'/12').fontSize(14).fontColor('#DAE2CF').layoutWeight(1);Button('添加封面',{buttonStyle:ButtonStyleMode.NORMAL}).height(40).fontSize(13).fontColor(GREEN).backgroundColor(Color.Transparent).onClick(()=>this.openMaterials('album',index))}.width('100%')
    if(albumLibrary(cap).length){
      Scroll(){Row({space:12}){ForEach(albumLibrary(cap),(album:AlbumCover)=>{Column({space:6}){Button({type:ButtonType.Normal}){Image(album.cover).objectFit(ImageFit.Cover).width(72).height(72).borderRadius(10)}.padding(3).backgroundColor(Color.Transparent).border({width:2,color:activeAlbum(cap,this.tick).id===album.id?GREEN:Color.Transparent}).borderRadius(14).accessibilityText('选择封面 '+(album.title||String(albumLibrary(cap).indexOf(album)+1))).onClick(()=>this.setCap(selectAlbum(cap,album),index));Button('移除',{buttonStyle:ButtonStyleMode.NORMAL}).height(32).fontSize(12).backgroundColor(Color.Transparent).fontColor('#B8C0AE').onClick(()=>this.removeAlbum(cap,index,album.id))}})}.padding({bottom:4})}.width('100%').scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off)
      Text('定时轮换').fontSize(14).fontColor('#DAE2CF').width('100%')
      Row({space:4}){ForEach(['关闭','1小时','3小时','6小时','每天'],(label:string,i:number)=>{Button(label,{buttonStyle:ButtonStyleMode.NORMAL}).height(36).layoutWeight(1).padding(0).fontSize(12).fontColor((cap.albumRotationMinutes??0)===[0,60,180,360,1440][i]?INK:'#DAE2CF').backgroundColor((cap.albumRotationMinutes??0)===[0,60,180,360,1440][i]?GREEN:Color.Transparent).enabled(i===0||albumLibrary(cap).length>1).onClick(()=>{const next=selectAlbum(cap,activeAlbum(cap,this.tick));next.albumRotationMinutes=[0,60,180,360,1440][i];this.setCap(next,index);})})}.width('100%').padding(4).backgroundColor('#242622').borderRadius(24)
    }
  }
  @Builder sheetBody(){
    Column({space:18}){
      Row(){Text(this.sheetType==='materials'?(this.materialAlbum()?'封面库':'照片库'):this.sheetType==='templates'?'添加模板':this.sheetType==='content'?(this.face.capability?.k==='album'?'专辑资料':'修改内容'):this.sheetType==='text'?'编辑文字':this.sheetType==='clock'?'时间与构图':this.sheetType==='layers'?'作品里的贴纸':this.sheetType==='asset'?'素材详情':this.sheetType==='new'?'新建作品':this.sheetType==='arrange'?'排列贴纸':'作品工具').fontSize(22).fontWeight(FontWeight.Medium).fontColor('#F0F2EA').layoutWeight(1);Button({type:ButtonType.Circle,buttonStyle:ButtonStyleMode.NORMAL}){SymbolGlyph($r('sys.symbol.xmark')).fontSize(18).fontColor(['#F2F2EC'])}.width(44).height(44).backgroundColor('#252722').accessibilityText('关闭面板').onClick(()=>this.closeSheet())}.width('100%').padding({left:24,right:24,top:14})
      if(this.sheetType==='materials'){this.materialGrid(true)
      }else if(this.sheetType==='text'){
        Column({space:18}){TextArea({text:this.face.elements.find(e=>e.kind==='text')?.text??'',placeholder:'写点什么…'}).height(140).fontColor('#EFF2E8').backgroundColor('#30362A').fontSize(22).onChange((text:string)=>this.setText(text));Row(){Text('字号').fontColor('#C7D1BA');Slider({value:this.face.elements.find(e=>e.kind==='text')?.fs??24,min:12,max:60,step:1}).layoutWeight(1).selectedColor(GREEN).onChange((value:number)=>{const e=this.face.elements.find(e=>e.kind==='text');if(e){e.fs=value;this.publishFace();}})};Row({space:12}){ForEach(['left','center','right'],(align:string,index:number)=>{this.chip(['左对齐','居中','右对齐'][index],this.face.elements.find(e=>e.kind==='text')?.align===align,()=>{const e=this.face.elements.find(e=>e.kind==='text');if(e){e.align=align;this.publishFace();}},true)})};this.chip('完成',true,()=>this.sheet=false,true)}.width('100%').padding(24)
      }else if(this.sheetType==='content'){
        Scroll(){Column({space:16}){ForEach(cardCapabilities(this.face),(cap:CapBlock,index:number)=>{
          Column({space:12}){if(cardCapabilities(this.face).length>1){Text(capabilityDescriptor(cap.k).name).fontSize(18).fontWeight(FontWeight.Medium).fontColor('#EAF0E0').width('100%')}
            if(['countdown','anniversary'].includes(cap.k)){TextInput({text:cap.title??'',placeholder:'标题'}).fontColor('#F1F4EB').backgroundColor('#30362A').onChange((v:string)=>{const next=JSON.parse(JSON.stringify(cap)) as CapBlock;next.title=v;this.setCap(next,index);});TextInput({text:cap.date??'',placeholder:'日期 YYYY-MM-DD'}).fontColor('#F1F4EB').backgroundColor('#30362A').onChange((v:string)=>{const next=JSON.parse(JSON.stringify(cap)) as CapBlock;next.date=v;this.setCap(next,index);})}
            else if(cap.k==='worldclock'){TimeCapabilitySettings({cap:cap,appDark:true,onUpdate:(next:CapBlock)=>this.setCap(next,index)})}
            else if(cap.k==='album'){this.albumContent(cap,index)}
            else if(['timetable','agenda'].includes(cap.k)){CapabilitySettings({useMaterialLibrary:true,onChooseAlbum:()=>this.openMaterials('album',index),cap:cap,cardId:this.face.id,appDark:true,tick:this.tick,onUpdate:(_id:string,next:CapBlock)=>this.setCap(next,index)})}
            else{Text('跟随系统自动更新').fontSize(13).fontColor('#8D9B7C').width('100%')}
          }.padding({top:8,bottom:16})
        })}.padding({left:24,right:24,bottom:24}).width('100%')}.layoutWeight(1).width('100%').align(Alignment.Top)
      }else if(this.sheetType==='asset'&&this.assets[this.contentIndex]){
        Scroll(){Column({space:16}){Image(this.libraryPurpose==='album'&&this.assets[this.contentIndex].albumCover?this.assets[this.contentIndex].albumCover:this.subjectMaterial?this.assets[this.contentIndex].subject:this.assets[this.contentIndex].original).objectFit(ImageFit.Contain).width('100%').height(Math.min(230,this.viewportH*.28));Text(this.assets[this.contentIndex].name).maxLines(2).textOverflow({overflow:TextOverflow.Ellipsis}).fontSize(18).fontColor('#E5EDDC');if(this.libraryPurpose!=='album'){Row({space:10}){this.chip('原图',!this.subjectMaterial,()=>this.subjectMaterial=false,true);if(this.assets[this.contentIndex].subject){this.chip('抠图',this.subjectMaterial,()=>this.subjectMaterial=true,true)}else{this.chip('提取主体',false,()=>this.extract(),true)}}}if(this.libraryPurpose==='album'){Text('封面会居中裁为正方形').fontSize(13).fontColor('#BAC2AE')}Button('标记为专辑封面',{buttonStyle:ButtonStyleMode.NORMAL}).backgroundColor('#30392A').fontColor('#DCE8D0').onClick(()=>{this.library.categorizeAlbum(this.assets[this.contentIndex]);this.assets=this.library.items.slice();this.toast('已收进专辑分类');});Button(this.libraryPurpose==='album'?'使用这个封面':'使用这个素材').backgroundColor(GREEN).fontColor(INK).enabled(!this.busy).onClick(()=>this.confirmLibraryAsset())}.width('100%').padding(24)}.width('100%').layoutWeight(1).scrollBar(BarState.Off)
      }
    }.width('100%').height('100%').padding({bottom:this.safeBottom+8}).backgroundColor('#1B2017').enabled(!this.busy)
  }
  build(){
    Stack(){
      if(!this.libraryMode){Column().width('100%').height('100%').backgroundColor('#10120F').opacity(this.entranceChrome).hitTestBehavior(HitTestMode.None)}
      if(!this.ready){Column({space:16}){Text(this.error||'正在打开').fontColor('#EEF1E8');Button('返回').onClick(()=>this.onCancel())}.width('100%').height('100%').justifyContent(FlexAlign.Center).backgroundColor('#10120F')}
      else if(this.libraryMode){Column({space:18}){Row(){Text(this.libraryPurpose==='album'?'封面库':'素材库').fontSize(20).fontColor('#EEF1E8').layoutWeight(1);Button('完成',{buttonStyle:ButtonStyleMode.NORMAL}).fontColor(GREEN).backgroundColor(Color.Transparent).enabled(!this.busy).onClick(()=>this.onCancel())}.padding({left:24,right:24});this.materialGrid(true)}.width('100%').height('100%').padding({top:this.safeTop+12,bottom:this.safeBottom}).backgroundColor('#10120F')}
      else{this.editor()}
      if(this.busy){Column(){LoadingProgress().width(28).height(28).color(GREEN);Text('处理中').fontSize(12).fontColor('#EEF5E6')}.padding(18).borderRadius(20).backgroundColor('#DD20271A').hitTestBehavior(HitTestMode.Block)}
      Column().width(1).height(1).bindSheet($$this.sheet,this.sheetBody,{height:'78%',showClose:false,dragBar:true,backgroundColor:'#1B2017',onWillDismiss:()=>this.closeSheet()})
    }.width('100%').height('100%').expandSafeArea([SafeAreaType.SYSTEM],[SafeAreaEdge.TOP,SafeAreaEdge.BOTTOM])
  }
}
