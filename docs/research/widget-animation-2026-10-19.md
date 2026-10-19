# 桌面小组件动画可行性（2026-10-19）

结论：可以做有限时长、事件触发的动效；不能从普通 App 的循环动画能力推导出桌面可无限播放。需要区分普通动态卡片、图片帧动画和 LiveForm 互动卡片。本轮只改系统绑定菜单外观，没有启用新的桌面动画或修改现有绑定。

## 当前代码

form_config 使用 ArkTS，未声明 isDynamic；官方配置文档的默认值为 true，因此属于普通动态卡片。FridgeWidgetCard 已调用 animateTo：背景混合 240ms，同画布内容更新 180ms、跨画布更新 300ms。动画状态提交不依赖 onFinish，避免桌面暂停卡片后留下空白。

WidgetPayload 将原图片文件描述符交给 formImages，并映射为 memory://；它没有将每个素材全部合成为一张预览图。所以存在对单个元素做动效的基础，但任意导入 GIF 的播放、暂停、内存和恢复尚未在桌面验收。首页仍是缓存图片预览，不应为了动效重新挂载全部编辑场景。

## 能力与边界

| 方案 | 已确认能力 | 限制与适合用途 |
| --- | --- | --- |
| 普通动态卡片属性／显式动画、组件转场 | 官方支持 | API 26 之前最长 1000ms；26 起最长 2000ms。tempo 固定 1，delay 固定 0，iterations 固定 1。适合点击反馈、刷新时淡入、贴纸短摆动，不能承诺无限呼吸／旋转。 |
| ImageAnimator 逐帧动画 | 从 API 10 支持卡片的 images/state/duration 等属性 | iterations 没有卡片能力标记；不能引用 App 中 iterations(-1) 的示例承诺桌面无限循环。图片列表不支持动态更新，帧资源会增加内存。适合预置小尺寸短帧序列，需实测宿主恢复和资源传递。普通属性动画的时长表不能直接当作这个独立组件的完整播放规格。 |
| Image 加载 GIF | Image 支持 GIF；普通 Image 能力支持卡片 | 这不足以证明当前 memory:// 传递链路和宿主能无限播放。单个 PixelMap 只代表静态帧，未来做动图不能先解成单帧再期待播放。需用打包资源 GIF、导入 GIF、逐帧序列分组真机验证，当前不宣称已支持。 |
| 场景动效互动卡片 LiveForm | API 20 起，LiveFormExtensionAbility + requestOverflow，独立页面渲染，可申请出框 | 桌面单张卡片、部分机型支持；不支持时报 801。普通应用最长 3500ms，到期回到普通状态；定时／定点触发每卡每天最多 50 次。不是常驻视频窗口。 |

本项目编译目标 API 26，兼容 API 24，不能把 API 26 的 2 秒上限直接用于所有兼容设备。优先设计 1 秒内完成的动效，再按实际运行版本和宿主验收扩展。

## 建议落地顺序（设计判断）

1. 优先利用现有普通卡片，做 200–600ms 的局部旋转、缩放或透明度变化，保留稳定静态终态；不用定时器续播，不用逐帧 updateForm。这样更符合当前降低开销的目标。
2. 真机建立独立测试素材，分别验证打包 GIF、用户导入 GIF 和 ImageAnimator：新增／刷新、滑走滑回、锁屏恢复、冷启动、同时放多个实例。记录帧是否真的变化、结束行为和内存，不能只以编译通过认定可用。
3. 如需要角色跳出画框等强动效，再单独接 LiveForm；保持普通卡片完整回退。先测目标平板 requestOverflow 能力及资源回收，不把它设为所有画布的基础运行模式。

## 原始依据

查阅华为 Form Kit 页面、互动卡片官方介绍，并用 OpenHarmony 官方当前文档及本机 SDK 核对细节；华为部分新版参考页面抓取超时，下面明确保留可读取的第一方原文，不以社区转述代替 API 证据。

- [官方卡片动效约束](https://github.com/openharmony/docs/blob/master/zh-cn/application-dev/form/arkts-ui-widget-page-animation.md)：包含 API 26 前后 1 秒／2 秒差异。
- [官方 ImageAnimator 文档](https://github.com/openharmony/docs/blob/master/zh-cn/application-dev/reference/apis-arkui/arkui-ts/ts-basic-components-imageanimator.md)：逐属性标注卡片能力，iterations 没有标记。
- [官方 Image 文档](https://github.com/openharmony/docs/blob/master/zh-cn/application-dev/reference/apis-arkui/arkui-ts/ts-basic-components-image.md)：GIF 和单 PixelMap 静态显示说明。
- [官方 LiveForm 场景动效概述](https://github.com/openharmony/docs/blob/master/zh-cn/application-dev/form/arkts-ui-liveform-sceneanimation-overview.md)：设备、时长和触发约束。
- [官方卡片配置](https://github.com/openharmony/docs/blob/master/zh-cn/application-dev/form/arkts-ui-widget-configuration.md)：isDynamic 默认 true。
- [华为 2026 年 2 月开发者月刊](https://developer.huawei.com/consumer/cn/monthly/202602?ha_source=202602yk&ha_sourceId=89000503)：互动卡片及天气触发后恢复普通状态的示例。
- 本机 API 26 SDK：ets/component/image_animator.d.ts；ets/api/@ohos.app.form.formProvider.d.ts；ets/api/@ohos.app.form.LiveFormExtensionAbility.d.ts。requestOverflow 和 LiveForm 已存在；这只证明 SDK 可编译，不证明当前设备一定支持。
