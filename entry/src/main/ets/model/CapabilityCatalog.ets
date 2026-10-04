/** The contract for a capability: one purpose, an honest source, one detail destination. */
export interface CapabilityDescriptor { key: string; name: string; group: string; summary: string; source: string; detail: string; }
export const CAPABILITY_GROUPS: string[] = ['时间', '生活', '自定义'];
export const CAPABILITY_CATALOG: CapabilityDescriptor[] = [
  {key:'clock',name:'时钟',group:'时间',summary:'当前时间',source:'系统时间',detail:'时间'},
  {key:'date',name:'日期',group:'时间',summary:'日期、星期与节日',source:'本机日历计算',detail:'日期'},
  {key:'calendar',name:'台历',group:'时间',summary:'小卡看本周，大卡看整月',source:'本机日历计算',detail:'月历'},
  {key:'countdown',name:'倒计时',group:'时间',summary:'距离重要日子还有多久',source:'本机计算',detail:'目标日期'},
  {key:'anniversary',name:'纪念日',group:'时间',summary:'记录已经走过的日子',source:'本机计算',detail:'纪念日期'},
  {key:'dayprogress',name:'今日进度',group:'时间',summary:'一天的时间进度',source:'系统时间',detail:'今日进度'},
  {key:'yearprogress',name:'年度进度',group:'时间',summary:'一年的时间进度',source:'系统时间',detail:'年度进度'},
  {key:'timetable',name:'课程表',group:'生活',summary:'下一课或每日概览',source:'本地课表 · 可从教务导入',detail:'课程安排'},
  {key:'agenda',name:'日程',group:'生活',summary:'接下来要做的安排',source:'本地日历文件',detail:'日程列表'},
  {key:'parcel',name:'取件码',group:'生活',summary:'待取包裹和取件地点',source:'本机识别 · 主动导入',detail:'待取包裹'},
  {key:'battery',name:'电量',group:'生活',summary:'本机电量和充电状态',source:'系统电量',detail:'电量状态'},
  {key:'weather',name:'天气',group:'生活',summary:'城市温度与天气',source:'联网获取',detail:'城市天气'},
  {key:'fetch',name:'URL 内容',group:'自定义',summary:'把接口中的一个值放上卡片',source:'联网获取 · JSON / 纯文本',detail:'所选内容'}
];
export function capabilityDescriptor(key: string): CapabilityDescriptor {
  return CAPABILITY_CATALOG.find((item) => item.key === key) ?? {key:'none',name:'纯创作',group:'自定义',summary:'只展示背景、图片与文字',source:'本地作品',detail:'卡片'};
}
