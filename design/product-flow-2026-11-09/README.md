# 冰箱贴 · 本地创作原型 05

2026-11-09。第 5 版保留 **作品 / 素材库 / 模板**，重做模板编辑体验：大预览、横滑分项、直接点选画面中的内容，按 Apple Watch / StandBy 的操作关系组织。

## 打开

仓库根目录运行：

```sh
python3 -m http.server 8765 --bind 127.0.0.1
```

打开 http://127.0.0.1:8765/design/product-flow-2026-11-09/ 。顶部可以切换手机 / 大屏，或有作品 / 空白资料库。

## 普通冰箱贴与模板的统一流程

- **作品 → 我的周末冰箱**：点便签选中，拖动摆放；使用缩放、旋转手柄，或点「排列」。
- **选中 → 自定**：普通照片、文字与模板使用同一个外观 / 颜色 / 内容编辑器；完成后回到原排版。双击文字可直接输入。
- **添加 → 文字便签**：直接输入；**添加 → 模板**：44 个模板直接进入当前作品，仍能继续自定。
- **单模板作品 → 更多 → 排布与添加**：继续在原作品上添加内容，保留原名称、几何与桌面绑定。
- 标题栏完成保存作品；单张贴纸自定页完成返回作品。具体取舍见 UX-DECISIONS.md 的原型 05 部分。

## 重点体验

1. **作品 → 棕猫 · 景深照片 → 外观 → 原图**：默认 cover 铺满，缩放下限 100%，拖到边缘停止。主体模式仍可完整显示，并单独记住构图。
2. **背景 → 原色 / 暖调 / 冷蓝 / 玫瑰 / 黑白**：调整照片背景，保留主体颜色。保存并刷新后仍恢复选中的效果。
3. **内容 → 点照片 / 时间**：分别进入构图和时间选位；自动排好不会缩小原图或改回留边。
4. **模板 → 任一模板 → 自定**：44 个生产模板共用同一编辑框架。外观里换同类样式，尺寸作为次级选择，内容与作品 ID 保留。
5. **课表 / 日程 / 倒数日 / 纪念日 / 世界时钟 / 专辑 → 内容**：点预览中的区域打开该项；课程和日程支持增删，学期与周次折叠展示。
6. **组合 → 远行**：城市和倒数日分别点选。**组合 → 相片日历**：照片和纪念日分别点选，照片入口复用素材库。
7. **完成 → 添加桌面**：新作品保存后进入模拟系统添加；已有作品保持原来的 ID 与绑定。原来的自由画布、素材库、归档、草稿恢复继续保留。

## 实现与说明

- UI / 交互：`index.html`、`style.css`、`face-editor.css`、`app.js`。
- 作品与素材状态：`state.js`，与 `editor-model.js` 及 `board-model.js` 合计 22 项测试见 `state.test.cjs`、`editor-model.test.cjs`。
- 模板与图像构图：复用项目 `previewer/renderer.js`、`TemplatePhotoComposition`、`PhotoCameraGesture`、`recommendPhotoClock` 等共享模型。
- 照片在浏览器本地处理；文件最长边压到 1200px 后用于演示，存于当前浏览器。此限制只用于原型。
- 使用独立的 `fridgememo-product-demo-v2` 和 `-draft` 存储。第一次打开会读取第 1 版演示的作品，保留作品、卡片与桌面绑定 ID；原生存储不参与。
- 桌面添加明确为模拟流程；普通照片可手动关联透明主体，示例主体是已有授权素材。

## 文档

- [具体交互取舍与原生调整点](UX-DECISIONS.md)
- [设计参考](DESIGN-REFERENCES.md)
- [验证记录](VERIFICATION.md)
- [新增原图来源](assets/README.md)及[原有素材授权](../template-capabilities-2026-11-01/LICENSES.md)

原型 05 截图：`v5-board-mobile.jpg`、`v5-sticker-content-mobile.jpg`、`v5-board-desktop.jpg`。

原型 04 截图：`v4-photo-background-mobile.jpg`、`v4-course-style-mobile.jpg`、`v4-composition-content-mobile.jpg`、`v4-editor-desktop.jpg`。`face-*` / `studio-*` 为历史画面。
