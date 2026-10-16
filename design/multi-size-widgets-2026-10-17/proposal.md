# 多尺寸画布与桌面实例绑定

日期：2026-10-17。状态：设计与 SDK 接入方案；未修改 App 业务代码，未完成真机验收。

本轮按现有 4×4、新增横向 2×4 和方形 2×2 设计。这里的“最小”指本轮产品的最小画布，不是 SDK 的最小枚举：SDK 还包含 1×2、1×1 等规格，不能直接推定每个手机桌面都支持。若产品目标包含 1×2，需要另做单行内容方案与宿主验证。

## 1. 产品决策

采用“一个画布有一个创作规格，一个桌面实例绑定一个画布”。同一画布可以绑定多个同规格实例；多个实例可以显示不同画布。

第一版不同规格使用独立画布副本，不给同一作品加入三套隐式同步的布局。用户点击“创建其他尺寸副本”，进入新画布，原作品保留。素材可以复用，卡片布局与能力配置独立保存；电量等实时数据仍来自原有数据服务。后续若需要同作品多规格联动，再显式引入作品组与布局版本。

App 中打开/切换画布只改变编辑目标；编辑提交会同步所有绑定该画布的实例。只在“选择此组件显示内容”中更换绑定。不能继续把“我正在编辑什么”当成“所有组件显示什么”。

## 2. 首页与编辑

保留当前白底、单色控件、暖白面板、底部“画布／定时／背景／添加”的浮动工具，保留作品的贴纸、纸张与画框质感。

首页顶部轻量显示画布名与规格，例如“猫咪时钟 · 2×2”，右上角提供“桌面预览”。规格是作品属性，点击进入尺寸说明与“创建其他尺寸副本”，不直接改变当前作品比例。

编辑区占据稳定的可用空间。2×4 横向作品居中并尽量铺满可用宽度；2×2 作品放大到适合操作的正方形。组件占用桌面的大小与编辑区大小分开，不能因为 2×2 在桌面更小，就让它在 App 里更难点。首次放大时显示一次“编辑已放大，桌面尺寸不变”。

支持“适合窗口”和双指缩放/平移，编辑缩放只保存为视图状态，不写入卡片坐标。初版先做好适合窗口、实际占位预览及选中卡片编辑；需要精细移动时再完善连续缩放。交互命中区域按屏幕坐标保证至少 44vp，不等于强制卡片本体达到 44vp。

编辑与桌面预览必须分开：编辑画面可放大，但预览要按目标实例的真实宿主宽高呈现文字、边缘与裁切。已有实例读取其 rect；尚未绑定时使用标明“示意”的设备参考规格。生成图中的桌面是概念占位，不是某台设备的精确测量。

| 规格 | 构图建议 | 同一主题的例子 |
| --- | --- | --- |
| 4×4 | 多卡自由拼贴，保留现有能力 | 猫、狗、兔、日期、电量、时钟 |
| 2×4 | 横向主次结构，1–3 个信息焦点 | 左猫咪，右侧大时钟与短日期 |
| 2×2 | 单一主要信息，1–2 个信息焦点 | 猫咪与大时钟，或柯基与电量 |

数量是创作建议，不设硬上限。密集课程表/月历等应主动选择紧凑模式或创建简版，不能仅缩小字体。以桌面最终显示字号评估可读性，而非放大编辑时看起来清楚即可。

跨比例复制需要一次构图过程：等比缩放可作为初始草稿、保留组合与景深关系，然后让用户调整。禁止直接改变 y 映射后保存；不能假装所有自由布局都能自动重排。异规格首次发布前进入预览检查，不自动覆盖源作品。

## 3. 华为 SDK 对应关系

SDK 负责实例 ID、宿主尺寸、生命周期与数据投递；“实例显示哪张画布”是应用持久化的业务映射。`formBindingData` 是传给组件的数据包，和业务上的画布绑定关系不是同一层。

沿用一个 `FridgeForm` 和一个 `FridgeFormAbility`，在 `form_config.json` 扩展：

```json
{
  "supportDimensions": ["2*2", "2*4", "4*4"],
  "defaultDimension": "4*4",
  "formConfigAbility": "ability://EntryAbility"
}
```

不用按画布或实例生成多个 Ability。实际组件宽高由宿主决定，不应把 2×4 固定为某个像素大小，也不保证精确 2:1。

本机 API 26 SDK 已确认以下签名，项目兼容 API 24：

| 接入点 | 职责 |
| --- | --- |
| `onAddForm(want)` | 读取 `FormParam.IDENTITY_KEY`、`DIMENSION_KEY`、`WIDTH_KEY`、`HEIGHT_KEY`；建立实例记录并返回首帧数据 |
| `FormDimension.Dimension_2_2 = 2` | 2×2；当前代码会错误落入 4×4 分支 |
| `Dimension_2_4 = 3`、`Dimension_4_4 = 4` | 横向与现有大尺寸 |
| `onSizeChanged(formId, newDimension, newRect)` | API 20 起；仅更新该实例的规格/宿主 rect，再解析适配内容并重发 |
| `formProvider.getFormRect(formId)` | 查询单个实例实际宽高，失败使用该实例缓存 |
| `formProvider.updateForm(formId, bindingData)` | 将本次内容投递给指定实例 |
| `onUpdateForm(formId)` | 读取绑定，解析其画布或播放策略，独立刷新 |
| `onFormEvent(formId, message)` | 按触发实例处理业务事件 |
| `onRemoveForm(formId)` | 删除该实例记录，保留画布与其他绑定 |
| `onCastToNormalForm(formId)` | 若支持临时卡片，持久化为正式实例，避免预览污染正式绑定 |

SDK 具有尺寸回调不等于每个桌面都会开放拖拽改尺寸；以手机/平板实际宿主验证结果为准。

配置入口沿用已有 `formConfigAbility`。系统“编辑卡片”拉起 App 后读取目标实例身份，显示“此组件显示哪张画布”，保存只更新该实例。用户不能靠记忆 formId 区分实例，UI 用当前预览、尺寸、可选名称识别。首版不声称能知道它在“桌面第几页”。

新实例：若添加流程明确带入已校验、同规格的目标画布，就绑定它；否则选择该规格的显式默认画布，没有默认则显示“选择画布”的空态。不能依赖全局 `pendingCanvasId` 或当前编辑画布猜测目标，并发添加容易串绑。具体添加携参需联调后确认；普通桌面添加应始终有空态兜底。

`onAddForm` 返回值同步，而 Preferences 读写异步。返回轻量首帧后，串行完成注册、持久化、投递；不要先按不确定的 activeId 推送别的画布。组件点击路由携带 `formId`；App 再从持久记录解析编辑目标，处理 `onCreate` 与 `onNewWant` 两条入口。

## 4. 数据与写入一致性

建议先落地版本化实例表，尺寸与绑定放在同一条记录中；`formId` 始终用字符串，避免大整数精度损失：

```ts
interface WidgetInstance {
  formId: string;
  dimension: '2*2' | '2*4' | '4*4';
  width: number;
  height: number;
  canvasId: string; // 空字符串表示待选择
  status: 'unconfigured' | 'bound' | 'needsLayout';
  bindingRevision: number;
}
```

实例表和编辑中的 `catalog.activeId` 分离。画布继续保存已有 `canvasDimension/canvasAspect`，宿主真实 rect 属于实例；不要再用 `canvasSpecs[dimension]` 的最后一次写入代表所有实例。

初版定时/轮换采用独立的播放配置引用，默认静态绑定。可以明确选择“绑定播放列表”；列表内作品按尺寸提供内容，不能继续把 catalog 全局规则无条件套给每个实例。临时中央卡片和自动轮换都要在该实例策略中解析，避免固定猫咪时钟突然被其他画布的课程场景替换。共享播放列表意味着用户有意让多个实例一起轮换。

多进程写入需专门处理：当前 FormExtension 的 Promise 队列只能串行本进程，App 与扩展中的两个 Preferences 读改写仍可能互相覆盖。建议使用 RDB 实例表，以 formId 为主键，注册/改绑/删除做事务，保留现有 Preferences 画布存储；不要以 `flush()` 作为跨进程事务保证。绑定修改使用 revision 防止旧配置页覆盖新绑定。

投递队列仍按 formId 串行，但排队数据带 bindingRevision；执行前重新解析最新绑定，丢弃过期任务，重绑后投递新版本。若旧 IPC 已发出，保证其后跟随最新版本投递；不能宣称可撤销已经发出的系统调用。缓存按 formId、绑定版本和内容版本失效。

升级时为已有实例绑定升级前实际显示的画布，保留当前桌面内容；不能直接恢复历史遗留 bindings，因为当前版本已明确忽略它们。迁移只做一次，完成后禁止 `repairDesktopSelection` 再把所有实例合并为当前画布。

删除已绑定画布时展示受影响的实例数，提供更换同规格画布或将这些实例设为待选择；不要静默改成 App 当前画布。删除组件只删实例记录。尺寸变化找不到匹配内容时设 `needsLayout` 并保留原作，用完整等比缩放作为临时显示，配置页提供创建适配副本。

## 5. 现有代码需要改变的位置

| 文件 | 当前行为 / 需要改变 |
| --- | --- |
| `model/CanvasLibrary.ets` | `boundCanvas()` 无条件返回 activeId，readCatalog 强制全局跟随；替换为实例解析与一次迁移 |
| `model/FridgeModel.ets` | `selectCanvas()` 会遍历重绑所有实例；改为仅编辑切换，增加独立 bind API，重做删除和修复路径 |
| `model/WidgetSync.ets` | 全部实例解析同一 activeId 和全局场景；按绑定及播放策略投递 |
| `form/FridgeFormAbility.ets` | 映射遗漏 2×2，注册与首帧存在顺序问题；接入实例表、尺寸变化、移除及临时实例 |
| `entryability/EntryAbility.ets` | 规格白名单遗漏 2×2，普通点击忽略 canvasId，未消费配置实例身份；补路由与配置模式 |
| `widget/pages/FridgeWidgetCard.ets` | 已下发 formId 但未消费；点击需传实例身份，增加待选择状态 |
| `model/WidgetDelivery.ets` | fallback 所有方形都是 344；改为实例 rect 优先和明确的各规格 fallback |
| `model/WorkspaceLayout.ets` / `pages/Index.ets` | 加规格标签、编辑视图状态、占位预览；打开组件不能将宿主比例直接写回作品 |
| `model/SceneLayout.ets` | 当前 x/y 不同轴缩放会改变跨比例构图关系；同规格适配保留原语义，跨规格复制走独立变换 |
| `model/SceneSchedule.ets` 等 | 定时和轮换从全局 catalog 改为按实例引用的播放配置解析 |

## 6. 实施顺序与验收

1. 实例表、迁移、配置路由及绑定解析先落地，仍用现有 4×4 验证 A/B 两个实例独立显示。
2. 开放 2×4、2×2，完成首帧、真实 rect、尺寸变化与同规格画布选择。
3. 首页编辑放大与桌面预览，补跨尺寸副本流程与紧凑能力排版。
4. 接入按实例的定时/轮换与场景恢复，再做原生端验收。

必要验证：A→猫咪、B→课程，切换编辑目标不改桌面；修改猫咪只刷新绑定猫咪的实例；两个实例绑定同一作品一起更新；并发添加/重绑/删除不丢记录；旧排队投递不盖住新绑定；冷启动/进程重启仍保持绑定；配置取消不改数据；改尺寸、旋转、窄/默认/宽宿主不拉伸卡片；删画布有明确处理；迁移不恢复历史错误绑定；固定实例不受其他实例轮换影响；图片/透明底/景深/时钟与日历点击行为回归。

SDK 文档建议对同一规格验证 Minimum、Default、Maximum 三种预览。生成图仅说明交互方向，不能替代这些真机与渲染检查。

## 7. 来源与演示图

- [华为：创建服务卡片（含多规格与三档预览）](https://developer.huawei.com/consumer/cn/doc/HarmonyOS-Guides/ide-service-widget)
- [华为：卡片生命周期](https://developer.huawei.com/consumer/en/doc/harmonyos-guides-V5/arkts-ui-widget-lifecycle-V5)
- [华为：FormInfo / FormParam 与配置入口](https://developer.huawei.com/consumer/en/doc/harmonyos-references-V2/js-apis-app-form-forminfo-0000001493903980-V2)
- 本机 SDK 核对：`/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/ets/api/@ohos.app.form.FormExtensionAbility.d.ts`、`@ohos.app.form.formInfo.d.ts`、`@ohos.app.form.formProvider.d.ts`。`onSizeChanged` 的 API 20 标记以本机 API 26 声明为直接依据；部分在线动态文档无法完整抓取。

演示图使用内置 image_gen，参考现有 `output/islands-phone.jpeg` 的浮动工具和 `output/canvas-switch-device.jpeg` 的贴纸作品风格。最终提示词见同目录 `imagegen-prompt.txt`。图中四屏依次表达：横向构图、方形放大编辑、多个独立桌面实例、配置当前实例。
