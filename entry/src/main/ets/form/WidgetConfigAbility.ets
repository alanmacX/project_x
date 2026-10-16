import { FormEditExtensionAbility } from '@kit.FormKit';
import { UIExtensionContentSession, Want } from '@kit.AbilityKit';
import { registerWidget, widgetDimension } from '../model/WidgetRegistry';
/** Each launcher session gets its own real ID, preview ID and authoritative size. */
export default class WidgetConfigAbility extends FormEditExtensionAbility {
  onSessionCreate(want:Want,session:UIExtensionContentSession):void{this.prepare(want,session);}
  private async prepare(want:Want,session:UIExtensionContentSession):Promise<void>{
    const storage=new LocalStorage(),value=want.parameters?.['cardId']??want.parameters?.['ohos.extra.param.key.form_identity'];
    const preview=want.parameters?.['previewCardId'];
    const id=typeof value==='string'?value:'',previewId=typeof preview==='string'&&preview!==id?preview:'';
    storage.setOrCreate('formId',id);storage.setOrCreate('previewFormId',previewId);
    try{
      const instance=await registerWidget(this.context,id,widgetDimension(want.parameters?.['ohos.extra.param.key.form_dimension']));
      if(previewId)await registerWidget(this.context,previewId,instance.dimension,id,true);
      storage.setOrCreate('dimension',instance.dimension);
    }catch(e){storage.setOrCreate('sessionError',(e as Error).message);}
    session.loadContent('pages/WidgetBinding',storage);
  }
}
