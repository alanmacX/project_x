# V90：MatePad 桌面 / App 显示回归

设备：MatePad Mini，5KLBB25C19200110。使用现有用户画布，未删除或重建桌面组件。

## 锁定的回归

`e175eb2`（Fit capability backings to visible content and hollow battery dial）引入 `PaperTextWidth` 与 capability 的自定义 background builder。

真机 `com.ohos.formrenderservice/ArkCompiler` 反复记录：

```
TypeError: Cannot read property vp2px of undefined
at paperTextWidth (.../model/PaperTextWidth.ts:5:1)
```

Form 环境没有 App 的 UIContext。构建能力时抛异常，桌面出现部分卡片及能力内容丢失。改变坐标后仍复现；消除 UIContext 依赖后，同一现有画布恢复全部卡片，包括负坐标的派大星与左下专辑。没有为具体素材添加分支。

另外 SDK common.d.ts 的 background(CustomBuilder) 没有 @form 标记，现改为普通 Stack 子节点承载材质。原生 Path 代替需清空后重画的 Canvas 衬底，透明孔使用反向子路径。两端使用同一套保守字体 advance 预算，避免各自测量带来的几何差异。

## 真机结果

- before：桌面只显示部分图片，没有电量徽标、课程表面板；App 有完整画布。
- after：7 张现有卡片都显示，画布外部分按边界裁切；电量白色徽标、纪念日挂签和课程表衬底恢复。
- widget-after 拍摄时用户已将课程表从 upcoming 改为每日概览，App-after 拍摄较早，不能把这对截图当作逐像素相同比较。
- 最终发布包不包含 P90 诊断文字、QA 路由或强制 reloadAllForms 调用。
- 最后一轮日志没有再出现 PaperTextWidth TypeError。一次保存的队列/矩形/素材/绑定/IPC 合计 79 ms；这是送达时间，不是桌面显示延迟或帧率。
- 全部 31 个测试入口通过，release HAP 构建通过。新增无 UIContext 的 Form 材质构建回归测试。

V89 保留前一阶段模拟器的贴合、拖动采样，不能替代真机逐帧性能测试。本轮未声称顶满设备刷新率。
