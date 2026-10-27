import { commonEventManager, batteryInfo } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
/** Subscriptions exist only while the app is alive. They do not promise a permanent background service. */
export class BatteryObserver {
  private subscriber:commonEventManager.CommonEventSubscriber|null=null;
  private closed:boolean=false;
  private generation:number=0;
  private lastReading:string='';
  async start(onChange:()=>void):Promise<void> {
    this.stop();this.closed=false;this.lastReading='';const generation=this.generation;
    try{
      const sub=await commonEventManager.createSubscriber({events:['usual.event.BATTERY_CHANGED','usual.event.POWER_CONNECTED','usual.event.POWER_DISCONNECTED']});
      if(this.closed||generation!==this.generation)return;this.subscriber=sub;
      commonEventManager.subscribe(sub,(error,data)=>{
        if(error&&error.code!==0){hilog.warn(0,'BatteryRefresh','event failed code=%{public}d',error.code);return;}
        if(this.closed||generation!==this.generation)return;
        const reading=batteryInfo.batterySOC+':'+batteryInfo.chargingStatus;
        // Voltage/temperature broadcasts and thawed event backlogs do not change this UI.
        if(reading===this.lastReading)return;this.lastReading=reading;
        hilog.info(0,'BatteryRefresh','event=%{public}s reading=%{public}s',data?.event??'',reading);
        onChange();
      });
      hilog.info(0,'BatteryRefresh','subscription requested generation=%{public}d',generation);
    }catch(e){hilog.warn(0,'BatteryRefresh','subscription failed %{public}s',(e as Error).message);}
  }
  stop():void {this.closed=true;this.generation++;if(this.subscriber!==null){commonEventManager.unsubscribe(this.subscriber,()=>{});this.subscriber=null;}}
}
