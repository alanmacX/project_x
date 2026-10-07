import { cardRenderSnapshot } from '../../model/CardViewSnapshot';
import { FridgeCard, CanvasBackground, normalizeBackground, BOARD_W } from '../../model/CardSchema';
import { scenePercent } from '../../model/SceneLayout';
import { CardFace } from '../../views/CardFace';

interface WidgetScenePacket {cards:string;background:string;canvasId:string;context:string;rev:number;}
interface WidgetSceneContext {ruleId:string;occurrence:string;baseId:string;focusId:string;}
@Entry
@Component
struct FridgeWidgetCard {
  @LocalStorageProp('scenePacket') @Watch('syncPacket') packetJson:string='';
  @State scenePhase:number=0;
  @State sceneReady:boolean=false;
  @State focusId:string='';
  private displayCanvasId:string='';
  private appliedPacket:string='';
  private appliedCards:string='';
  private appliedBackground:string='';
  private appliedContext:string='';
  private sceneAnimating:boolean=false;
  private sceneGeneration:number=0;
  private alive:boolean=false;
  private context:WidgetSceneContext|null=null;
  private hasArtwork:boolean=false;
  @State displayed:CanvasBackground=new CanvasBackground();
  @State incoming:CanvasBackground|null=null;
  @State mix:number=0;
  private signature:string='';
  private generation:number=0;
  private blending:boolean=false;
  private refresh():void {
    if(!this.alive||!this.sceneReady)return;
    if(!this.hasArtwork){this.hasArtwork=true;this.displayed=this.canvasBackground;this.signature=JSON.stringify(this.canvasBackground);return;}
    const signature=JSON.stringify(this.canvasBackground);if(signature===this.signature)return;
    this.signature=signature;this.generation++;this.blending=false;
    if(this.incoming&&this.mix>.5)this.displayed=this.incoming;
    this.incoming=this.canvasBackground;this.mix=0;
    if(!this.incoming.src||this.incoming.mode==='solid'||this.incoming.mode==='smart')this.imageReady(this.incoming.src);
  }
  private imageReady(src:string):void {
    if(!this.alive||!this.incoming||this.incoming.src!==src||this.blending)return;
    this.blending=true;const generation=this.generation;
    // Establish the incoming node before animating its opacity. Form pages have
    // global animateTo, but no app UIContext or JS timer-based frame loop.
    animateTo({duration:16,onFinish:()=>{
      if(!this.alive||generation!==this.generation)return;
      animateTo({duration:240,curve:Curve.EaseInOut,onFinish:()=>{
        if(!this.alive||generation!==this.generation||!this.incoming)return;
        this.displayed=this.incoming;this.incoming=null;this.mix=0;this.blending=false;
      }},()=>this.mix=1);
    }},()=>this.mix=.001);
  }
  private syncPacket():void {
    if(!this.alive||!this.packetJson||this.appliedPacket===this.packetJson)return;
    let packet:WidgetScenePacket;
    try{packet=JSON.parse(this.packetJson) as WidgetScenePacket;if(typeof packet.cards!=='string'||typeof packet.background!=='string')return;}catch(_){return;}
    // Visibility/time refreshes still update rev, but identical artwork needs no rebuild.
    if(!this.sceneAnimating && this.appliedPacket && this.displayCanvasId===packet.canvasId && this.appliedCards===packet.cards && this.appliedBackground===packet.background && this.appliedContext===packet.context) {this.appliedPacket=this.packetJson;return;}
    const cards=this.parse(packet.cards).sort((a,b)=>a.z-b.z);
    const backgroundChanged=this.appliedBackground!==packet.background;
    const first=this.appliedPacket.length===0,differentCanvas=!first&&this.displayCanvasId!==packet.canvasId;
    const generation=++this.sceneGeneration;
    this.appliedPacket=this.packetJson;
    const apply=():void=>{
      this.displayCanvasId=packet.canvasId;this.appliedCards=packet.cards;this.appliedBackground=packet.background;this.appliedContext=packet.context;
      try{this.context=packet.context?JSON.parse(packet.context) as WidgetSceneContext:null;}catch(_){this.context=null;}
      this.focusId=this.context?.focusId??'';
      const map:Record<string,FridgeCard>={};cards.forEach((c)=>map[c.id]=cardRenderSnapshot(c,true));this.cardMap=map;this.cardIds=cards.map(c=>c.id);
      if(backgroundChanged)try{this.canvasBackground=normalizeBackground(JSON.parse(packet.background) as CanvasBackground);}catch(_){}
      this.sceneReady=true;this.refresh();
    };
    if(first){apply();return;}
    // Form pages support the global animation API; UIContext.animateTo is app-only.
    this.sceneAnimating=true;
    const finish=():void=>{if(!this.alive||generation!==this.sceneGeneration)return;this.sceneAnimating=false;this.syncPacket();};
    if(differentCanvas) {
      animateTo({duration:240,curve:Curve.EaseIn,onFinish:()=>{if(!this.alive||generation!==this.sceneGeneration)return;apply();
        // Commit the new nodes at the offscreen pose before their entrance.
        // Form renderers do not support JS timers or app UIContext methods.
        animateTo({duration:16,onFinish:()=>{if(this.alive&&generation===this.sceneGeneration)animateTo({duration:420,curve:Curve.Friction,onFinish:finish},()=>this.scenePhase=0);}},()=>this.scenePhase=1.001);
      }},()=>this.scenePhase=1);
    }else animateTo({duration:180,curve:Curve.EaseOut,onFinish:finish},()=>{apply();this.scenePhase=0;});
  }
  private sceneOffset(id:string,horizontal:boolean):number {
    const rect=scenePercent(this.cardMap[id],this.widthValue()/this.heightValue()),dx=rect.x+rect.w/2-50,dy=rect.y+rect.h/2-50;
    const axis=Math.abs(dx)>=Math.abs(dy),length=Math.max(this.widthValue(),this.heightValue())*1.5;
    return (horizontal===axis?(horizontal?(dx<0?-1:1):(dy<0?-1:1))*length:0)*this.scenePhase;
  }
  @LocalStorageProp('background') @Watch('syncBackground') backgroundJson: string = '{}';
  @State canvasBackground: CanvasBackground = new CanvasBackground();
  private syncBackground(): void { if(this.packetJson)return;try { this.canvasBackground = normalizeBackground(JSON.parse(this.backgroundJson) as CanvasBackground); } catch (_) { this.canvasBackground = new CanvasBackground(); } this.displayed=this.canvasBackground;this.signature=JSON.stringify(this.canvasBackground); }
  @LocalStorageProp('cards') @Watch('syncCards') cardsJson: string = '';
  @State cardIds: string[] = [];
  @State cardMap: Record<string, FridgeCard> = {};
  @LocalStorageProp('faceCards') @Watch('syncLegacyCards') faceCardsJson: string = '[]';
  @LocalStorageProp('doorCards') @Watch('syncLegacyCards') doorCardsJson: string = '[]';
  @LocalStorageProp('rev') rev: number = 0;
  @LocalStorageProp('canvasId') canvasId: string = 'canvas_main';
  @LocalStorageProp('dim') dim: string = '4*4';
  @LocalStorageProp('canvasWidth') canvasWidth: number = 344;
  @LocalStorageProp('canvasHeight') canvasHeight: number = 344;
  @State measuredWidth: number = 0;
  @State measuredHeight: number = 0;
  private widthValue(): number { return this.measuredWidth > 0 ? this.measuredWidth : this.canvasWidth; }
  private heightValue(): number { return this.measuredHeight > 0 ? this.measuredHeight : this.canvasHeight; }
  private parse(json: string): FridgeCard[] {
    try { return JSON.parse(json) as FridgeCard[]; } catch (_) { return []; }
  }
  aboutToAppear(): void {this.alive=true; this.syncPacket();this.syncBackground(); this.syncCards(); }
  aboutToDisappear():void {this.alive=false;this.sceneGeneration++;this.sceneAnimating=false;this.appliedPacket='';this.scenePhase=0;this.generation++;this.blending=false;this.incoming=null;this.mix=0;this.hasArtwork=false;}
  private syncLegacyCards(): void { if (this.cardsJson.length === 0) this.syncCards(); }
  private syncCards(): void {
    if(this.packetJson)return;
    const cards = (this.cardsJson.length > 0 ? this.parse(this.cardsJson) : this.parse(this.faceCardsJson).concat(this.parse(this.doorCardsJson)))
      .sort((a: FridgeCard, b: FridgeCard) => a.z - b.z);
    const map: Record<string, FridgeCard> = {};
    cards.forEach((card: FridgeCard) => { map[card.id] = cardRenderSnapshot(card); });
    this.cardMap = map; this.cardIds = cards.map((card: FridgeCard) => card.id);
  }
  private open(): void {
    postCardAction(this, { action: 'router', abilityName: 'EntryAbility',
      params: { canvasId: this.displayCanvasId||this.canvasId, viewCardId: '', canvasDimension: this.dim, canvasAspect: String(this.widthValue() / this.heightValue()) } });
  }
  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Stack() {
        Column().width('100%').height('100%').backgroundColor(this.displayed.color)
        if(this.displayed.src&&this.displayed.mode!=='solid'&&this.displayed.mode!=='smart') {
          Image(this.displayed.src).width('100%').height('100%').objectFit(ImageFit.Cover)
        }
        if(this.incoming) {
          Stack() {
            Column().width('100%').height('100%').backgroundColor(this.incoming.color)
            if(this.incoming.src&&this.incoming.mode!=='solid'&&this.incoming.mode!=='smart') {
              ForEach([this.incoming.src],(src:string)=>{
                Image(src).width('100%').height('100%').objectFit(ImageFit.Cover)
                  .onComplete(()=>this.imageReady(src))
                  .onError(()=>this.imageReady(src))
              },(src:string)=>src)
            }
          }.width('100%').height('100%').opacity(this.mix)
        }
      }.width('100%').height('100%').hitTestBehavior(HitTestMode.None)
      ForEach(this.cardIds, (id: string) => {
        Stack({ alignContent: Alignment.TopStart }) {
        CardFace({ card: this.cardMap[id], scaleFactor: this.widthValue() / BOARD_W, tick: this.rev, widget: true })
          .width('100%').height('100%').hitTestBehavior(HitTestMode.None)

        }
          .width(scenePercent(this.cardMap[id], this.widthValue() / this.heightValue()).w + '%').height(scenePercent(this.cardMap[id], this.widthValue() / this.heightValue()).h + '%')
          .position({x:0,y:0})
          .rotate({ angle: this.cardMap[id].rot, centerX: 0, centerY: '100%' }).translate({x:scenePercent(this.cardMap[id],this.widthValue()/this.heightValue()).x*this.widthValue()/100+this.sceneOffset(id,true),y:scenePercent(this.cardMap[id],this.widthValue()/this.heightValue()).y*this.heightValue()/100+this.sceneOffset(id,false)}).zIndex(this.cardMap[id].z)
          .transition(TransitionEffect.OPACITY.combine(TransitionEffect.scale({x:.96,y:.96})))
          .hitTestBehavior(HitTestMode.None)
      }, (id: string) => id)
    }.width('100%').height('100%').backgroundColor(Color.White).borderRadius(24).clip(true)
      .onSizeChange((_: SizeOptions, size: SizeOptions) => {
        const width = Number(size.width), height = Number(size.height);
        if (width > 0 && height > 0 && (Math.abs(width - this.measuredWidth) > .1 || Math.abs(height - this.measuredHeight) > .1)) {
          this.measuredWidth = width; this.measuredHeight = height;
        }
      })
      .accessibilityText('打开冰箱贴画布').onClick(() => this.open())
  }
}
