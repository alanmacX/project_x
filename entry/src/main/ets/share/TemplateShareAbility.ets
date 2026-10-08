import { ShareExtensionAbility, Want, UIExtensionContentSession } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { systemShare } from '@kit.ShareKit';
import { sharedTemplateUri } from '../model/IncomingTemplate';

export default class TemplateShareAbility extends ShareExtensionAbility {
  onSessionCreate(want: Want, session: UIExtensionContentSession): void {
    systemShare.getSharedData(want).then((data: systemShare.SharedData) => {
      const records = data.getRecords();
      records.forEach((record:systemShare.SharedRecord)=>hilog.info(0,'TemplateReceive','type=%{public}s uriFile=%{public}s',record.utd,String(record.uri?.startsWith('file://'))));
      const uri = records.length === 1 ? sharedTemplateUri(records[0].utd, records[0].uri) : '';
      const storage = new LocalStorage(); storage.setOrCreate('incomingUri',uri);storage.setOrCreate('session',session);
      session.loadContent('pages/ReceiveTemplate', storage);
    }).catch(() => {
      const storage = new LocalStorage(); storage.setOrCreate('incomingUri','');storage.setOrCreate('session',session);
      session.loadContent('pages/ReceiveTemplate', storage);
    });
  }
}
