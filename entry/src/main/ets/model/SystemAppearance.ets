/** Configuration can be temporarily unavailable while the extension is attaching. */
export function systemIsDark(context:Context):boolean {
  try{return context.resourceManager.getConfigurationSync().colorMode===0;}catch(_){return false;}
}
