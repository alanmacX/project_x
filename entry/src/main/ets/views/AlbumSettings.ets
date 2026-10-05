import { CapBlock } from '../model/CardSchema';
import { importAlbumCover } from '../model/AlbumWorker';
import { taskpool } from '@kit.ArkTS';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { AppDesign } from '../model/AppDesign';
import { SettingsAction } from './SettingsAction';
@Component
export struct AlbumSettings {
  @Prop cap:CapBlock={k:'album'};
  @Prop @Watch('cardChanged') cardId:string='';
  @Prop appDark:boolean=false;
  onUpdate:(id:string,cap:CapBlock)=>void=()=>{};
  @State busy:boolean=false;
  @State message:string='';
  @State sources:boolean=false;
  private alive:boolean=true;
  private generation:number=0;
  private cardChanged():void {this.generation++;this.busy=false;this.message='';this.sources=false;}
  aboutToDisappear():void {this.alive=false;this.generation++;}
  aboutToAppear():void {this.alive=true;}
  private async choose():Promise<void> {
    const context=this.getUIContext().getHostContext();if(!context||this.busy)return;
    const token=++this.generation,id=this.cardId,next=JSON.parse(JSON.stringify(this.cap)) as CapBlock;this.busy=true;this.message='';
    try {
      const options=new photoAccessHelper.PhotoSelectOptions();options.maxSelectNumber=1;options.MIMEType=photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
      const selection=await new photoAccessHelper.PhotoViewPicker().select(options);
      if(!selection.photoUris.length||!this.alive||token!==this.generation)return;
      this.message='正在生成融合背景';
      const saved=JSON.parse(await taskpool.execute(new taskpool.Task(importAlbumCover,selection.photoUris[0],JSON.stringify(next),context.filesDir)) as string) as CapBlock;
      if(this.alive&&token===this.generation&&id===this.cardId){this.onUpdate(id,saved);this.message='';}
    }catch(e){if(this.alive&&token===this.generation)this.message=(e as Error).message;}
    finally{if(token===this.generation)this.busy=false;}
  }
  private text(value:string,artist:boolean):void {
    const next=JSON.parse(JSON.stringify(this.cap)) as CapBlock;
    if(artist)next.artist=value.slice(0,160);else next.title=value.slice(0,160);this.onUpdate(this.cardId,next);
  }
  build() {
    Column({space:12}) {
      if(this.cap.albumCover) {Image(this.cap.albumCover).width(64).height(64).borderRadius(6).objectFit(ImageFit.Contain).draggable(false)}
      SettingsAction({label:this.busy?'处理中':this.cap.albumCover?'更换本地封面':'选择本地封面',appDark:this.appDark,fillWidth:true,isEnabled:!this.busy,onPress:()=>this.choose()})
      TextInput({text:this.cap.title??'',placeholder:'专辑名（可选）'}).height(44).maxLength(160).fontColor(AppDesign.text(this.appDark)).placeholderColor(AppDesign.muted(this.appDark)).backgroundColor(AppDesign.control(this.appDark)).borderRadius(14).enabled(!this.busy).onChange((v:string)=>this.text(v,false))
      TextInput({text:this.cap.artist??'',placeholder:'歌手（可选）'}).height(44).maxLength(160).fontColor(AppDesign.text(this.appDark)).placeholderColor(AppDesign.muted(this.appDark)).backgroundColor(AppDesign.control(this.appDark)).borderRadius(14).enabled(!this.busy).onChange((v:string)=>this.text(v,true))
      Text('封面居中，背景在本机自动生成，无需联网。').fontSize(12).fontColor(AppDesign.muted(this.appDark)).width('100%')
      SettingsAction({label:this.sources?'收起封面来源建议':'封面来源建议',appDark:this.appDark,fillWidth:true,onPress:()=>this.sources=!this.sources})
      if(this.sources) {
        Text('MusicBrainz / Cover Art Archive：musicbrainz.org\nDiscogs：discogs.com\n也可使用艺术家或唱片公司官网的封面。\n\n自行在浏览器保存图片，再从相册导入。这里仅提供名称，可长按复制；App 不访问这些网站。').fontSize(12).fontColor(AppDesign.muted(this.appDark)).width('100%').copyOption(CopyOptions.LocalDevice)
      }
      if(this.message) {Text(this.message).fontSize(12).fontColor(AppDesign.muted(this.appDark)).width('100%')}
    }.width('100%')
  }
}
