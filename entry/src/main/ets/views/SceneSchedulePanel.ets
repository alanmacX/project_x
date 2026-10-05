import { SceneRule, SavedSceneLayout, sceneDay, sceneClock } from '../model/SceneScheduleSchema';
import { CanvasEntry } from '../model/CanvasLibrary';
import { AppDesign } from '../model/AppDesign';
import { SettingsSegmented } from './SettingsSegmented';
import { SettingsSelect } from './SettingsSelect';
@Component
export struct SceneSchedulePanel {
  @Prop layouts:SavedSceneLayout[]=[];
  @Prop rules:SceneRule[]=[];
  @Prop canvases:CanvasEntry[]=[];
  @Prop cards:CanvasEntry[]=[];
  @Prop appDark:boolean=false;
  onCapture:(name:string)=>void=()=>{};
  onRemoveLayout:(id:string)=>void=()=>{};
  onSave:(rule:SceneRule)=>void=()=>{};
  onRemove:(id:string)=>void=()=>{};
  onToggle:(id:string,value:boolean)=>void=()=>{};
  onPreview:(rule:SceneRule)=>void=()=>{};
  @State draft:SceneRule=new SceneRule();
  @State editingRule:boolean=false;
  @State layoutName:string='';
  private targets():CanvasEntry[] {return this.draft.kind==='layout'?this.layouts.map((s):CanvasEntry=>({id:s.id,name:s.name})):this.draft.kind==='canvas'?this.canvases:this.cards;}
  private edit(rule:SceneRule|null=null):void {
    this.draft=rule?JSON.parse(JSON.stringify(rule)) as SceneRule:new SceneRule();
    if(!rule){this.draft.name='新场景';this.draft.date=sceneDay(new Date());this.draft.start=(new Date().getHours()*60+new Date().getMinutes()+5)%1440;this.draft.end=(this.draft.start+60)%1440;this.draft.targetId=this.targets()[0]?.id??'';}
    this.editingRule=true;
  }
  private pickTime(start:boolean):void {
    const minute=start?this.draft.start:this.draft.end,date=new Date();date.setHours(Math.floor(minute/60),minute%60,0,0);
    TimePickerDialog.show({selected:date,useMilitaryTime:true,onAccept:(value:TimePickerResult)=>{const next=(value.hour??0)*60+(value.minute??0);if(start)this.draft.start=next;else this.draft.end=next;}});
  }
  private pickDate():void {
    const p=this.draft.date.split('-').map(Number);
    DatePickerDialog.show({selected:new Date(p[0],p[1]-1,p[2]),onAccept:(value:DatePickerResult)=>{this.draft.date=sceneDay(new Date(value.year??new Date().getFullYear(),value.month??0,value.day??1));}});
  }
  @Builder
  textButton(text:string,action:()=>void) {Button(text,{type:ButtonType.Capsule,buttonStyle:ButtonStyleMode.NORMAL}).height(44).fontColor(AppDesign.text(this.appDark)).backgroundColor(AppDesign.control(this.appDark)).onClick(action)}
  @Builder
  ruleEditor() {
    Column({space:16}) {
      Row(){Text(this.draft.id?'编辑场景':'添加场景').fontSize(18).fontWeight(FontWeight.Medium).fontColor(AppDesign.text(this.appDark));Blank();this.textButton('返回',()=>this.editingRule=false)}.width('100%')
      Column({space:16}) {
        TextInput({text:this.draft.name,placeholder:'场景名称'}).maxLength(30).height(44).fontColor(AppDesign.text(this.appDark)).backgroundColor(AppDesign.control(this.appDark)).borderRadius(12).onChange((v)=>this.draft.name=v)
        SettingsSegmented({labels:['切换摆放','切换画布','中央展示'],selectedIndex:['layout','canvas','focus'].indexOf(this.draft.kind),appDark:this.appDark,onSelect:(i)=>{this.draft.kind=['layout','canvas','focus'][i];this.draft.targetId=this.targets()[0]?.id??'';}})
        Text(this.draft.kind==='layout'?'使用同一组卡片，改变摆放、大小和角度':this.draft.kind==='canvas'?'进入另一张画布；区间结束后返回原画布':'卡片扫到边缘，中央展示你选的卡片').fontSize(13).fontColor(AppDesign.muted(this.appDark)).width('100%')
        SettingsSelect({labels:this.targets().map(t=>t.name),selectedIndex:this.targets().findIndex(t=>t.id===this.draft.targetId),placeholder:'请先准备布局或卡片',appDark:this.appDark,onSelect:(i)=>this.draft.targetId=this.targets()[i].id})
      }.padding(16).width('100%').backgroundColor(AppDesign.surface(this.appDark)).borderRadius(20)
      Column({space:16}) {
        Text('时间').fontSize(16).fontWeight(FontWeight.Medium).fontColor(AppDesign.text(this.appDark)).width('100%')
        SettingsSegmented({labels:['每周重复','指定一天'],selectedIndex:this.draft.repeat==='once'?1:0,appDark:this.appDark,onSelect:(i)=>this.draft.repeat=i===1?'once':'daily'})
        if(this.draft.repeat==='once') {this.textButton(this.draft.date,()=>this.pickDate())}
        else {Row({space:4}) {ForEach([1,2,3,4,5,6,0],(d:number)=>{
          Button(['日','一','二','三','四','五','六'][d],{type:ButtonType.Circle,buttonStyle:ButtonStyleMode.NORMAL}).height(40).layoutWeight(1).fontColor(AppDesign.choiceText(this.appDark,this.draft.weekdays.includes(d))).backgroundColor(AppDesign.choice(this.appDark,this.draft.weekdays.includes(d))).onClick(()=>this.draft.weekdays=this.draft.weekdays.includes(d)?this.draft.weekdays.filter(n=>n!==d):this.draft.weekdays.concat(d))
        },(d:number)=>String(d))}.width('100%')}
        Row({space:12}) {this.textButton('开始 '+sceneClock(this.draft.start),()=>this.pickTime(true));this.textButton('结束 '+sceneClock(this.draft.end),()=>this.pickTime(false))}.width('100%')
        if(this.draft.end<=this.draft.start) {Text('结束时间在次日；起止相同表示整天。').fontSize(12).fontColor(AppDesign.muted(this.appDark)).width('100%')}
        if(this.draft.kind==='focus') {Row(){Text('点击后才恢复').fontSize(14).fontColor(AppDesign.text(this.appDark)).layoutWeight(1);Toggle({type:ToggleType.Switch,isOn:this.draft.untilDismissed}).onChange((v)=>this.draft.untilDismissed=v)}.width('100%')}
      }.padding(16).width('100%').backgroundColor(AppDesign.surface(this.appDark)).borderRadius(20)
      Button('保存场景',{type:ButtonType.Capsule,buttonStyle:ButtonStyleMode.EMPHASIZED}).height(48).width('100%').fontColor(AppDesign.onSelected(this.appDark)).backgroundColor(AppDesign.selected(this.appDark)).enabled(this.draft.name.trim().length>0&&this.targets().some(t=>t.id===this.draft.targetId)&&(this.draft.repeat==='once'||this.draft.weekdays.length>0)).onClick(()=>{this.onSave(this.draft);this.editingRule=false;})
    }.width('100%')
  }
  build() {
    Scroll() {
      Column({space:20}) {
        Text('定时场景').fontSize(22).fontWeight(FontWeight.Medium).fontColor(AppDesign.text(this.appDark)).width('100%')
        if(this.editingRule){this.ruleEditor()}
        else {
          Column({space:12}) {
            Text('保存摆放').fontSize(16).fontWeight(FontWeight.Medium).fontColor(AppDesign.text(this.appDark)).width('100%')
            Text('调整首页卡片后保存为布局。内容仍使用原卡片，自动切换不会改动原始排版。').fontSize(13).fontColor(AppDesign.muted(this.appDark)).width('100%')
            Row({space:8}) {TextInput({text:this.layoutName,placeholder:'例如：晚间布局'}).layoutWeight(1).height(44).maxLength(30).fontColor(AppDesign.text(this.appDark)).backgroundColor(AppDesign.control(this.appDark)).borderRadius(12).onChange((v)=>this.layoutName=v);this.textButton('保存当前摆放',()=>{this.onCapture(this.layoutName.trim()||'布局 '+(this.layouts.length+1));this.layoutName='';})}.width('100%').enabled(this.layouts.length<8)
            ForEach(this.layouts,(s:SavedSceneLayout)=>{Row(){Text(s.name).fontSize(14).fontColor(AppDesign.text(this.appDark)).maxLines(1).textOverflow({overflow:TextOverflow.Ellipsis}).layoutWeight(1);Button({type:ButtonType.Circle,buttonStyle:ButtonStyleMode.NORMAL}){SymbolGlyph($r('sys.symbol.trash')).fontSize(18).fontColor(['#C43A35'])}.width(44).height(44).backgroundColor(Color.Transparent).accessibilityText('删除布局 '+s.name).onClick(()=>this.onRemoveLayout(s.id))}.width('100%')},(s:SavedSceneLayout)=>s.id)
          }.width('100%').padding(16).backgroundColor(AppDesign.surface(this.appDark)).borderRadius(20)
          ForEach(this.rules,(r:SceneRule)=>{
            Column({space:12}) {
              Row(){Text(r.name).fontSize(17).fontWeight(FontWeight.Medium).fontColor(AppDesign.text(this.appDark)).layoutWeight(1);Toggle({type:ToggleType.Switch,isOn:r.enabled}).onChange((v)=>this.onToggle(r.id,v))}.width('100%')
              Text((r.repeat==='once'?r.date:'每周 '+r.weekdays.map(d=>['日','一','二','三','四','五','六'][d]).join('、'))+' · '+sceneClock(r.start)+'–'+sceneClock(r.end)).fontSize(13).fontColor(AppDesign.muted(this.appDark)).width('100%')
              Text((r.kind==='layout'?'切换摆放':r.kind==='canvas'?'切换画布':'中央展示')+' · '+((r.kind==='layout'?this.layouts:r.kind==='canvas'?this.canvases:this.cards).find(t=>t.id===r.targetId)?.name??'目标已移除')).maxLines(2).textOverflow({overflow:TextOverflow.Ellipsis}).fontSize(13).fontColor(AppDesign.muted(this.appDark)).width('100%')
              Row({space:8}) {this.textButton('预览',()=>this.onPreview(r));this.textButton('编辑',()=>this.edit(r));Button({type:ButtonType.Circle,buttonStyle:ButtonStyleMode.NORMAL}){SymbolGlyph($r('sys.symbol.trash')).fontSize(18).fontColor(['#C43A35'])}.width(44).height(44).backgroundColor(Color.Transparent).accessibilityText('删除场景 '+r.name).onClick(()=>this.onRemove(r.id))}.width('100%')
            }.padding(16).width('100%').backgroundColor(AppDesign.surface(this.appDark)).borderRadius(20)
          },(r:SceneRule)=>r.id)
          Button('添加定时场景',{type:ButtonType.Capsule,buttonStyle:ButtonStyleMode.EMPHASIZED}).height(48).width('100%').fontColor(AppDesign.onSelected(this.appDark)).backgroundColor(AppDesign.selected(this.appDark)).enabled(this.rules.length<12).onClick(()=>this.edit())
          Text('时间以设备当地时区为准。重叠时最近开始的场景优先。桌面自动刷新受系统调度影响，不能保证精确到秒；App 内按时间边界切换。').fontSize(12).fontColor(AppDesign.muted(this.appDark)).width('100%')
        }
      }.width('100%').constraintSize({maxWidth:640}).padding({top:24,left:20,right:20,bottom:36})
    }.width('100%').height('100%').align(Alignment.Top).scrollBar(BarState.Off)
  }
}
