import { AppDesign } from '../model/AppDesign';
import { motionFrameRate } from '../model/MotionPolicy';
import { SettingsSegmented } from './SettingsSegmented';

/** Keep native controls mounted while only their clipped viewport expands. */
@Component
export struct BackgroundFrameSettings {
  @Prop @Watch('syncStyle') style:string='none';
  @Prop material:string='stone';
  @Prop appDark:boolean=false;
  onStyle:(style:string)=>void=()=>{};
  onMaterial:(material:string)=>void=()=>{};
  @State expanded:boolean=false;
  @State preferredStyle:string='auto';

  aboutToAppear():void {this.syncStyle();}
  private syncStyle():void {
    if(this.style!=='none')this.preferredStyle=this.style;
    const on=this.style!=='none';
    if(on!==this.expanded)this.expanded=on;
  }
  private toggle(on:boolean):void {
    if(on===this.expanded)return;
    this.getUIContext().animateTo({duration:240,curve:Curve.EaseOut,expectedFrameRateRange:motionFrameRate()},()=>{
      this.expanded=on;
    });
    // Persistence and artwork preparation run once, outside the animation transaction.
    this.onStyle(on?this.preferredStyle:'none');
  }
  build() {
    Column() {
      Row() {
        Text('画框').fontSize(15).fontWeight(FontWeight.Medium).fontColor(AppDesign.text(this.appDark)).layoutWeight(1)
        Toggle({type:ToggleType.Switch,isOn:this.expanded})
          .selectedColor(AppDesign.selected(this.appDark))
          .switchPointColor(this.expanded?AppDesign.onSelected(this.appDark):AppDesign.text(this.appDark))
          .backgroundColor(AppDesign.border(this.appDark))
          .accessibilityText('显示画框').onChange((on:boolean)=>this.toggle(on))
      }.width('100%').constraintSize({minHeight:40})
      Stack({alignContent:Alignment.TopStart}) {
        Column({space:12}) {
          Row({space:12}) {
            Text('材质').fontSize(13).fontColor(AppDesign.muted(this.appDark)).width(40)
            SettingsSegmented({labels:['白岩','胡桃木','浅橡木'],selectedIndex:Math.max(0,['stone','walnut','oak'].indexOf(this.material)),appDark:this.appDark,
              onSelect:(index:number)=>this.onMaterial(['stone','walnut','oak'][index])}).layoutWeight(1)
          }.width('100%').height(44)
          Row({space:12}) {
            Text('色调').fontSize(13).fontColor(AppDesign.muted(this.appDark)).width(40)
            SettingsSegmented({labels:['浅色','深色','自动'],selectedIndex:Math.max(0,['light','dark','auto'].indexOf(this.preferredStyle)),appDark:this.appDark,
              onSelect:(index:number)=>{this.preferredStyle=['light','dark','auto'][index];this.onStyle(this.preferredStyle);}}).layoutWeight(1)
          }.width('100%').height(44)
        }.width('100%').height(112).padding({top:12})
      }.width('100%').height(this.expanded?112:0).opacity(this.expanded?1:0).clip(true)
        .enabled(this.expanded).hitTestBehavior(this.expanded?HitTestMode.Default:HitTestMode.None)
        .accessibilityLevel(this.expanded?'auto':'no-hide-descendants')
    }.width('100%').padding(14).borderRadius(AppDesign.sectionRadius).backgroundColor(AppDesign.control(this.appDark))
  }
}
