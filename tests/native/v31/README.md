# v31 课程显示与自适应 QA

临时将此页面复制到 entry/src/main/ets/pages/qa/TimetableQA.ets（其中相对 import 按该运行位置编写），注册测试页面并将 EntryAbility 临时指向它。测试结束恢复 EntryAbility/main_pages，删除运行目录，再做正式签名构建。

夹具不初始化 FridgeStore，不写用户课程/作品。`tick` 固定到 2026-09-07，八项课程为人工测试数据。导入预览由夹具直接初始化解析后状态，验证真实导入对话框的周课表/作息/确认 UI，不冒充真实学校联网导入成功。确认调用真实 resolveWakeUp，onImport 不写存储。

按钮用于切换最小单课、2/3 列日概览、周课表、真实设置面板、自由边角卡片、深浅色、周课表弹窗和导入预览。

首个夹具把 CustomDialogController 放在局部表达式里，关闭时缺少 controller 导致 JS 错误。修正为保存到页面字段后验证关闭和再次打开；生产 CapabilitySettings 一直使用字段保存 controller。
