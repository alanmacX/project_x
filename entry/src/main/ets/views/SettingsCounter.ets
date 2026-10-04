import { CounterComponent, CounterOptions, CounterType } from '@kit.ArkUI';

/** Native counter treats value as an initial value. Remount only for an external restore,
 * not for its own taps or repeats, and ignore callbacks from a retired instance. */
@Component
export struct SettingsCounter {
  @Prop @Watch('valueChanged') value:number=18;
  onChange:(value:number)=>void=()=>{};
  @State instance:number=0;
  private liveValue:number=18;
  aboutToAppear():void {this.liveValue=this.value;}
  private valueChanged():void {
    if(this.liveValue===this.value)return;
    this.liveValue=this.value;this.instance++;
  }
  private options(version:number):CounterOptions {
    return {type:CounterType.LIST,numberOptions:{label:'字号',value:this.value,min:10,max:64,step:2,
      onChange:(value:number)=>{
        if(version!==this.instance||value===this.liveValue)return;
        this.liveValue=value;
        if(value!==this.value)this.onChange(value);
      }}};
  }
  build() {
    Column() {
      ForEach([this.instance],(version:number)=>{
        CounterComponent({options:this.options(version)}).width('100%')
      },(version:number)=>String(version))
    }.width('100%')
  }
}
