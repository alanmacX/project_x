# 产品报告核验记录

日期：2026-11-09。检查期间仓库从 `cd7742a` 加工作区模板改动更新为 `a9cd1dc`。输入包含模板、构图、分钟更新和测试改动；兼容性探针在最终 HEAD 上再次执行，结果相同。

## 新执行的自动检查

| 命令 | 结果 | 覆盖范围 |
| --- | --- | --- |
| `npm run test:storage` | 通过，4 组 | SQLite 多进程迁移、WAL/SIGKILL、独立备份/坏文件/空间不足、云隔离 |
| `npm run templates:check` | 通过 | 生成物一致性、模板存取、12,480 布局场景/90,720 文本槽、组合、刷新、照片相机/构图/会话、1,408 发布场景 |
| `node research/product-upgrade-2026-11-09/compatibility-probe.cjs` | 已运行 | 仅使用合成内存数据，核对未知模板行为、Index 规模和增长表计算 |

对应执行输出保存在本目录 `storage-check.log`、`templates-check.log`、`compatibility-probe.json`。

## 兼容性探针结果

| 合成输入 | 卡片保留 | template 保留 | 再序列化有 template |
| --- | --- | --- | --- |
| 已知 portrait / version 1 | 是 | 是 | 是 |
| 未知 future-design / version 1 | 是 | 否 | 否 |
| 已知 portrait / version 2 | 是 | 否 | 否 |

调用的是经 `previewer/build.cjs --check` 检查的共享生产模型。探针没有对用户库执行迁移。报告要求在发布未来模板、撤下历史 ID 或设计回退前补齐原始 payload 保留。

## 本地代码核对

- `AppScope/app.json5`：1.2.0 / 1002006；两个云同步声明关闭。
- 本机 `build-profile.json5` 指定 compile/target 26.0.0，compatible 6.1.1(24)。只读取版本字段。
- `module.json5`：phone/tablet；form、formEdit、share 扩展；无 backup 扩展。
- `CardTemplate`：39 单卡 + 5 组合；`version` 是协议版本，实例未保存独立 designRevision。
- `LibraryBackup`：带哈希的 values 快照、三代；`readLibraryBackup` 没有产品调用点。
- `SharedCapability`：公开分享会清理私人来源字段，私人整库备份需要单独格式。
- `Index.ets`：3,211 行、130 个 `@State`。
- 本机 SDK `FormMenu.d.ets`：AddFormMenuItem 的 Want、组件快照 ID、回调与 formBindingData 声明，since 12。
- 本机 SDK `harmonyShare.d.ts`：knockShare 与 SharableTarget.share 声明。

## 本次浏览观察

1. 华为应用市场“小组件”搜索列表；YX Widget 详情页与三条可见评价；精确“灵动小组件”搜索的近似名称结果。
2. 亿象鸿蒙教程、会员权益、更新记录、FAQ。
3. 华为原生案例正文、页面发布日期、灵动小组件功能展示图。
4. Widgetsmith 官网与城市照片桌面图、开发者照片组件文章。
5. iScreen 官网与冰箱主题展示图。
6. 当前 Live View Kit 支持场景：TIMER、准入与不适用场景。
7. 当前 Intents Kit 主体限制：仅企业开发者，个人开发者无法申请和注册。
8. 官方 Share Kit 与自由流转资料。

来源链接与对设计的影响分别在主报告和 DESIGN-REFERENCES 中。2026-10-31 的 75 条评价采样是仓库历史研究，本次新读取的 YX 评价为 3 条。

## 性能与原生记录的时间范围

报告引用 2026-10-20 的三画布平板启动/PSS 数据，以及 2026-11-01 的原生截图与模板验收。此次没有重新安装原生包或采集设备性能；性能表是下一阶段的测量矩阵与建议预算。业务代码没有因这次报告发生修改。
