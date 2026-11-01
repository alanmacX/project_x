import { FridgeCard } from '../model/CardSchema';
import { TemplateScene, TemplateMark, cardTemplateScene } from '../model/TemplateScene';
import { paintTemplate } from '../model/TemplatePaint';
import { sceneImage } from '../model/SceneImageCache';
@Component
export struct TemplateFace {
  @Prop @Watch('sceneChanged') card:FridgeCard=new FridgeCard();
  @Prop @Watch('sceneChanged') tick:number=0;
  @Prop @Watch('sceneChanged') scaleFactor:number=1;
  @Prop snapshot:boolean=false;
  private base:CanvasRenderingContext2D=new CanvasRenderingContext2D(new RenderingContextSettings(true));
  private ink:CanvasRenderingContext2D=new CanvasRenderingContext2D(new RenderingContextSettings(true));
  private ready:boolean=false;
  aboutToAppear():void {try{this.getUIContext().getFont().registerFont({familyName:'TemplateDigits',familySrc:$rawfile('template-digits.ttf')});}catch(_){}}
  private cachedCard:FridgeCard|null=null;
  private cachedTick:number=-1;
  @State cachedScene:TemplateScene=new TemplateScene();
  private scene():TemplateScene{if(this.cachedCard!==this.card||this.cachedTick!==this.tick){this.cachedCard=this.card;this.cachedTick=this.tick;this.cachedScene=cardTemplateScene(this.card,this.tick);}return this.cachedScene;}
  private unit():number{return Math.min(this.card.w/this.scene().width,this.card.h/this.scene().height)*this.scaleFactor;}
  private photos(layer:number):TemplateMark[]{return this.scene().marks.filter(m=>m.kind==='image'&&m.layer===layer);}
  private sceneChanged():void {this.cachedCard=null;this.redraw();}
  private redraw():void {if(!this.ready)return;const scene=this.scene();paintTemplate(this.base,scene,this.card.w*this.scaleFactor,this.card.h*this.scaleFactor,0,this.card.template?.fill===true);if(this.scene().marks.some(m=>m.layer===2&&m.kind!=='image'))paintTemplate(this.ink,scene,this.card.w*this.scaleFactor,this.card.h*this.scaleFactor,2,true);}
  private photoAt(layer:number,index:number):TemplateMark{return this.photos(layer)[index]??new TemplateMark();}
  @Builder
  images(layer:number){ForEach(this.photos(layer).map((_mark:TemplateMark,index:number)=>index),(index:number)=>{
    Image(sceneImage(this.photoAt(layer,index).src)).syncLoad(this.snapshot)
      .width(this.photoAt(layer,index).w*this.unit()).height(this.photoAt(layer,index).h*this.unit())
      .position({x:(this.card.w*this.scaleFactor-this.scene().width*this.unit())/2+this.photoAt(layer,index).x*this.unit(),y:(this.card.h*this.scaleFactor-this.scene().height*this.unit())/2+this.photoAt(layer,index).y*this.unit()})
      .objectFit(this.photoAt(layer,index).fit==='contain'?ImageFit.Contain:ImageFit.Cover).borderRadius(this.photoAt(layer,index).r*this.unit()).clip(this.photoAt(layer,index).r>0).draggable(false).hitTestBehavior(HitTestMode.None)
  },(index:number)=>String(index))}

  build(){
    Stack({alignContent:Alignment.TopStart}){
      Canvas(this.base).width('100%').height('100%').onReady(()=>{this.ready=true;this.redraw();}).onAreaChange(()=>this.redraw())
      if(/(paper|ledger|slips|sleeve)/.test(this.card.template?.id??'')){Image($rawfile('template-paper.webp')).width('100%').height('100%').objectFit(ImageFit.Cover).opacity(.09).hitTestBehavior(HitTestMode.None)}
      this.images(1)
      if(this.scene().marks.some(m=>m.layer===2&&m.kind!=='image')){Canvas(this.ink).width('100%').height('100%').onReady(()=>{this.ready=true;this.redraw();}).onAreaChange(()=>this.redraw())}
      this.images(3)
    }.width('100%').height('100%').clip(true).hitTestBehavior(HitTestMode.None)
  }
}
