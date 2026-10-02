export function widgetImageKey(id: string, src: string): string {
  let hash: number = 2166136261;
  for (let i = 0; i < src.length; i++) hash = Math.imul(hash ^ src.charCodeAt(i), 16777619);
  return id + '_' + (hash >>> 0).toString(16);
}
