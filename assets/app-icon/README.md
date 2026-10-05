# 冰箱贴正式图标

采用用户选定的第三个候选：鼠尾草绿上门、珊瑚色下门、米白把手，黄色磁贴叠在门缝右侧。使用内置 image_gen 从已批准候选提取透明前景，工具脚本仅完成规格归一、纯色背景与导出合成，不重新塑形。

## 资源与配置

- AppScope 和 entry 的 `foreground.png`：1024×1024，透明背景，包含主体及轻微接触阴影。
- `background.png`：1024×1024，完全不透明，全部像素为 #F6F2E9。
- `layered_image.json` 引用这两层；应用与主 UIAbility 均引用双层资源。
- `app_icon.png`：同一图案的合成图，供文件分享入口使用。
- `start_icon.png`：透明前景，供现有简单/增强启动页配置使用。
- 此目录 `appgallery-icon-216.png`：216×216 方形合成导出，保留为上架资源源图；正式提交时按 DevEco Image Asset 与最新 AGC 规范处理和核对。

没有预先裁剪外层圆角；由系统图标处理负责桌面显示效果。没有引入联网动态图标或账号能力。

官方规范：https://developer.huawei.com/consumer/cn/doc/best-practices/bpta-app-icon-configuration

## Imagegen 提示词

Edit target: the provided approved icon candidate. Prepare its FINAL HarmonyOS icon foreground layer, a square 1024x1024 transparent PNG. Remove ONLY the entire ivory background and any background texture. Keep the small refrigerator foreground IDENTICAL: pale sage upper rounded door, coral terracotta lower rounded door, two cream capsule handles on left, butter yellow irregular square magnet overlapping the right-hand seam, frontal geometry, silhouette, material, proportions and colors. Preserve original position and size on the square canvas exactly. Do not zoom, recenter, enlarge, crop or redesign anything. Retain only the subtle close contact shadow immediately beneath the fridge as low-opacity transparent pixels; no colored opaque halo, no diffuse full-canvas shadow. Crisp smooth anti-aliased edges. Genuine alpha transparency all around the foreground, no checkerboard painted into pixels, no ivory rectangle, no outer icon mask, no text. This is a foreground extraction, not a new icon concept.

生成源图尺寸为 1254×1254；通过 `tools/prepare-app-icon.cjs` 归一到 1024×1024。复用时设置 SHARP_MODULE 指向可用的 sharp 包并传入透明源图路径；不增加 App 运行时依赖。
