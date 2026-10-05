import { HdsColorPicker } from '@kit.UIDesignKit';
import { deviceInfo } from '@kit.BasicServicesKit';
import { AppDesign } from '../model/AppDesign';

/** The system picker opens at this setting, without an enclosing custom dialog. */
@Component
export struct ColorSetting {
  @Prop label: string = '';
  @Prop @Watch('syncColor') color: string = '#FFFFFF';
  @Prop automatic: boolean = false;
  @Prop canReset: boolean = true;
  @Prop @Watch('syncSource') sourceKey: string = '';
  @Prop appDark: boolean = false;
  onPick: (color: string, sourceKey: string) => void = () => {};
  onFallback: () => void = () => {};
  private alive: boolean = false;
  private liveColor: string = '';
  @State private pickerVersion: number = 0;
  aboutToAppear(): void { this.alive = true; this.liveColor = this.color.toUpperCase(); }
  private instanceKey(): string { return this.sourceKey + ':' + this.pickerVersion; }
  private syncColor(): void {
    // HDS consumes initialColor on creation. Recreate for external undo/reset only;
    // the picker already owns its selected value when its own callback updates the model.
    if (this.liveColor !== this.color.toUpperCase()) { this.liveColor = this.color.toUpperCase(); this.pickerVersion++; }
  }
  private syncSource(): void { this.liveColor = this.color.toUpperCase(); this.pickerVersion++; }
  aboutToDisappear(): void { this.alive = false; }
  private picked(color: string, key: string): void {
    if (!this.alive || key !== this.instanceKey()) return;
    // Card colour tokens are opaque RGB; element transparency is a separate control.
    if (!/^#(?:[0-9a-fA-F]{6}|[0-9a-fA-F]{8})$/.test(color)) return;
    const rgb = '#' + color.slice(-6).toUpperCase();
    if (rgb !== this.color.toUpperCase()) { this.liveColor = rgb; this.onPick(rgb, this.sourceKey); }
  }
  @Builder
  description() {
    Column({ space: 3 }) {
      Text(this.label).fontSize(14).fontColor(AppDesign.text(this.appDark)).maxLines(1)
      Text(this.automatic ? '自动' : '自定义').fontSize(12).fontColor(AppDesign.muted(this.appDark)).maxLines(1)
    }.alignItems(HorizontalAlign.Start).layoutWeight(1).hitTestBehavior(HitTestMode.None)
  }
  build() {
    Row({ space: 8 }) {
      if (deviceInfo.sdkApiVersion >= 26 && canIUse('SystemCapability.UIDesign.HDSPattern.Standard')) {
        this.description()
        ForEach([this.instanceKey()], (key: string) => {
          HdsColorPicker({ initialColor: this.color, options: { circleRadius: 22 },
            onColorSelected: (color: string) => this.picked(color, key) })
            .accessibilityText('选择' + this.label)
        }, (key: string) => key)
      } else {
        Button({ type: ButtonType.ROUNDED_RECTANGLE, buttonStyle: ButtonStyleMode.NORMAL, role: ButtonRole.NORMAL }) {
          Row({ space: 12 }) {
            this.description()
            Column().width(28).height(28).borderRadius(8).backgroundColor(this.color)
              .border({ width: .5, color: AppDesign.border(this.appDark) }).hitTestBehavior(HitTestMode.None)
          }.width('100%')
        }.height(48).padding({left:0,right:0}).layoutWeight(1).backgroundColor(Color.Transparent)
          .accessibilityText('选择' + this.label).onClick(() => this.onFallback())
      }
      if (this.canReset) {
        Button({ type: ButtonType.Circle, buttonStyle: ButtonStyleMode.NORMAL, role: ButtonRole.NORMAL }) {
          SymbolGlyph($r('sys.symbol.arrow_counterclockwise')).fontSize(18)
            .fontColor([AppDesign.text(this.appDark)]).hitTestBehavior(HitTestMode.None)
        }.width(44).height(44).backgroundColor(Color.Transparent).enabled(!this.automatic)
          .accessibilityText(this.label + '恢复默认').onClick(() => { if (this.alive) this.onPick('', this.sourceKey); })
      }
    }.width('100%').constraintSize({ minHeight: 52 }).padding({ left: 12, right: 8, top: 4, bottom: 4 })
      .backgroundColor(AppDesign.control(this.appDark)).borderRadius(AppDesign.controlRadius).clip(true)
  }
}
