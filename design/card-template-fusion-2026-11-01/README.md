# 卡片模板融合研究与原型

- [架构与升级方案](ARCHITECTURE.md)：产品模型、景深、个性槽位、现有代码接入点、升级兼容、资源/性能与验收。
- [参考记录](DESIGN-REFERENCES.md)：Apple Photos、Widgetsmith、Kustom 官方资料与实际查看画面。
- [交互原型](index.html)：单卡与组合两种场景；同一张时钟 card 保持数据源/ID/个性设置；可添加独立日程/便签，再移除其中一张；景深开关和无底模式。
- [流程概念图](concept-flow.png)、[定制概念图](concept-customize.png)：内置 imagegen 生成，提示词见 [image-prompts.md](image-prompts.md)。仅用于产品概念沟通，不作运行素材。

原型使用上一目录的真实授权照片/字体/纸张，详见 [授权](../template-capabilities-2026-11-01/LICENSES.md)。示例时间固定 09:41；示例日程是演示内容，没有读取设备日历。

顶部“单卡画布 / 自由组合”是两个产品使用场景的演示切换，不提交真实 canvas 尺寸变化，不写入 App；切回单卡时其他卡的编辑草稿保留。正式产品仍由原画布尺寸选择/变更流程管理尺寸，不按卡片数量静默改变宿主尺寸。

原型中的前后遮挡实际由 DOM 图层实现；背景虚化、完整异形贴纸轮廓及 HDS 材质以 imagegen 概念图表达。原型没有声称完成 Native/Form 实现。

运行仓库 HTTP 服务后打开 `/design/card-template-fusion-2026-11-01/`。`node verify.cjs` 检查状态与主要交互，生成桌面/390px 截图和 qa.json。断言覆盖 card/canvas ID、数据源、参数保留、重置保留其他卡、独立添加/移除、深度层序、窄屏无溢出与无外部请求。
