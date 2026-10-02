# FridgeMemo

原生 HarmonyOS / ArkUI 卡片白板。App 与桌面 Widget 共用作品和布局，手机／平板仅提供 4×4 组件，并读取宿主实际比例。

## 功能

- 卡片直接拖动；点按显示删除、缩放、编辑控制；图层列表处理重叠卡片。
- 单卡由背景创作图层与一个能力组成，支持本地图片、GIF、文字和形状。预览外层的整卡控件可拖动旋转、点击回正，保留元素自己的移动／缩放／旋转及撤销。
- 系统主体抠图、紧致裁切、窄边柔化和误差受限轮廓简化；抠图固定白边。
- 画布背景：纯色、从所有可见卡片提取的智能纯色、按卡片位置融合的智能多色、本地照片，以及本地生成的柔色预设。智能计算在工作线程运行，结果缓存为一张背景图，App 与 Widget 共用。
- 单卡透明 PNG／实色 JPG、整板图片，通过原生系统分享面板分享。GIF 导出为静态图片。可编辑模板分享尚未实现。
- 天气、时间、日期、月历、倒计时、纪念日、今日／年度进度；单卡最多一个能力，按内部可读区域适配尺寸。
- 单色圆角工具 UI、原生 ArkUI 控件、HDS 沉浸导航，App 随系统浅／深色，Widget 保留作品色彩。

## 开发

使用 DevEco Studio 和 HarmonyOS API 26 SDK，兼容 API 24。此仓库只包含 App 源码、配置和测试，不包含签名证书、密码、个人照片、设备截图或构建产物。

```sh
cp build-profile.example.json5 build-profile.json5
```

在 DevEco 中打开项目并配置自己的自动签名。`build-profile.json5` 是本地文件，禁止提交；示例配置不带签名。通过 DevEco / hvigor 编译 `entry` 模块。

测试运行实际模型和服务代码，平台接口使用模拟实现：

```sh
node tests/model.test.cjs
node tests/appearance-lifecycle.test.cjs
node tests/share.test.cjs
```

跨平台运行测试时，用 `FRIDGE_TYPESCRIPT` 指定已安装 TypeScript 模块路径。原生分享、分割与实际桌面呈现还需设备验证；CPU 耗时不等于实际呈现帧率。
