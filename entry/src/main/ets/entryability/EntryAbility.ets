import { deferStartupReveal, revealStartup, cancelStartupReveal } from '../model/StartupPresentation';
import { startStartupTrace, startupMark } from '../model/StartupTrace';
import { UIAbility, AbilityConstant, Want, Configuration, ConfigurationConstant } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { taskpool } from '@kit.ArkTS';
import { incomingTemplateUri, stageIncomingTemplate, removeStagedTemplate } from '../model/IncomingTemplate';

const TAG: string = 'EntryAbility';

export default class EntryAbility extends UIAbility {
  private launchPage: string = 'pages/Index';
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    startStartupTrace(); startupMark('ability');
    hilog.info(0x0000, TAG, 'onCreate');
    AppStorage.setOrCreate('appBackgrounded', false); this.updateAppearance(this.context.config.colorMode);
    this.routeCard(want);
    this.routeTemplate(want);
    if (want.parameters?.['demo'] === 'sketch') this.launchPage = 'pages/SketchLab';
  }

  private mainWindow: window.Window | null = null;
  private windowReady: boolean = false;
  private updateAppearance(mode: ConfigurationConstant.ColorMode | undefined): void {
    const dark = mode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
    AppStorage.setOrCreate('appDark', dark);
    if (this.windowReady && this.mainWindow !== null) {
      try {
        this.mainWindow.setWindowBackgroundColor(dark ? '#101113' : '#FFFFFF');
        this.mainWindow.setWindowSystemBarProperties({ statusBarColor: '#00000000', navigationBarColor: '#00000000',
          statusBarContentColor: dark ? '#F1F2F3' : '#202020', navigationBarContentColor: dark ? '#F1F2F3' : '#202020' })
          .catch((e: Error) => hilog.warn(0x0000, TAG, 'appearance %{public}s', e.message));
      } catch (e) { hilog.warn(0x0000, TAG, 'appearance window %{public}s', (e as Error).message); }
    }
  }
  onConfigurationUpdate(config: Configuration): void { this.updateAppearance(config.colorMode ?? this.context.config.colorMode); }

  private routeCard(want: Want): void {
    const canvasId = want.parameters?.['canvasId'];
    AppStorage.setOrCreate('routeCanvasId', typeof canvasId === 'string' ? canvasId : '');
    const dim = want.parameters?.['canvasDimension'];
    AppStorage.setOrCreate('widgetDimension', typeof dim === 'string' && ['2*4', '4*4', '6*4'].includes(dim) ? dim : '');
    const aspect = Number(want.parameters?.['canvasAspect'] ?? 0);
    AppStorage.setOrCreate('widgetAspect', Number.isFinite(aspect) && aspect >= .3 && aspect <= 3 ? aspect : 0);
    const viewId = want.parameters?.['viewCardId'];
    AppStorage.setOrCreate('viewCardId', typeof viewId === 'string' ? viewId : '');
    const id = want.parameters?.['cardId'];
    AppStorage.setOrCreate('editCardId', typeof id === 'string' ? id : '');
  }

  private incomingGeneration: number = 0;
  private acceptTemplate(uri:string):void {
    const previous=AppStorage.get<string>('incomingTemplateUri')??'';
    if(previous!==uri)removeStagedTemplate(previous,this.context.cacheDir);
    AppStorage.setOrCreate('incomingTemplateUri',uri);
  }
  private async routeTemplate(want: Want): Promise<void> {
    const owned = want.parameters?.['incomingTemplatePath'];
    const prefix = 'file://' + this.context.cacheDir + '/';
    if (typeof owned === 'string' && owned.startsWith(prefix) && /^received_[0-9]+_[0-9]+\.fridge$/.test(owned.slice(prefix.length))) {
      this.incomingGeneration++;
      this.acceptTemplate(owned); return;
    }
    const uri = incomingTemplateUri(want.uri);
    if (!uri || want.action !== 'ohos.want.action.viewData') return;
    const generation = ++this.incomingGeneration;
    try {
      const local = await taskpool.execute(new taskpool.Task(stageIncomingTemplate,uri,this.context.cacheDir)) as string;
      if (generation === this.incomingGeneration) this.acceptTemplate(local);
      else removeStagedTemplate(local,this.context.cacheDir);
    } catch (_) {
      if (generation === this.incomingGeneration) AppStorage.setOrCreate('incomingTemplateError','作品文件无法读取，请保存到本地后从首页导入');
    }
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.routeCard(want);
    this.routeTemplate(want);
  }

  onDestroy(): void {
    hilog.info(0x0000, TAG, 'onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    const mainWindow = windowStage.getMainWindowSync(); this.mainWindow = mainWindow;
    deferStartupReveal(() => windowStage.removeStartingWindow());
    windowStage.loadContent(this.launchPage, (err) => {
      if (err.code) {
        revealStartup();
        hilog.error(0x0000, TAG, 'loadContent failed %{public}s', JSON.stringify(err));
        return;
      }
      this.windowReady = true;
      // Window properties and UIContext insets require loaded content on physical devices.
      try {
        mainWindow.setPreferredOrientation(window.Orientation.AUTO_ROTATION_UNSPECIFIED)
          .catch((e: Error) => hilog.warn(0x0000, TAG, 'orientation %{public}s', e.message));
        mainWindow.setImmersiveModeEnabledState(true);
        this.updateAppearance(this.context.config.colorMode);
        const updateInsets = (): void => {
          const ui = mainWindow.getUIContext();
          AppStorage.setOrCreate('safeTop', ui.px2vp(mainWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM).topRect.height));
          AppStorage.setOrCreate('safeBottom', ui.px2vp(mainWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR).bottomRect.height));
        };
        updateInsets();
        mainWindow.on('avoidAreaChange', () => updateInsets());
      } catch (e) { hilog.error(0x0000, TAG, 'immersive %{public}s', (e as Error).message); }
      startupMark('content-loaded');
      if (this.launchPage !== 'pages/Index') revealStartup();
      hilog.info(0x0000, TAG, 'loadContent ok');
    });
  }

  onWindowStageDestroy(): void { cancelStartupReveal(); this.windowReady = false; this.mainWindow = null; }

  onForeground(): void { AppStorage.setOrCreate('appBackgrounded', false); this.updateAppearance(this.context.config.colorMode); }

  onBackground(): void { AppStorage.setOrCreate('appBackgrounded', true); }
}
