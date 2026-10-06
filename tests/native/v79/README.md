# 网格纸团删除 · 2026-10-07

替代 v78 的整图压缩和折痕叠层。卡片纹理现在随真实三角折面变形，最后收成不规则纸团并甩出屏幕。

## 实现与研究

- 自行编写固定 6×6 网格：49 顶点、72 三角形。交错折叠、包裹成团、透视投影、面法线明暗、按深度排序；不运行布料物理求解器。
- 卡片快照一次，最长边不超过 640px；透明轮廓和原图纹理保留。复用顶点、纹理坐标和颜色数组，一次 drawVertices 绘制所有折面。
- 80ms 拎起，360ms 网格折叠，340ms 回摆与抛掷，总计 780ms。逐帧计算只 invalidate 一个 RenderNode，不通过 @State 重建页面或重新布局；位移和旋转仍用 ArkUI 属性动画。请求设备刷新率范围，不保证实际呈现帧率。
- 删除期间暂缓前台重同步、定时场景切换、智能背景结果替换。失败、后台、页面退出和 watchdog 都保留确定性删除收尾。
- 参考 Paperfold 的折面表现：https://github.com/mrflix/paperfold
- 参考 PaperDesign 的形变与光照分离：https://github.com/paper-design/shaders/blob/main/packages/shaders/src/shaders/paper-texture.ts
- 三角网格纸张研究：https://team.inria.fr/imagine/files/2015/03/SRHCSWB15-TOG15s.pdf
- 华为自定义 RenderNode 渲染：https://developer.huawei.com/consumer/en/doc/harmonyos-guides/ndk-embed-render-components

未复制上述项目源代码。SDK 本地声明确认 createImageShader 自 API20、drawVertices 自 API23 可用；API24 兼容是声明级检查，尚未做 API24 真机测试。

## 验证

MatePad Mini API26，最终 release 包，复制现有异形卡片并仅删除副本，保留用户原卡。trace 包含 CardDeletionFlight 生命周期。

最终 hitrace /tmp/mesh-delete-final.trace（PID32990）：折叠阶段多数 UI 帧处理约 2.7–4.3ms，个别达到 6.49ms；挂载 11.26ms，最终 Index 删除收尾最高 29.93ms（其中 rerender 18.84ms）。上一轮 trace 折叠约 2.5–3.7ms、收尾 22.91ms。这里测量的是 UI 任务时间，并非实际呈现 FPS；收尾仍有超出高刷新率预算的一帧，不能宣称全程零掉帧。

额外用临时测试 Ability 检查 0、0.35、0.65、1 四个停帧，确认异形透明纹理、折面覆盖和成团效果；临时 Ability 不在生产包中，已重新安装生产 release。

25 个 host suites 通过；新几何测试覆盖宽高比、平面 UV 对齐、100 步有限坐标、纸团边界、面深度排序、对象复用。最终 release assembleHap 和 git diff --check 通过。
