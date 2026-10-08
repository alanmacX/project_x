import { fileIo } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { activeAlbum, albumLibrary, selectAlbum } from '../model/AlbumRotation';
import { SettingsSegmented } from './SettingsSegmented';
import { AlbumCover, CapBlock } from '../model/CardSchema';
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
  @Prop tick:number=0;
  @Prop section:string='all';
  @Prop showPresentation:boolean=true;
  onUpdate:(id:string,cap:CapBlock)=>void=()=>{};
  @State busy:boolean=false;
  @State message:string='';
  @State sources:boolean=false;
  @State libraryWidth:number=300;
  private alive:boolean=true;
  private generation:number=0;
  private cardChanged():void {this.generation++;this.busy=false;this.message='';this.sources=false;}
  aboutToDisappear():void {this.alive=false;this.generation++;}
  aboutToAppear():void {this.alive=true;}
  private async choose():Promise<void> {
    const context=this.getUIContext().getHostContext();if(!context||this.busy)return;
    const token=++this.generation,id=this.cardId,next=JSON.parse(JSON.stringify(this.cap)) as CapBlock;this.busy=true;this.message='';
    try {
      const options=new photoAccessHelper.PhotoSelectOptions();options.maxSelectNumber=Math.max(1,12-albumLibrary(next).length);options.MIMEType=photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
      const selection=await new photoAccessHelper.PhotoViewPicker().select(options);
      if(!selection.photoUris.length||!this.alive||token!==this.generation)return;
      this.message='正在生成融合背景';
      let saved=next;const items=albumLibrary(next);
      for(const uri of selection.photoUris) {
        if(!this.alive||token!==this.generation)return;
        const imported=JSON.parse(await taskpool.execute(new taskpool.Task(importAlbumCover,uri,JSON.stringify({k:'album'}),context.filesDir)) as string) as CapBlock;
        if(!this.alive||token!==this.generation){for(const src of [imported.albumCover??'',imported.albumBackground??''])if(src.startsWith('file://'))await fileIo.unlink(src.slice(7)).catch(()=>{});return;}
        items.push({id:(imported.albumCover??'').split('/').pop()??'',cover:imported.albumCover??'',background:imported.albumBackground??'',title:'',artist:''});
        saved.albumItems=items;saved=selectAlbum(saved,items[items.length-1]);this.onUpdate(id,saved);
      }
      if(this.alive&&token===this.generation&&id===this.cardId){this.message='';}
    }catch(e){if(this.alive&&token===this.generation)this.message=(e as Error).message;}
    finally{if(token===this.generation)this.busy=false;}
  }
  private text(value:string,artist:boolean):void {
    const next=JSON.parse(JSON.stringify(this.cap)) as CapBlock;
    const album=activeAlbum(next);next.albumItems=albumLibrary(next).map((a:AlbumCover):AlbumCover=>a.id===album.id?{id:a.id,cover:a.cover,background:a.background,title:artist?a.title:value.slice(0,160),artist:artist?value.slice(0,160):a.artist}:a);
    if(artist)next.artist=value.slice(0,160);else next.title=value.slice(0,160);this.onUpdate(this.cardId,next);
  }
  private setPresentation(index:number):void {const next=JSON.parse(JSON.stringify(this.cap)) as CapBlock;next.albumPresentation=['cover','classic','row'][index];this.onUpdate(this.cardId,next);}
  private currentAlbum():AlbumCover {return activeAlbum(this.cap,this.tick||Date.now());}
  private setRotation(index:number):void {
    const next=selectAlbum(this.cap,this.currentAlbum());next.albumRotationMinutes=[0,60,180,360,1440][index];this.onUpdate(this.cardId,next);
  }
  private remove(album:AlbumCover):void {
    let next=selectAlbum(this.cap,this.currentAlbum());next.albumItems=albumLibrary(next).filter(a=>a.id!==album.id);
    if(next.albumId===album.id) {const first=next.albumItems[0];next.albumId='';next.albumCover='';next.albumBackground='';next.title='';next.artist='';if(first)next=selectAlbum(next,first);}
    if((next.albumItems??[]).length<2)next.albumRotationMinutes=0;
    this.onUpdate(this.cardId,next);
  }
  private async source(url:string):Promise<void> {
    try {await (this.getUIContext().getHostContext() as common.UIAbilityContext).openLink(url,{appLinkingOnly:false});}
    catch(_){this.message='未能打开浏览器，请稍后重试';}
  }
  build() {
    Column({space:12}) {
      if(this.showPresentation) {SettingsSegmented({labels:['纯封面','经典信息','横向信息'],selectedIndex:Math.max(0,['cover','classic','row'].indexOf(this.cap.albumPresentation??'cover')),appDark:this.appDark,onSelect:(i:number)=>this.setPresentation(i)})}
      if(this.section==='all'||this.section==='library') {
      if(this.cap.albumCover) {Image(this.cap.albumCover).width(64).height(64).borderRadius(6).objectFit(ImageFit.Contain).draggable(false)}
      SettingsAction({label:this.busy?'处理中':this.cap.albumCover?'添加到封面库':'选择本地封面',appDark:this.appDark,fillWidth:true,isEnabled:!this.busy&&albumLibrary(this.cap).length<12,onPress:()=>this.choose()})
      }
      if(this.section==='all'||this.section==='metadata') {
      TextInput({text:this.currentAlbum().title,placeholder:'专辑名（可选）'}).height(44).maxLength(160).fontColor(AppDesign.text(this.appDark)).placeholderColor(AppDesign.muted(this.appDark)).backgroundColor(AppDesign.control(this.appDark)).borderRadius(14).enabled(!this.busy).onChange((v:string)=>this.text(v,false))
      TextInput({text:this.currentAlbum().artist,placeholder:'歌手（可选）'}).height(44).maxLength(160).fontColor(AppDesign.text(this.appDark)).placeholderColor(AppDesign.muted(this.appDark)).backgroundColor(AppDesign.control(this.appDark)).borderRadius(14).enabled(!this.busy).onChange((v:string)=>this.text(v,true))
      }
      if(this.section==='all'||this.section==='library') {
      if(albumLibrary(this.cap).length) {
        Text('封面库 · '+albumLibrary(this.cap).length+'/12').fontSize(14).fontColor(AppDesign.text(this.appDark)).width('100%')
        Grid() {
          ForEach(albumLibrary(this.cap),(album:AlbumCover)=>{
            GridItem() {
              Column({space:6}) {
                Button({type:ButtonType.Normal}) {Image(album.cover).width('100%').aspectRatio(1).objectFit(ImageFit.Contain).borderRadius(4).draggable(false)}
                  .width('100%').padding(4).borderRadius(12).backgroundColor(album.id===this.currentAlbum().id?AppDesign.selected(this.appDark):AppDesign.control(this.appDark))
                  .onClick(()=>this.onUpdate(this.cardId,selectAlbum(this.cap,album)))
                Text(album.title||'添加专辑资料').fontSize(11).fontColor(AppDesign.text(this.appDark)).maxLines(1).textOverflow({overflow:TextOverflow.Ellipsis})
                Button('移除',{type:ButtonType.Capsule}).fontSize(11).fontColor(AppDesign.muted(this.appDark)).backgroundColor(AppDesign.control(this.appDark)).height(28).onClick(()=>this.remove(album))
              }.width('100%').enabled(!this.busy)
            }
          },(album:AlbumCover)=>album.id)
        }.columnsTemplate('1fr 1fr 1fr').columnsGap(10).rowsGap(12).width('100%').height(Math.ceil(albumLibrary(this.cap).length/3)*(Math.max(60,(this.libraryWidth-20)/3)+70)).onAreaChange((_,area:Area)=>{const width=Number(area.width);if(width>0&&Math.abs(width-this.libraryWidth)>1)this.libraryWidth=width;})
      }
      if(albumLibrary(this.cap).length>1) {SettingsAction({label:'下一张 · 预览切换',appDark:this.appDark,fillWidth:true,onPress:()=>{const items=albumLibrary(this.cap),index=items.findIndex(a=>a.id===this.currentAlbum().id);this.onUpdate(this.cardId,selectAlbum(this.cap,items[(index+1)%items.length]));}})}
      }
      if(this.section==='all'||this.section==='rotation') {
      Text('定时轮换').fontSize(14).fontColor(AppDesign.text(this.appDark)).width('100%')
      SettingsSegmented({labels:['关闭','1小时','3小时','6小时','每天'],selectedIndex:Math.max(0,[0,60,180,360,1440].indexOf(this.cap.albumRotationMinutes??0)),appDark:this.appDark,onSelect:(i:number)=>{if(i>0&&albumLibrary(this.cap).length<2){this.message='请先添加至少两张封面';return;}this.message='';this.setRotation(i);}})
      Text('按库内顺序轮换；桌面更新由系统调度，可能稍有延迟。').fontSize(12).fontColor(AppDesign.muted(this.appDark)).width('100%')
      }
      if(this.section==='all'||this.section==='library') {
      Text('仅支持正方形封面（1:1）；背景在本机自动生成，无需联网。').fontSize(12).fontColor(AppDesign.muted(this.appDark)).width('100%')
      SettingsAction({label:this.sources?'收起封面来源建议':'封面来源建议',appDark:this.appDark,fillWidth:true,onPress:()=>this.sources=!this.sources})
      if(this.sources) {
        SettingsAction({label:'iSearch · 中文封面搜索 ↗',appDark:this.appDark,fillWidth:true,onPress:()=>this.source('https://i.oppsu.cn/')})
        SettingsAction({label:'CoverBox · 备用搜索 ↗',appDark:this.appDark,fillWidth:true,onPress:()=>this.source('https://coverbox.henry-hu.com/')})
        Text('在浏览器搜索专辑或歌手，保存封面到相册后导入。外部网站需要联网，封面库和轮换在本机运行。').fontSize(12).fontColor(AppDesign.muted(this.appDark)).width('100%')
      }
      }
      if(this.message) {Text(this.message).fontSize(12).fontColor(AppDesign.muted(this.appDark)).width('100%')}
    }.width('100%').enabled(!this.busy)
  }
}
