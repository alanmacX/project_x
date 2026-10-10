import type uiMaterial from '@ohos.arkui.uiMaterial';
import { deviceInfo } from '@kit.BasicServicesKit';
let preparation: Promise<void> | undefined = undefined;
const chromeMaterials: (uiMaterial.ImmersiveMaterial | undefined)[] = [];
let factory: ((tint:string,interactive:boolean)=>uiMaterial.ImmersiveMaterial) | undefined = undefined;
/** Load the new native module only on supported OS versions, before exposing the scene. */
export function prepareChromeMaterial():Promise<void> {
  if(preparation!==undefined)return preparation;
  preparation=loadMaterial();return preparation;
}
async function loadMaterial():Promise<void> {
  if(deviceInfo.sdkApiVersion<26)return;
  try {
    const module=await import('@ohos.arkui.uiMaterial');
    if(!module.default.isImmersiveMaterialSupported())return;
    factory=(tint:string,interactive:boolean):uiMaterial.ImmersiveMaterial=>new module.default.ImmersiveMaterial({
      style:interactive?module.default.ImmersiveStyle.REGULAR:module.default.ImmersiveStyle.THIN,
      materialColor:tint||Color.Transparent,interactive:interactive,applyShadow:interactive,colorInvert:false,lightEffect:interactive?{color:undefined}:null});
    // Supply the tint to the material itself: systemMaterial owns the fill and
    // can replace backgroundColor, especially against the dark app surface.
    chromeMaterials[0]=factory('#E6F6F2E9',true);
    chromeMaterials[1]=factory('#E63B3933',true);
    chromeMaterials[2]=factory('#30332E',true);
    chromeMaterials[3]=factory('#EEE8DC',true);
  } catch (_) { /* Native styling and the contrast tint remain usable without material support. */ }
}
export function chromeMaterial(dark:boolean=false,emphasized:boolean=false):uiMaterial.ImmersiveMaterial|undefined {return chromeMaterials[(dark?1:0)+(emphasized?2:0)];}
const popupMaterials=new Map<string,uiMaterial.ImmersiveMaterial>();
export function popupMaterial(dark:boolean):uiMaterial.ImmersiveMaterial|undefined {
  if(factory===undefined)return undefined;
  const tint=dark?'#E62C2B27':'#E6F6F2E9';
  let material=popupMaterials.get(tint);if(material===undefined){material=factory(tint,true);popupMaterials.set(tint,material);}return material;
}
const readingMaterials=new Map<string,uiMaterial.ImmersiveMaterial>();
export function readingMaterial(tint:string):uiMaterial.ImmersiveMaterial|undefined {
  if(factory===undefined)return undefined;
  let material=readingMaterials.get(tint);
  if(material===undefined){material=factory(tint,false);if(readingMaterials.size>32)readingMaterials.clear();readingMaterials.set(tint,material);}return material;
}
class ChromeModifier implements AttributeModifier<ButtonAttribute> {
  private dark:boolean;private emphasized:boolean;
  constructor(dark:boolean=false,emphasized:boolean=false){this.dark=dark;this.emphasized=emphasized;}
  applyNormalAttribute(instance:ButtonAttribute):void {
    // Native system material is scoped to navigation/tab bars and popup hosts.
    // Floating canvas tools still need a native blur/tint fallback in ordinary content.
    if(!this.emphasized)instance.backgroundColor(this.dark?'#E63B3933':'#E6F6F2E9');
    instance.border({width:this.emphasized?0:.5,color:this.dark?'#38FFFFFF':'#18000000'});
    const material=deviceInfo.sdkApiVersion>=26?chromeMaterial(this.dark,this.emphasized):undefined;
    if(material!==undefined) {instance.systemMaterial(material);}
    else {
      if(!this.emphasized)instance.backgroundBlurStyle(BlurStyle.COMPONENT_THIN);
      instance.shadow({radius:10,color:'#18000000',offsetY:3});
    }
  }
}
class ReadingModifier implements AttributeModifier<ColumnAttribute> {
  tint:string;
  constructor(tint:string){this.tint=tint;}
  applyNormalAttribute(instance:ColumnAttribute):void {
    if(deviceInfo.sdkApiVersion>=26)instance.systemMaterial(readingMaterial(this.tint));
  }
}
const chromeModifiers:ChromeModifier[]=[new ChromeModifier(false,false),new ChromeModifier(true,false),new ChromeModifier(false,true),new ChromeModifier(true,true)];
const modifiers=new Map<string,ReadingModifier>();
export function immersiveChrome(dark:boolean=false,emphasized:boolean=false):AttributeModifier<ButtonAttribute> {return chromeModifiers[(dark?1:0)+(emphasized?2:0)];}
export function immersiveReading(tint:string):AttributeModifier<ColumnAttribute> {
  let modifier=modifiers.get(tint);if(modifier===undefined){modifier=new ReadingModifier(tint);if(modifiers.size>32)modifiers.clear();modifiers.set(tint,modifier);}return modifier;
}
