(function(g){
const categories=[['clock','时间'],['date','日期'],['calendar','台历'],['countdown','倒计时'],['anniversary','纪念日'],['dayprogress','今日进度'],['yearprogress','年度进度'],['battery','电量'],['agenda','日程'],['timetable','课程表'],['worldclock','世界时钟'],['lunar','农历'],['album','专辑'],['ensemble','组合']];
// Stable design IDs; schemes are preview definitions, not native package fields.
const rows=[
['clock','standby','浮字','StandBy','薄字、横向留白、远距离读数',['配色','12/24 小时制','日期']],
['clock','dial','色盘','Watch Palette / Simple','盘面色块、清晰指针与小时刻度',['配色','数字刻度']],
['clock','flip','翻页','物件 / 热门翻页钟','数字面与机械接缝',['深浅色','12/24 小时制']],
['clock','portrait','景深照片','Watch Photos','个人抠图与大数字前后遮挡',['照片','景深','位置','配色']],
['date','date-poster','日历海报','StandBy 日期','大日期与竖向星期分工',['强调色','星期']],
['date','date-paper','纸页','纸本','轻纸纹、当天日期、星期',['纸色','文字颜色']],
['date','date-strip','一周','编辑排版','横向星期与当天突出',['周起始','强调色']],
['calendar','calendar-month','月历','StandBy Calendar','安静网格与强对比当天',['周起始','配色']],
['calendar','calendar-ledger','月记','纸本 / 编辑排版','月份大标题与衬线日期',['纸色','强调色']],
['calendar','calendar-week','周历','紧凑日历','只保留本周的七天',['周起始','配色']],
['countdown','countdown-poster','出发','大数字海报','目标标题、极大剩余天数',['标题','目标日期','配色']],
['countdown','countdown-orbit','环绕','Watch 图形信息','剩余天数置中，外圈按起止区间显示',['目标日期','起始日期','配色']],
['countdown','countdown-paper','撕页','纸本','独立数字面与目标日期',['标题','目标日期','纸色']],
['anniversary','anniversary-photo','相遇','照片 / 个性内容','照片与共同经历的天数',['照片','标题','起始日期']],
['anniversary','anniversary-type','记忆','编辑排版','高反差大数字与日期刻印',['标题','起始日期','配色']],
['anniversary','anniversary-stamp','纪念章','纸本印刷','印章式信息与拱形日期',['标题','起始日期','印色']],
['dayprogress','day-dial','一天','Watch 环形信息','24 小时刻度与时间经过比例',['配色','数字开关']],
['dayprogress','day-timeline','日线','StandBy / 时间线','一日时段条与当前位置',['配色','时间标记']],
['dayprogress','day-blocks','时块','图形信息','24 格对应一天 24 小时',['配色','数字开关']],
['yearprogress','year-dots','年点','年度点阵','每天一个点，全年进度一眼可见',['配色','数字开关']],
['yearprogress','year-arc','年轮','Watch 弧形信息','已过天数与剩余天数沿弧组织',['配色','年份']],
['yearprogress','year-months','十二月','编辑排版','十二个月的进度，当前月突出',['配色','年份']],
['battery','battery-ring','能量环','Watch Battery','环形读数与简洁数值',['配色','数字开关']],
['battery','battery-cell','电芯','图形信息','大电池轮廓与真实比例填充',['配色','横竖布局']],
['battery','battery-segments','电格','复古电子屏','十段能量与点阵味数字',['屏幕色','数字开关']],
['agenda','agenda-editorial','留白日程','编辑排版','下一条主事件与后续两条',['信息密度','强调色']],
['agenda','agenda-timeline','时间轴','Watch Modular','时间与事件沿同一轴排列',['强调色','时间格式']],
['agenda','agenda-paper','手帐','纸本','细横线与安静标题',['纸色','信息密度']],
['timetable','course-next','下节课','Watch Modular Duo','下一节课程做主角，时间地点收在底部',['课程来源','配色']],
['timetable','course-week','一周课表','网格 / 功能型','五个工作日的课程结构',['课程来源','配色']],
['timetable','course-slips','课程纸条','冰箱贴','当日课程按时间分成小纸条',['课程来源','纸色']],
['worldclock','world-dial','异地','Watch GMT','双时区指针与目的地时间',['城市','配色']],
['worldclock','world-duo','两地','StandBy 分栏','本地与目的地两列直接比较',['城市','12/24 小时制']],
['worldclock','world-type','时差','编辑排版','目的地大时间与清晰日期关系',['城市','强调色']],
['lunar','lunar-paper','东方日历','纸本 / 中文排版','农历日期、干支年与公历对照',['纸色','印色']],
['lunar','lunar-night','月白','暗色 / 中文排版','农历大字与克制的装饰性圆盘',['配色','年号']],
['lunar','lunar-seal','朱印','中文印刷','红白强对比与纵向农历字序',['印色','日期顺序']],
['album','album-record','唱片','复古物件 / 热门音乐卡','本地封面与黑胶同框',['封面','标题','唱片色']],
['album','album-cover','封面','照片 / 编辑排版','封面占主体，元数据在下方',['封面','标题','配色']],
['album','album-sleeve','唱片袋','纸本物件','纸袋、圆形开窗与专辑标签',['封面','纸色','标题']],
['ensemble','mix-standby','桌边','StandBy / Duo','时间 + 月历',['时钟','月历','配色']],
['ensemble','mix-modular','今日','Watch Modular Duo','时间 + 日程 + 电量',['日程来源','时区','配色']],
['ensemble','mix-study','课间','Watch Modular Duo','时间 + 下节课 + 今日进度',['课程来源','配色']],
['ensemble','mix-travel','远行','两地信息组合','世界时钟 + 倒计时',['城市','目标日期','配色']],
['ensemble','mix-memory','相片日历','照片 + 纸本','纪念日照片 + 日期 + 农历',['照片','起始日期','配色']]
];
const sourceMap={'mix-standby':['clock','calendar'],'mix-modular':['clock','agenda','battery'],'mix-study':['clock','timetable','dayprogress'],'mix-travel':['worldclock','countdown'],'mix-memory':['anniversary','date','lunar']};
const catalog=rows.map(([kind,id,name,reference,intent,customize])=>({kind,id,name,reference,intent,customize,sources:sourceMap[id]||[kind],scope:kind==='ensemble'?'group':'card',aspect:id==='mix-standby'?2:1,revision:1}));
g.TemplateCatalog={categories,catalog};if(typeof module!=='undefined')module.exports=g.TemplateCatalog;
})(globalThis);
