import { common } from '@kit.AbilityKit';
import { BindableCanvas, bindingCanvases, bindWidget } from '../model/WidgetBinding';
import { cachedGalleryPreview } from '../model/GalleryPreviewCache';
import { AppDesign } from '../model/AppDesign';
import preferences from '@ohos.data.preferences';
class BindingChoice extends BindableCanvas {preview:string='';}
/** Only the edit region; the system owns size selection, preview, title and Done. */
@Entry
@Component
struct WidgetBinding {
  private formId:string='';
  private previewFormId:string='';
  @State dimension:string='4*4';
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
    this.formId=storage?.get<string>('formId')??'';this.previewFormId=storage?.get<string>('previewFormId')??'';this.dimension=storage?.get<string>('dimension')??'4*4';
    this.alive=true;this.load();
  }
  aboutToDisappear():void{this.alive=false;}
  private async load():Promise<void>{
    try{
      const context=this.context();this.appDark=context.config.colorMode===0;
      const entries=await bindingCanvases(context),items:BindingChoice[]=[];
      for(const entry of entries){const item=new BindingChoice();item.id=entry.id;item.name=entry.name;item.dimension=entry.dimension;item.aspect=entry.aspect;item.preview=(await cachedGalleryPreview(context.cacheDir,entry.id))?.path??'';items.push(item);}
      if(!this.alive)return;this.choices=items;
      const prefs=await preferences.getPreferences(context,'fridge_store');
      const dims=JSON.parse(await prefs.get('fridge_form_dims_json','{}') as string) as Record<string,string>;
      this.dimension=dims[this.formId]??dims[this.previewFormId]??this.dimension;
      const bindings=JSON.parse(await prefs.get('fridge_form_bindings_json','{}') as string) as Record<string,string>;
      this.selectedId=bindings[this.formId]??'';this.ready=true;
    }catch(e){this.error=(e as Error).message;}
  }
  private async choose(id:string):Promise<void>{
    if(this.busy)return;this.busy=true;this.error='';
    try{
      // The launcher has a second temporary form for its native live preview.
      await bindWidget(this.context(),this.formId,id,this.dimension);
      this.selectedId=id;
      if(this.previewFormId&&this.previewFormId!==this.formId)await bindWidget(this.context(),this.previewFormId,id,this.dimension);
    }catch(e){this.error=(e as Error).message;}finally{this.busy=false;}
  }
  build(){
    Scroll(){
      Column({space:12}){
        Text('绑定画布').fontSize(18).fontWeight(FontWeight.Medium).fontColor(AppDesign.text(this.appDark)).width('100%')
        Text(this.dimension.replace('*','×')+' · 选择这个小组件显示的画布').fontSize(13).fontColor(AppDesign.muted(this.appDark)).width('100%')
        if(this.ready&&this.choices.filter(c=>c.dimension===this.dimension).length===0){
          Text('还没有这个尺寸的画布，请先在 App 中创建。').fontSize(15).fontColor(AppDesign.muted(this.appDark)).padding({top:16,bottom:16})
        }
        ForEach(this.choices.filter((c:BindingChoice)=>c.dimension===this.dimension),(item:BindingChoice)=>{
          Button({type:ButtonType.ROUNDED_RECTANGLE,buttonStyle:ButtonStyleMode.NORMAL}){
            Row({space:12}){
              if(item.preview){Image(item.preview).width(48).height(48/item.aspect).objectFit(ImageFit.Contain).borderRadius(8)}
              Text(item.name).fontSize(16).fontColor(AppDesign.text(this.appDark)).layoutWeight(1).textAlign(TextAlign.Start)
              if(item.id===this.selectedId){SymbolGlyph($r('sys.symbol.checkmark')).fontSize(18).fontColor([AppDesign.text(this.appDark)])}
            }.width('100%').padding(12)
          }.width('100%').constraintSize({minHeight:48}).backgroundColor(AppDesign.surface(this.appDark)).borderRadius(14)
            .border({width:item.id===this.selectedId?1.5:0,color:AppDesign.text(this.appDark)}).enabled(!this.busy)
            .onClick(()=>this.choose(item.id)).accessibilityText('绑定 '+item.name+(item.id===this.selectedId?'，已选中':''))
        },(item:BindingChoice)=>item.id)
        if(this.error){Text(this.error).fontColor('#D3423C').fontSize(14).width('100%')}
      }.width('100%').padding(16)
    }.width('100%').height('100%').align(Alignment.Top).backgroundColor(AppDesign.background(this.appDark))
  }
}
