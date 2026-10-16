import { TitleBarStyleOptions, BlurStrategy, ScrollEffectType, hdsMaterial } from '@kit.UIDesignKit';
import { AppDesign } from './AppDesign';

/** Material belongs to the native HDS title bar, including every generated menu/back button. */
export function navigationChrome(dark: boolean): TitleBarStyleOptions {
  return {
    blurStrategy: BlurStrategy.ADAPTIVE, thermoCtrl: true,
    scrollEffectOpts: { enableScrollEffect: true, scrollEffectType: ScrollEffectType.IMMERSIVE_GRADIENT_BLUR },
    systemMaterialEffect: { materialType: hdsMaterial.MaterialType.IMMERSIVE, materialLevel: hdsMaterial.MaterialLevel.ADAPTIVE },
    originalStyle: {
      backgroundStyle: { backgroundColor: Color.Transparent, maskExtraHeight: 0, blurRadius: 16 },
      contentStyle: {
        menuStyle: { backgroundColor: AppDesign.surface(dark), textColor: AppDesign.text(dark), iconColor: AppDesign.text(dark) },
        backIconStyle: { backgroundColor: AppDesign.surface(dark), textColor: AppDesign.text(dark), iconColor: AppDesign.text(dark) }
      }
    },
    scrollEffectStyle: {
      backgroundStyle: { backgroundColor: Color.Transparent, maskExtraHeight: 0, blurRadius: 16 },
      contentStyle: {
        menuStyle: { backgroundColor: AppDesign.surface(dark), textColor: AppDesign.text(dark), iconColor: AppDesign.text(dark) },
        backIconStyle: { backgroundColor: AppDesign.surface(dark), textColor: AppDesign.text(dark), iconColor: AppDesign.text(dark) }
      }
    }
  };
}
