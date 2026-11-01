# Repository instructions

涉及内置模板、组合、模板预览或模板定制时，先读 [模板规范](standards/templates/STANDARD.md)；新增设计按 [制作记录](standards/templates/AUTHORING.md) 补齐几何、数据与验收记录。执行 `npm run templates:check`，原生改动同时执行原生编译。

组合必须设计为一个共享底面的完整画面；一个模板是一张 card；组合的辅助来源保存在 template.sources，内部排版不成为独立图层。禁止将独立小卡网格当作新组合设计，保留旧创作分组与用户修改过的布局；只合并结构和几何完整匹配的预发布 face-* 组合。其余工作遵循用户的全局指令。
