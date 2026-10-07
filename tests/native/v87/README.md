# v87 — 云白云母融合、单边吸附与自由挂钩

2026-10-07。仅使用 Mate 80 RS 模拟器 `127.0.0.1:5555`，没有操作连接的实机。

## 实现与兼容

- 裸字是一笔粗略覆盖真实内容尺寸的半透明云白笔触；徽章、贴片、云朵、挂签和 Dock 使用中性云白。没有按卡片颜色异步换色，也没有运行中的背景模糊采样。这里的“云母”指视觉材质，不冒充系统原生 Mica API。
- 新样式和旧衬底统一遵守 ReadingStylePolicy；旧纸纹/羽化配置迁移为对应默认样式，不改变已保存的卡片形状和手动坐标。
- 时间、日期、倒计时、纪念日、今日/今年进度、日程及课程表：除徽章外的五种；世界时钟和农历：贴片、负空间、挂签、Dock；台历：贴片、负空间；电量：徽章、挂签、Dock。专辑沿用专用布局。
- 负空间/贴片吸附最近一条内侧或外侧边：6vp 进入、10vp 脱离。主体轮廓使用缓存栅格边界，拖动热路径读取四个边界值；圆形使用解析边界。普通矩形使用边框。倾斜超过 3 度时不吸附，避免强行拉直。调整右/下吸附边尺寸时保持原边位置。
- 不逐帧遍历主体轮廓。轮廓边界在启动布局准备时预热，后续沿用有上限的布局缓存。
- 手动能力坐标从限制在底板内部放宽为 [-2, 2]；“位置预设”仍可恢复到卡片内。拖动只更新独立 motion，完成后记录一次历史/存储。
- 挂钩沿上半圈自由选位；独立 foreground overlay，外移小幅留出穿孔区，避免盖住标题；绘制缓存考虑挂钩外伸部分。只在手势完成后应用位置。
- ReadingBacking 移除测量后写回 @State 的反馈循环。内在内容尺寸决定衬底，静态矢量素材负责缩放。路径单位问题通过 SVG viewBox/preserveAspectRatio=none 明确处理，ArkUI 原生 Image 渲染。

## 验收证据

- `mica-portrait.jpeg`：六种实际 ArkUI CardFace/CapabilityView，使用本地程序生成的黄色底板。
- `mica-hook-after.jpeg`：拖动挂钩选位后，挂签/Dock 同步到右上；不是 HTML 模拟。
- `mica-landscape.jpeg`、`mica-landscape-lower.jpeg`：横屏滚动、空日程、三位电量。
- `mica-dynamic.jpeg`：每 1.5s 切换 67/100、长短标题、空/两项日程；固定节点，内容自适应。
- `sampled-stability.json`：动态测试期间 16 个截图样本，笔触、台历和云朵静态材质区域的平均像素差最大值均为 0。说明抽样中未出现材质消失/重建，不能替代逐帧录像或真机 120Hz 测试。
- 30 个 `tests/*.test.cjs` 全通过，含兼容策略、迁移、物理吸附阈值、轮廓边界、缓存、分享序列化及 App/Form 模型一致性；release assembleHap 成功。日志为 `test-results.txt`。
- 5,000 次预热轮廓边界吸附约 2–3ms（Mac 模型 CPU），不作为设备帧率结论。
- 本轮没有测真实桌面 Form 宿主动画、实机连续拖动帧率，也没有用空画布截图声称验证了复杂主页闪烁。已修复能在组件中复现的布局反馈与裁切原因，需后续真实用户画布复测。

## 素材

`mica_hook.png` 由 imagegen 生成，原图未修改；运行时 sourceSize=64×64，避免完整尺寸解码。其余 SVG 是代码定义的矢量素材。

生成需求摘要: A single standalone small open U-shaped / open oval attachment hook for a refined sticker/card app, softly brushed pearl-silver metal, clean rounded edges, subtle believable depth and tiny dark inner highlights, isolated on truly transparent background. One hook only, front view, no text, no paper, no shadow plate or background. Suitable as a reusable native UI attachment asset.

## 原生复现

`MicaQA.ets` 只保存在此测试目录，不进入正式包。临时复制到 `entry/src/main/ets/pages/`，在 main_pages 加页面，并给 EntryAbility 添加 demo=mica 的开发路由后构建：

```
hdc -t 127.0.0.1:5555 shell aa start -a EntryAbility -b com.fridgewidget.app --ps demo mica
```

最终正式包已移除上述临时页面、路由与注册。

路径单位参照 [华为 Path 文档](https://developer.huawei.com/consumer/cn/doc/doccenter-capabilities/api/ts-drawing-components-path)：commands 的坐标单位为 px。SDK shape.d.ts 同时确认 ViewportRect 默认单位为 vp，不能混用。
