import { layoutTemplateText, TemplateTextLayout } from '../model/TemplateTextLayout';
import { FridgeCard } from '../model/CardSchema';
import { TemplateMark, TemplateScene, cardTemplateScene } from '../model/TemplateScene';
import { templateArcPath } from '../model/TemplateGeometry';
import { sceneImage } from '../model/SceneImageCache';
/** Builder snapshots cannot rely on Canvas.onReady. Paint the same scene with native nodes. */
@Component
export struct TemplateSnapshot {
  @Prop card:FridgeCard=new FridgeCard();
  @Prop tick:number=0;
  @Prop scaleFactor:number=1;
  private scene:TemplateScene=new TemplateScene();
  aboutToAppear():void {this.scene=cardTemplateScene(this.card,this.tick);try{this.getUIContext().getFont().registerFont({familyName:'TemplateDigits',familySrc:$rawfile('template-digits.ttf')});}catch(_){}}
  private unit():number{return Math.min(this.card.w/this.scene.width,this.card.h/this.scene.height)*this.scaleFactor;}
  private x(m:TemplateMark):number{return (this.card.w*this.scaleFactor-this.scene.width*this.unit())/2+m.x*this.unit();}
  private y(m:TemplateMark):number{return (this.card.h*this.scaleFactor-this.scene.height*this.unit())/2+m.y*this.unit();}
  private textCache:Map<TemplateMark,TemplateTextLayout>=new Map();
  private fitted(m:TemplateMark):TemplateTextLayout{
    const cached=this.textCache.get(m);if(cached)return cached;
    const result=layoutTemplateText(m,(value:string,size:number):number=>this.getUIContext().getMeasureUtils().measureText({textContent:value,fontSize:size+'vp',fontFamily:m.font==='digits'?'TemplateDigits':m.font,fontWeight:m.font!=='digits'&&m.weight>=600?'bold':'normal'})/this.getUIContext().vp2px(1));
    this.textCache.set(m,result);return result;
  }
  @Builder
  mark(m:TemplateMark){
    if(m.kind==='text'){
      Column(){ForEach(this.fitted(m).lines,(value:string)=>{Text(value).fontSize(this.fitted(m).fontSize*this.unit()+'vp').fontFamily(m.font==='digits'?'TemplateDigits':m.font).fontWeight(m.font!=='digits'&&m.weight>=600?FontWeight.Bold:FontWeight.Normal).fontColor(m.color).maxLines(1)
        .textAlign(m.align==='center'?TextAlign.Center:m.align==='right'?TextAlign.End:TextAlign.Start).width('100%').height(this.fitted(m).lineHeight*this.unit())},(value:string,index:number)=>String(index))}
        .width(m.w*this.unit()).height(m.h*this.unit()).clip(true).position({x:this.x(m),y:this.y(m)})
    }else if(m.kind==='image'){
      Image(sceneImage(m.src)).syncLoad(true).objectFit(m.fit==='contain'?ImageFit.Contain:ImageFit.Cover).width(m.w*this.unit()).height(m.h*this.unit()).position({x:this.x(m),y:this.y(m)}).borderRadius(m.r*this.unit()).clip(m.r>0)
    }else if(m.kind==='line'){
      Line().startPoint([m.x*this.unit(),m.y*this.unit()]).endPoint([m.w*this.unit(),m.h*this.unit()]).stroke(m.color).strokeWidth(m.stroke*this.unit()).strokeLineCap(LineCapStyle.Round)
        .width(this.scene.width*this.unit()).height(this.scene.height*this.unit()).position({x:(this.card.w*this.scaleFactor-this.scene.width*this.unit())/2,y:(this.card.h*this.scaleFactor-this.scene.height*this.unit())/2})
    }else if(m.kind==='arc'){
      Path().commands(templateArcPath(m,vp2px(this.unit()))).fill(Color.Transparent).stroke(m.color).strokeWidth(m.stroke*this.unit()).strokeLineCap(LineCapStyle.Round)
        .width(this.scene.width*this.unit()).height(this.scene.height*this.unit()).position({x:(this.card.w*this.scaleFactor-this.scene.width*this.unit())/2,y:(this.card.h*this.scaleFactor-this.scene.height*this.unit())/2})
    }else if(m.kind==='circle'){
      Ellipse().fill(m.color).width(m.w*this.unit()).height(m.h*this.unit()).position({x:this.x(m),y:this.y(m)})
    }else{
      Column().width(m.w*this.unit()).height(m.h*this.unit()).backgroundColor(m.stroke?Color.Transparent:m.color)
        .linearGradient({angle:135,colors:m.end?[[m.color,0],[m.end,1]]:[[m.stroke?'#00000000':m.color,0],[m.stroke?'#00000000':m.color,1]]})
        .borderRadius(m.r*this.unit()).border({width:m.stroke*this.unit(),color:m.color})
        .rotate({angle:m.angle}).position({x:this.x(m),y:this.y(m)})
    }
  }
  build(){
    Stack({alignContent:Alignment.TopStart}){
      if(this.scene.surface&&!this.card.template?.fill){Column().width('100%').height('100%').backgroundColor(this.scene.background)}
      ForEach([0,1,2,3],(layer:number)=>{ForEach(this.scene.marks.filter(m=>m.layer===layer),(m:TemplateMark)=>{Stack(){this.mark(m)}.width('100%').height('100%').opacity(m.opacity)});if(layer===0&&/(paper|ledger|slips|sleeve)/.test(this.card.template?.id??'')){Image($rawfile('template-paper.webp')).syncLoad(true).width('100%').height('100%').objectFit(ImageFit.Cover).opacity(.09)}})
    }.width('100%').height('100%').clip(true).hitTestBehavior(HitTestMode.None)
  }
}
