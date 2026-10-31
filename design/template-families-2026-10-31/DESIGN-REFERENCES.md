# 设计参考

2026-10-31，使用 anti-aidesign 和仓库 fridge-create skill。

1. [Apple Watch 表盘及功能](https://support.apple.com/zh-hans/guide/watch/apde9218b440/27/watchos/27)：浏览器实际查看“模块”与“调色盘”图像及相邻数字表盘。模块将主时间、中央内容与小型数据位置分开；调色盘用同心色面建立完整构图。借鉴**每一系列独立的构图、信息密度和可配置位置**，不复制 Apple/Snoopy 图像、表壳、表盘或指针。
2. [Widgetsmith 5，David Smith 原始发布文章](https://david-smith.org/blog/2023/09/18/widgetsmith-5-interactive-widgets/)：重新阅读照片图库、照片与信息组合、photo locket 的不同呈现机制；之前调研实际查看其照片组件图像。借鉴同一内容源可采用不同视觉容器，内容选择与外形选择分开，互动只承担一个容易理解的动作。
3. [Apple Watch 表盘图库](https://support.apple.com/zh-cn/guide/watch/-apda6559ad78/watchos)：搜索可读取配置流程；直接打开遇限流。只将其作为颜色、样式和数据位置分别配置的文字依据，不记录为已查看画面。

## 构成选择

这次将三种系列同时呈现，直接比较轮廓、排版和密度；图库的栏目只写风格名。仪表采用正交排列与荧光主读数；纸本采用原创票根、暖色纸张与角度；色块采用横椭圆、放射形和蓝橙对比。每张作品仍由独立原生卡片组成。

图形来源：本目录 `sources/ticket.svg` 与 `sunburst.svg` 是原创代码图形，PNG 由 Sharp 栅格化，透明轮廓由当前 SubjectGeometry.traceMask 提取。无网络素材、AI 素材、字体文件或第三方照片。

视觉检查发现仪表初稿年度进度条被底部裁切，删去第五个信息位并重新安排圆形电量；纸本初稿周历在大纸片中偏空，改用原生日程并检查空/长内容。保留宿主原来的阴影、圆角和主体边界。
