import { common, ConfigurationConstant, UIExtensionContentSession } from '@kit.AbilityKit';
import { taskpool } from '@kit.ArkTS';
import { stageIncomingTemplate, removeStagedTemplate } from '../model/IncomingTemplate';
import { inspectTemplate } from '../model/TemplateFiles';
import { TemplateSummary } from '../model/TemplatePackage';
import { AppDesign } from '../model/AppDesign';

@Entry
@Component
struct ReceiveTemplate {
  private uri: string = '';
  private session: UIExtensionContentSession | undefined = undefined;
  @StorageLink('appDark') dark: boolean = false;
  @State message: string = '正在检查作品';
  @State title: string = '收到作品';
  @State ready: boolean = false;
  @State opening: boolean = false;
  private ownedUri: string = '';
  private alive: boolean = true;
  private transferred: boolean = false;
  private cacheDir: string = '';
  private releaseCopy(): void { if(!this.transferred && this.ownedUri) {removeStagedTemplate(this.ownedUri,this.cacheDir);this.ownedUri='';} }
  aboutToAppear(): void { const storage=this.getUIContext().getSharedLocalStorage();this.uri=storage?.get<string>('incomingUri')??'';this.session=storage?.get<UIExtensionContentSession>('session');this.prepare(); }
  aboutToDisappear(): void { this.alive = false; this.releaseCopy(); }
  private async prepare(): Promise<void> {
    const context = this.getUIContext().getHostContext() as common.UIExtensionContext;
    if(context){this.cacheDir=context.cacheDir;}
    if(context)this.dark=context.config.colorMode===ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
    if (!context || !this.uri) { this.message = '请分享一个冰箱贴 .fridge 作品文件'; return; }
    try {
      this.ownedUri = await taskpool.execute(new taskpool.Task(stageIncomingTemplate,this.uri,context.cacheDir)) as string;
      const summary = JSON.parse(await taskpool.execute(new taskpool.Task(inspectTemplate,this.ownedUri)) as string) as TemplateSummary;
      if (!this.alive) {this.releaseCopy();return;}
      this.title = summary.kind === 'card' ? '收到卡片' : '收到画布';
      this.message = summary.count + ' 张卡片 · ' + summary.images + ' 个素材\n打开后选择添加，不会覆盖现有作品。';
      this.ready = true;
    } catch (e) { this.releaseCopy(); if (this.alive) this.message = (e as Error).message; }
  }
  private async open(): Promise<void> {
    if (!this.ready || this.opening) return;
    const context = this.getUIContext().getHostContext() as common.UIExtensionContext;
    this.opening = true; this.transferred=true;
    try {
      await context.startAbility({bundleName:context.applicationInfo.name,abilityName:'EntryAbility',parameters:{incomingTemplatePath:this.ownedUri}});
      this.session?.terminateSelf().catch(()=>{});
    } catch (_) { this.transferred=false;if(!this.alive)this.releaseCopy();this.message = '未能打开，请重试'; }
    finally { this.opening = false; }
  }
  build() {
    Column({space:24}) {
      Column({space:12}) {
        Text(this.title).fontSize(24).fontWeight(FontWeight.Medium).fontColor(AppDesign.text(this.dark))
        Text(this.message).fontSize(14).fontColor(AppDesign.muted(this.dark)).textAlign(TextAlign.Center).lineHeight(24)
      }.width('100%').padding(24).borderRadius(24).backgroundColor(AppDesign.surface(this.dark))
      Button(this.opening?'打开中':'在冰箱贴中打开',{type:ButtonType.Capsule})
        .height(48).width('100%').enabled(this.ready&&!this.opening).onClick(()=>this.open())
    }.width('100%').height('100%').padding(24).justifyContent(FlexAlign.Center).backgroundColor(AppDesign.background(this.dark))
  }
}
