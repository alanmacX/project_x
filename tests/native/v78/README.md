# 纸团删除动画 · 2026-10-07

## 实现
确认删除后：拎起 90ms → 折皱压紧 150ms → 收成纸团 120ms → 向上抛 110ms → 向右下屏外甩出 190ms。总计 660ms。

- 捕获 BoardCard 不含控制按钮的 face 一次，快照最长边 ≤640px。
- 一张卡片图、一张一次性绘制的折痕 Canvas；缩放、旋转、圆角、位移和折痕透明度使用 ArkUI keyframeAnimateTo。没有逐帧 JS 回调、粒子模拟、照片解码或能力重画。
- 属性动画符合华为建议优先采用属性动画而非帧动画的方向；API 24 可用，无需 API 26 粒子能力。参考：https://developer.huawei.com/consumer/cn/doc/doccenter-capabilities/ndk-use-animation
- 飞出层在画布裁切之外，允许自然离开屏幕。透明主体在折皱阶段逐渐浮现纸面明暗。
- 仅串行删除一个卡片。快照失败/超过 1s 直接完成删除，迟到快照释放；动画完成、后台切换、页面销毁均收尾。图片组件解绑后再释放像素存储。
- 收尾只更新画布，不重新校验和克隆编辑设置；保留删除确认、组合清理、桌面发布流程。

## 真机验证
MatePad Mini，API 26，发布包。复制现有异形卡片后测试删除，原卡片保留。检查中间折皱画面和删除后的图层列表，临时复制卡片均已删除。

hitrace ace/app/graphic：最终 trace 中除收尾的一帧外，UI 帧处理最长 5.91ms；整段最高 24.24ms 为 Index 删除收尾的节点更新（首次版本 31.51ms）。这不是实际呈现 FPS，不能声称整个流程零掉帧。

release assembleHap 通过，24 组 host suites 通过，git diff --check 通过。未做 API 24 真机验证。
