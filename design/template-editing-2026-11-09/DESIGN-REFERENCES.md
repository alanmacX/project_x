# 模板编辑与素材复用 · 设计依据

## 实际检查的参考

- [Apple Watch 表盘](https://support.apple.com/en-us/guide/watch/apda6559ad78/watchos)：查看官方 Flow 表盘编辑入口截图。中心大预览保持唯一焦点，编辑控制依附当前对象；保留现在的聚焦编辑与进退场，不在编辑器里再进入另一套模板设置。
- [Apple Watch Photos](https://support.apple.com/en-us/guide/watch/apd501eb33b3/watchos)：读取官方照片来源与构图流程。照片作为表盘内容来源，原图、主体和色调共享同一素材身份；来源选择后回到当前内容页。
- [StandBy](https://support.apple.com/en-ie/guide/iphone/iph878d77632/ios)：读取官方在显示类型和样式间切换的说明。外观选择和数据修改按当前模板提供，避免把所有能力塞进常驻面板。
- 鸿蒙本地 SDK 系统 symbol 清单：`arrow_up_left_and_arrow_down_right`（展开）和 `arrow_down_right_and_arrow_up_left`（收回）。在选中模板的操控 pill 中采用这对系统符号，并配“铺满/缩回”文字，明确作用于画布而非进入设备全屏。

网页检索接口返回 429，以上 Apple 正文与图片改用直接 HTTP 获取并检查。沿用原画布、深色模板编辑器、现有绿色选中态；没有重做品牌视觉。
