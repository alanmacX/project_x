# 柔软云朵正式接入验收

2026-10-08，Pura X Max HarmonyOS 模拟器，2584 × 1828。截图来自 ArkUI 原生渲染；未生成概念图。

正式入口：卡片编辑 → 上层内容 → 融合方式 → 柔软云朵。新选择的能力默认使用云朵，电量默认徽章，专辑维持独立设计。已有卡片保存的样式保持原样。

## 能力覆盖

| 能力 | 完整 / 可读下限 | 观察结果 |
|---|---|---|
| 时间、日期、台历、世界时钟 | time-full / time-compact | 数字完整；日期紧凑副标题不再截断；台历分别显示月 / 周 |
| 倒计时、纪念日、今日进度、年度进度 | progress-full / progress-compact | 主数字和单位位于云朵内容安全区 |
| 日程 | agenda-full / agenda-compact / agenda-empty | 完整两条、小尺寸一条并标记额外项；空内容缩短衬底 |
| 课程表每日概览、下一课 | agenda-full / agenda-compact / agenda-empty | 两种模式一致；起止时间完整；最小尺寸长课程名允许单行省略 |
| 农历 | agenda-full / agenda-compact | 日期和干支年份完整 |
| 电量徽章、电量云朵 | special-full / special-compact / special-empty | 环与数字完整；无百分号或充电状态文字；不可用显示短横线 |
| 专辑 | special-full / special-compact | 原封面和边框保留，无云朵叠加；使用模拟器已有本地图片，图片中的英文不是应用报错 |

agenda-widget、special-widget 是 App 内 widget=true 分支检查，不能代替真实桌面宿主。

desktop-calendar、desktop-anniversary、desktop-timetable、desktop-battery 是实际桌面 FormKit 宿主截图：经正常 updateWidget 队列和 scenePacket 传递，检查外扩云瓣、文字安全区、抗锯齿和渲染一致性。没有修改本地画布数据，测试结束恢复原绑定画布。其余能力在生产 CardFace / CardCanvas / CapabilityView 路径检查。

## 实现约束与检查

- 云朵使用固定复杂度的原生贝塞尔路径，外扩云瓣，不扩大文字布局的 padding 或能力最小尺寸。
- 轻微偏移的同形路径提供厚度；不使用模糊、位图生成、随机轮廓或定时绘制。
- 云朵外扩纳入卡片缓存、截图和分享的边界计算。
- cloud-capability.test.cjs 覆盖全部 12 个非专辑能力的保存恢复、外移旋转、最小尺寸不变、实体卡片衬底启用，以及几何安全区。
- 全部 34 个 tests/*.test.cjs 通过；release assembleHap 成功并安装。
- 本轮没有真机帧率测量，不能据此宣称满刷新率；也没有将分享导出的成品图纳入截图验收。

复现：冷启动 EntryAbility，参数 --ps demo cloud。隐藏验收页读取正式渲染器与固定测试数据；“发送桌面验收”只发送临时组件数据，“恢复桌面”恢复绑定画布。正常应用流程不会进入此页。
