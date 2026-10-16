import { InstantShapeGenerator, ShapeInfo } from '@kit.Penkit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AppDesign } from '../model/AppDesign';
import { SettingsSegmented } from '../views/SettingsSegmented';
import { beautifyContour, SketchCurve, SketchPoint, roughSketchSample, sketchDistance } from '../model/SketchContour';

class SketchDraft {
  raw:SketchPoint[]=[];
  curve:SketchCurve={start:{x:0,y:0},segments:[],closed:false,anchors:[]};
  width:number=1; height:number=1;
  recognized:Path2D|null=null; shapeString:string=''; shapeType:number=0;
}

/** Isolated drawing experiment. No FridgeStore, network request or modification of user cards. */
@Entry
@Component
struct SketchLab {
  @StorageLink('appDark') dark:boolean=false;
  @StorageLink('safeTop') safeTop:number=24;
  @StorageLink('safeBottom') safeBottom:number=20;
  @State screenWidth:number=0;
  @State screenHeight:number=0;
  @State mode:number=0;
  @State penOnly:boolean=false;
  @State compare:boolean=false;
  @State filled:boolean=true;
  @State hasDraft:boolean=false;
  @State canUndo:boolean=false;
  @State canRedo:boolean=false;
  @State status:string='画一个闭合轮廓，抬笔后自动柔化';
  @State engineState:string='系统识别初始化中';
  @State metrics:string='';
  private ink:CanvasRenderingContext2D=new CanvasRenderingContext2D(new RenderingContextSettings(true));
  private preview:CanvasRenderingContext2D=new CanvasRenderingContext2D(new RenderingContextSettings(true));
  private engine:InstantShapeGenerator|undefined=undefined;
  private engineEpoch:number=0;
  private draft:SketchDraft=new SketchDraft();
  private previous:SketchDraft|null=null;
  private undone:SketchDraft|null=null;
  private points:SketchPoint[]=[];
  @State private pointer:number=-1;
  private drawWidth:number=1; private drawHeight:number=1;
  private previewWidth:number=1; private previewHeight:number=1;
  private inkReady:boolean=false; private previewReady:boolean=false;
  private candidate:ShapeInfo|null=null;
  private candidatePoint:SketchPoint|null=null;

  aboutToAppear():void {this.resetEngine();}
  aboutToDisappear():void {this.disposeEngine();}
  onPageHide():void {this.cancelStroke();this.disposeEngine();}
  private disposeEngine():void {
    this.engineEpoch++;try{this.engine?.release();}catch(_e){}this.engine=undefined;
  }
  private resetEngine():void {
    this.disposeEngine();const epoch=this.engineEpoch;
    try {
      this.engine=new InstantShapeGenerator();this.engine.setPauseTime(350);
      this.engine.notifyAreaChange(this.drawWidth,this.drawHeight);
      this.engine.onShapeRecognized((shape:ShapeInfo)=>{
        if(epoch!==this.engineEpoch||this.pointer<0||this.mode!==1||shape.shapeType===0)return;
        this.candidate=shape;this.candidatePoint=this.points[this.points.length-1]??null;
        this.status='已识别'+this.shapeName(shape.shapeType)+' · 抬笔采用，继续画可取消';
        hilog.info(0x0000,'SketchLab','native recognized type=%{public}d',shape.shapeType);
      });
      this.engineState='Pen Kit 已就绪';
    } catch(_e) {this.engineState='系统识别不可用 · 自由平滑仍可使用';this.disposeEngine();}
  }
  private shapeName(type:number):string {
    if(type===1)return '直线';if(type===2)return '椭圆';if(type===6)return '矩形';
    if([10,11].includes(type))return '三角形';if(type===12)return '五角星';return '规整图形';
  }
  private landscape():boolean {return this.screenWidth>this.screenHeight && this.screenWidth>600;}
  private hint():string {return this.mode===0?'画一个闭合轮廓，抬笔后自动柔化':'画完停留约半秒再抬笔，系统会尝试一笔成形';}
  private switchMode(mode:number):void {this.cancelStroke();this.mode=mode;this.candidate=null;this.resetEngine();this.status=this.hint();}
  private cancelStroke():void {if(this.pointer>=0){this.pointer=-1;this.points=[];this.candidate=null;this.candidatePoint=null;this.disposeEngine();this.redraw();}}
  private area(width:number,height:number):void {
    if(width<1||height<1)return;
    if(Math.abs(width-this.drawWidth)<.1 && Math.abs(height-this.drawHeight)<.1)return;
    this.cancelStroke();this.drawWidth=width;this.drawHeight=height;
    try{this.engine?.notifyAreaChange(width,height);}catch(_e){this.resetEngine();}
    this.redraw();
  }
  private path(curve:SketchCurve):Path2D {
    // SVG string construction uses physical pixels; explicit path commands preserve Canvas vp coordinates.
    const path=new Path2D();path.moveTo(curve.start.x,curve.start.y);
    curve.segments.forEach((s)=>path.bezierCurveTo(s.c1.x,s.c1.y,s.c2.x,s.c2.y,s.end.x,s.end.y));
    if(curve.closed)path.closePath();return path;
  }
  private paint(ctx:CanvasRenderingContext2D,width:number,height:number,thumbnail:boolean):void {
    ctx.clearRect(0,0,width,height);if(!this.hasDraft)return;
    const d=this.draft,xs=d.raw.map((p)=>p.x),ys=d.raw.map((p)=>p.y);
    const left=thumbnail?Math.min(...xs):0,top=thumbnail?Math.min(...ys):0;
    const contentWidth=thumbnail?Math.max(1,Math.max(...xs)-left):d.width,contentHeight=thumbnail?Math.max(1,Math.max(...ys)-top):d.height;
    const inset=thumbnail?24:0,scale=Math.max(.01,Math.min((width-inset)/contentWidth,(height-inset)/contentHeight));
    ctx.save();ctx.translate((width-contentWidth*scale)/2-left*scale,(height-contentHeight*scale)/2-top*scale);ctx.scale(scale,scale);
    ctx.lineCap='round';ctx.lineJoin='round';ctx.lineWidth=(thumbnail?2.5:2)/scale;
    if(this.compare && !thumbnail) {
      ctx.strokeStyle=this.dark?'#73726C':'#B9B6AE';ctx.beginPath();
      d.raw.forEach((p,i)=>{if(i===0)ctx.moveTo(p.x,p.y);else ctx.lineTo(p.x,p.y);});ctx.stroke();
    }
    const path=d.recognized??this.path(d.curve);
    const closed=d.recognized?[2,6,7,9,10,11,12,13].includes(d.shapeType):d.curve.closed;
    if(closed && this.filled){ctx.fillStyle='#E6D8B9';ctx.fill(path);}
    ctx.strokeStyle=this.dark?'#EFE9DA':'#49483E';ctx.stroke(path);ctx.restore();
  }
  private redraw():void {
    if(this.inkReady)this.paint(this.ink,this.drawWidth,this.drawHeight,false);
    if(this.previewReady)this.paint(this.preview,this.previewWidth,this.previewHeight,true);
  }
  private take(points:SketchPoint[],sample:boolean=false):void {
    this.previous=this.hasDraft?this.draft:null;
    const before=Date.now(),draft=new SketchDraft();draft.raw=points.map((p):SketchPoint=>({x:p.x,y:p.y}));
    draft.width=this.drawWidth;draft.height=this.drawHeight;draft.curve=beautifyContour(points);
    if(!sample && this.mode===1 && this.candidate) {
      draft.recognized=this.candidate.shapePath;draft.shapeType=this.candidate.shapeType;draft.shapeString=this.candidate.shapeString;
    }
    this.draft=draft;this.hasDraft=points.length>0;this.canUndo=true;this.canRedo=false;this.undone=null;
    this.metrics=points.length+' 个采样 → '+draft.curve.anchors.length+' 个锚点 · '+(Date.now()-before)+' ms';
    this.status=draft.recognized?'系统已整理为'+this.shapeName(draft.shapeType):draft.curve.closed?'轮廓已柔化 · 保留自由形状':'线条已柔化 · 画闭合轮廓可预览底板';
    if(sample)this.status='示例仅验证自由平滑；系统识别请亲手画并停笔';
    this.redraw();
  }
  private addPoint(point:TouchObject):void {
    const p:SketchPoint={x:Math.max(0,Math.min(this.drawWidth,point.x)),y:Math.max(0,Math.min(this.drawHeight,point.y))};
    const last=this.points[this.points.length-1];if(last && sketchDistance(last,p)<.45)return;
    // Bound storage without decimating visible ink. Expensive curve fitting happens only on lift.
    if(this.points.length>=4096)this.points=this.points.filter((_p,i)=>i%2===0);
    this.points.push(p);this.ink.beginPath();this.ink.moveTo(last?.x??p.x,last?.y??p.y);
    this.ink.lineTo(p.x,p.y);this.ink.stroke();
    if(this.candidatePoint && sketchDistance(this.candidatePoint,p)>4){this.candidate=null;this.candidatePoint=null;this.status=this.hint();}
  }
  private touch(event:TouchEvent):void {
    event.stopPropagation();
    if(event.type===TouchType.Cancel){this.cancelStroke();return;}
    if(!this.inkReady || (this.penOnly && event.sourceTool!==SourceTool.Pen))return;
    const point=event.changedTouches.find((p)=>this.pointer<0||p.id===this.pointer);
    if(!point)return;
    if(event.type===TouchType.Down) {
      if(this.pointer>=0||event.touches.length>1)return;
      this.pointer=point.id;this.points=[];this.candidate=null;this.candidatePoint=null;
      if(this.mode===1)this.resetEngine();else this.disposeEngine();
      this.ink.clearRect(0,0,this.drawWidth,this.drawHeight);
      this.ink.lineCap='round';this.ink.lineJoin='round';this.ink.lineWidth=2.5;
      this.ink.strokeStyle=this.dark?'#EFE9DA':'#49483E';this.status=this.hint();
    }
    if(this.pointer!==point.id)return;
    try {const history=event.getHistoricalPoints();history.forEach((p)=>{if(p.touchObject.id===this.pointer)this.addPoint(p.touchObject);});}catch(_e){}
    this.addPoint(point);
    if(this.mode===1){try{this.engine?.processTouchEvent(event);}catch(_e){this.engineState='系统识别不可用 · 已保留自由平滑';this.disposeEngine();}}
    if(event.type===TouchType.Up) {
      this.pointer=-1;if(this.points.length>1)this.take(this.points);else this.redraw();
      this.points=[];this.candidate=null;this.disposeEngine();
    }
  }
  private sample(kind:string):void {this.cancelStroke();this.take(roughSketchSample(kind,this.drawWidth,this.drawHeight),true);}
  private undo():void {
    this.cancelStroke();if(!this.canUndo)return;this.undone=this.draft;this.draft=this.previous??new SketchDraft();
    this.hasDraft=this.draft.raw.length>0;this.canUndo=false;this.canRedo=true;this.status='已撤销';this.redraw();
  }
  private redo():void {if(!this.undone)return;this.draft=this.undone;this.hasDraft=this.draft.raw.length>0;this.canUndo=true;this.canRedo=false;this.status='已重做';this.redraw();}
  private clear():void {
    this.cancelStroke();this.disposeEngine();this.previous=this.hasDraft?this.draft:null;this.draft=new SketchDraft();
    this.hasDraft=false;this.canUndo=this.previous!==null;this.canRedo=false;this.undone=null;this.metrics='';this.status=this.hint();this.redraw();
  }
  @Builder
  tool(title:string,symbol:Resource,action:()=>void) {
    Button({type:ButtonType.Circle,buttonStyle:ButtonStyleMode.NORMAL,role:title==='清空'?ButtonRole.ERROR:ButtonRole.NORMAL}) {
      SymbolGlyph(symbol).fontSize(20).fontColor([title==='清空'?'#C43A35':AppDesign.text(this.dark)]).hitTestBehavior(HitTestMode.None)
    }.width(44).height(44).backgroundColor(AppDesign.surface(this.dark)).enabled(title==='撤销'?this.canUndo:title==='重做'?this.canRedo:title==='清空'?this.hasDraft:true).accessibilityText(title).onClick(action)
  }
  @Builder
  drawing() {
    Stack({alignContent:Alignment.TopStart}) {
      Canvas(this.ink).width('100%').height('100%').onReady(()=>{this.inkReady=true;this.redraw();})
        .onAreaChange((_old,area)=>this.area(Number(area.width),Number(area.height)))
        .onTouch((event:TouchEvent)=>this.touch(event))
      if(!this.hasDraft && this.pointer<0) {
        Column({space:8}) {
          Text('画出你的卡片').fontSize(22).fontWeight(FontWeight.Medium).fontColor(AppDesign.text(this.dark))
          Text('手写笔或手指都可以，先试一个自由轮廓').fontSize(13).fontColor(AppDesign.muted(this.dark))
        }.width('100%').height('100%').justifyContent(FlexAlign.Center).hitTestBehavior(HitTestMode.None)
      }
    }.width('100%').height('100%').backgroundColor(AppDesign.surface(this.dark)).borderRadius(24).clip(true)
  }
  @Builder
  inspector() {
    Column({space:12}) {
      Row() {Text('底板预览').fontSize(16).fontWeight(FontWeight.Medium).fontColor(AppDesign.text(this.dark)).layoutWeight(1);Text('独立实验').fontSize(12).fontColor(AppDesign.muted(this.dark))}.width('100%')
      Canvas(this.preview).width('100%').layoutWeight(1).onReady(()=>{this.previewReady=true;this.redraw();})
        .onAreaChange((_old,area)=>{this.previewWidth=Number(area.width);this.previewHeight=Number(area.height);this.redraw();})
      Row() {Text('仅手写笔').fontSize(14).fontColor(AppDesign.text(this.dark)).layoutWeight(1);Toggle({type:ToggleType.Switch,isOn:this.penOnly}).onChange((v)=>{this.cancelStroke();this.penOnly=v;})}.width('100%')
      Row() {Text('对比原稿').fontSize(14).fontColor(AppDesign.text(this.dark)).layoutWeight(1);Toggle({type:ToggleType.Switch,isOn:this.compare}).onChange((v)=>{this.compare=v;this.redraw();})}.width('100%')
      Row() {Text('预览填色').fontSize(14).fontColor(AppDesign.text(this.dark)).layoutWeight(1);Toggle({type:ToggleType.Switch,isOn:this.filled}).onChange((v)=>{this.filled=v;this.redraw();})}.width('100%')
      Text(this.metrics).fontSize(11).fontColor(AppDesign.muted(this.dark)).width('100%').maxLines(2)
      Text(this.engineState).fontSize(11).fontColor(AppDesign.muted(this.dark)).width('100%').maxLines(2)
    }.width('100%').height('100%').padding(16).backgroundColor(AppDesign.surface(this.dark)).borderRadius(20)
  }
  build() {
    Column({space:16}) {
      Row({space:8}) {
        this.tool('返回',$r('sys.symbol.chevron_left'),()=>{this.getUIContext().getRouter().replaceUrl({url:'pages/Index'});})
        Text('手绘实验').fontSize(18).fontWeight(FontWeight.Medium).fontColor(AppDesign.text(this.dark)).layoutWeight(1)
        this.tool('撤销',$r('sys.symbol.arrowshape_turn_up_left'),()=>this.undo())
        this.tool('重做',$r('sys.symbol.arrowshape_turn_up_right'),()=>this.redo())
        this.tool('清空',$r('sys.symbol.trash'),()=>this.clear())
      }.width('100%')
      SettingsSegmented({labels:['自由轮廓','一笔成形'],selectedIndex:this.mode,appDark:this.dark,onSelect:(index:number)=>this.switchMode(index)}).width('100%')
      Text(this.status).fontSize(13).fontColor(AppDesign.muted(this.dark)).width('100%').height(36).maxLines(2)
      if(this.landscape()) {
        Row({space:16}) {Column(){this.drawing()}.layoutWeight(1).height('100%');Column(){this.inspector()}.width('30%').height('100%')}.width('100%').layoutWeight(1)
      } else {
        Column({space:16}) {Column(){this.drawing()}.width('100%').layoutWeight(1.8);Column(){this.inspector()}.width('100%').layoutWeight(1)}.width('100%').layoutWeight(1)
      }
      Button('试画示例',{type:ButtonType.Capsule,buttonStyle:ButtonStyleMode.NORMAL,role:ButtonRole.NORMAL})
        .height(44).fontSize(14).fontColor(AppDesign.text(this.dark)).backgroundColor(AppDesign.surface(this.dark))
        .bindMenu([{value:'粗略椭圆',action:()=>this.sample('oval')},{value:'自由边缘',action:()=>this.sample('leaf')}])
    }.width('100%').height('100%').padding({top:this.safeTop+8,bottom:this.safeBottom+8,left:20,right:20})
      .backgroundColor(AppDesign.background(this.dark))
      .onAreaChange((_old,area)=>{this.screenWidth=Number(area.width);this.screenHeight=Number(area.height);})
  }
}
