import { CapBlock } from '../model/CardSchema';
import { AlbumResult } from '../model/AlbumCatalog';
import { searchAlbums, saveAlbum } from '../model/AlbumWorker';
import { taskpool } from '@kit.ArkTS';
import { AppDesign } from '../model/AppDesign';
import { SettingsAction } from './SettingsAction';
@Component
export struct AlbumSettings {
  @Prop cap:CapBlock={k:'album'};
  @Prop @Watch('cardChanged') cardId:string='';
  @Prop appDark:boolean=false;
  onUpdate:(id:string,cap:CapBlock)=>void=()=>{};
  @State query:string='';
  @State results:AlbumResult[]=[];
  @State busy:boolean=false;
  @State message:string='';
  private alive:boolean=true;
  private generation:number=0;
  private lastSearch:number=0;
  private cardChanged():void {this.generation++;this.busy=false;this.message='';this.results=[];this.query='';}
  aboutToDisappear():void {this.alive=false;this.generation++;}
  aboutToAppear():void {this.alive=true;}
  private async search():Promise<void> {
    if(this.busy||!this.query.trim())return;
    if(Date.now()-this.lastSearch<1100)return;this.lastSearch=Date.now();
    const token=++this.generation;this.busy=true;this.message='';this.results=[];
    try{const found=JSON.parse(await taskpool.execute(new taskpool.Task(searchAlbums,this.query)) as string) as AlbumResult[];if(!this.alive||token!==this.generation)return;this.results=found;if(found.length===0)this.message='没有找到专辑，试试专辑原名或歌手名';}
    catch(e){if(this.alive&&token===this.generation)this.message=(e as Error).message;}
    finally{if(token===this.generation)this.busy=false;}
  }
  private async choose(album:AlbumResult):Promise<void> {
    const context=this.getUIContext().getHostContext();if(!context||this.busy)return;
    const token=++this.generation,id=this.cardId;this.busy=true;this.message='正在保存封面与背景';
    try{const next=JSON.parse(await taskpool.execute(new taskpool.Task(saveAlbum,JSON.stringify(album),context.filesDir)) as string) as CapBlock;
      if(this.alive&&token===this.generation&&id===this.cardId){this.onUpdate(id,next);this.results=[];this.message='';}
    }catch(e){if(this.alive&&token===this.generation)this.message=(e as Error).message;}
    finally{if(token===this.generation)this.busy=false;}
  }
  build() {
    Column({space:12}) {
      if(this.cap.albumCover) {
        Row({space:12}) {
          Image(this.cap.albumCover).width(52).height(52).borderRadius(6).objectFit(ImageFit.Contain).draggable(false)
          Column({space:4}) {Text(this.cap.title??'').fontSize(15).fontWeight(FontWeight.Medium).fontColor(AppDesign.text(this.appDark)).maxLines(2);Text(this.cap.artist??'').fontSize(12).fontColor(AppDesign.muted(this.appDark)).maxLines(1)}.layoutWeight(1).alignItems(HorizontalAlign.Start)
        }.width('100%')
      }
      TextInput({text:this.query,placeholder:'搜索专辑名或歌手'}).height(44).fontColor(AppDesign.text(this.appDark)).placeholderColor(AppDesign.muted(this.appDark)).backgroundColor(AppDesign.control(this.appDark)).borderRadius(14).enterKeyType(EnterKeyType.Search).enabled(!this.busy)
        .onChange((v:string)=>this.query=v).onSubmit(()=>this.search())
      SettingsAction({label:this.busy?'处理中':'搜索专辑',appDark:this.appDark,fillWidth:true,isEnabled:!this.busy&&this.query.trim().length>0,onPress:()=>this.search()})
      ForEach(this.results,(album:AlbumResult)=>{
        Button({type:ButtonType.ROUNDED_RECTANGLE,buttonStyle:ButtonStyleMode.NORMAL,role:ButtonRole.NORMAL}) {
          Column({space:4}) {Text(album.title).fontSize(15).fontColor(AppDesign.text(this.appDark)).maxLines(2).width('100%');Text(album.artist+(album.year?' · '+album.year:'')).fontSize(12).fontColor(AppDesign.muted(this.appDark)).maxLines(2).width('100%')}.padding(14).alignItems(HorizontalAlign.Start)
        }.width('100%').backgroundColor(AppDesign.control(this.appDark)).enabled(!this.busy).onClick(()=>this.choose(album))
      },(album:AlbumResult)=>album.id)
      if(this.message) {Text(this.message).fontSize(12).fontColor(AppDesign.muted(this.appDark)).width('100%')}
      Text('MusicBrainz · Cover Art Archive\n封面居中，背景由封面自动生成。保存后离线显示。').fontSize(12).fontColor(AppDesign.muted(this.appDark)).width('100%')
    }.width('100%')
  }
}
