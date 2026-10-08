import { bundleManager, common } from '@kit.AbilityKit';
import { picker, fileIo } from '@kit.CoreFileKit';
import { taskpool } from '@kit.ArkTS';
import { image } from '@kit.ImageKit';
import { FridgeCard, FridgeState, defaultState, BOARD_W, BOARD_H } from '../model/CardSchema';
import { loadPreviewPackage, clearPreviewPackage } from '../model/FridgePreviewWorker';
import { primeRenderContours } from '../model/RenderContours';
import { prepareSubjectDepth } from '../model/SubjectDepthCache';
import { CardFace } from '../views/CardFace';
import { CanvasBackdrop } from '../views/CanvasBackdrop';
import { AppDesign } from '../model/AppDesign';
import { SettingsSegmented } from '../views/SettingsSegmented';
import { immersiveChrome } from '../model/ChromeMaterial';
import { PREVIEW_DESIGN_FINGERPRINT } from '../model/PreviewDesignContract';
/** Harness entry: demo=preview, previewFile=an owned cache .fridge path. No store or Form writes. */
@Entry
@Component
struct FridgePreviewer {
 @StorageLink('appDark') dark:boolean=false;
 @StorageLink('safeTop') safeTop:number=24;
 @StorageLink('safeBottom') safeBottom:number=20;
 @State scene:FridgeState=defaultState();
 @State pageWidth:number=390;
 @State sizeIndex:number=1;
 @State loaded:boolean=false;
 @State busy:boolean=false;
 @State status:string='选择 .fridge 文件，在相同原生渲染器中预览';
 private tick:number=1791429300000;
 private generation:number=0;
 private autoCapture:boolean=false;
 private captureTimer:number=-1;
 private alive:boolean=true;
 private completed:number[]=[];
 private ctx():common.UIAbilityContext {return this.getUIContext().getHostContext() as common.UIAbilityContext;}
 aboutToAppear():void {
  const path=AppStorage.get<string>('previewFile')??'';AppStorage.delete('previewFile');
  this.autoCapture=AppStorage.get<boolean>('previewCapture')===true;AppStorage.delete('previewCapture');
  if(/^qa_[A-Za-z0-9_-]+\.fridge$/.test(path)){this.load('file://'+this.ctx().cacheDir+'/'+path);return;}
  if(path.startsWith(this.ctx().cacheDir+'/')){const name=path.slice(this.ctx().cacheDir.length+1);if(/^qa_[A-Za-z0-9_-]+\.fridge$/.test(name))this.load('file://'+this.ctx().cacheDir+'/'+name);}
 }
 aboutToDisappear():void {this.alive=false;this.generation++;if(this.captureTimer>=0)clearTimeout(this.captureTimer);for(const revision of this.completed)taskpool.execute(new taskpool.Task(clearPreviewPackage,this.ctx().cacheDir,revision));this.completed=[];}
 private boardWidth():number {return Math.min(this.pageWidth-48,[180,300,420][this.sizeIndex]);}
 private boardScale():number {return this.boardWidth()/BOARD_W;}
 private boardHeight():number {return this.boardWidth()/this.scene.canvasAspect;}
 private async choose():Promise<void> {
  try {const options=new picker.DocumentSelectOptions();options.maxSelectNumber=1;
   const uris=await new picker.DocumentViewPicker(this.ctx()).select(options);if(uris.length)this.load(uris[0]);
  }catch(e){this.status=(e as Error).message;}
 }
 private async load(uri:string):Promise<void> {
  if(this.busy)return;this.busy=true;this.loaded=false;if(this.captureTimer>=0){clearTimeout(this.captureTimer);this.captureTimer=-1;}const token=++this.generation,revision=Date.now();
  try {
   const json=await taskpool.execute(new taskpool.Task(loadPreviewPackage,uri,this.ctx().cacheDir,revision)) as string;
   if(!this.alive||token!==this.generation){taskpool.execute(new taskpool.Task(clearPreviewPackage,this.ctx().cacheDir,revision));return;}
   this.completed.push(revision);
   const scene=JSON.parse(json) as FridgeState;scene.cards.sort((a,b)=>a.z-b.z);
   await primeRenderContours(scene.cards,json);
   await prepareSubjectDepth(scene.cards,this.boardScale(),this.ctx().cacheDir,this.getUIContext().vp2px(1));
   if(!this.alive||token!==this.generation)return;
   this.scene=scene;this.loaded=true;this.status='已读取 '+scene.cards.length+' 张卡 · schema '+scene.schemaVersion+' · 原生渲染';
   if(this.autoCapture)this.captureTimer=setTimeout(()=>{this.captureTimer=-1;if(this.alive)this.capture();},1500);
  }catch(e){if(this.alive&&token===this.generation)this.status='无法预览：'+(e as Error).message;}
  finally {if(this.alive&&token===this.generation)this.busy=false;}
 }
 private async capture():Promise<void> {
  if(!this.loaded||this.busy)return;this.busy=true;
  let pixel:image.PixelMap|null=null,file:fileIo.File|null=null;const packer=image.createImagePacker();
  try {
   pixel=await this.getUIContext().getComponentSnapshot().get('fridgePreviewArtwork',{scale:1,waitUntilRenderFinished:true});
   const base=this.ctx().cacheDir+'/fridge_preview_capture';
   file=fileIo.openSync(base+'.png',fileIo.OpenMode.CREATE|fileIo.OpenMode.READ_WRITE|fileIo.OpenMode.TRUNC);
   await packer.packToFile(pixel,file.fd,{format:'image/png',quality:100});
   const app=await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT);
   const report=JSON.stringify({previewVersion:1,sourceFingerprint:PREVIEW_DESIGN_FINGERPRINT,appVersion:app.versionName,appVersionCode:app.versionCode,renderer:'CardFace/CanvasBackdrop',packageVersion:1,schemaVersion:this.scene.schemaVersion,canvasAspect:this.scene.canvasAspect,widthVp:this.boardWidth(),heightVp:this.boardHeight(),tick:this.tick,cards:this.scene.cards.length,host:'app',clockMode:'system-live',actualFormVerified:false},null,2);
   const out=fileIo.openSync(base+'.json',fileIo.OpenMode.CREATE|fileIo.OpenMode.READ_WRITE|fileIo.OpenMode.TRUNC);
   try{fileIo.writeSync(out.fd,report);}finally{fileIo.closeSync(out.fd);}
   this.status='已导出 PNG 和验收元数据到缓存目录';
  }catch(e){this.status='导出失败：'+(e as Error).message;}
  finally{if(file)fileIo.closeSync(file.fd);if(pixel)await pixel.release();await packer.release();this.busy=false;}
 }
 @Builder artwork() {
  Stack({alignContent:Alignment.TopStart}) {
   CanvasBackdrop({sceneBackground:this.scene.background})
   ForEach(this.scene.cards,(c:FridgeCard)=>{
    CardFace({card:c,scaleFactor:this.boardScale(),tick:this.tick})
     .width(c.w*this.boardScale()).height(c.h*this.boardScale())
     .rotate({angle:c.rot}).position({x:c.x*this.boardScale(),y:c.y*this.boardHeight()/BOARD_H})
   },(c:FridgeCard)=>c.id)
  }.width(this.boardWidth()).height(this.boardHeight()).borderRadius(20).clip(true).id('fridgePreviewArtwork')
 }
 build() {
  Column({space:16}) {
   Row({space:12}) {
    Text('.fridge 预览器').fontSize(22).fontWeight(FontWeight.Medium).fontColor(AppDesign.text(this.dark)).layoutWeight(1)
    Button('打开文件',{type:ButtonType.Capsule,buttonStyle:ButtonStyleMode.NORMAL}).fontColor(AppDesign.text(this.dark)).attributeModifier(immersiveChrome(this.dark)).enabled(!this.busy).onClick(()=>this.choose())
   }.width('100%')
   SettingsSegmented({labels:['紧凑','标准','放大'],selectedIndex:this.sizeIndex,appDark:this.dark,onSelect:(i:number)=>this.sizeIndex=i})
   Scroll() {Column({space:16}) {if(this.loaded){this.artwork()}Text(this.status).fontSize(13).fontColor(AppDesign.muted(this.dark)).width('100%')}}.width('100%').layoutWeight(1).scrollBar(BarState.Off)
   Button('导出验收图',{type:ButtonType.Capsule,buttonStyle:ButtonStyleMode.EMPHASIZED}).enabled(this.loaded&&!this.busy).onClick(()=>this.capture())
   Text('只读预览，不写入画布；此页不能代替真实桌面 Form 验收。').fontSize(12).fontColor(AppDesign.muted(this.dark))
  }.width('100%').height('100%').padding({left:16,right:16,top:this.safeTop+12,bottom:this.safeBottom+12}).backgroundColor(AppDesign.background(this.dark)).onAreaChange((_o:Area,a:Area)=>this.pageWidth=Number(a.width))
 }
}
