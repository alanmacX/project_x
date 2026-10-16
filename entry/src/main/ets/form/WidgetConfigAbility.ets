import { FormEditExtensionAbility } from '@kit.FormKit';
import { UIExtensionContentSession, Want } from '@kit.AbilityKit';
import { widgetDimension } from '../model/WidgetBinding';
/** Hosted by the launcher's native widget editor, never a standalone app activity. */
export default class WidgetConfigAbility extends FormEditExtensionAbility {
  onSessionCreate(want:Want,session:UIExtensionContentSession):void{
    const storage=new LocalStorage();
    const formId=want.parameters?.['cardId']??want.parameters?.['ohos.extra.param.key.form_identity'];
    const previewId=want.parameters?.['previewCardId'];
    storage.setOrCreate('formId',typeof formId==='string'?formId:'');
    storage.setOrCreate('previewFormId',typeof previewId==='string'?previewId:'');
    storage.setOrCreate('dimension',widgetDimension(want.parameters?.['ohos.extra.param.key.form_dimension']));
    session.loadContent('pages/WidgetBinding',storage);
  }
}
