/** The contract for a capability: one purpose, an honest source, one detail destination. */
export interface CapabilityDescriptor { key: string; name: string; group: string; summary: string; source: string; detail: string; }
export const CAPABILITY_GROUPS: string[] = ['时间', '生活'];
export const CAPABILITY_CATALOG: CapabilityDescriptor[] = [
  {key:'clock',name:'时钟',group:'时间',summary:'当前时间',source:'系统时间',detail:'时间'},
  {key:'worldclock',name:'世界时钟',group:'时间',summary:'另一座城市的时间、日期与时差',source:'系统时区规则 · 自动适配夏令时',detail:'城市时间'},
  {key:'lunar',name:'农历',group:'时间',summary:'农历月日与干支年份',source:'系统农历计算 · 完全离线',detail:'农历日期'},
  {key:'date',name:'日期',group:'时间',summary:'日期、星期与节日',source:'本机日历计算',detail:'日期'},
  {key:'calendar',name:'台历',group:'时间',summary:'小卡看本周，大卡看整月',source:'本机日历计算',detail:'月历'},
  {key:'countdown',name:'倒计时',group:'时间',summary:'距离重要日子还有多久',source:'本机计算',detail:'目标日期'},
  {key:'anniversary',name:'纪念日',group:'时间',summary:'记录已经走过的日子',source:'本机计算',detail:'纪念日期'},
  {key:'dayprogress',name:'今日进度',group:'时间',summary:'一天的时间进度',source:'系统时间',detail:'今日进度'},
  {key:'yearprogress',name:'年度进度',group:'时间',summary:'一年的时间进度',source:'系统时间',detail:'年度进度'},
  {key:'timetable',name:'课程表',group:'生活',summary:'下一课或每日概览',source:'本地课表 · WakeUp 文件导入',detail:'课程安排'},
  {key:'agenda',name:'日程',group:'生活',summary:'接下来要做的安排',source:'本地日历文件',detail:'日程列表'},
  {key:'album',name:'音乐专辑',group:'生活',summary:'居中封面与静态融合背景',source:'本地封面 · 离线融合背景',detail:'专辑'},
  {key:'battery',name:'电量',group:'生活',summary:'本机电量和充电状态',source:'系统电量',detail:'电量状态'}
];
export function capabilityDescriptor(key: string): CapabilityDescriptor {
  return CAPABILITY_CATALOG.find((item) => item.key === key) ?? {key:'none',name:'纯创作',group:'自定义',summary:'只展示背景、图片与文字',source:'本地作品',detail:'卡片'};
}
