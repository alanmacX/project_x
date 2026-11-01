# 新模板设计记录

复制本记录到对应设计目录的 README，再开始实现。

```text
稳定 ID / revision：
名称 / capability：
第一眼读数：
辅助角色（最多 2 个）：
视觉性格与两条参考来源：
background / ink / accent：
方形布局 / 横向布局：
用户定制：数据 / 色彩 / 照片 / 抠图
未配置 / 长内容 / 边界数据的处理：
新增资产和商业授权：无，或来源/许可证
变更的生产文件：
180vp / 方形 / 横向截图：
自动检查 / 原生验收记录：
```

## 组合代码骨架

下面是声明结构，不是已注册模板。几何以实际构图为准。

```ts
// CompositionCatalog.ets：新增稳定 ID；实际落地时还要写横向 compositionLayout 分支。
{id:'mix-example', revision:1, name:'示例', slots:[
  {id:'face-example-clock',kind:'clock',role:'主时间',x:0,y:0,w:300,h:300,primary:true},
  {id:'face-example-agenda',kind:'agenda',role:'下一个日程',x:24,y:180,w:252,h:96,primary:false}
]}
// CardTemplate.ets：公开 ensemble 的 sources 顺序与各槽位 capability 保持一致。
// CompositionScene.ets：每个槽位共用 compositionColors；只画它自己的信息。
// 后续渲染、绑定、存储、刷新和分组继续走原来的 card 管线。
```

不新增模板专属定时器、文件夹、数据仓库或网络请求。需要新能力时先扩展 capability 数据框架，再设计模板。
