import { SegmentButton, SegmentButtonOptions, ItemRestriction, SegmentButtonTextItem } from '@kit.ArkUI';
import { SettingsSelect } from './SettingsSelect';
import { AppDesign } from '../model/AppDesign';

/** Mutually exclusive settings use the native sliding selection, focus and touch behavior. */
@Component
export struct SettingsSegmented {
  @Prop @Watch('optionsChanged') labels:string[]=[];
  @Prop @Watch('selectionChanged') selectedIndex:number=0;
  @Prop @Watch('optionsChanged') appDark:boolean=false;
  onSelect:(index:number)=>void=()=>{};
  @State @Watch('nativeSelectionChanged') indexes:number[]=[0];
  @State options:SegmentButtonOptions=SegmentButtonOptions.capsule({buttons:[{text:''},{text:''}]});
  private optionsSignature:string='';
  aboutToAppear():void {this.optionsChanged();this.selectionChanged();}
  private optionsChanged():void {
    const signature=this.labels.join('\u0000')+':'+this.appDark;
    if(signature===this.optionsSignature)return;
    this.optionsSignature=signature;
    if(this.labels.length>5)return;
    this.options=SegmentButtonOptions.capsule({
      buttons:this.labels.map((text):SegmentButtonTextItem=>({text:text})) as ItemRestriction<SegmentButtonTextItem>,
      multiply:false,fontSize:this.labels.length>3?12:14,selectedFontSize:this.labels.length>3?12:14,fontWeight:FontWeight.Normal,selectedFontWeight:FontWeight.Medium,
      fontColor:AppDesign.text(this.appDark),selectedFontColor:AppDesign.onSelected(this.appDark),
      backgroundColor:AppDesign.surface(this.appDark),selectedBackgroundColor:AppDesign.selected(this.appDark),
      buttonPadding:{top:12,bottom:12,left:8,right:8},textPadding:0
    });
  }
  private selectionChanged():void {
    const index=Math.max(0,Math.min(this.labels.length-1,this.selectedIndex));
    if(this.indexes[0]!==index)this.indexes=[index];
  }
  private nativeSelectionChanged():void {
    const index=this.indexes[0];
    if(index!==undefined && index>=0 && index<this.labels.length && index!==this.selectedIndex)this.onSelect(index);
  }
  build() {
    if(this.labels.length>5) {SettingsSelect({labels:this.labels,selectedIndex:this.selectedIndex,appDark:this.appDark,onSelect:this.onSelect})}
    else {SegmentButton({options:this.options,selectedIndexes:$indexes}).width('100%').clip(true)}
  }
}
