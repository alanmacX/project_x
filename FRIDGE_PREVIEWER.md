# .fridge 原生预览与版本演进

2026-10-08。**主预览器是独立浏览器工具，不依赖鸿蒙。** [previewer/README.md](previewer/README.md) 描述离线入口、覆盖范围和 harness API。下面的原生页面是两端一致性的对照端，不能替代独立工具。当前只能读取 v1 原生作品，HTML 尚未实现。普通用户仍通过现有作品导入流程使用文件。

## 独立预览与原生对照的关系

浏览器共用生产纯模型的生成产物：文件 reader、schema、全部能力布局/最小尺寸、日期与课程表数据、轮廓/贴边/衬底路径、专辑布局/轮换、圆角等。设计计算只有一个来源，适配器分别输出 SVG 和 ArkUI。源码指纹同时生成到浏览器与原生报告；构建检查能发现共享逻辑未同步。浏览器不模拟鸿蒙控件或权限，不另写协议解释器。

当前浏览器支持全部现有原生能力、异形蒙版、文字/图片/形状图层和衬底；直接使用生产纯模块与纹理素材。未知能力和缺失资源阻断验收，HTML 尚未支持。字体和合成差异需要原生截图对照，不能仅凭共享模型宣称像素完全一致。未来将共享布局逐步收敛成可版本化的显示树，再分别适配两端；在此之前绝不放宽未覆盖的验收条件。

预览页复用生产 `CardFace → CardCanvas → capability` 和 CanvasBackdrop，包解析复用 TemplateIO。素材只解到独立 cache 目录，不写 FridgeStore，不覆盖画布，不发送桌面更新。原生预览可检查布局、文字、圆角、素材和卡片层级；独立浏览器可验收作品布局，但不能作为真实 Form 一致性证据。

支持文件选择、紧凑/标准/放大显示，保持作品原始比例，按 z 排序，并导出纯画布 PNG 与 JSON 元数据。元数据记录 previewVersion、渲染器、package/schema 版本、尺寸、比例、数据时间、卡数。时钟/日期 TextClock 仍使用系统实时值，其他按 tick 计算的能力使用固定时间；不声称像素完全确定。

**此页是 App 原生预览，不是桌面宿主。** Form 的字体、图片传递、刷新和点击仍需真实 Form 回归。截图按钮等待布局完成；初版没有对每张图片/字体建立全量加载就绪屏障，harness 必须目视确认图片已加载，自动等待并不等于完整验收。

## Harness 用法

先用 `scripts/fridge-package-check.cjs` 检查结构，再复制作品到 emulator 的本 App entry cache 下，文件名为 `qa_<name>.fridge`，例如 `qa_native.fridge`。

```
hdc file send -b com.fridgewidget.app skills/fridge-create/examples/native-canvas.fridge /data/storage/el2/base/haps/entry/cache/qa_native.fridge
hdc shell aa force-stop com.fridgewidget.app
hdc shell aa start -a EntryAbility -b com.fridgewidget.app --ps demo preview --ps previewFile qa_native.fridge --ps previewCapture yes
```

HDC 的 -b 使用可调试应用的沙箱通道；普通 file send 没有写 App 私有目录的权限。发行签名如果不开放调试，改用页面文件选择器，不扩大目录权限。路径和设备根据测试环境调整。预览器仅接受本 App cache 中的路径，短文件名只接受 `qa_*.fridge`。它不会读取调用方给出的任意系统文件。参数必须在冷启动生效，已有页面 onNewWant 不会强制跳转。

自动捕获后，用 `hdc file recv -b com.fridgewidget.app /data/storage/el2/base/haps/entry/cache/fridge_preview_capture.png <local-path>` 取 PNG，同样取 `.json`。自动捕获延迟是准备窗口，不是性能指标。检查截图、元数据、日志并保存结果。失败文件应显示明确错误，不能退回默认画布假装导入成功。下一版补图片/字体就绪屏障、边界检查及多宿主报告。

## 未来更新兼容原则

分开维护：

- **packageVersion**：容器、资源和引用格式；当前 1。
- **schemaVersion**：卡片/布局的数据模型；当前 2。
- **designProfileVersion**：默认材质、字体、布局行为；未来显式增加，当前没有该字段。
- **rendererVersion**：渲染实现与能力支持，用于截图回归；目前报告为 previewVersion=1 + 组件路径，尚未有正式产品渲染版本号。
- **skillContractVersion**：作者能生成的字段、设计规范和能力清单，与以上版本配套发布。

新增 capability 并不一定升级容器；新增 HTML/资源种类或改变字段语义才需要明确版本迁移。旧包先按原版本解析并迁移副本，保留原文件，不能改写作者原件。未知必需能力拒绝/提示升级；可选装饰只有经过用户确认才降级。不能静默丢弃字段后报成功。

布局或材质改版优先保持用户已选的尺寸、颜色和源数据。对旧设计需要重大视觉重排时保留旧 profile 或提供“升级样式”预览，由用户选择；bug 修复可以统一更新，但须做回归，不把修 bug 变成推翻全部作品风格。

skill 不固定跟某版源码永久绑定：已由 previewer/build.cjs 从 App 生成机器可读设计契约，包含字段、能力、设计参数及模型/素材/两端视图身份。Node-only 校验器和 skill 使用同一产物，--check 检测过期；每次发布归档契约并用 fridge-contract-diff.cjs 标出变更，随后做兼容与视觉验收。收到新契约不支持时停止生成可导入包，明确给草稿。HTML 包必须声明最低 reader、renderer、design profile 和 required providers。

## 回归验收要求

保留旧版本真实作品作为 fixtures；至少覆盖原生/HTML（实现后）、异形、组合、长中文、空数据、专辑轮换、16卡上限、缺素材和未来未知字段。比较同一数据时间和目标比例下的 App/真实 Form/分享截图，工具栏不混入作品。

像素差异是线索，不是唯一通过条件：文字截断、数据错绑、按钮失效比少量阴影差更重要。人工确认的合法设计更新才能重录基准，不得自动把新截图覆盖为“正确答案”。

## 专辑候选

`demo=album` 是只读原生设计页，复用 AlbumCapability，新参数 presentation 默认 cover，因此现有作品外观不改变。A 为已批准纯封面；B 左上小封面，下方标题/歌手；C 大封面，下方标题/歌手；D 横向封面和文字。没有播放按钮或音乐图标。样例优先读取测试已提供的 cache 图片，没有测试素材时读取现有本地专辑，不内置商业封面到发行包。

选定设计后再实现可保存的 album presentation 字段及设置 UI，迁移时缺省值仍为 cover。新增信息款不能让原纯封面尺寸规则被意外更改。
