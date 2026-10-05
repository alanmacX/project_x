import { ShareExtensionAbility, Want, UIExtensionContentSession } from '@kit.AbilityKit';
import { systemShare } from '@kit.ShareKit';
import { incomingTemplateUri } from '../model/IncomingTemplate';

export default class TemplateShareAbility extends ShareExtensionAbility {
  onSessionCreate(want: Want, session: UIExtensionContentSession): void {
    systemShare.getSharedData(want).then((data: systemShare.SharedData) => {
      const records = data.getRecords();
      const uri = records.length === 1 ? incomingTemplateUri(records[0].uri) : '';
      const storage = new LocalStorage(); storage.setOrCreate('incomingUri',uri);
      session.loadContent('pages/ReceiveTemplate', storage);
    }).catch(() => {
      const storage = new LocalStorage(); storage.setOrCreate('incomingUri','');
      session.loadContent('pages/ReceiveTemplate', storage);
    });
  }
}
