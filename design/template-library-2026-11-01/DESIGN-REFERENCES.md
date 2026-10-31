# 模板扩展的参考与取舍

2026-11-01。按用户要求扩展候选，不改正式 App 界面。原有三组方向继续保留；本目录为浏览器设计样稿。

## 1. iPhone StandBy 与 iPhone Duo

- [Apple StandBy 官方指南](https://support.apple.com/en-mt/guide/iphone/iph878d77632/ios)：浏览器实际查看普通 iPhone 黑底指针钟/月历并排图，以及 Duo 帐篷姿态下“大日期+小月历+大指针钟”的图。文字记录了 Duo 对样式、字体、内容、位置与 widgets 的定制。
- [iPhone Duo 官方产品页](https://www.apple.com/iphone-duo/)：核对 Standing 和 StandBy 的产品定位；未把第三方泄漏图当正式设计依据。
- 采用的关系：远距离读数、明确大主角、日期与时间不争抢同一面积。单卡“浮字”“日历海报”“月历”分别发展；“桌边”组合采用左右分区，给时间和日历足够面积。
- 不复制 Apple 字体文件、界面截图、系统图标或专属数字轮廓。数字使用已授权的 Barlow 与系统通用字体。

## 2. Apple Watch

[官方表盘与功能目录](https://support.apple.com/en-gb/guide/watch/apde9218b440/watchos) 在浏览器访问，实际查看 Modular Compact、Modular Duo 的界面图；阅读 Numerals Duo、Palette、GMT、Lunar、Photos 方向。

- Modular Duo：时间保持稳定位置，两个大信息区各有主次。对应“今日”“课间”，时间、下一事件/课程、电量或进度形成统一构图。
- Numerals / X-Large：数字本身承担构图。对应“浮字”“出发”“记忆”。
- Palette / Simple：从盘面色块、刻度与指针建立性格。对应“色盘”“异地”。
- 活动与电量的图形：环必须对应真实进度，不增加无含义装饰圈。对应“能量环”“一天”“年轮”。
- Photos：沿用个人照片与景深方向；示例照片保持真实授权来源。
- Lunar：借鉴中文信息的主次，不展示尚未实现的天文月相、日出或地理数据。样稿“月白”的圆盘是装饰，无月相读数。

## 3. 热门与其他小组件

- [Widgetopia Popular](https://widgetopia.io/?sort=popular)：这次重新读取榜单，头部仍可见 Date calendar、Flip Clock、电量等。前一次保存的 40 项热门/20 项近期榜单和截图观察见 [调研记录](../../research/template-preferences-2026-10-31/README.md)。这是样本观察，不标注未经公开的用户占比。
- [MD Clock 官方 App Store](https://apps.apple.com/us/app/md-clock-flip-clock/id1536358464)：读取开发者主题/StandBy介绍和可见评论；有用户要求更丰富设计与可定制成品。借鉴电子屏与实体钟的明确风格分化，不靠换颜色凑模板数。
- [Widgetsmith 开发者披露](https://david-smith.org/blog/2023/09/18/widgetsmith-5-interactive-widgets/)：2023 年披露 Single Photo 是当时配置最多的类型。用于支持个人照片的优先级，不外推为当前市场份额。
- 音乐物件、纸本记录、年度点阵：作为视觉题材，实际数据沿用本地专辑、日期和进度；没有画音乐播放键、健康数据或天气功能。

## 4. 这次设计策略

每种 capability 3 款，时间额外保留景深照片，共 40 款单卡；再补 5 组组合。变体的构图、信息密度、字形或物件关系不同，不将同一款的深浅/配色计成新模板。

| 家族 | 使用方式 |
| --- | --- |
| 远读数字 | 主读数极大，次级日期收边 |
| 指针与图形 | 指针、环、填充与数据一一对应 |
| 纸本 | 扫描纸纹轻混合，排版与线条负责主要层级 |
| 编辑排版 | 对齐、字号与信息顺序；不用装饰图标撑场 |
| 个性照片 | 可替换个人照片，主体清晰、文字可读 |
| 模块组合 | 每个数据区独立来源，整体保持协调的字体和色彩 |

原型可切换示例/未设置/长内容、180px 小尺寸，并对各款收藏。收藏仅保存在本浏览器，方便评审，不是 App 新导航。

## 5. 素材

没有新生成式 AI 素材。照片/纸张/字体引用 [上次保留的授权文件](../template-capabilities-2026-11-01/LICENSES.md)：Painjet 真实猫照片 CC BY 4.0、ambientCG 纸张 CC0、Barlow Condensed OFL。

本地专辑示例封面为本目录 `renderers.js` 中原创几何构图，标题“蓝色练习”，不是商业唱片封面或在线音乐功能。其余为可编辑 HTML/CSS/SVG 设计，未引入 Apple 资产。


## 2026-11-01 精修：调色盘与弱项

用户指出原调色盘明显弱于 Apple，重新核对 [watchOS 10 官方发布说明](https://www.apple.com/uk/newsroom/2023/09/watchos-10-is-available-today/) 及其中 Palette 的官方照片（Image 16）。官方照片仅用于研究，没有纳入仓库或运行素材。画面观察：三层同心叠色、颜色随指针方向分布，细白描边指针，盘面没有原样稿的 60 个刻度和四个大数字。原稿混入传统指针钟的元素，固定低饱和四色使时间与颜色失去关系。

- 调色盘改为独立 renderer；背景、外环、中环与中心叠色，小时/分钟角度参与色相分布，指针从中心精确对齐。光谱、海蓝、暖光、暮紫为同一模板的配色，不增加模板计数。没有用 Apple 字体、截图或运行素材。
- 环绕倒计时改薄弧；日期与弧线分开，降低圆环对主读数的压迫。
- 今日进度改为 24 段，数量与小时直接对应；部分时段按实际进度填充。
- 年轮改轻字重百分比、细轨道与月刻度，已过/剩余天数回到页脚。
- 周课表从逐列堆叠改成按实际开始/结束时间定位。使用生产 weekLessons 的日期、lane 与 lanes；小尺寸课程名称按两字宽控制断行。
- 月记改为衬线月份与日期；纪念章收细边线和字重；电格改为真实七段数字与部分格填充。

精修前截图保存在 `previews/polish-before.png`；精修总览 `polish.png`，调色盘配色总览 `palette-v2.png`。定义 revision 对这 8 款升为 2；图库仍为 40 款单卡 + 5 组组合。
