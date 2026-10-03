/** Shared app chrome tokens. Card artwork and the desktop widget keep their own palette. */
export class AppDesign {
  static readonly sectionRadius: number = 20;
  static readonly controlRadius: number = 12;
  static readonly controlHeight: number = 44;
  static readonly sectionInset: number = 16;
  static readonly gap: number = 16;
  static background(dark: boolean): string { return dark ? '#101113' : '#FFFFFF'; }
  static surface(dark: boolean): string { return dark ? '#25231F' : '#F6F2E9'; }
  static text(dark: boolean): string { return dark ? '#F4F4F4' : '#262824'; }
  static control(dark: boolean): string { return AppDesign.background(dark); }
  static muted(dark: boolean): string { return dark ? '#A8ADB5' : '#666B73'; }
  static border(dark: boolean): string { return dark ? '#49443C' : '#E4DED2'; }
  static selected(dark: boolean): string { return dark ? '#EEE8DC' : '#30332E'; }
  static onSelected(dark: boolean): string { return dark ? '#25231F' : '#FFFFFF'; }
  static choice(dark: boolean, active: boolean): string { return active ? AppDesign.selected(dark) : AppDesign.control(dark); }
  static choiceText(dark: boolean, active: boolean): string { return active ? AppDesign.onSelected(dark) : AppDesign.text(dark); }
}
