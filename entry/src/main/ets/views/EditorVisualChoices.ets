import { FridgeCard } from '../model/CardSchema';
import { EditorVisualChoice, editorVisualChoices } from '../model/EditorVisualChoices';
import { AppDesign } from '../model/AppDesign';
import { CardFace } from './CardFace';
/** Actual native artwork, frozen time and cached render groups; no network or screenshot worker. */
@Component
export struct EditorVisualChoices {
  @Prop card:FridgeCard=new FridgeCard();
  @Prop mode:string='reading';
  @Prop selected:string='';
  @Prop appDark:boolean=false;
  @State choices:EditorVisualChoice[]=[];
  private previewTick:number=Date.now();
  onChoose:(key:string)=>void=()=>{};
  aboutToAppear():void {this.choices=editorVisualChoices(this.card,this.mode);}
  build() {
    Scroll() {
      Row({space:10}) {
        ForEach(this.choices,(choice:EditorVisualChoice)=>{
          Button({type:ButtonType.ROUNDED_RECTANGLE,buttonStyle:ButtonStyleMode.NORMAL}) {
            Column({space:6}) {
              Stack() {CardFace({card:choice.card,scaleFactor:choice.scale,tick:this.previewTick,hideContent:this.mode==='shape'})
                .width(choice.card.w*choice.scale).height(choice.card.h*choice.scale).translate({x:choice.offsetX,y:choice.offsetY})}
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
