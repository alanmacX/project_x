# 一体式组合的设计参考

2026-11-01 阅读官方资料并实际查看 Apple Watch 表盘截图，重点查看 Ultra 模块的完整盘面与模块/紧凑模块/模块 Duo 的说明。

- [Apple Watch 表盘及其功能](https://support.apple.com/en-cn/guide/watch/apde9218b440/27/watchos/27)：主时间与日期共享一个盘面；辅助信息依附角色槽位，颜色、字重和留白建立层级。采用整体主次结构，重新设计自己的纸白/深蓝/鼠尾草主题。
- [iPhone StandBy](https://support.apple.com/guide/iphone/use-standby-iph878d77632/ios)：横向远读、大时间与日历配对。横向单独编排，数字不拉伸；方形保留同一套视觉语言。
- [Apple complications HIG](https://developer.apple.com/design/human-interface-guidelines/complications)：辅助信息应短、清楚，服从整体表盘。每槽位继续对应一种原生 capability。

## 应用到这次实现

| 组合 | 主信息 | 辅助角色 | 整体语言 |
| --- | --- | --- | --- |
| 桌边 | 大数字时间 | 周历 / 横向月历 | 纸白、细分隔线、冷墨色 |
| 今日 | 大数字时间 | 日程、电量 | 深墨蓝、浅绿强调、统一横条 |
| 课间 | 时间 | 下节课、今日进度 | 暖纸色、课程标题、赭色进度 |
| 远行 | 目的地模拟时钟 | 出发倒计时 | 深海蓝、暖金指针、一体盘面 |
| 相片日历 | 个人照片 / 纪念日天数 | 日期、农历 | 鼠尾草绿，支持真实照片和离线主体提取 |

生产设计使用自己的几何、已授权 Barlow Condensed 数字字体和系统中文字体。没有使用 Apple 表盘素材、商标或 AI 生成图片。
