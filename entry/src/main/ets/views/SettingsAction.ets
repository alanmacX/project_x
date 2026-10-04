import { AppDesign } from '../model/AppDesign';

/** Native action with reactive inputs; scalar Builder parameters can retain old labels. */
@Component
export struct SettingsAction {
  @Prop label: string = '';
  @Prop isEnabled: boolean = true;
  @Prop emphasis: boolean = false;
  @Prop error: boolean = false;
  @Prop fillWidth: boolean = false;
  @Prop appDark: boolean = false;
  onPress: () => void = () => {};

  build() {
    Button(this.label, {
      type: ButtonType.Capsule,
      buttonStyle: this.emphasis ? ButtonStyleMode.EMPHASIZED : ButtonStyleMode.NORMAL,
      role: this.error ? ButtonRole.ERROR : ButtonRole.NORMAL
    })
      .height(AppDesign.controlHeight).width(this.fillWidth ? '100%' : undefined)
      .constraintSize({ maxWidth: '100%' }).fontSize(14)
      .labelStyle({ maxLines: 1, overflow: TextOverflow.Ellipsis })
      .fontColor(this.error ? '#C43A35' : AppDesign.choiceText(this.appDark, this.emphasis))
      .backgroundColor(AppDesign.choice(this.appDark, this.emphasis))
      .enabled(this.isEnabled).onClick(() => { if (this.isEnabled) this.onPress(); })
  }
}
