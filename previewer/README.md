# 独立 .fridge Previewer

运行时是离线 HTML/CSS/JS，不需要鸿蒙、DevEco、HDC 或模拟器。直接打开 `index.html`，或由任意静态服务器提供文件。用户导入的文件不会上传，也不执行其中的脚本。无需安装依赖即可使用已构建版本。

## 统一来源

`shared-models.js` 是生产纯模型的生成产物：直接使用 App 的 `TemplatePackage.readPackage`、CardSchema、AlbumLayout、AlbumRotation、CardDepth 等。浏览器只实现 SVG 输出适配。修改设计计算后运行 `npm ci && npm run build`（开发依赖只有 TypeScript），并提交生成产物；`npm run check` 阻止源码和构建产物不一致。生成的 `PreviewDesignContract.ets` 让原生截图报告带相同源码指纹。

不把 ArkUI 控件移植成 CSS。统一的是作品协议、归一化、坐标、设计参数和数据计算；字体栅格化、阴影和宿主合成仍需对照真实 App/Form。指纹相同只证明模型版本相同，不代表像素相同。

## 当前覆盖范围

- 读取 v1 `.fridge`，继承生产版本/容量/素材引用检查。
- 已实现正方形外框的现有专辑、专辑轮换的数据选择、画布背景图片与纯色、普通底板。
- B/C/D 专辑备选使用相同生产几何函数，封面正方形；尚未持久化为正式作品选项。
- 非专辑能力、异形蒙版、自定义图层以及非正方形专辑外框，目前给出 **unsupported** 报告及可见占位，不能作为通过的视觉验收。HTML card 仍未实现。
- 浏览器报告不会声称 Form 已验收或像素一致。后续逐能力补适配与两端基准图；未覆盖前始终阻断验收。

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
