# 定时画布状态与驻留提醒：实施前结论

2026-10-05。此轮只修组合与背景；以下是下一阶段的方案和约束，尚未接入业务。

## 能做到什么

| 需求 | 结论 | 实现方向 |
| --- | --- | --- |
| 每天一个时间段呈现另一状态 | 可做，桌面按分钟判断，不按秒保证 | 提前下发规则和下一状态资源，卡片内部 TextClock 分钟回调判断当前状态 |
| 指定日期一次切换 | 可做 | 日期与时间组成唯一 occurrence，错过切换时直接恢复当前状态 |
| 同一画布的位置/内容状态 | 可做 | 原布局不修改，应用临时显示姿态；相同卡片 ID 保持渲染节点 |
| 切换另一画布 | 可做，需要提前准备目标资源 | 单独记录 widget 的展示状态，不改变用户正在编辑的画布或持久绑定 |
| 卡片扫向四周，露出少量边缘，中间提醒 | 可做 | 每张卡片固定边缘停靠姿态、中心提醒层，保留原始几何；原生 translate/rotate/opacity |
| 点提醒后恢复，而且不立即再次出现 | 可做，需要持久确认 | message → onFormEvent → 写入本次 occurrence 的确认 → updateForm；点击不必进入 App |
| App 被杀后，锁屏时仍准时响铃/通知 | 不能靠桌面刷新保证 | 另接经过华为开放能力申请的代理提醒，并取得通知/代理提醒所需授权 |
| 所有桌面状态每秒刷新或长期播放流体动画 | 不应采用 | 卡片的时间回调为分钟级；应本地播放短过渡，不能逐帧 updateForm |

前三种状态切换及驻留提醒可以保持离线，规则、资源、确认都在本机。这里的“提醒”是画布内视觉提醒；是否增加系统通知/声音必须作为独立能力说明。

## 已核对的框架边界

1. `updateForm` 是主动推送数据；不是桌面帧循环。App 和卡片属于不同进程，LocalStorageProp 接收绑定数据。用户编辑完成应主动推送，不等待下次定时刷新。
2. `setFormNextRefreshTime` 的参数是相对分钟，最小 5 分钟。定时方式每张卡片每天最多 50 次，午夜重置；定时/下次刷新共享这个预算。可见性也影响触发和布局更新。不能承诺一个后台 5 分钟轮询永远可靠。
3. `updateDuration` 单位 30 分钟；`scheduledUpdateTime`/`multiScheduledUpdateTime` 是包内配置，不是每个用户任意修改的运行时闹钟接口。启用周期刷新时会优先于定点刷新；多定点最多 24 个。
4. TextClock 在 ArkTS 卡片支持 `onDateChange`，回调为分钟级。它适合预加载状态的轻量时间判断，不适合放网络、图片解码、存储或逐帧计算。首次显示也须立即按当前时间求状态，不能等下一次 tick。不把锁屏下的回调或进程生存当保证。
5. 卡片支持原生属性动画，包括 translate、rotate、scale、opacity。API 24 的单次持续时间上限为 1000ms；API 26 为 2000ms。过渡规划控制在约 600–800ms，用原生 delay 安排先退后进；不用 JS 定时器串动画，也不在过渡期间重复推送绑定数据。
6. API 20+ 共享内存刷新总量不能超过 10MB，图片数量不能超过 20 张。目标状态必须提前准备且控制资源量，复用照片、蒙版、背景；大画布不能无限预加载。
7. 当前 SDK 的 `onChangeFormVisibility` 明确仅系统应用、且须 formVisibleNotify=true。现有代码虽然实现了这个回调，第三方 App 不能以它为补偿刷新保障。
8. 代理提醒由系统在应用退出或进程终止后代理通知，支持闹钟/日历/倒计时；华为当前要求先申请开放能力。代理提醒是通知能力，不能据此声称它会自动唤醒我们的 provider 并执行任意 updateForm。

来源（华为文档部分为动态页面，结合当前安装 SDK 注释和 OpenHarmony 官方同接口文档核对）：

- [华为卡片被动刷新](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/arkts-ui-widget-passive-refresh)，[官方底层文档：配额、可见性、定点规则](https://github.com/openharmony/docs/blob/master/zh-cn/application-dev/form/arkts-ui-widget-passive-refresh.md)
- [华为 formProvider](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-app-form-formprovider)，[官方刷新模型与数据上限](https://github.com/openharmony/docs/blob/master/zh-cn/application-dev/form/arkts-ui-widget-interaction-overview.md)
- [官方 TextClock 文档](https://github.com/openharmony/docs/blob/master/zh-cn/application-dev/reference/apis-arkui/arkui-ts/ts-basic-components-textclock.md)
- [官方属性动画](https://github.com/openharmony/docs/blob/master/zh-cn/application-dev/reference/apis-arkui/arkui-ts/ts-animatorproperty.md)，[API 26 动画时长变化](https://github.com/openharmony/docs/blob/master/zh-cn/application-dev/reference/apis-arkui/arkui-ts/ts-explicit-animation.md)
- [华为代理提醒开放能力与权限说明](https://developer.huawei.com/consumer/cn/doc/doccenter-dev-faq/faqs-background-tasks-11)
- 本机 SDK：`@ohos.app.form.formProvider.d.ts`、`@ohos.app.form.FormExtensionAbility.d.ts`、`text_clock.d.ts`、`@ohos.reminderAgentManager.d.ts`。

## 当前项目刷新路径与缺口

编辑提交 → `FridgeStore.save` 生成存储快照 → 串行本地落盘 → 每个画布自己的 `LatestWidgetQueue` 合并待发送版本 → 工作线程 `deliverWidget` 准备资源、绑定数据 → `updateForm` → 卡片 LocalStorageProp 更新。

已有：不等待退出 App 才刷新；按画布绑定只更新对应实例；发送过程中只保留最新待发送快照；图片准备和绑定在工作线程；有限重试；退出/隐藏时补交最后编辑。

后台现有：form_config 设置每 30 分钟一次；onUpdateForm 读取绑定画布、更新数据、按能力边界安排下次刷新。目前没有用户定时规则、驻留提醒确认或分钟级状态判断。

必须先整改的地方：

- 半小时基线理论上每天占用 48 次，留给用户状态和能力边界的余量太少。下一阶段按真实边界调度并明确每日预算，不能在这个基线上简单追加提醒轮询。
- `scheduleForm` 当前只在 provider 的新增/更新周期调用，不在 App 每次修改规则后重排。规则增删改必须重新登记下一边界；距边界不足 5 分钟时靠已下发规则的卡片本地判断，不滥用后台定时器。
- 卡片目前只收到当前画布的数据。预先下发下一状态与规则才能脱离后台刷新延迟完成可见时间切换。
- UI 的 rev 目前是发送时间；需区分内容 revision、规则 revision、occurrence ID、确认 revision，避免背景数据更新重复播放入场。
- App/provider 有各自的队列；提醒确认需独立存储键并合并，不让 App 的旧快照覆盖 provider 刚写的“已确认”。
- 传输成功表示系统接受了数据，不是“屏幕已呈现”的回执。可见桌面首次帧延迟需单独测量，不能直接等同 IPC 耗时。

## 建议的最小完整框架

**规则**：归属画布/组件实例，启用、每天/指定日期、星期、开始与结束分钟、时区策略、目标（同画布状态/另一画布/驻留提醒）、优先级。

**发生实例**：rule ID + 本地日期 + 时间；不同日期的每日提醒是不同实例。确认只影响当前实例，不能把以后的每天也取消。

**状态求值**：一个纯函数同时供 App、provider、卡片使用。输入规则、当前时间和确认集合，输出当前场景及下一边界。跨午夜、夏令时、手动调时、重启/重新添加、删除目标画布、禁用规则都用同一个判定。已错过的普通场景直接显示当前；驻留提醒按配置保留到确认，不补播一整串过期动画。

**过渡**：保留卡片原始 x/y/w/h/rot；显示变换存放在单独的临时层。扫到最近边缘，保留 12–24vp 可见；中心留出可读区域；最多轻微旋转，不压缩提醒字号。组合视作同一对象扫出，不能拆开。扫出约 250ms，入场约 350ms，合计低于旧版 1000ms 上限；稳定 ID 和预解码资源；普通更新不重新播放。

**确认**：中心明确的原生按钮发 message。卡片即时回归显示并提交本次 occurrence，provider 验证规则/画布/实例、独立持久确认、再向同绑定的其他实例推送。重复点击幂等。失败或未收到确认时保留待确认状态，下一次收到 provider 数据对账；不能悄悄丢提醒。

**编辑期间**：预览可以展示提醒状态，但实际编辑总是原始布局，不保存被扫到角落的姿态。切换展示画布不改桌面原绑定；时间段结束恢复原绑定画布。

建议第一步做“同画布驻留提醒 + 每日/一次 + 点确认恢复”的独立技术样机，先验证真机桌面前后台、锁屏、重启以及确认竞态；第二步加同画布 states；第三步加跨画布。系统通知能力另行申请，不能阻塞纯视觉版本。

## 下一阶段验收矩阵

- API 24 / API 26；手机 / Pad；桌面正在显示 / 页面离开 / 锁屏 / App 被杀 / 重启。
- 设置后不足 5 分钟、跨午夜、重复日、跨时区、手动改时钟、同分钟多规则优先级。
- 点确认后 provider 尚未发送/正在刷新；App 同时编辑；多个 widget 同绑定/不同绑定；重复事件。
- 背景与卡片资源不超传输上限；不逐帧 IPC；过渡只改原生变换；重复 revision 不重播；恢复不破坏原布局或组合。

上述桌面时序及转场尚未做样机实测，因此“可做”是文档与架构可行性，不等同已经验收的后台准时保障。
