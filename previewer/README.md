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
