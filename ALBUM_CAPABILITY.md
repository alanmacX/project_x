# 音乐专辑能力

2026-10-05。专辑目录采用 MusicBrainz，封面采用 Cover Art Archive。不是播放控制，也不依赖用户当前播放或音乐平台登录。按专辑名、歌手搜索，用户确认具体版本后保存封面和背景。

## 设计与性能

封面保持原比例，居中，大小为卡片短边的 70%。背景复用 Cindori/FluidGradient 移植的 blendPixels：色团、Overlay 高光与三次模糊；只在选择专辑时运行一次 TaskPool，生成 320×320 PNG。封面最长边 500px。首页、编辑、桌面共用已保存素材，拖动/缩放不取色、不联网、不播放背景动画。换专辑完成后一次提交，失败时保留旧封面与背景。

当前卡片背景为固定圆角矩形，不开放普通背景创作或能力位置控制。原创作图层保留，切回其他能力可继续使用。分享包嵌入封面与融合图，接收方无需重新搜索；桌面用 FormKit 图片描述符传输并释放文件句柄。

## 数据源与边界

- [MusicBrainz 搜索 API](https://musicbrainz.org/doc/MusicBrainz_API/Search)：release-group 专辑检索，最多 20 项，支持专辑名/歌手组合。
- [MusicBrainz 请求限制](https://musicbrainz.org/doc/MusicBrainz_API/Rate_Limiting)：明确 User-Agent；手动提交，不随输入逐字请求；界面最短 1.1 秒间隔，无后台自动刷新。
- [Cover Art Archive API](https://musicbrainz.org/doc/Cover_Art_Archive/API)：按 release-group 取正面封面，500px；404 显示缺封面，不拿其他专辑图片代替。
- [MusicBrainz 服务口径](https://musicbrainz.org/doc/MusicBrainz_API)：非商业调用免费，商业发布需核对其商业服务要求；开放目录不等于封面版权授权。尚未接入 QQ 音乐/网易云音乐账号或目录，不承诺覆盖所有中文专辑。

未采用 iTunes 免费搜索作为任意装饰素材库：[Apple 条款](https://developer.apple.com/library/archive/documentation/AudioVideo/Conceptual/iTuneSearchAPI/index.html)限定其推广用途，与纯装饰卡片不直接一致。

## 验证

API 24 手机模拟器：从能力选择进入专辑搜索；实际搜索 Abbey Road Beatles，选中 The Beatles 的 Abbey Road；封面下载、静态背景生成、预览与退出重新进入均通过。专辑模式不显示普通底板和内容位置控制。编译与专辑、模型、作品包、多画布回归检查；作品包资产映射和 FormKit 双素材描述符均有测试。没有使用真机，未验证国内所有网络环境和全部音乐目录。
