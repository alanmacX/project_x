import { WidgetActionRect, widgetActionRects } from '../../model/WidgetActions';
import { CanvasBackdrop } from '../../views/CanvasBackdrop';
import { cardRenderSnapshot } from '../../model/CardViewSnapshot';
import { FridgeCard, CanvasBackground, normalizeBackground, BOARD_W, materialColors } from '../../model/CardSchema';
import { scenePercent } from '../../model/SceneLayout';
import { widgetHit, widgetCanvasPoint } from '../../model/WidgetHitTest';
import { CardFace } from '../../views/CardFace';

interface WidgetScenePacket {cards:string;background:string;canvasId:string;context:string;rev:number;}
interface WidgetSceneContext {ruleId:string;occurrence:string;baseId:string;focusId:string;}
@Entry
@Component
struct FridgeWidgetCard {
  @LocalStorageProp('scenePacket') @Watch('syncPacket') packetJson:string='';
  @State scenePhase:number=0;
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
  private syncPacket():void {
    if(!this.alive||!this.packetJson||this.appliedPacket===this.packetJson)return;
    let packet:WidgetScenePacket;
    try{packet=JSON.parse(this.packetJson) as WidgetScenePacket;if(typeof packet.cards!=='string'||typeof packet.background!=='string')return;}catch(_){return;}
    // Visibility/time refreshes still update rev, but identical artwork needs no rebuild.
    if(!this.sceneAnimating && this.appliedPacket && this.displayCanvasId===packet.canvasId && this.appliedCards===packet.cards && this.appliedBackground===packet.background && this.appliedContext===packet.context) {this.appliedPacket=this.packetJson;return;}
    const cards=this.parse(packet.cards).sort((a,b)=>a.z-b.z);
    const first=this.appliedPacket.length===0,differentCanvas=!first&&this.displayCanvasId!==packet.canvasId;
    const generation=++this.sceneGeneration;
    this.appliedPacket=this.packetJson;
    const apply=():void=>{
      this.displayCanvasId=packet.canvasId;this.appliedCards=packet.cards;this.appliedBackground=packet.background;this.appliedContext=packet.context;
      try{this.context=packet.context?JSON.parse(packet.context) as WidgetSceneContext:null;}catch(_){this.context=null;}
      this.focusId=this.context?.focusId??'';
      const map:Record<string,FridgeCard>={};cards.forEach((c)=>map[c.id]=cardRenderSnapshot(c,true));this.cardMap=map;this.cardIds=cards.map(c=>c.id);
      try{this.canvasBackground=normalizeBackground(JSON.parse(packet.background) as CanvasBackground);}catch(_){}
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
    }else animateTo({duration:180,curve:Curve.EaseOut,onFinish:finish},apply);
  }
  private sceneOffset(id:string,horizontal:boolean):number {
    const rect=scenePercent(this.cardMap[id],this.widthValue()/this.heightValue()),dx=rect.x+rect.w/2-50,dy=rect.y+rect.h/2-50;
    const axis=Math.abs(dx)>=Math.abs(dy),length=Math.max(this.widthValue(),this.heightValue())*1.5;
    return (horizontal===axis?(horizontal?(dx<0?-1:1):(dy<0?-1:1))*length:0)*this.scenePhase;
  }
  private restoreScene():void {if(this.context&&!this.sceneAnimating)postCardAction(this,{action:'message',params:{operation:'dismissScene',ruleId:this.context.ruleId,occurrence:this.context.occurrence}});}
  @LocalStorageProp('background') @Watch('syncBackground') backgroundJson: string = '{}';
  @State canvasBackground: CanvasBackground = new CanvasBackground();
  private syncBackground(): void { if(this.packetJson)return;try { this.canvasBackground = normalizeBackground(JSON.parse(this.backgroundJson) as CanvasBackground); } catch (_) { this.canvasBackground = new CanvasBackground(); } }
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
  private dispatch(x: number, y: number): void {
    if(this.sceneAnimating)return;
    const hit = widgetHit(this.cardIds.map((id: string) => this.cardMap[id]), x, y, this.widthValue(), this.heightValue(),this.rev||Date.now(),this.focusId);
    if(this.focusId&&hit.id===this.focusId){this.restoreScene();return;}
    if (hit.id.length === 0 || hit.operation === 'disabled') return;
    if (hit.operation.length > 0) this.action(hit.id, hit.operation); else this.open(hit.id);
  }
  private parse(json: string): FridgeCard[] {
    try { return JSON.parse(json) as FridgeCard[]; } catch (_) { return []; }
  }
  aboutToAppear(): void {this.alive=true; this.syncPacket();this.syncBackground(); this.syncCards(); }
  aboutToDisappear():void {this.alive=false;this.sceneGeneration++;this.sceneAnimating=false;this.appliedPacket='';this.scenePhase=0;}
  private syncLegacyCards(): void { if (this.cardsJson.length === 0) this.syncCards(); }
  private syncCards(): void {
    if(this.packetJson)return;
    const cards = (this.cardsJson.length > 0 ? this.parse(this.cardsJson) : this.parse(this.faceCardsJson).concat(this.parse(this.doorCardsJson)))
      .sort((a: FridgeCard, b: FridgeCard) => a.z - b.z);
    const map: Record<string, FridgeCard> = {};
    cards.forEach((card: FridgeCard) => { map[card.id] = cardRenderSnapshot(card); });
    this.cardMap = map; this.cardIds = cards.map((card: FridgeCard) => card.id);
  }
  private open(id: string = ''): void {
    postCardAction(this, { action: 'router', abilityName: 'EntryAbility',
      params: { canvasId: this.displayCanvasId||this.canvasId, viewCardId: id, canvasDimension: this.dim, canvasAspect: String(this.widthValue() / this.heightValue()) } });
  }
  private action(id: string, operation: string): void {
    postCardAction(this, { action: 'message', params: { cardId: id, operation: operation } });
  }
  @Builder
  actionButton(card:FridgeCard,action:WidgetActionRect) {
    Button(action.symbol,{type:ButtonType.Circle}).width(44).height(44).padding(0).fontSize(20).fontColor(card.shape==='subject'&&card.subjectPhoto&&card.ink.length===0?card.subjectInk:materialColors(card.material,card.paper,card.ink)[1]).backgroundColor(Color.Transparent)
      .position({x:action.x*this.widthValue()/BOARD_W,y:action.y*this.widthValue()/BOARD_W})
      .accessibilityText(action.operation==='previousMonth'?'上个月':'下个月')
      .onClick((event:ClickEvent)=>{
        const scale=this.widthValue()/BOARD_W,point=widgetCanvasPoint(card,action.x*scale+event.x,action.y*scale+event.y,this.widthValue(),this.heightValue());this.dispatch(point.x,point.y);
      })
  }
  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      CanvasBackdrop({ sceneBackground: this.canvasBackground }).width('100%').height('100%')
      ForEach(this.cardIds, (id: string) => {
        Stack({ alignContent: Alignment.TopStart }) {
        CardFace({ card: this.cardMap[id], scaleFactor: this.widthValue() / BOARD_W, tick: this.rev, widget: true })
          .width('100%').height('100%').hitTestBehavior(HitTestMode.None)
        ForEach(widgetActionRects(this.cardMap[id],this.widthValue()/BOARD_W,this.rev||Date.now()),(action:WidgetActionRect)=>{
          this.actionButton(this.cardMap[id],action)
        },(action:WidgetActionRect)=>action.operation)
        }
          .width(scenePercent(this.cardMap[id], this.widthValue() / this.heightValue()).w + '%').height(scenePercent(this.cardMap[id], this.widthValue() / this.heightValue()).h + '%')
          .position({ x: scenePercent(this.cardMap[id], this.widthValue() / this.heightValue()).x + '%', y: scenePercent(this.cardMap[id], this.widthValue() / this.heightValue()).y + '%' })
          .rotate({ angle: this.cardMap[id].rot, centerX: 0, centerY: '100%' }).translate({x:this.sceneOffset(id,true),y:this.sceneOffset(id,false)}).zIndex(this.cardMap[id].z)
          .hitTestBehavior(HitTestMode.Transparent)
      }, (id: string) => id)
      if(this.focusId) {Button('恢复',{type:ButtonType.Capsule}).height(44).padding({left:16,right:16}).fontSize(12).backgroundColor('#EEFFFFFF').fontColor('#303030').position({x:12,y:12}).zIndex(100001).onClick(()=>this.restoreScene())}
      Button('打开', { type: ButtonType.Capsule }).width(56).height(44).padding(0).fontSize(12).borderRadius(10)
        .backgroundColor('#EEFFFFFF').fontColor('#303030').position({ x: '100%', y: '100%' }).translate({ x: -64, y: -52 }).zIndex(100000)
        .accessibilityText('打开卡片画布').onClick(() => this.open())
    }.width('100%').height('100%').backgroundColor(Color.White).borderRadius(24).clip(true)
      .onSizeChange((_: SizeOptions, size: SizeOptions) => {
        const width = Number(size.width), height = Number(size.height);
        if (width > 0 && height > 0 && (Math.abs(width - this.measuredWidth) > .1 || Math.abs(height - this.measuredHeight) > .1)) {
          this.measuredWidth = width; this.measuredHeight = height;
        }
      })
      .onClick((event: ClickEvent) => this.dispatch(event.x, event.y))
  }
}
