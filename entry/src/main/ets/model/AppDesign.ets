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
  static muted(dark: boolean): string { return dark ? '#A8ADB5' : '#666B73'; }
  static border(dark: boolean): string { return dark ? '#41454C' : '#DDE1E5'; }
}
