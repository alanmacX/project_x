# 原型 05 补充参考

- [Apple Freeform：Position items](https://support.apple.com/en-gb/guide/iphone/iph5e1a18c04/ios)：实际阅读移动、旋转、缩放、前后顺序、编组的流程，并查看多对象照片画布的截图。截图中选中框贴着对象，排列工具依附当前选择，画布一直可见。用于作品层的选中框、手柄、按需出现的排列控件和单独的选择列表。
- 原型 03 已实际查看的 Apple Watch / StandBy 参考继续负责单个对象的聚焦自定：统一大预览、按项切换、点内容后打开选择器。整体画布保留自由摆放，进入单个对象后使用相同编辑规则。
- 原生对照：`Index.ets` 的选中浮条与单卡编辑、`EditorLayerControls.ets` 的几何手势、`EditorVisualChoices.ets` 的真实外观选项。保留这些能力，将入口和编辑层级统一。

检索到的 Keynote 文本编辑页面返回 429，未将它作为实际查看过的界面参考。

---

# 原型 04 补充

继续采用下方已实际查看的 Apple Watch、StandBy 与照片壁纸编辑参考。此次按用户补充约束调整照片行为：原图铺满，颜色影响背景，主体保持自然颜色。原图与主体的构图工具分开；其他模板沿用大预览、单项切换、点选位置、临时输入层。

官方补充资料：[Apple Watch Photos face](https://support.apple.com/en-ca/guide/watch/apd501eb33b3/watchos)。颜色处理算法是本原型的本地实现，具体选项以此次可交互效果为准。

---

# 原型 03：Apple Watch / StandBy 编辑参考

2026-11-09。按用户指定方向重做模板选择与编辑。素材库仍沿用原型 02 的本地资料组织。

## 实际查看的参考

- [Apple：Change Apple Watch faces](https://support.apple.com/en-ie/guide/watch/apda6559ad78/watchos)：阅读官方流程并查看表盘选择截图。主表盘居中、相邻表盘露出、单独的 Edit 按钮。用于本原型模板横滑预览与「自定」入口。
- [Apple：Add complications](https://support.apple.com/en-ie/guide/watch/apd8d0b9c582/watchos)：阅读长按 → Edit → 横滑到复杂功能 → 点选位置的流程，查看官方功能选择截图。用于编辑项分页、直接点选内容区域、再进入该项选择器。
- [MacRumors / Tim Hardwick：Customize StandBy Widgets](https://www.macrumors.com/how-to/customize-widgets-standby-mode/)：实际查看 2023 年 StandBy 截图，包括中间堆栈编辑、顶部 Done 和组件选择界面。借鉴深色环境、当前对象聚焦、选择器临时展开、完成操作固定。

## 当前实现

- 作品居中占主要视觉区域；编辑环境黑色，当前模板维持自身配色。
- 顶部返回、作品名称、完成；外观（或尺寸）/ 颜色 / 内容横向切换。
- 内容页用浅绿色边框标出可点区域；照片、时间、专辑文字、课程分别点选。
- 仅当前编辑项显示控件。素材和文本输入在临时浮层中；照片构图保留全尺寸画布。
- 横滑、长按有可见按钮替代。没有添加虚拟数码表冠；手机使用拖动、滑杆和选项按钮。
- 图像和排版继续消费项目共享 renderer，使用项目原有字体、图标与素材。

---

以下保留原型 02 素材库参考记录。

# 设计参考 · 本地创作原型 02

使用 anti-aidesign 的实际参考与浏览器验证流程。第 1 版精选首页的决策已经撤回，新的默认入口是本地作品。

## Eagle：素材与使用信息的层级

- 页面：https://www.eagle.cool/home
- 实际查看：浏览器滚动到产品界面大图，看到左侧目录 / 标签、中间图像网格、右侧选中图片的名称 / 标签 / 属性。没有采用页面的 AI 示例内容或营销布局。
- 应用：素材以图片识别，类型和分组分开；详情承载名称与使用关系；创作中复用同一选择器。手机采用两列，详情打开独立面板，大屏详情与预览并排。

## Apple 照片壁纸编辑：在画面上直接选择对象

- 官方说明：https://support.apple.com/en-us/102638
- 实际查看：文章中的原有壁纸集合、照片轮换设置；单独打开编辑截图：https://cdsassets.apple.com/live/7WUAS350/images/ios/ios-26-iphone-16-pro-lock-screen-customize-add-widgets.png
- 观察：画面保持大面积可见，时间区域直接显示可编辑边框，完成位于固定顶栏；底部动作靠近图片本身。
- 应用：景深页固定预览，点时间直接进入时间设置；时间拖动吸附到生产模型已有的六个位置；原图和主体共享相机，对比不改变保存状态。没有引入 iOS 字体、系统壁纸图片或锁屏权限能力。

## 当前 App 的实现约束

- `TemplatePhotoEditor.ets` 已有独立构图页面、单指 / 双指手势、固定控制区域与六位置选时。原型继续复用这些模型。
- `TemplateSettings.ets` 的照片、主体处理、构图入口目前分散；`AlbumSettings.ets` 的封面库属于当前卡片。
- 具体改动见 [UX-DECISIONS.md](UX-DECISIONS.md)。

## 视觉方向

冷中性色工具界面，白色控制面，统一蓝色主要动作；去掉推荐周期、标语、装饰性英文与大横幅。作品和素材承担视觉内容；编辑时把注意力集中在固定画布与当前对象上。

## 授权

新增真实原图来自 Wikimedia：Matt Buck 的 Asian tabby cat.jpg，CC BY-SA 2.0；透明主体沿用项目已有的 YukiKoKo 版本，CC BY-SA 4.0。保持对应的完整画幅，便于验证景深对齐。示例专辑封面是原型运行时的几何排版，名称与音乐人为示例数据。详细来源在 `assets/README.md`。
