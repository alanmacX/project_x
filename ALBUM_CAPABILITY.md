# 本地音乐专辑能力

2026-10-05。用户决定以本地封面为准。当前不搜索平台、不下载封面、不读取播放状态。

系统相册选择 → 本机 TaskPool 复制/缩放封面 → 本机取色 → 生成静态 FluidGradient 背景 → 一次提交。封面保持原比例，居中，占卡片短边 70%；背景固定。普通背景、形状和能力位置不开放。失败保留旧封面与背景，拖动/缩放不联网、不重新取色。封面最长边 500px，背景为 320×320 PNG。

专辑名和歌手可选，本地填写。来源建议是可复制文字：MusicBrainz / Cover Art Archive、Discogs、艺术家或唱片公司官网；用户自行在浏览器保存图片后导入，App 不访问这些网站。平台搜索及远端下载代码已删除；此前保存在本机的专辑照常显示。

参考来源：[Cover Art Archive](https://musicbrainz.org/doc/Cover_Art_Archive)、[Discogs 图片规则](https://support.discogs.com/hc/en-us/articles/360005006874-Database-Guidelines-13-Images)。公开查看封面不等于获得任意商业再发行授权。

分享包包含封面与背景；桌面用 FormKit 本地图片传输，接收方不必重新生成或访问网站。专辑布局、静态背景、资源打包和桌面描述符均由回归检查覆盖。
