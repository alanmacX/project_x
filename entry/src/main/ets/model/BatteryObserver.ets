import { commonEventManager } from '@kit.BasicServicesKit';
/** Subscriptions exist only while the app is alive. They do not promise a permanent background service. */
export class BatteryObserver {
  private subscriber:commonEventManager.CommonEventSubscriber|null=null;
  private closed:boolean=false;
  async start(onChange:()=>void):Promise<void> {
    this.closed=false;
    try{
      const sub=await commonEventManager.createSubscriber({events:['usual.event.BATTERY_CHANGED','usual.event.POWER_CONNECTED','usual.event.POWER_DISCONNECTED']});
      if(this.closed)return;this.subscriber=sub;commonEventManager.subscribe(sub,()=>{if(!this.closed)onChange();});
    }catch(_){/* Timer and foreground reads remain available on systems without these broadcasts. */}
  }
  stop():void {this.closed=true;if(this.subscriber!==null){commonEventManager.unsubscribe(this.subscriber,()=>{});this.subscriber=null;}}
}
