# 云同步优先排查 — 2026-10-27

## 证据与边界

- 保存的 1.1 / 1001000、1.1 / 1001001 和存储修复 1.2.0 / 1002003 APP 包：app 清单中的 cloudFileSyncEnabled 为 true；ABC 均无 SystemCloudSync、CloudSyncFiles、CloudSyncDialog 或 FileSync 标识。
- 进入本轮修复前的 1.2 源码也没有产品入口调用协调器。没有保留原 1002002 安装包，不能将源码检查冒充该真机二进制的完整核验。
- 初次保存的真机日志包含为该应用挂载 hmdfs 云目录的记录。挂载只能证明系统云文件路径参与启动，不能证明同步业务运行、上传成功或覆写了 preferences。
- 初次备份的模块 preferences 没有 fridge_cloud_sync_v1 游标文件；这不是“历史上从未同步”的证明，也可能已经缺失。
- 后续日志的 sync switch off 出现在卸载前后。用户确认已卸载，安装包及原沙箱现已不存在，无法再读取故障发生时的系统开关与云目录。不能用卸载后的状态排除故障前云同步。
- 尚无 10 月 25 日云端数据覆盖/删除本地目录的直接证据。Preferences 实例失效缺陷是真实的，但不能由此排除系统云备份恢复等另一条路径。

## 查到并修复的风险

实验协调器原来根据“游标中有、本地目录没有”生成 deleted 记录，未区分用户删除与本地读取失败。现在在任何修订发布之前检查目录缺项并停止同步；缺失共享数据也保留旧记录，不能凭缺失生成删除。未来要同步删除，必须先实现独立、持久化的明确删除日志。

本地发布包显式禁用 cloudFileSyncEnabled 和 cloudStructuredDataSyncEnabled；移除菜单不等于禁用系统能力声明。此次没有修改设备账号/系统开关，没有清除或请求同步云端文件，没有重新安装原 App。

## 发布检查

104/104 回归套件；新增入口依赖图检查，禁止产品可达实验云协议/协调器；包审计同时拒绝已启用的云能力声明及协调器 ABC。1.2.0 / code 1002005 为本地隔离构建，不声称关闭所有系统备份服务或已经证明云是这次丢失的根因。

官方字段定义：[app.json5](https://github.com/openharmony/docs/blob/master/zh-cn/application-dev/quick-start/app-configuration-file.md)。官方 Context 将 cloudFileDir、preferencesDir、databaseDir 分别列为不同用途的目录：[Context](https://github.com/openharmony/docs/blob/master/zh-cn/application-dev/reference/apis-ability-kit/js-apis-inner-application-context.md)。这两个接口说明不能替代具体设备在故障时的服务日志。
