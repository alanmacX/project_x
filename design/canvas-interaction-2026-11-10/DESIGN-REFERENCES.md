# 画布操作整理 · 2026-11-10

保留原画布、普通冰箱贴编辑与模板沉浸式定制。调整选中状态、操作归属、历史和图层面板。

## 实际参考

- [Procreate 官方 Layers 教学](https://assets.procreate.art/education/pdfs/ProcreateLayers-IntermediateSeries.pdf)：查看 PDF 第 9 页（印刷页 6）图层面板截图：缩略图/名称/可见性在同一行，选中行突出，画布背景独立位于最底部；阅读印刷页 10 的拖动排序说明。采用低密度行和明确选中状态，低频操作集中到所选图层菜单。
- [Apple Freeform：定位画板项目](https://support.apple.com/guide/ipad/position-items-on-a-board-ipad0b4f22b0/ipados)：直接读取官方页面的移动、调整大小、安排、锁定操作。采用移动和排列分离、固定底层的语义，保持用户原来的画布手势和手柄。
- 本地 HarmonyOS SDK `resources.txt`：核实 `fullscreen`、`square_and_square`、`line_3_horizontal`、撤销与重做 symbol。铺满使用四角框；缩回使用大小方框；自由缩放保留对角箭头。

## 构成

导航栏常驻撤销/重做。面板展开时画布等比缩小并完整留在面板上方；面板负责所选对象操作，隐藏画布 pill 和变换手柄。普通行保留缩略图、名称、单行类型、排序手柄和可见性；底部只有编辑、模板铺满/缩回和更多。全屏模板固定为底层，用户原来的 z/group 布局在缩回后继续使用。
