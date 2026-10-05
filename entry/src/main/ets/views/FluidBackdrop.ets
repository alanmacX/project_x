import { BackgroundAnchor } from '../model/CardSchema';
import { fluidBase } from '../model/BackgroundPalette';
import { motionFrameRate } from '../model/MotionPolicy';
/** ArkUI compositor port of FluidGradient's two animated radial layers (MIT).
 * One state transaction starts an infinite native animation. No per-frame timer,
 * image decode, palette calculation or JS mutation is involved.
 */
@Component
export struct FluidBackdrop {
  @Prop anchors: BackgroundAnchor[] = [];
  @State phase: number = 0;
  @State viewW: number = 1;
  @State viewH: number = 1;
  private startTimer: number = -1;
  aboutToAppear(): void {
    this.startTimer = setTimeout(() => {
      this.startTimer = -1;
      this.getUIContext().animateTo({ duration: 180000, iterations: -1, playMode: PlayMode.Alternate,
        curve: Curve.EaseInOut, expectedFrameRateRange: motionFrameRate() }, () => { this.phase = 1; });
    }, 80);
  }
  aboutToDisappear(): void { if(this.startTimer>=0)clearTimeout(this.startTimer); }
  private radius(k:number):number {return (.3+.45*((k*7+3)%11)/10)*this.viewW;}
  private ratio(k:number):number {return Math.max(this.viewW/this.viewH,1)*(.65+.9*((k*5+1)%7)/6)*this.viewH/this.viewW;}
  @Builder
  blob(p:BackgroundAnchor,k:number,highlight:boolean) {
    // Cache only the untransformed colour core. All movement remains outside it.
    Stack() {
      Column().width('100%').height('100%').radialGradient({center:['50%','50%'],radius:'50%',
        colors:[[p.color,0],[p.color,.9],['#00'+p.color.slice(1),1]]}).renderGroup(true)
    }.width(this.radius(k)*2).height(this.radius(k)*2)
      .opacity(.95*Math.pow(p.weight/Math.max(.001,...this.anchors.map((a:BackgroundAnchor)=>a.weight)),.75))
      .position({ x:(highlight?Math.max(0,Math.min(1,p.x+.28*Math.sin(k*2.4+1))):p.x)*this.viewW-this.radius(k),
        y:(highlight?Math.max(0,Math.min(1,p.y+.24*Math.cos(k*1.7+1))):p.y)*this.viewH-this.radius(k) })
      .scale({ x:(highlight?.85:1)*(1+this.phase*.12*Math.sin(k+1)),
        y:this.ratio(k)*(highlight?.85:1)*(1+this.phase*.16*Math.cos(k+2)) })
      .translate({ x:this.phase*this.viewW*.08*Math.sin(k*2.1+(highlight?3:1)),
        y:this.phase*this.viewH*.08*Math.cos(k*1.8+(highlight?2:0)) })
  }
  build() {
    Stack({alignContent:Alignment.TopStart}) {
      Stack({alignContent:Alignment.TopStart}) {
        ForEach(this.anchors.slice().sort((a:BackgroundAnchor,b:BackgroundAnchor)=>b.weight-a.weight),(p:BackgroundAnchor,k:number)=>{this.blob(p,k,false);},(p:BackgroundAnchor,k:number)=>p.color+':'+k)
      }.width('100%').height('100%').backgroundColor(fluidBase(this.anchors))
      Stack({alignContent:Alignment.TopStart}) {
        ForEach(this.anchors.slice().sort((a:BackgroundAnchor,b:BackgroundAnchor)=>b.weight-a.weight),(p:BackgroundAnchor,k:number)=>{this.blob(p,k,true);},(p:BackgroundAnchor,k:number)=>p.color+':'+k)
      }.width('100%').height('100%').blendMode(BlendMode.OVERLAY,BlendApplyType.OFFSCREEN)
    }.width('100%').height('100%').blur(Math.pow(Math.min(this.viewW,this.viewH),.75))
      .onAreaChange((_old:Area,area:Area)=>{const w=Number(area.width),h=Number(area.height);if(w>0&&h>0){this.viewW=w;this.viewH=h;}})
      .hitTestBehavior(HitTestMode.None)
  }
}
