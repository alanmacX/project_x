import type uiMaterial from '@ohos.arkui.uiMaterial';
import { deviceInfo } from '@kit.BasicServicesKit';
let preparation: Promise<void> | undefined = undefined;
let chrome: uiMaterial.ImmersiveMaterial | undefined = undefined;
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
      materialColor:tint||Color.Transparent,interactive:interactive,applyShadow:interactive,colorInvert:false});
    chrome=factory('',true);
  } catch (_) { /* Native styling and the contrast tint remain usable without material support. */ }
}
export function chromeMaterial():uiMaterial.ImmersiveMaterial|undefined {return chrome;}
const readingMaterials=new Map<string,uiMaterial.ImmersiveMaterial>();
export function readingMaterial(tint:string):uiMaterial.ImmersiveMaterial|undefined {
  if(factory===undefined)return undefined;
  let material=readingMaterials.get(tint);
  if(material===undefined){material=factory(tint,false);if(readingMaterials.size>32)readingMaterials.clear();readingMaterials.set(tint,material);}return material;
}
class ChromeModifier implements AttributeModifier<ButtonAttribute> {
  applyNormalAttribute(instance:ButtonAttribute):void {
    if(deviceInfo.sdkApiVersion>=26)instance.systemMaterial(chromeMaterial());
  }
}
class ReadingModifier implements AttributeModifier<ColumnAttribute> {
  tint:string;
  constructor(tint:string){this.tint=tint;}
  applyNormalAttribute(instance:ColumnAttribute):void {
    if(deviceInfo.sdkApiVersion>=26)instance.systemMaterial(readingMaterial(this.tint));
  }
}
const chromeModifier=new ChromeModifier();
const modifiers=new Map<string,ReadingModifier>();
export function immersiveChrome():AttributeModifier<ButtonAttribute> {return chromeModifier;}
export function immersiveReading(tint:string):AttributeModifier<ColumnAttribute> {
  let modifier=modifiers.get(tint);if(modifier===undefined){modifier=new ReadingModifier(tint);if(modifiers.size>32)modifiers.clear();modifiers.set(tint,modifier);}return modifier;
}
