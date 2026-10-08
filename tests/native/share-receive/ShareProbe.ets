import { common } from '@kit.AbilityKit';
import { systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor } from '@kit.ArkData';
import { fileIo, fileUri } from '@kit.CoreFileKit';
@Entry
@Component
struct ShareProbe {
  @State result:string='';
  private async share(fridge:boolean):Promise<void> {
    const context=this.getUIContext().getHostContext() as common.UIAbilityContext;
    const suffix=fridge?'.fridge':'.txt',path=context.cacheDir+'/share_probe'+suffix;
    const file=fileIo.openSync(path,fileIo.OpenMode.CREATE|fileIo.OpenMode.READ_WRITE|fileIo.OpenMode.TRUNC);
    fileIo.writeSync(file.fd,fridge?'{"format":"fridgememo-template","version":1,"kind":"card","state":{"schemaVersion":2,"cards":[{"id":"probe","x":24,"y":24,"w":160,"h":160,"capability":null,"elements":[],"outline":[]}],"canvasId":"probe"},"assets":[]}':'not a fridge');fileIo.closeSync(file.fd);
    const type=uniformTypeDescriptor.getUniformDataTypesByFilenameExtension(suffix)[0];
    this.result=type;
    const data=new systemShare.SharedData({utd:type,uri:fileUri.getUriFromPath(path),title:'Share probe'+suffix});
    await new systemShare.ShareController(data).show(context,{previewMode:systemShare.SharePreviewMode.DETAIL});
  }
  build(){Column({space:24}){Text(this.result).fontSize(18);Button('Fridge').onClick(()=>this.share(true));Button('Text').onClick(()=>this.share(false));}.width('100%').height('100%').justifyContent(FlexAlign.Center)}
}
