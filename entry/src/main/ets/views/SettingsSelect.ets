import { AppDesign } from '../model/AppDesign';

/** One native Select surface. Its trigger and child share a single capsule clip;
 * menu rows stay transparent so the native menu owns its four corners. */
@Component
export struct SettingsSelect {
  @Prop @Watch('labelsChanged') labels: string[] = [];
  @Prop selectedIndex: number = 0;
  @Prop valueLabel: string = '';
  @Prop placeholder: string = '请选择';
  @Prop appDark: boolean = false;
  onSelect: (index: number) => void = () => {};
  @State private options: SelectOption[] = [];
  private signature: string = '';
  aboutToAppear(): void { this.labelsChanged(); }
  private labelsChanged(): void {
    const signature = JSON.stringify(this.labels);
    if (signature === this.signature) return;
    this.signature = signature; this.options = this.labels.map((value: string): SelectOption => ({ value: value }));
  }
  build() {
    Select(this.options).selected(this.selectedIndex)
      .value(this.valueLabel || this.labels[this.selectedIndex] || this.placeholder)
      .font({size:14}).fontColor(AppDesign.text(this.appDark))
      .optionFont({size:14}).optionFontColor(AppDesign.text(this.appDark)).optionBgColor(Color.Transparent)
      .selectedOptionFontColor(AppDesign.onSelected(this.appDark)).selectedOptionBgColor(AppDesign.selected(this.appDark))
      .optionWidth(OptionWidthMode.FIT_TRIGGER).menuAlign(MenuAlignType.START)
      .menuBackgroundColor(AppDesign.surface(this.appDark)).menuBackgroundBlurStyle(BlurStyle.NONE)
      .backgroundColor(AppDesign.control(this.appDark)).controlSize(ControlSize.NORMAL)
      .width('100%').height(AppDesign.controlHeight).borderRadius(AppDesign.controlHeight / 2).clip(true)
      .enabled(this.labels.length > 0)
      .onSelect((index: number) => { if (index >= 0 && index < this.labels.length) this.onSelect(index); })
  }
}
