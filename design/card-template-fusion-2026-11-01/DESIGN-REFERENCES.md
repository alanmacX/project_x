# 参考与设计决定

2026-11-01。调研使用浏览器和官方文档；下列功能观察与本产品建议分开记录。

## 实际查看

1. [Apple Watch Photos 定制指南](https://support.apple.com/en-gb/guide/watch/apd501eb33b3/26/watchos/26)：浏览器打开正文与青蛙照片表盘截图。主体靠右，狭长数字靠左；照片主角与数字的重叠来自构图，操作控件留在表盘外。先选择照片与样式，再调整布局。借鉴照片/排版/遮挡的局部定制，不搬入 complications 多消息源模型。
2. [Apple watchOS 11 发布说明](https://www.apple.com/ie/newsroom/2024/09/watchos-11-is-available-today/)：官方明确提及按主体位置优化构图、营造纵深。支持“自动选初始构图”的方向，不能推导为任意图片都能自动获得理想遮挡。
3. [Widgetsmith 官网](https://widgetsmith.app/)：浏览器查看实际四台手机展示图。照片保持主要面积，时钟、倒计时、列表各有独立表面；同色和字体把多个信息块联系起来。借鉴协调主题，不将照片、日历、天气强塞进一张模板卡。
4. [Widgetsmith FAQ](https://widgetsmith.app/widgetsmith-faq)：主题可改背景、字体、色调、边框、装饰，支持只用于一枚或更新主题。我们采用实例级编辑，首期不做自动全局联动，防止改一张影响其他画布。
5. [Kustom Komponent](https://docs.kustom.rocks/docs/general_information/groups_explained/)：官方定义为可复用的局部模块，对使用者暴露局部参数，组合后仍能整体移动。借鉴“封装好的部件”，不引入其嵌套对象树、公式编辑和组件全局变量体系。
6. [Kustom Globals](https://docs.kustom.rocks/docs/reference/globals/)：说明有界的颜色、图片、文本等参数足以支持多处外观定制。本产品参数限制在当前卡实例中。

## 产品决定

- 模板是 card 的专属外观；整套成品通过现有 canvas 内的普通 cards 组合实现。
- 从首页选模板：创建现有 canvas + 一张模板 card；从编辑页选模板：向当前 canvas 加一张 card。没有第二套可绑定对象。
- 照片卡、贴纸、无底是模板设计声明支持的呈现形式，不是让所有模板被任意剪裁。不同尺寸采用作者设计的构图档位。
- 卡片数据源/外观各自稳定。clock 的日期属于同一时间上下文的派生字段；独立课表、倒计时仍用独立 cards。
- 现有照片、纸本模板和新模板能在一块冰箱画布共存；不自动重排老画布。

## 生成图与真实素材

`concept-flow.png`、`concept-customize.png` 是按用户这次请求用内置 imagegen 生成的产品概念板，不是素材包，不进入 App。

交互原型引用上一目录的 Painjet 真实猫抠图、ambientCG CC0 纸张与 OFL 字体。作者与授权：[LICENSES.md](../template-capabilities-2026-11-01/LICENSES.md)。生成图里的背景虚化、完整贴纸轮廓、系统材质为概念表达；浏览器原型实际验证的是单卡/组合、静态遮挡、外观与实例参数保留。
