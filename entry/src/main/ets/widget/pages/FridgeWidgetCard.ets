import { depthRenderCards } from '../../model/DepthComposition';
import { capabilityRenderTick } from '../../model/CapabilityClock';
import { cardRenderSnapshot } from '../../model/CardViewSnapshot';
import { FridgeCard, CanvasBackground, normalizeBackground, BOARD_W } from '../../model/CardSchema';
import { scenePercent } from '../../model/SceneLayout';
import { CanvasFrame } from '../../views/CanvasFrame';
import { CardFace } from '../../views/CardFace';

function initialFormBackground():CanvasBackground {const bg=new CanvasBackground();bg.mode='transparent';return bg;}
interface WidgetScenePacket {cards:string;background:string;canvasId:string;context:string;aspect?:number;rev:number;}
interface WidgetSceneContext {ruleId:string;occurrence:string;baseId:string;focusId:string;}
@Entry
@Component
struct FridgeWidgetCard {
  @LocalStorageProp('scenePacket') @Watch('syncPacket') packetJson:string='';
  @State authoredAspect:number=1;
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
  @State displayed:CanvasBackground=initialFormBackground();
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
    if(this.incoming.mode==='transparent'||!this.incoming.src||this.incoming.mode==='solid'||this.incoming.mode==='smart')this.imageReady(this.incoming.src);
  }
  private imageReady(src:string):void {
    if(!this.alive||!this.incoming||this.incoming.src!==src||this.blending)return;
    this.blending=true;const generation=this.generation;
    // Visibility commits in the animation update itself. Completion is cleanup only;
    // a suspended Form host may omit callbacks without hiding the newest artwork.
    animateTo({duration:240,curve:Curve.EaseInOut,onFinish:()=>{
      if(!this.alive||generation!==this.generation||!this.incoming)return;
      this.displayed=this.incoming;this.incoming=null;this.mix=0;this.blending=false;
    }},()=>this.mix=1);
  }
  private syncPacket():void {
    if(!this.alive||!this.packetJson||this.appliedPacket===this.packetJson)return;
    let packet:WidgetScenePacket;
    try{packet=JSON.parse(this.packetJson) as WidgetScenePacket;if(typeof packet.cards!=='string'||typeof packet.background!=='string')return;}catch(_){return;}
    // Visibility/time refreshes still update rev, but identical artwork needs no rebuild.
    if(!this.sceneAnimating && this.appliedPacket && this.displayCanvasId===packet.canvasId && this.appliedCards===packet.cards && this.appliedBackground===packet.background && this.appliedContext===packet.context && this.authoredAspect===(packet.aspect??1)) {this.appliedPacket=this.packetJson;return;}
    const cards=depthRenderCards(this.parse(packet.cards)).sort((a,b)=>a.z-b.z);
    const backgroundChanged=this.appliedBackground!==packet.background;
    const first=this.appliedPacket.length===0,differentCanvas=!first&&this.displayCanvasId!==packet.canvasId;
    const generation=++this.sceneGeneration;
    this.appliedPacket=this.packetJson;
    const apply=():void=>{
      const aspect=packet.aspect??1;this.authoredAspect=Number.isFinite(aspect)&&aspect>=.3&&aspect<=3?aspect:1;
      this.displayCanvasId=packet.canvasId;this.appliedCards=packet.cards;this.appliedBackground=packet.background;this.appliedContext=packet.context;
      try{this.context=packet.context?JSON.parse(packet.context) as WidgetSceneContext:null;}catch(_){this.context=null;}
      this.focusId=this.context?.focusId??'';
      const map:Record<string,FridgeCard>={};cards.forEach((c)=>map[c.id]=cardRenderSnapshot(c,true));this.cardMap=map;this.cardIds=cards.map(c=>c.id);
      if(backgroundChanged)try{this.canvasBackground=normalizeBackground(JSON.parse(packet.background) as CanvasBackground);}catch(_){}
      this.sceneReady=true;this.refresh();
    };
    // Commit the complete latest scene now. A Form can be suspended before animation
    // completion; correctness must never depend on an onFinish callback.
    this.sceneAnimating=false;this.scenePhase=0;
    if(first)apply();
    else animateTo({duration:differentCanvas?300:180,curve:Curve.EaseOut},()=>apply());
  }

  private sceneOffset(id:string,horizontal:boolean):number {
    return 0;
  }
  @LocalStorageProp('background') @Watch('syncBackground') backgroundJson: string = '{"mode":"transparent"}';
  @State canvasBackground: CanvasBackground = initialFormBackground();
  private syncBackground(): void { if(this.packetJson)return;try { this.canvasBackground = normalizeBackground(JSON.parse(this.backgroundJson) as CanvasBackground); } catch (_) { this.canvasBackground = new CanvasBackground(); } this.displayed=this.canvasBackground;this.signature=JSON.stringify(this.canvasBackground); }
  @LocalStorageProp('cards') @Watch('syncCards') cardsJson: string = '';
  @State cardIds: string[] = [];
  @State cardMap: Record<string, FridgeCard> = {};
  @LocalStorageProp('faceCards') @Watch('syncLegacyCards') faceCardsJson: string = '[]';
  @LocalStorageProp('doorCards') @Watch('syncLegacyCards') doorCardsJson: string = '[]';
  @LocalStorageProp('rev') @Watch('syncRenderClock') rev: number = 0;
  @State renderTick:number=Math.floor(Date.now()/60000)*60000;
  private syncRenderClock():void {
    const tick=Math.floor((this.rev>0?this.rev:Date.now())/60000)*60000;
    if(tick!==this.renderTick)this.renderTick=tick;
  }
  @LocalStorageProp('canvasId') canvasId: string = 'canvas_main';
  @LocalStorageProp('dim') dim: string = '4*4';
  @LocalStorageProp('canvasWidth') canvasWidth: number = 344;
  @LocalStorageProp('canvasHeight') canvasHeight: number = 344;
  @State measuredWidth: number = 0;
  @State measuredHeight: number = 0;
  private widthValue(): number { return this.measuredWidth > 0 ? this.measuredWidth : this.canvasWidth; }
  private heightValue(): number { return this.measuredHeight > 0 ? this.measuredHeight : this.canvasHeight; }
  private hostAspect():number {return this.widthValue()/this.heightValue();}
  private parse(json: string): FridgeCard[] {
    try { return JSON.parse(json) as FridgeCard[]; } catch (_) { return []; }
  }
  aboutToAppear(): void {this.alive=true;this.syncRenderClock(); this.syncPacket();this.syncBackground(); this.syncCards(); }
  aboutToDisappear():void {this.alive=false;this.sceneGeneration++;this.sceneAnimating=false;this.appliedPacket='';this.scenePhase=0;this.generation++;this.blending=false;this.incoming=null;this.mix=0;this.hasArtwork=false;}
  private syncLegacyCards(): void { if (this.cardsJson.length === 0) this.syncCards(); }
  private syncCards(): void {
    if(this.packetJson)return;
    const cards = depthRenderCards(this.cardsJson.length > 0 ? this.parse(this.cardsJson) : this.parse(this.faceCardsJson).concat(this.parse(this.doorCardsJson)))
      .sort((a: FridgeCard, b: FridgeCard) => a.z - b.z);
    const map: Record<string, FridgeCard> = {};
    cards.forEach((card: FridgeCard) => { map[card.id] = cardRenderSnapshot(card); });
    this.cardMap = map; this.cardIds = cards.map((card: FridgeCard) => card.id);
  }
  private open(): void {
    postCardAction(this, { action: 'router', abilityName: 'EntryAbility',
      params: { canvasId: this.displayCanvasId||this.canvasId, viewCardId: '', canvasDimension: this.dim, canvasAspect: String(this.hostAspect()) } });
  }
  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      // Restore the original full-host layout: normalized centres adapt to the
      // launcher rectangle; each card retains its width/height proportion.
      Stack() {
        if(this.displayed.mode!=='transparent'){
        Stack(){
        Column().width('100%').height('100%').backgroundColor(this.displayed.color)
        if(this.displayed.src&&this.displayed.mode!=='solid'&&this.displayed.mode!=='smart') {
          Image(this.displayed.src).width('100%').height('100%').objectFit(ImageFit.Cover)
        }
        }.width('100%').height('100%').opacity(this.incoming?1-this.mix:1)
        }
        if(this.incoming) {
          Stack() {
            if(this.incoming.mode!=='transparent'){
            Column().width('100%').height('100%').backgroundColor(this.incoming.color)
            if(this.incoming.src&&this.incoming.mode!=='solid'&&this.incoming.mode!=='smart') {
              ForEach([this.incoming.src],(src:string)=>{
                Image(src).width('100%').height('100%').objectFit(ImageFit.Cover)
                  .onComplete(()=>this.imageReady(src))
                  .onError(()=>this.imageReady(src))
              },(src:string)=>src)
            }
            }
          }.width('100%').height('100%').opacity(this.mix)
        }
      }.width('100%').height('100%').hitTestBehavior(HitTestMode.None)
      if(this.canvasBackground.mode==='transparent'&&this.cardIds.length===0){
        Column({space:8}){Text('冰箱贴').fontSize(18).fontWeight(FontWeight.Medium).fontColor('#302D23');Text('点击添加卡片').fontSize(13).fontColor('#696459')}
         .width('72%').height('28%').justifyContent(FlexAlign.Center).backgroundColor('#F2FAF8EF').borderRadius(20).position({x:'14%',y:'36%'}).hitTestBehavior(HitTestMode.None)
      }
      ForEach(this.cardIds.filter((id:string)=>!this.cardMap[id].hidden), (id: string) => {
        Stack({alignContent:Alignment.TopStart}) {
          CardFace({card:this.cardMap[id],scaleFactor:this.widthValue()/BOARD_W,tick:capabilityRenderTick(this.cardMap[id].capability,this.renderTick),widget:true})
            .width('100%').height('100%').hitTestBehavior(HitTestMode.None)
        }.width(scenePercent(this.cardMap[id],this.hostAspect()).w+'%')
          .height(scenePercent(this.cardMap[id],this.hostAspect()).h+'%')
          .position({x:scenePercent(this.cardMap[id],this.hostAspect()).x+'%',y:scenePercent(this.cardMap[id],this.hostAspect()).y+'%'})
          .rotate({angle:this.cardMap[id].rot,centerX:0,centerY:'100%'})
          .zIndex(this.cardMap[id].z).hitTestBehavior(HitTestMode.None)
      }, (id: string) => id)
      if(this.canvasBackground.frameStyle!=='none'){CanvasFrame({material:this.canvasBackground.frameMaterial,style:this.canvasBackground.frameStyle}).width('100%').height('100%').zIndex(100000).hitTestBehavior(HitTestMode.None)}
    }.width('100%').height('100%').backgroundColor(this.canvasBackground.mode==='transparent'?Color.Transparent:this.canvasBackground.color).borderRadius(this.canvasBackground.frameStyle==='none'?24:this.widthValue()*31/600).clip(true)
      // Cache the complete clipped form, including shadow fringes, while its
      // host scales it during launch/return. Crossfades render live until settled.
      .renderGroup(this.incoming===null)
      .onSizeChange((_: SizeOptions, size: SizeOptions) => {
        const width = Number(size.width), height = Number(size.height);
        if (width > 0 && height > 0 && (Math.abs(width - this.measuredWidth) > .1 || Math.abs(height - this.measuredHeight) > .1)) {
          this.measuredWidth = width; this.measuredHeight = height;
        }
      })
      .accessibilityText('打开冰箱贴画布')
      .onClick(() => this.open())
  }
}
