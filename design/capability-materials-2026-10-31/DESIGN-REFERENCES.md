# 单能力卡片：学习记录与设计决定

2026-10-31。采用 anti-aidesign、仓库 fridge-create 与 imagegen skill。范围已经按用户纠偏改为单能力卡片预设。

状态：此页记录旧材质稿的制作依据。用户随后撤回手工复现限制，并否定吊牌与信号；最新研究与架构见[模板偏好调查](../../research/template-preferences-2026-10-31/README.md)。

## 实际查看

- [Apple Watch 表盘](https://support.apple.com/en-ie/guide/watch/apde9218b440/watchos)：浏览器查看 Artist、Contour、Numerals Duo、Playtime 的图像。时间可参与插画、轮廓和数字造型；据此选择让每张能力卡拥有自己的外形与材质，不要求每张都带相同标题和底板。没有使用 Apple 图像、字体、角色或表盘资产。
- [Widgetopia / Date calendar，dooks2](https://widgetopia.io/widget/date-calendar-sMH)：实际查看大日期与小月历组成同一作品的画面；借鉴单张作品内部主次清楚、不逐字段加独立容器。未下载或复用作品。
- [Color Widgets 官网](https://colorwidgets.app/)：实际查看组件组合图。相同时间/日期内容通过照片、字体层级、背景和构图形成不同个性。借鉴同能力多种外观，不把照片或图像纹理误当额外的数据能力。
- [iScreen 官网](https://www.iscreenapp.com/)：实际查看 Creative Widgets 与 Theme 两组画面，包括物件化电量、音乐物件与不同主题。借鉴把能力融入一个可辨认的小物件；本稿选择液晶机身、黑胶、日历纸、票据和吊牌，没有复制其角色、图片或交互能力。
- [Widgetsmith 配色主题文章](https://widgetsmith.app/blog/2025/6/widgetsmith-7-3-wallpapers)：实际查看主题配置与协调配色截图。借鉴材质/配色可复用到用户自己的卡片，而不是固定一整张画布。

## 文字资料

[Widgy 官方 App Store](https://apps.apple.com/us/app/widgy-widgets-home-lock-watch/id1524540481)介绍了文本、照片、形状、图表的图层编辑及导入后修改；这次浏览器打开被地区重定向，没有将该商店截图记录为已查看。[MD Clock 官方商店](https://apps.apple.com/us/app/md-clock-flip-clock/id1536358464?platform=mac)描述多种时钟主题；这次只核对文字，没有据此推断内部技术。

## 本次设计

前一稿用户评价粗糙，因此保留原生结构作为对照，用 imagegen 补充纸纤维、压纹黑胶和磨砂塑料三种原创材质。生成的只有静态纹理；原生 capability、卡片形状、能力位置和装饰保持独立。用户可以在同一编辑器中添加相同的图片图层、基础形状和能力，从头做出同款。

材质提供原始图与压缩展示图，作为图片元素随单卡打包；不增加隐藏渲染分支或无法手动复现的模板专属字段。材质可关闭、替换、改透明度；关掉后回到基础稿。生成提示词、来源、哈希和尺寸见 `materials/sources.json`。
