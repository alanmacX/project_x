import { FridgeCard } from '../model/CardSchema';
import { EditorVisualChoice, editorVisualChoices } from '../model/EditorVisualChoices';
import { AppDesign } from '../model/AppDesign';
import { CardFace } from './CardFace';
/** Actual native artwork, frozen time and cached render groups; no network or screenshot worker. */
@Component
export struct EditorVisualChoices {
  @Prop @Watch('sourceChanged') card:FridgeCard=new FridgeCard();
  @Prop @Watch('sourceChanged') mode:string='reading';
  @Prop selected:string='';
  @Prop appDark:boolean=false;
  @State choices:EditorVisualChoice[]=[];
  private previewTick:number=Date.now();
  onChoose:(key:string)=>void=()=>{};
  private sourceSignature:string='';
  aboutToAppear():void {this.sourceChanged();}
  private sourceChanged():void {
    const cap=this.card.capability;
    const signature=[this.mode,this.card.id,cap?.k,this.card.w,this.card.h,this.card.cutout,this.card.subjectVersion,this.card.subjectPhoto,this.card.material,this.card.paper,this.card.ink,cap?.readingMaterial,cap?.readingTint,cap?.readingBlend,cap?.readingEdge,cap?.readingOutside,cap?.readingHook,cap?.albumCover,cap?.title,cap?.artist,cap?.courses?.length].join(':');
    if(signature===this.sourceSignature)return;
    this.sourceSignature=signature;this.choices=editorVisualChoices(this.card,this.mode);
  }
  build() {
    Scroll() {
      Row({space:10}) {
        ForEach(this.choices,(choice:EditorVisualChoice)=>{
          Button({type:ButtonType.ROUNDED_RECTANGLE,buttonStyle:ButtonStyleMode.NORMAL}) {
            Column({space:6}) {
              Stack({alignContent:Alignment.TopStart}) {Column() {CardFace({card:choice.card,scaleFactor:choice.scale,tick:this.previewTick,hideContent:this.mode==='shape'})
                }.width(choice.card.w*choice.scale).height(choice.card.h*choice.scale).position({x:(92-choice.card.w*choice.scale)/2+choice.offsetX,y:(104-choice.card.h*choice.scale)/2+choice.offsetY})}
                .width(92).height(104).renderGroup(true).hitTestBehavior(HitTestMode.None)
              Text(choice.label).fontSize(12).fontWeight(choice.key===this.selected?FontWeight.Medium:FontWeight.Normal).fontColor(AppDesign.text(this.appDark)).maxLines(1).textOverflow({overflow:TextOverflow.Ellipsis}).width(96).textAlign(TextAlign.Center)
            }.padding({top:6,bottom:10}).hitTestBehavior(HitTestMode.None)
          }.id('visualChoice_'+choice.key).width(104).height(140).padding(0).borderRadius(18)
            .backgroundColor(choice.key===this.selected?AppDesign.control(this.appDark):AppDesign.surface(this.appDark))
            .border({width:choice.key===this.selected?2:0,color:this.appDark?'#E6D3A2':'#B29A64'})
            .accessibilityText(choice.label+(choice.key===this.selected?'，已选择':''))
            .onClick(()=>this.onChoose(choice.key))
        },(choice:EditorVisualChoice)=>choice.key)
      }.padding(3)
    }.width('100%').height(146).scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off).align(Alignment.Start)
  }
}
