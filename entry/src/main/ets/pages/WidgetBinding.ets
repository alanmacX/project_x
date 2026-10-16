import { common } from '@kit.AbilityKit';
import { LengthMetrics } from '@kit.ArkUI';
import { BindableCanvas, bindingCanvases, bindWidget } from '../model/WidgetBinding';
import { widgetInstance } from '../model/WidgetRegistry';
import { cachedGalleryPreview } from '../model/GalleryPreviewCache';
import { AppDesign } from '../model/AppDesign';
class BindingChoice extends BindableCanvas {preview:string='';}
/** Compact selection rows inside the system-owned editor, with no nested app chrome. */
@Entry
@Component
struct WidgetBinding {
  private formId:string='';
  private previewFormId:string='';
  @State dimension:string='';
  @State choices:BindingChoice[]=[];
  @State selectedId:string='';
  @State appDark:boolean=false;
  @State busy:boolean=false;
  @State error:string='';
  @State ready:boolean=false;
  private alive:boolean=false;
  private context():common.FormEditExtensionContext{return this.getUIContext().getHostContext() as common.FormEditExtensionContext;}
  aboutToAppear():void{
    const storage=this.getUIContext().getSharedLocalStorage();
    this.formId=storage?.get<string>('formId')??'';this.previewFormId=storage?.get<string>('previewFormId')??'';
    this.dimension=storage?.get<string>('dimension')??'';this.error=storage?.get<string>('sessionError')??'';
    this.alive=true;if(!this.error)this.load();
  }
  aboutToDisappear():void{this.alive=false;}
  private async load():Promise<void>{
    try{
      const context=this.context();this.appDark=context.config.colorMode===0;
      const instance=await widgetInstance(context,this.formId);
      if(!instance||instance.removed||!instance.dimension)throw new Error('小组件尚未就绪，请重新打开编辑');
      this.dimension=instance.dimension;
      const entries=await bindingCanvases(context),items:BindingChoice[]=[];
      for(const entry of entries.filter(c=>c.dimension===instance.dimension)){
        const item=new BindingChoice();item.id=entry.id;item.name=entry.name;item.dimension=entry.dimension;
        item.aspect=entry.aspect;item.cardCount=entry.cardCount;item.preview=(await cachedGalleryPreview(context.cacheDir,entry.id))?.path??'';items.push(item);
      }
      if(!this.alive)return;this.choices=items;this.selectedId=items.some(c=>c.id===instance.canvasId)?instance.canvasId:'';this.ready=true;
      if(instance.canvasId&&!this.selectedId)this.error='原画布已失效或尺寸不符，请重新选择。';
      if(this.selectedId&&this.previewFormId){try{await bindWidget(context,this.previewFormId,this.selectedId,this.dimension);}catch(_){/* Real binding is unchanged if a temporary preview closes. */}}
    }catch(e){if(this.alive)this.error=(e as Error).message;}
  }
  private async choose(id:string):Promise<void>{
    if(this.busy||!this.ready)return;this.busy=true;this.error='';
    try{
      await bindWidget(this.context(),this.formId,id,this.dimension);
      if(!this.alive)return;this.selectedId=id;
      if(this.previewFormId){try{await bindWidget(this.context(),this.previewFormId,id,this.dimension);}catch(_){if(this.alive)this.error='画布已绑定，系统预览暂未刷新。';}}
    }catch(e){if(this.alive)this.error=(e as Error).message;}finally{this.busy=false;}
  }
  @Builder
  canvasChoice(item:BindingChoice){
    Button({type:ButtonType.ROUNDED_RECTANGLE,buttonStyle:ButtonStyleMode.NORMAL}){
      Row({space:12}){
        Stack(){
          if(item.preview){Image(item.preview).width('100%').height('100%').objectFit(ImageFit.Contain)}
          else{SymbolGlyph($r('sys.symbol.square_stack_3d')).fontSize(22).fontColor([AppDesign.muted(this.appDark)])}
        }.width(44).height(44).borderRadius(10).backgroundColor(AppDesign.surface(this.appDark)).clip(true)
        Column({space:3}){
          Text(item.name).fontSize(15).fontWeight(FontWeight.Medium).fontColor(AppDesign.text(this.appDark)).maxLines(1).textOverflow({overflow:TextOverflow.Ellipsis}).width('100%')
          Text(item.cardCount+' 张卡片').fontSize(12).fontColor(AppDesign.muted(this.appDark)).width('100%')
        }.layoutWeight(1).alignItems(HorizontalAlign.Start)
        Stack(){
          if(item.id===this.selectedId){SymbolGlyph($r('sys.symbol.checkmark')).fontSize(13).fontColor([AppDesign.onSelected(this.appDark)])}
        }.width(22).height(22).borderRadius(11)
          .backgroundColor(item.id===this.selectedId?AppDesign.selected(this.appDark):Color.Transparent)
          .border({width:item.id===this.selectedId?0:1,color:AppDesign.muted(this.appDark)})
      }.width('100%').padding({left:12,right:12,top:8,bottom:8})
    }.width('100%').height(60).padding(0).borderRadius(14)
      .backgroundColor(item.id===this.selectedId?AppDesign.control(this.appDark):Color.Transparent).enabled(!this.busy)
      .onClick(()=>this.choose(item.id)).accessibilityText('绑定 '+item.name+(item.id===this.selectedId?'，已选中':''))
  }
  build(){
    Column({space:8}){
      Row(){
        Text('选择画布').fontSize(16).fontWeight(FontWeight.Medium).fontColor(AppDesign.text(this.appDark)).layoutWeight(1)
        if(this.dimension){Text(this.dimension.replace('*','×')).fontSize(12).fontColor(AppDesign.muted(this.appDark)).padding({left:8,right:8,top:3,bottom:3}).borderRadius(8).backgroundColor(AppDesign.surface(this.appDark))}
      }.width('100%')

      if(!this.ready&&!this.error){LoadingProgress().width(28).height(28).layoutWeight(1)}
      else if(this.ready&&!this.choices.length){
        Column({space:6}){
          Text('还没有这个尺寸的画布').fontSize(15).fontColor(AppDesign.text(this.appDark))
          Text('先在 App 中创建 '+this.dimension.replace('*','×')+' 画布，再回来选择。').fontSize(12).fontColor(AppDesign.muted(this.appDark)).textAlign(TextAlign.Center)
        }.width('100%').layoutWeight(1).justifyContent(FlexAlign.Center)
      }else{
        List({space:4}){ForEach(this.choices,(item:BindingChoice)=>{ListItem(){this.canvasChoice(item)}},(item:BindingChoice)=>item.id)}
          .width('100%').layoutWeight(1).scrollBar(BarState.Auto).edgeEffect(EdgeEffect.None).fadingEdge(true,{fadingEdgeLength:LengthMetrics.vp(8)})
      }
      if(this.error){Text(this.error).fontColor('#D3423C').fontSize(12).maxLines(2).width('100%')}
    }.width('100%').height('100%').padding({left:16,right:16,top:12,bottom:8}).backgroundColor(this.appDark?'#2F3032':'#F4F5F7')
  }
}
