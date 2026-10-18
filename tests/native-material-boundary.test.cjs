const assert=require('node:assert/strict'),fs=require('node:fs'),vm=require('node:vm');
const ts=require('/Applications/DevEco-Studio.app/Contents/tools/hvigor/hvigor/node_modules/typescript');
const page=fs.readFileSync('entry/src/main/ets/pages/Index.ets','utf8'),gallery=fs.readFileSync('entry/src/main/ets/views/CanvasGallery.ets','utf8');
// Native backdrop samplers must retain window-space coordinates. Pure artwork may be cached independently.
const workspace=page.slice(page.indexOf("}.id('canvasWorkspace')"),page.indexOf('        if(this.galleryMounted){'));
const galleryHost=page.slice(page.indexOf('          CanvasGallery({'),page.indexOf('        Column().width(1).height(1).position({x:this.navMenuX'));
for(const [name,source] of [['workspace',workspace],['gallery host',galleryHost]]){
 assert(!/\.renderGroup\(|\.scale\(|\.opacity\(/.test(source),name+' must not flatten, transform, or fade native material descendants');
}
const navigation=page.slice(page.indexOf('  private async setGalleryPage('),page.indexOf('  @Builder\n  canvasNavigation('));
assert(!navigation.includes('getComponentSnapshot'),'navigation must not read the full window back from GPU');
assert((navigation.match(/await this.waitGalleryFrame\(\)/g)||[]).length>=2,'destination still mounts behind the gallery before handoff');
assert(!/get\('(canvasWorkspace|editorMotionChrome)'/.test(page),'native material must stay outside snapshots');
assert.match(gallery,/ignoreLayoutSafeArea\(\[LayoutSafeAreaType.SYSTEM\], \[LayoutSafeAreaEdge.TOP\]\)/,'native component safe area owns scroll origin');
assert.match(gallery,/HdsNavigation\(\) \{\s*Scroll\(this.scroller\)/,'native navigation owns scrolling content, avoiding a full-page hit-test overlay');
assert.match(gallery,/hideTitleBar\(!this.chromeVisible\)/,'native chrome only participates in settled page');
assert.match(gallery,/opacity\(this.pageVisible\?1:0\)/,'fade pure content rather than native title sampler');
const nativeBar=gallery.slice(gallery.indexOf('      HdsNavigation() {'),gallery.indexOf('      Column().width(1).height(1).position'));
assert(!/\.scale\(|\.renderGroup\(/.test(nativeBar));
const appSource=fs.readFileSync('entry/src/main/ets/model/AppDesign.ets','utf8');
function execute(source,require){const context={exports:{},require,Color:{Transparent:0}};vm.runInNewContext(ts.transpileModule(source,{compilerOptions:{module:ts.ModuleKind.CommonJS}}).outputText,context);return context.exports;}
const {AppDesign}=execute(appSource,()=>({}));
const {navigationChrome}=execute(fs.readFileSync('entry/src/main/ets/model/NavigationChrome.ets','utf8'),name=>name==='./AppDesign'?{AppDesign}:{BlurStrategy:{ADAPTIVE:0},ScrollEffectType:{IMMERSIVE_GRADIENT_BLUR:1},hdsMaterial:{MaterialType:{IMMERSIVE:1},MaterialLevel:{ADAPTIVE:1}}});
for(const dark of [false,true])for(const native of [false,true]){
 const style=navigationChrome(dark,native);
 for(const state of [style.originalStyle,style.scrollEffectStyle]){
  assert.equal(state.contentStyle.titleStyle.mainTitleColor,AppDesign.text(dark));
  assert.equal(state.contentStyle.titleStyle.subTitleColor,AppDesign.muted(dark));
  assert.equal(state.backgroundStyle.maskExtraHeight,native?undefined:0);
 }
 assert.equal(style.systemMaterialEffect.materialType,1,'HDS material remains enabled');
}
console.log('PASS native material boundaries: window-coordinate chrome, artwork-only snapshots, content-only animation, explicit light/dark title colors.');
