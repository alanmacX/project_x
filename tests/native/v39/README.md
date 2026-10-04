# Select 边缘、画布浮层与响应式动作复测

MatePad Mini，HarmonyOS 7 / API26，2560×1600，暗色横屏，签名包覆盖安装。

- 底板配色和形状使用原生 Select，触发区统一22vp胶囊裁切。检查展开菜单的四角和选中项，没有逐项背景叠放产生的边缘接缝；系统保留自身菜单材质与分隔线。
- 配色选择从原值切到白色，撤销后 Select 标签、底色样本恢复原值，撤销／重做按钮状态同步。测试修改已撤销。
- 课程编辑星期菜单切到周日，关闭菜单后标签同步；取消课程编辑，没有保存测试课程。底板形状、调课课程、时钟城市均复用相同 SettingsSelect；后两项本轮只检查代码及构建。
- 首页多选使用真实 Checkbox。点击第一个复选框及第二张整行，两个 checked=true，原生紧凑主按钮数量为2且启用；取消退出，没有提交组合。没有新增工具底板，图层列表保留底部可滚动余量。
- 画布菜单锚定按钮，无大 sheet／第二层创建对话框。新建在同一浮层内输入名称并创建空白画布；测试重命名后，首页标题、当前行、名称输入同步。测试画布已删除，回到原画布。
- 键盘遮挡在测试中复现并修复：增加原生 keyboardAvoidMode=DEFAULT 与受限内部 Scroll。再次输入新建名称，浮层移到键盘上方，名称、返回／关闭和创建按钮全部可见；取消此草稿。
- 导入页面展开备份方式后，按钮从“导入已有课表备份”立即变为“收起其他方式”。原生动作的标签、启用状态通过组件属性更新；作息同节次与画布同ID重命名从最新观察数组读取。
- assembleHap、git diff --check 通过。本轮未测浅色、竖屏、API24或持续帧率；不据此声称全设备满帧。未操作真实教务账号／提交课程导入，原有卡片与组合保持。

依据：Huawei [ArkUI 圆角边缘常见问题](https://developer.huawei.com/consumer/cn/doc/doccenter-dev-faq/faqs-arkui-1083)、[bindPopup 材质与状态问题](https://developer.huawei.com/consumer/cn/doc/doccenter-dev-faq/faqs-arkui-1331)，以及本机 SDK 的 Select、CustomPopupOptions、Button 类型定义。浮层键盘避让属于标准原生 API，不靠手算键盘偏移。
