/** One host clock, aligned to civil minute boundaries. No per-card timers or second polling. */
export class MinutePulse {
  private timer:number=-1;
  private active:boolean=false;
  private action:()=>void;
  constructor(action:()=>void) {this.action=action;}
  start():void {this.stop();this.active=true;this.schedule();}
  stop():void {this.active=false;if(this.timer>=0)clearTimeout(this.timer);this.timer=-1;}
  private schedule():void {
    if(!this.active)return;
    this.timer=setTimeout(()=>{this.timer=-1;try{if(this.active)this.action();}finally{this.schedule();}},60000-Date.now()%60000+16);
  }
}
