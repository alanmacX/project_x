/** Local HTML authoring source plus an immutable appearance cache. Never executed on drag or in a Form. */
export interface HtmlCardTemplate {
  version:number;
  designVersion:number;
  width:number;
  height:number;
  source:string;
  previewElementId:string;
}
export function validateHtmlCard(template:HtmlCardTemplate):void {
  if(!template||template.version!==1||template.designVersion!==1||!Number.isInteger(template.width)||!Number.isInteger(template.height)||template.width<32||template.height<32||template.width>1024||template.height>1024||typeof template.previewElementId!=='string'||!template.previewElementId.length||template.previewElementId.length>96||typeof template.source!=='string'||!template.source.length||template.source.length>512*1024)throw new Error('HTML 卡片版本或尺寸不受支持，请更新应用');
  for(const key of Object.keys(template))if(!['version','designVersion','width','height','source','previewElementId'].includes(key))throw new Error('HTML 卡片包含尚未支持的字段，请更新应用');
  const source=template.source;
  // These sources are data in the app. The same policy gates any authoring preview.
  if(/<\s*\/?\s*(script|iframe|object|embed|link|base|form|input|button|audio|video|foreignobject|animate|animatetransform|animatemotion|set|marquee)\b/i.test(source)||/\bon[a-z]+\s*=/i.test(source)||/(javascript\s*:|https?\s*:|file\s*:|@import|@font-face|expression\s*\(|animation(?:-[a-z]+)?\s*:|transition(?:-[a-z]+)?\s*:)/i.test(source))throw new Error('HTML 卡片只支持静态本地外观，不支持脚本、联网或交互控件');
  const refs=source.match(/(?:src|href)\s*=\s*[^>\s]+/gi)??[];
  for(const ref of refs)if(!/^(?:src|href)\s*=\s*["'](?:data:image\/(?:png|jpeg|webp);base64,|#)/i.test(ref))throw new Error('HTML 素材必须内嵌为本地图片');
  for(const ref of source.match(/url\s*\([^)]*\)/gi)??[])if(!/^url\s*\(\s*(["']?)#[a-z0-9_-]+\1\s*\)$/i.test(ref))throw new Error('HTML 不使用外部 CSS 资源；SVG 可以引用本地渐变 ID');
  if(/\bsrcset\s*=/i.test(source))throw new Error('HTML 不使用外部响应式图片资源');
}
export function normalizeHtmlCard(template:HtmlCardTemplate|undefined):HtmlCardTemplate|undefined {
  if(template===undefined||template===null)return undefined;
  validateHtmlCard(template);
  return {version:1,designVersion:1,width:template.width,height:template.height,source:template.source,previewElementId:template.previewElementId};
}
