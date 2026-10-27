import { deferStartupReveal, revealStartup, cancelStartupReveal } from '../model/StartupPresentation';
import { startStartupTrace, startupMark } from '../model/StartupTrace';
import { UIAbility, AbilityConstant, Want, Configuration, ConfigurationConstant } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window, display } from '@kit.ArkUI';
import { deviceInfo } from '@kit.BasicServicesKit';
import { lockPhonePortrait } from '../model/DevicePolicy';
import { taskpool } from '@kit.ArkTS';
import { incomingTemplateUri, stageIncomingTemplate, removeStagedTemplate } from '../model/IncomingTemplate';
import { BatteryObserver } from '../model/BatteryObserver';

const TAG: string = 'EntryAbility';

export default class EntryAbility extends UIAbility {
  private backgroundBattery:BatteryObserver=new BatteryObserver();
  private backgroundActive:boolean=false;
  private backgroundRefresh:Promise<void>|null=null;
  private backgroundRefreshPending:boolean=false;
  private refreshBackgroundWidgets():void {
    if(!this.backgroundActive)return;
    if(this.backgroundRefresh){this.backgroundRefreshPending=true;return;}
    const job=(async():Promise<void>=>{
      hilog.info(0,'BatteryRefresh','background refresh started');
      const service=await import('../model/CapabilityService');service.invalidateCapabilityRead('battery');
      if(!this.backgroundActive||AppStorage.get<boolean>('appBackgrounded')!==true)return;
      const widgets=await import('../model/WidgetSync');
      if(this.backgroundActive&&AppStorage.get<boolean>('appBackgrounded')===true){await widgets.refreshStoredWidgets(this.context);hilog.info(0,'BatteryRefresh','background refresh completed');}
    })();this.backgroundRefresh=job;
    job.catch((e:Error)=>hilog.warn(0,TAG,'battery widgets %{public}s',e.message)).finally(()=>{
      if(this.backgroundRefresh===job)this.backgroundRefresh=null;
      if(this.backgroundRefreshPending){this.backgroundRefreshPending=false;this.refreshBackgroundWidgets();}
    });
  }
  private launchPage: string = 'pages/Index';
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    startStartupTrace(); startupMark('ability');
    hilog.info(0x0000, TAG, 'onCreate');
    AppStorage.setOrCreate('appWindowFocused',true);AppStorage.setOrCreate('appBackgrounded', false); this.updateAppearance(this.context.config.colorMode);
    this.routeCard(want);
    this.routeTemplate(want);

  }

  private mainWindow: window.Window | null = null;
  private windowReady: boolean = false;
  private appliedAppearance: boolean | null = null;
  private foldStatusWatching: boolean = false;
  private foldModeWatching: boolean = false;
  private appliedOrientation: window.Orientation | null = null;
  private desiredOrientation: window.Orientation = window.Orientation.PORTRAIT;
  private orientationGeneration: number = 0;
  private orientationUpdating: boolean = false;
  private foldStatusChanged = (status: display.FoldStatus): void => { this.updateOrientation(status); };
  private foldModeChanged = (_mode: display.FoldDisplayMode): void => { this.updateOrientation(); };
  private watchOrientation(): void {
    try {if(display.isFoldable()) {
      if(!this.foldStatusWatching){display.on('foldStatusChange',this.foldStatusChanged);this.foldStatusWatching=true;}
      if(!this.foldModeWatching){display.on('foldDisplayModeChange',this.foldModeChanged);this.foldModeWatching=true;}
    }} catch(e) {hilog.warn(0x0000,TAG,'fold watcher %{public}s',(e as Error).message);}
  }
  private stopOrientation(): void {
    this.orientationGeneration++;this.orientationUpdating=false;this.appliedOrientation=null;
    try {if(this.foldStatusWatching)display.off('foldStatusChange',this.foldStatusChanged);}catch(_){}
    try {if(this.foldModeWatching)display.off('foldDisplayModeChange',this.foldModeChanged);}catch(_){}
    this.foldStatusWatching=false;this.foldModeWatching=false;
  }
  private updateOrientation(eventStatus?: display.FoldStatus): void {
    if(!this.windowReady||!this.mainWindow)return;
    let foldable=false,status=0,mode=0;
    try {foldable=display.isFoldable();if(foldable){status=eventStatus??display.getFoldStatus();mode=display.getFoldDisplayMode();}}
    catch(e) {hilog.warn(0x0000,TAG,'fold query %{public}s',(e as Error).message);}
    this.desiredOrientation=lockPhonePortrait(deviceInfo.deviceType,foldable,status,mode)?window.Orientation.PORTRAIT:window.Orientation.AUTO_ROTATION_UNSPECIFIED;
    if(!this.orientationUpdating&&this.appliedOrientation!==this.desiredOrientation)this.applyOrientation();
  }
  private async applyOrientation(): Promise<void> {
    const target=this.mainWindow,generation=this.orientationGeneration;if(!target)return;
    this.orientationUpdating=true;
    try {
      // Serialize requests: a late unfold result cannot overwrite a newer fold.
      while(generation===this.orientationGeneration&&this.windowReady&&this.appliedOrientation!==this.desiredOrientation) {
        const orientation=this.desiredOrientation;await target.setPreferredOrientation(orientation);
        if(generation!==this.orientationGeneration)return;
        this.appliedOrientation=orientation;
      }
    } catch(e) {if(generation===this.orientationGeneration)this.appliedOrientation=null;hilog.warn(0x0000,TAG,'orientation %{public}s',(e as Error).message);}
    finally {if(generation===this.orientationGeneration)this.orientationUpdating=false;}
  }
  private updateAppearance(mode: ConfigurationConstant.ColorMode | undefined): void {
    const dark = mode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
    AppStorage.setOrCreate('appDark', dark);
    if (this.windowReady && this.mainWindow !== null && this.appliedAppearance !== dark) {
      try {
        this.mainWindow.setWindowBackgroundColor(dark ? '#101113' : '#FFFFFF');
        this.mainWindow.setWindowSystemBarProperties({ statusBarColor: '#00000000', navigationBarColor: '#00000000',
          statusBarContentColor: dark ? '#F1F2F3' : '#202020', navigationBarContentColor: dark ? '#F1F2F3' : '#202020' })
          .catch((e: Error) => {if(this.appliedAppearance===dark)this.appliedAppearance=null;hilog.warn(0x0000, TAG, 'appearance %{public}s', e.message);});
        this.appliedAppearance=dark;
      } catch (e) { hilog.warn(0x0000, TAG, 'appearance window %{public}s', (e as Error).message); }
    }
  }
  onConfigurationUpdate(config: Configuration): void { this.updateAppearance(config.colorMode ?? this.context.config.colorMode); }

  private routeCard(want: Want): void {
    const canvasId = want.parameters?.['canvasId'];
    // A widget opens its bound document without rebinding any other instance.
    AppStorage.setOrCreate('routeCanvasId', typeof canvasId === 'string' ? canvasId : '');
    const dim = want.parameters?.['canvasDimension'];
    AppStorage.setOrCreate('launchFromWidget',typeof canvasId==='string'&&canvasId.length>0&&typeof dim==='string'&&['2*2','2*4','4*4','6*4'].includes(dim));
    AppStorage.setOrCreate('widgetDimension', typeof dim === 'string' && ['2*2', '2*4', '4*4', '6*4'].includes(dim) ? dim : '');
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
    this.backgroundActive=false;
    this.backgroundBattery.stop();
    this.stopOrientation();
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
        this.watchOrientation();this.updateOrientation();
        mainWindow.setImmersiveModeEnabledState(true);
        this.updateAppearance(this.context.config.colorMode);
        const updateInsets = (): void => {
          const ui = mainWindow.getUIContext();
          AppStorage.setOrCreate('safeTop', ui.px2vp(mainWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM).topRect.height));
          AppStorage.setOrCreate('safeBottom', ui.px2vp(mainWindow.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR).bottomRect.height));
        };
        updateInsets();
        mainWindow.on('windowEvent',(event:window.WindowEventType)=>{
          if(event===window.WindowEventType.WINDOW_ACTIVE)AppStorage.setOrCreate('appWindowFocused',true);
          else if(event===window.WindowEventType.WINDOW_INACTIVE||event===window.WindowEventType.WINDOW_HIDDEN)AppStorage.setOrCreate('appWindowFocused',false);
        });
        mainWindow.on('avoidAreaChange', () => updateInsets());
      } catch (e) { hilog.error(0x0000, TAG, 'immersive %{public}s', (e as Error).message); }
      startupMark('content-loaded');
      if (this.launchPage !== 'pages/Index') revealStartup();
      hilog.info(0x0000, TAG, 'loadContent ok');
    });
  }

  onWindowStageDestroy(): void { this.stopOrientation();cancelStartupReveal(); this.appliedAppearance=null;this.windowReady = false; this.mainWindow = null; }

  onForeground(): void {this.backgroundActive=false;this.backgroundBattery.stop(); AppStorage.setOrCreate('appBackgrounded', false); this.updateAppearance(this.context.config.colorMode);this.watchOrientation();this.updateOrientation(); }

  onBackground(): void {
    hilog.info(0,'BatteryRefresh','ability background');
    this.backgroundActive=true;
    AppStorage.setOrCreate('appBackgrounded', true);
    this.backgroundBattery.start(()=>this.refreshBackgroundWidgets());
    this.refreshBackgroundWidgets();
  }
}
