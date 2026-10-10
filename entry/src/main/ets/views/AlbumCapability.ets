import { AlbumCover, CapBlock } from '../model/CardSchema';
import { albumCoverSize, albumCoverRadius, albumInfoGeometry } from '../model/AlbumLayout';
import { activeAlbum } from '../model/AlbumRotation';
@Component
export struct AlbumCapability {
  @Prop @Watch('refresh') cap:CapBlock={k:'album'};
  @Prop @Watch('refresh') tick:number=0;
  @Prop widget:boolean=false;
  @Prop presentation:string=''; // Optional read-only study override; production uses the saved layout.
  @Prop cardWidth:number=180;
  @Prop cardHeight:number=180;
  @Prop scaleFactor:number=1;
  @State current:AlbumCover={id:'',cover:'',background:'',title:'',artist:''};
  @State previous:AlbumCover={id:'',cover:'',background:'',title:'',artist:''};
  @State opacityValue:number=1;
  private generation:number=0;
  private coverReady:boolean=false;
  private backgroundReady:boolean=false;
  aboutToAppear():void {this.current=activeAlbum(this.cap,this.tick||Date.now());}
  aboutToDisappear():void {this.generation++;}
  private refresh():void {
    const next=activeAlbum(this.cap,this.tick||Date.now());
    if(next.cover===this.current.cover&&next.background===this.current.background){if(next.title!==this.current.title||next.artist!==this.current.artist)this.current=next;return;}
    if(!next.cover){this.generation++;this.current=next;this.previous=next;this.opacityValue=1;return;}
    this.generation++;this.coverReady=false;this.backgroundReady=!next.background;
    if(this.opacityValue>0||!this.previous.cover)this.previous=this.current;this.opacityValue=this.previous.cover?0:1;this.current=next;
  }
  private ready(cover:string,background:boolean):void {
    if(cover!==this.current.cover)return;
    if(background)this.backgroundReady=true;else this.coverReady=true;
    if(!this.coverReady||!this.backgroundReady)return;
    if(this.widget||!this.previous.cover){this.opacityValue=1;this.previous={id:'',cover:'',background:'',title:'',artist:''};return;}
    const generation=this.generation;
    this.getUIContext().animateTo({duration:420,curve:Curve.EaseInOut,onFinish:()=>{if(generation===this.generation)this.previous={id:'',cover:'',background:'',title:'',artist:''};}},()=>this.opacityValue=1);
  }
  private style():string {return this.presentation||this.cap.albumPresentation||'cover';}
  @Builder private artwork(album:AlbumCover,incoming:boolean) {
    Stack() {
      if(album.background) {Image(album.background).width('100%').height('100%').objectFit(ImageFit.Fill).draggable(false).onComplete(()=>{if(incoming)this.ready(album.cover,true)}).onError(()=>{if(incoming)this.ready(album.cover,true)})}
      if(album.cover && this.style()==='cover') {
        Image(album.cover).width(albumCoverSize(this.cardWidth,this.cardHeight)*this.scaleFactor).height(albumCoverSize(this.cardWidth,this.cardHeight)*this.scaleFactor)
          .objectFit(ImageFit.Contain).borderRadius(albumCoverRadius(this.cardWidth,this.cardHeight)*this.scaleFactor).draggable(false)
          .shadow({radius:12*this.scaleFactor,color:'#35000000',offsetY:5*this.scaleFactor})
          .accessibilityText((album.title||'专辑')+' · '+album.artist)
          .onComplete(()=>{if(incoming)this.ready(album.cover,false)}).onError(()=>{if(incoming)this.ready(album.cover,false)})
      }
      if(album.cover && this.style()!=='cover') {
        Column().width('100%').height('100%').backgroundColor('#38000000')
        Image(album.cover)
          .width(albumInfoGeometry(this.cardWidth,this.cardHeight,this.style()).coverSize*this.scaleFactor)
          .height(albumInfoGeometry(this.cardWidth,this.cardHeight,this.style()).coverSize*this.scaleFactor)
          .position({x:albumInfoGeometry(this.cardWidth,this.cardHeight,this.style()).coverX*this.scaleFactor,y:albumInfoGeometry(this.cardWidth,this.cardHeight,this.style()).coverY*this.scaleFactor})
          .borderRadius(14*this.scaleFactor).objectFit(ImageFit.Contain).draggable(false)
          .shadow({radius:10*this.scaleFactor,color:'#28000000',offsetY:4*this.scaleFactor})
          .onComplete(()=>{if(incoming)this.ready(album.cover,false)}).onError(()=>{if(incoming)this.ready(album.cover,false)})
        Column({space:albumInfoGeometry(this.cardWidth,this.cardHeight,this.style()).artistGap*this.scaleFactor}) {
          if(album.title){Text(album.title).fontSize(albumInfoGeometry(this.cardWidth,this.cardHeight,this.style()).titleSize*this.scaleFactor).fontWeight(FontWeight.Medium).lineHeight(albumInfoGeometry(this.cardWidth,this.cardHeight,this.style()).titleSize*1.15*this.scaleFactor).minFontScale(1).maxFontScale(1).fontColor('#FFFFFF').maxLines(2).textOverflow({overflow:TextOverflow.Ellipsis}).width('100%')}
          if(album.artist) {Text(album.artist).fontSize(albumInfoGeometry(this.cardWidth,this.cardHeight,this.style()).artistSize*this.scaleFactor).lineHeight(albumInfoGeometry(this.cardWidth,this.cardHeight,this.style()).artistSize*1.15*this.scaleFactor).minFontScale(1).maxFontScale(1).fontColor('#DDFFFFFF').maxLines(albumInfoGeometry(this.cardWidth,this.cardHeight,this.style()).artistLines).textOverflow({overflow:TextOverflow.Ellipsis}).width('100%')}
        }.alignItems(HorizontalAlign.Start)
          .width(albumInfoGeometry(this.cardWidth,this.cardHeight,this.style()).textWidth*this.scaleFactor)
          .position({x:albumInfoGeometry(this.cardWidth,this.cardHeight,this.style()).textX*this.scaleFactor,y:albumInfoGeometry(this.cardWidth,this.cardHeight,this.style()).textY*this.scaleFactor})
          .translate({y:this.style()==='row'?'-50%':0})
      }
    }.width('100%').height('100%')
  }
  build() {
    Stack() {
      Column().width('100%').height('100%').backgroundColor('#D9D4CD')
      if(this.previous.cover) {this.artwork(this.previous,false)}
      if(this.current.cover) {Column(){this.artwork(this.current,true)}.width('100%').height('100%').opacity(this.opacityValue)}
      else {Text('选择专辑').fontSize(Math.min(14,this.cardWidth/4.5,this.cardHeight/1.5)*this.scaleFactor).maxLines(1).minFontScale(1).maxFontScale(1).fontColor('#494640')}
    }.width('100%').height('100%').hitTestBehavior(HitTestMode.None)
  }
}
