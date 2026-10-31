# 六个简约能力模块

时间、月历、下一课、接下来、倒计日、电量。每个都有独立单卡和配好尺寸的完整画布，共 12 个 `.fridge`。全部使用当前 App 的原生能力、文字和底板，新增图片素材 0 个。

- `cards/`：单卡，导入到当前作品。
- `canvases/`：完整画布，导入后成为独立作品；课表画布额外配有独立时钟。
- `index.html`：本地审阅页，可切换演示、空数据、长内容，并下载对应作品。
- `previews/`：由生产模型预览器生成的图。
- `*.qa.json`：协议指纹、包哈希、尺寸、样例和 fit 检查记录。
- [设计依据](DESIGN-REFERENCES.md)。

课表和日程使用接收者自己的数据；倒计日需要设置日期；电量使用本机读数。预览中的演示记录只存在于预览宿主，没有写进作品包。模板本身没有天气能力。

## 重新生成

在仓库根目录运行：

```sh
node previewer/build.cjs --check
node design/modules-2026-10-31/build.cjs
python3 -m http.server 8766 --bind 127.0.0.1
```

另一个终端运行 `node design/modules-2026-10-31/capture.cjs`。截图脚本使用 Playwright 和 Chrome，可通过 `FRIDGE_PLAYWRIGHT` 指定模块路径、`FRIDGE_CHROME` 指定浏览器；当前工作区也能使用相邻 `parcel-prototype` 的开发依赖。只监听本机的 HTTP 预览地址为 `http://127.0.0.1:8766/design/modules-2026-10-31/`。

这组文件是可导入的设计作品，尚未接入 App 的内置模板菜单。
