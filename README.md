# 冰箱贴 · 原画布局部改进 Demo

独立目录、独立包名 `com.fridgewidget.demo`，沿用原 App 的 `pages/Index` 作为入口。原来的画布、画框、拖拽、缩放、图层、分组、自由创作、作品切换和桌面添加继续由原界面承接。

## 体验入口

1. 原画布 → 添加卡片 → 模板 → 直接进入 **外观 / 色彩 / 内容** 聚焦编辑。再次编辑模板也直接进入这里，完成或取消回到原画布。模板在画布直接调整位置和大小，操控 pill 提供 **铺满 / 缩回**。
2. 景深模板 → 同一自定页。原图铺满、拖动和缩放、不遮挡预览的时间位置控件、背景色调、原图与主体切换。
3. 原画布 → 添加卡片 → 右上 **素材库**。预览照片、提取主体、标记专辑，点「使用这个素材」加入当前画布。
4. 专辑模板 → 内容 → **封面库**。复用已有封面或照片；资料、轮换和封面移除在同一内容页完成。
5. 普通卡片 → 原来的图片图层设置 → **从素材库选择**。替换当前图片，沿用原图层的位置和尺寸。

自定页只提交当前卡片内容，位置、尺寸、旋转、层级和分组由原画布持有；取消不提交。保存、撤销和桌面更新走原编辑器的逻辑。

## 本机运行

DevEco Studio 打开当前目录，选择 `entry` 和手机模拟器；或运行：

```sh
./scripts/demo-build.sh
./scripts/demo-install.sh
```

开发模拟器产物：`entry/build/default/outputs/default/entry-default-unsigned.hap`。真机调试在此工程配置 `com.fridgewidget.demo` 的签名。原应用与 Demo 各自存储作品，可以并存。

## 改动位置

- `entry/src/main/ets/pages/Index.ets`：局部入口和回写。
- `entry/src/main/ets/views/CardCustomizer.ets`：独立自定面板与素材选择。
- `entry/src/main/ets/views/CardTemplatePicker.ets`：添加面板的素材库按钮。
- `entry/src/main/ets/demo/`：素材和照片构图处理。

上一版重做的首页、简化画布已移出页面路由和编译目录，归档在 `design/rejected-full-shell/`。

编译及回归记录在 `demo-verification/balanced-editor-*`；原工程哈希检查在 `demo-verification/original-integrity.json`。

最新设计与 UI 检查：`design/template-editing-2026-11-09/`；编译、回归和原生截图：`demo-verification/template-redesign-*`、`demo-verification/live-flow/`。
