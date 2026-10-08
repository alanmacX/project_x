# 独立 .fridge Previewer

运行时是离线 HTML/CSS/JS，不需要鸿蒙、DevEco、HDC 或模拟器。直接打开 `index.html`，或由任意静态服务器提供文件。用户导入的文件不会上传，也不执行其中的脚本。无需安装依赖即可使用已构建版本。

## 统一来源

`shared-models.js` 是生产纯模型的生成产物：直接使用 App 的 `TemplatePackage.readPackage`、CardSchema、AlbumLayout、AlbumRotation、CardDepth 等。浏览器只实现 SVG 输出适配。修改设计计算后运行 `npm ci && npm run build`（开发依赖只有 TypeScript），并提交生成产物；`npm run check` 阻止源码和构建产物不一致。生成的 `PreviewDesignContract.ets` 让原生截图报告带相同源码指纹。

不把 ArkUI 控件移植成 CSS。统一的是作品协议、归一化、坐标、设计参数和数据计算；字体栅格化、阴影和宿主合成仍需对照真实 App/Form。指纹相同只证明模型版本相同，不代表像素相同。

## 当前覆盖范围

- 读取 v1 `.fridge`，继承生产版本/容量/素材引用检查。
- 全部 13 种现有 capability：时间、日期、台历、倒计时、纪念日、今日/今年进度、电量、课程表、日程、世界时钟、农历、专辑。
- 普通底板、异形透明蒙版、白边/厚度、自定义文字/图片/形状图层、旋转、层级、画布裁切与能力自由溢出。主体轮廓缓存、贴边计算、能力最小尺寸和课程表日期直接共用 App 模型。
- 笔触、徽章、贴边、挂钩、云朵和已有纸纹材质；纹理直接从 App 素材生成，禁止另做概念图代替。
- B/C/D 专辑备选使用生产几何函数，尚未持久化为正式作品选项。HTML card 仍未实现。
- 未知能力、缺失蒙版或轮廓阻断视觉验收。图片必须解码成功后才允许导出；重复导入不会混入上一份作品。
- 浏览器导出静态帧，不复现 GIF 播放、系统实时控件或宿主动画。系统 Symbol 使用矢量替身，字体和阴影合成仍有平台差异；不能声称像素一致或真实 Form 已验收。

## Harness 接口

打开页面后通过 `window.FridgeHarness`：

```js
await FridgeHarness.loadText(packageJSON); // 返回报告，等待图片解码与字体就绪
FridgeHarness.setSize(300);                // 180/300/420 CSS px，对应作品逻辑尺寸
const png = await FridgeHarness.capture(); // Blob，2倍像素导出，只有画布
const report = FridgeHarness.getReport();
```

报告包含 `sourceFingerprint`、adapter/version、package/schema 版本、目标尺寸、tick、时区、卡数和 issues。`ready-for-review` 只表示已支持并可人工对照，绝不是自动 PASS。当前 renderer 版本由 adapter 标识，设计 profile 和最低 reader 的持久化字段待下一代协议加入；不能凭空写进当前 v1。

正式验收：结构校验 → 独立预览 → 同 fingerprint 的 App 对照 → 真实 Form/分享对照。不同版本的基准图保留，合法改版经人工批准再更新，不能自动用失败截图覆盖基准。

专辑页可直接导入本地正方形封面和对应静态背景图。没有捆绑商业封面或调用在线音乐接口。

## 发布契约与设计升级

`design-contract.js` 和 skill 的 `references/design-contract.json` 由同一次 build 生成。内容来自 App：版本、能力/字段清单、阅读样式、容量、坐标、圆角与专辑参数；分别记录模型、素材、浏览器适配器、原生作品视图的身份。`--check` 会检查所有生成产物；发布前再检查浏览器支持清单与生产能力清单一致。App 版本号不变时也能发现上架前 polishing 的变化。

归档每次通过人工验收的 contract、原始 `.fridge`、素材、时间/尺寸和截图。`scripts/fridge-contract-diff.cjs old.json new.json` 用于指出协议/能力移除及视觉实现变化，不自动批准迁移或替换基准。当前 v1 没有持久化 design profile，旧作品随宿主默认设计变化；要锁定旧视觉必须将来同时实现版本化 profile 与迁移，而非在文件里先造字段。

`FridgeHarness.getDesignContract()` 读取契约，`getCardMetrics()` 查询每张卡片实际内容尺寸、最小尺寸、compact 模式与 fit。结果辅助排版，不能替代观察文字是否截断。

## 单张卡片供外部前端使用

无需视频 pipeline。`renderLayers` 与整画布使用同一个渲染过程：

```js
const pack = FridgeCore.load('TemplatePackage').readPackage(json);
// 解码素材尺寸与 loadText 一样；也可直接取已加载页的 FridgeHarness.getLayers()。
const layers = FridgeWeb.renderLayers(pack, 900, fixedTick, {namespace: 'profileA'});
// layers.defs：素材/蒙版/滤镜，仅插入一次。
// layers.background：背景 markup。
// layers.cards：按 z 排序的 {id, groupId, x, y, width, height, rotation, pivot, markup}。
```

每张 card 保留 `data-fridge-card` 独立外层节点，内部已有位置与旋转、文字/图片层、能力衬底和自由溢出。外部前端可以用 Web Animations、GSAP 等给该外层加位移/缩放/透明度，或按 groupId 联动；不要覆盖里面原有的 transform。画布边界裁切由外部场景决定：卡片离场可暂时不裁切，正常静态作品仍按 previewer 裁切。透视、相机、时序由外部项目实现，本项目不加入时间轴，也不改 App 存储。

同一页面多幅作品必须指定不同 namespace，以免 SVG 素材/滤镜 ID 相互覆盖。`width/height` 是逻辑画布单位，`pivot` 为该单位下整卡中心；不包括阴影与外贴 capability 的溢出范围，不可用它裁掉内容。SVG 根保留 `font-family="system-ui,sans-serif"`，挂钩/能力在同一 card 内，不拆散。

先渲染/解码一次并保留节点，再只更新 transform 等合成属性；不要在动画每帧调用 readPackage/renderLayers 或复制 Base64。改变作品设计或数据时重新渲染相应静态帧。素材本身是离线嵌入数据，不会让外部动画获得系统权限或读取当前设备电量。GIF、宿主交互、HTML card 仍按前述限制处理。

## 异形素材准备

[subject-tool.html](subject-tool.html) 是独立离线作者工具，导入已透明的 PNG，读取原始 alpha，用生产 SubjectGeometry.traceMask 输出轮廓；保留 PNG 字节、孔洞与完整坐标空间。支持原创异形底板以及真实照片/插画主体。导出包含素材 asset、cardFields、源文件校验和、透明边界/碎片诊断的辅助 JSON，供作者组装 `.fridge`；不是成品文件，也不做 AI 分割或修改图片。

大留白先裁紧源图并重新提取，不能单改轮廓；不要对照片编造 polygon。异常碎片在建立轮廓图之前限流，1024px 长边/24MB 及当前轮廓限制用于避免准备工具卡死。真实输入和整张作品仍要目视检查。主题创作的素材搜寻、原创生成和异形组合方法见 skill 的 art-direction.md；下载来源、使用范围与加工过程放在作品旁的 `.sources.json`，不塞进 v1 包。

HTML card：v2 作品包携带静态 HTML 源码和 image 图层缓存，预览器与 ArkUI/Form 使用同一个缓存，源码不执行。支持一个原生能力；网页脚本、网络和动态 DOM 不支持。源文件的重新渲染由离线创作工具完成，App 内可编辑图层、能力及整卡布局。
