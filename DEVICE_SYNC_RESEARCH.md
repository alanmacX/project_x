# 华为账号与作品同步

2026-10-05。当前只做调研，没有增加账号 SDK、联网／分布式权限或同步服务。

Account Kit 的登录返回身份标识；它不会自动把应用画布、照片或 GIF 同步到其他设备。官方：https://developer.huawei.com/consumer/cn/sdk/account-kit

Cloud Foundation Kit 提供云数据库和文件存储；账号绑定之后仍需实现作品上传、下载及冲突处理。这属于端云方案，不能因为服务器由华为提供就描述为纯端侧处理。官方：https://developer.huawei.com/consumer/cn/sdk/cloud-foundation-kit/ 及 https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/cloudfoundation-cloudstorage-V5

保持无自建云服务的候选是 ArkData 的可信设备间同步。其文档和本机 SDK 均把 `autoSync` 限定在跨设备 Call 协同场景，需要 `ohos.permission.DISTRIBUTED_DATASYNC`；不能仅打开这个布尔值就承诺所有设备远场、后台、实时同步。官方：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/data-sync-of-kv-store

适合下一步做“手机／平板近场同步作品”原型：通过系统可信设备机制，同步作品元数据、变更版本与素材文件；素材不能直接同步原设备的 file:// 路径。图片／GIF 传输、删除冲突、离线修改合并和桌面组件刷新都需两台设备验证。优先复用现有本地作品包处理素材。不要把整包写入 KV 数据库，也不要在拖动每帧发同步。

这种设备间方案保留端侧存储、不上传作品到业务服务器的工程边界。华为对带分布式同步的应用是否认可单机分类，没有查到可据此保证的公开条款，需要向审核支持明确确认；不以缺少 INTERNET 权限作为审核保证。

系统云备份也不能代替自动同步：官方列明第三方应用支持范围取决于系统／云空间版本和备份页面，不能默认我们的 App 已被支持。官方：https://consumer.huawei.com/cn/support/content/zh-cn16019648/

结论：首发继续本地作品包＋系统分享。未来可验证近场设备间同步；不承诺“登录一次、不同地点所有设备持续自动同步”同时仍保持纯本地。
