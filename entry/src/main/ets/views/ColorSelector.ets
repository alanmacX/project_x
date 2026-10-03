import { HdsColorPicker } from '@kit.UIDesignKit';
import { AppDesign } from '../model/AppDesign';
import { deviceInfo } from '@kit.BasicServicesKit';

@CustomDialog
export struct ColorSelector {
  controller?: CustomDialogController;
  initialColor: string = '#FFFFFF';
  onPick: (color: string) => void = () => {};
  @StorageLink('appDark') appDark: boolean = false;
  @State chosen: string = '#FFFFFF';
  @State red: number = 255;
  @State green: number = 255;
  @State blue: number = 255;
  aboutToAppear(): void {
    this.chosen = this.initialColor;
    this.red = parseInt(this.chosen.slice(1, 3), 16); this.green = parseInt(this.chosen.slice(3, 5), 16); this.blue = parseInt(this.chosen.slice(5, 7), 16);
  }
  private update(): void {
    this.chosen = '#' + [this.red, this.green, this.blue].map((v: number) => Math.round(v).toString(16).padStart(2, '0')).join('');
  }
  build() {
    Column({ space: 16 }) {
      Row() {
        Text('选择颜色').fontColor(AppDesign.text(this.appDark)).fontSize(18).fontWeight(FontWeight.Medium); Blank()
        Button('取消', { type: ButtonType.Capsule }).height(44).backgroundColor(Color.Transparent).fontColor(AppDesign.muted(this.appDark)).onClick(() => this.controller?.close())
      }.width('100%')
      if (deviceInfo.sdkApiVersion >= 26 && canIUse('SystemCapability.UIDesign.HDSPattern.Standard')) {
        HdsColorPicker({ initialColor: this.initialColor, onColorSelected: (color: string) => {
          const value = color.replace('#', ''); if (/^[0-9a-fA-F]{6,8}$/.test(value)) this.chosen = '#' + value.slice(-6);
        } })
      } else {
        Column({ space: 12 }) {
          Column().width('100%').height(64).borderRadius(12).backgroundColor(this.chosen)
          Text('红').fontSize(13).fontColor(AppDesign.text(this.appDark)).width('100%'); Slider({ value: this.red, min: 0, max: 255, step: 1 }).selectedColor('#D85E55').onChange((v: number) => { this.red = v; this.update(); })
          Text('绿').fontSize(13).fontColor(AppDesign.text(this.appDark)).width('100%'); Slider({ value: this.green, min: 0, max: 255, step: 1 }).selectedColor('#68876B').onChange((v: number) => { this.green = v; this.update(); })
          Text('蓝').fontSize(13).fontColor(AppDesign.text(this.appDark)).width('100%'); Slider({ value: this.blue, min: 0, max: 255, step: 1 }).selectedColor('#6E85A5').onChange((v: number) => { this.blue = v; this.update(); })
        }.width('100%')
      }
      Row({ space: 12 }) {
        Button('恢复默认', { type: ButtonType.Capsule }).height(44).layoutWeight(1).borderRadius(12).backgroundColor(AppDesign.control(this.appDark)).fontColor(AppDesign.text(this.appDark)).onClick(() => { this.onPick(''); this.controller?.close(); })
        Button('完成', { type: ButtonType.Capsule }).height(44).layoutWeight(1).borderRadius(12).backgroundColor(AppDesign.selected(this.appDark)).fontColor(AppDesign.onSelected(this.appDark)).onClick(() => { this.onPick(this.chosen); this.controller?.close(); })
      }.width('100%')
    }.padding(20).width('92%').constraintSize({ maxWidth: 520 }).borderRadius(24).backgroundColor(AppDesign.surface(this.appDark))
  }
}
