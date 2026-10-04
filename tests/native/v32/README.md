# v32 Card framework QA

把 CardFrameworkQA.ets 临时复制到 entry/src/main/ets/pages/qa，注册测试页面并临时修改 EntryAbility 的 loadContent；结束后恢复正式 EntryAbility / main_pages、移除运行目录并重新签名构建。

人工数据验证实际 CapabilityView、CapabilityPicker、CapabilityAppearance、CapabilitySettings、CapabilityDetails、ParcelImportDialog 和 CardFace；不初始化 FridgeStore，不修改用户作品。固定日期 2026-10-04，初始五件包裹。

已检查：最小/完整包裹摘要与阅读衬底；选中生活分类、关闭再开；横屏深色选择器；两件通知的勾选/取消、只导入一件；详情已取/撤销；浅/深色设置。通知来自人工文字，并不代表真实截图 OCR 已离线验证。

设备为 Mate 80 RS 手机模拟器。蓝色顶部按钮仅为 QA 控制，生产 UI 的颜色与导航来自 AppDesign / HDS。照片主体的轮廓留白、模板数据、点击几何与计数由纯模型回归另行覆盖。这个夹具不测真机刷新率。
