import { SceneRule, sceneDay, sceneClock } from '../model/SceneScheduleSchema';
import { CanvasEntry } from '../model/CanvasLibrary';
import { CanvasRotation, CanvasTimeSlot, normalizeCanvasRotation, canvasRotationEnabled } from '../model/CanvasRotation';
import { AppDesign } from '../model/AppDesign';
import { SettingsSegmented } from './SettingsSegmented';
import { SettingsSelect } from './SettingsSelect';
@Component
export struct SceneSchedulePanel {
  @Prop rules:SceneRule[]=[];
  @Prop scenes:CanvasEntry[]=[];
  @Prop canvases:CanvasEntry[]=[];
  @Prop rotation:CanvasRotation=new CanvasRotation();
  @Prop appDark:boolean=false;
  @Prop initialTab:number=0;
  onCreate:()=>void=()=>{};
  onEditCard:(id:string)=>void=()=>{};
  onSave:(rule:SceneRule)=>void=()=>{};
  onRemove:(id:string)=>void=()=>{};
  onToggle:(id:string,value:boolean)=>void=()=>{};
  onPreview:(rule:SceneRule)=>void=()=>{};
  onRotation:(rotation:CanvasRotation)=>void=()=>{};
  private contentScroller:Scroller=new Scroller();
  @State tab:number=0;
  private draft:SceneRule=new SceneRule();
  @State draftStart:number=1200;
  @State draftDate:string='';
  @State draftName:string='';
  @State draftEnabled:boolean=true;
  @State draftRepeat:string='daily';
  @State draftWeekdays:number[]=[0,1,2,3,4,5,6];
  @State draftTimeout:number=15;
  @State editingRule:boolean=false;
  @State rotationDraft:CanvasRotation=new CanvasRotation();
  aboutToAppear():void {this.tab=this.initialTab;this.rotationDraft=normalizeCanvasRotation(this.rotation,this.canvases.map(c=>c.id));}
  private edit(rule:SceneRule):void {
    this.draft=JSON.parse(JSON.stringify(rule)) as SceneRule;
    this.draftStart=rule.start;this.draftDate=rule.date;this.draftName=rule.name;this.draftEnabled=rule.enabled;this.draftRepeat=rule.repeat;this.draftWeekdays=rule.weekdays.slice();this.draftTimeout=rule.timeoutMinutes;
    this.contentScroller.scrollTo({xOffset:0,yOffset:0});this.editingRule=true;
  }
  private draftRule():SceneRule {
    const rule=JSON.parse(JSON.stringify(this.draft)) as SceneRule;
    rule.start=this.draftStart;rule.date=this.draftDate;rule.name=this.draftName;rule.enabled=this.draftEnabled;rule.repeat=this.draftRepeat;rule.weekdays=this.draftWeekdays.slice();rule.timeoutMinutes=this.draftTimeout;return rule;
  }
  private pickTime():void {const d=new Date();d.setHours(Math.floor(this.draftStart/60),this.draftStart%60,0,0);this.getUIContext().showTimePickerDialog({selected:d,useMilitaryTime:true,onAccept:(v:TimePickerResult)=>{this.draftStart=(v.hour??0)*60+(v.minute??0);}});}
  private pickDate():void {const p=this.draftDate.split('-').map(Number);this.getUIContext().showDatePickerDialog({selected:p.length===3?new Date(p[0],p[1]-1,p[2]):new Date(),onAccept:(v:DatePickerResult)=>{this.draftDate=sceneDay(new Date(v.year??new Date().getFullYear(),v.month??0,v.day??1));}});}
  private saveRotation():void {this.rotationDraft=normalizeCanvasRotation(this.rotationDraft,this.canvases.map(c=>c.id));this.onRotation(this.rotationDraft);}
  private slotTime(index:number):void {const d=new Date();d.setHours(Math.floor(this.rotationDraft.slots[index].start/60),this.rotationDraft.slots[index].start%60,0,0);this.getUIContext().showTimePickerDialog({selected:d,useMilitaryTime:true,onAccept:(v:TimePickerResult)=>{const minute=(v.hour??0)*60+(v.minute??0);if(this.rotationDraft.slots.some((slot:CanvasTimeSlot,i:number)=>i!==index&&slot.start===minute)){this.getUIContext().getPromptAction().showToast({message:'这个时间已有分界'});return;}this.rotationDraft.slots[index].start=minute;this.saveRotation();}});}
  @Builder
  action(label:string,callback:()=>void) {Button(label,{type:ButtonType.Capsule,buttonStyle:ButtonStyleMode.NORMAL}).height(40).fontSize(13).fontColor(AppDesign.text(this.appDark)).backgroundColor(AppDesign.control(this.appDark)).onClick(callback)}
  @Builder
  timing() {
    Column({space:10}) {
      Row(){Text('出现时间').fontSize(17).fontWeight(FontWeight.Medium).fontColor(AppDesign.text(this.appDark));Blank();this.action('返回',()=>{this.contentScroller.scrollTo({xOffset:0,yOffset:0});this.editingRule=false;})}.width('100%')
      Row(){Text('启用场景').fontColor(AppDesign.text(this.appDark)).layoutWeight(1);Toggle({type:ToggleType.Switch,isOn:this.draftEnabled}).onChange(value=>this.draftEnabled=value)}.width('100%')
      TextInput({text:this.draftName,placeholder:'场景名称'}).height(44).maxLength(30).fontColor(AppDesign.text(this.appDark)).backgroundColor(AppDesign.control(this.appDark)).onChange(v=>this.draftName=v)
      SettingsSegmented({labels:['每周重复','仅一次'],selectedIndex:this.draftRepeat==='once'?1:0,appDark:this.appDark,onSelect:i=>{this.draftRepeat=i===1?'once':'daily';if(!this.draftDate)this.draftDate=sceneDay(new Date());}})
      if(this.draftRepeat==='once'){Button(this.draftDate,{type:ButtonType.Capsule,buttonStyle:ButtonStyleMode.NORMAL}).height(40).fontSize(13).fontColor(AppDesign.text(this.appDark)).backgroundColor(AppDesign.control(this.appDark)).onClick(()=>this.pickDate())}
      else {Row({space:4}){ForEach([1,2,3,4,5,6,0],(d:number)=>{Button(['日','一','二','三','四','五','六'][d],{type:ButtonType.Circle}).height(40).layoutWeight(1).fontColor(AppDesign.choiceText(this.appDark,this.draftWeekdays.includes(d))).backgroundColor(AppDesign.choice(this.appDark,this.draftWeekdays.includes(d))).onClick(()=>this.draftWeekdays=this.draftWeekdays.includes(d)?this.draftWeekdays.filter(n=>n!==d):this.draftWeekdays.concat(d))},(d:number)=>String(d))}.width('100%')}
      Row(){Text('到点出现').fontColor(AppDesign.text(this.appDark)).layoutWeight(1);Button(sceneClock(this.draftStart),{type:ButtonType.Capsule,buttonStyle:ButtonStyleMode.NORMAL}).height(40).fontSize(13).fontColor(AppDesign.text(this.appDark)).backgroundColor(AppDesign.control(this.appDark)).onClick(()=>this.pickTime())}.width('100%')
      Row({space:12}){Text('最多显示').fontColor(AppDesign.text(this.appDark)).layoutWeight(1);this.action('−',()=>this.draftTimeout=Math.max(1,this.draftTimeout-1));Text(this.draftTimeout+' 分钟').fontSize(14).fontColor(AppDesign.text(this.appDark));this.action('+',()=>this.draftTimeout=Math.min(120,this.draftTimeout+1))}.width('100%')
      Text('点击中央卡片或超时，恢复当前主画布。新场景出现会结束旧场景；旧场景不会重新出现。').fontSize(13).fontColor(AppDesign.muted(this.appDark)).width('100%')
      Button('保存',{type:ButtonType.Capsule,buttonStyle:ButtonStyleMode.EMPHASIZED}).height(44).width('100%').backgroundColor(AppDesign.selected(this.appDark)).fontColor(AppDesign.onSelected(this.appDark)).enabled(this.draftName.trim().length>0&&(this.draftRepeat==='once'||this.draftWeekdays.length>0)).onClick(()=>{this.onSave(this.draftRule());this.editingRule=false;})
    }.width('100%').padding(12).backgroundColor(AppDesign.surface(this.appDark)).borderRadius(20)
  }
  @Builder
  rotationEditor() {
    Column({space:10}) {
      Row(){Text('画布轮换').fontSize(16).fontColor(AppDesign.text(this.appDark)).layoutWeight(1);Toggle({type:ToggleType.Switch,isOn:canvasRotationEnabled(this.rotationDraft)}).accessibilityText('启用画布轮换').onChange(value=>{this.rotationDraft.enabled=value;if(value&&this.rotationDraft.mode==='off')this.rotationDraft.mode='time';this.saveRotation();})}.width('100%')
      SettingsSegmented({labels:['按时间','跟随深浅'],selectedIndex:this.rotationDraft.mode==='theme'?1:0,appDark:this.appDark,onSelect:i=>{this.rotationDraft.mode=i===1?'theme':'time';this.saveRotation();}})
      if(!canvasRotationEnabled(this.rotationDraft)){Text('已暂停，保留以下轮换设置。手动切换画布也会暂停轮换。').fontSize(12).fontColor(AppDesign.muted(this.appDark)).width('100%')}

      if(this.rotationDraft.mode==='theme') {
        Text('浅色模式').fontColor(AppDesign.text(this.appDark)).width('100%')
        SettingsSelect({labels:this.canvases.map(c=>c.name),selectedIndex:this.canvases.findIndex(c=>c.id===this.rotationDraft.lightId),appDark:this.appDark,onSelect:i=>{this.rotationDraft.lightId=this.canvases[i].id;this.saveRotation();}})
        Text('深色模式').fontColor(AppDesign.text(this.appDark)).width('100%')
        SettingsSelect({labels:this.canvases.map(c=>c.name),selectedIndex:this.canvases.findIndex(c=>c.id===this.rotationDraft.darkId),appDark:this.appDark,onSelect:i=>{this.rotationDraft.darkId=this.canvases[i].id;this.saveRotation();}})
        Text('跟随系统外观切换，不叠加自定义时间。').fontSize(13).fontColor(AppDesign.muted(this.appDark)).width('100%')
      } else if(this.rotationDraft.mode==='time') {
        ForEach(this.rotationDraft.slots,(slot:CanvasTimeSlot,index:number)=>{
          Column({space:8}) {
            Row(){if(index===0){Text('00:00 – '+(this.rotationDraft.slots.length>1?sceneClock(this.rotationDraft.slots[1].start):'24:00')).height(40).fontSize(13).fontColor(AppDesign.text(this.appDark))}else{Button(sceneClock(slot.start)+' – '+(index+1<this.rotationDraft.slots.length?sceneClock(this.rotationDraft.slots[index+1].start):'24:00'),{type:ButtonType.Capsule,buttonStyle:ButtonStyleMode.NORMAL}).height(40).fontSize(13).fontColor(AppDesign.text(this.appDark)).backgroundColor(AppDesign.control(this.appDark)).onClick(()=>this.slotTime(index))}Blank();if(index>0){Button({type:ButtonType.Circle}){SymbolGlyph($r('sys.symbol.trash')).fontSize(18).fontColor(['#C43A35'])}.width(44).height(44).backgroundColor(Color.Transparent).accessibilityText('删除时段').onClick(()=>{this.rotationDraft.slots=this.rotationDraft.slots.filter((s,i)=>i!==index);this.saveRotation();})}}.width('100%')
            SettingsSelect({labels:this.canvases.map(c=>c.name),selectedIndex:this.canvases.findIndex(c=>c.id===slot.canvasId),appDark:this.appDark,onSelect:i=>{slot.canvasId=this.canvases[i].id;this.saveRotation();}})
          }.padding(12).width('100%').backgroundColor(AppDesign.control(this.appDark)).borderRadius(16)
        },(slot:CanvasTimeSlot)=>String(slot.start))
        this.action('添加时间分界',()=>{if(this.rotationDraft.slots.length>=12)return;let start=720;while(this.rotationDraft.slots.some(s=>s.start===start)&&start<1439)start++;if(start>=1440)return;this.rotationDraft.slots.push({start,canvasId:this.canvases[0]?.id??''});this.saveRotation();})
        Text('从 00:00 到 24:00 连续覆盖；修改分界会同时调整相邻区间。').fontSize(13).fontColor(AppDesign.muted(this.appDark)).width('100%')
      } else {Text('在“画布”里自由切换。').fontSize(14).fontColor(AppDesign.muted(this.appDark)).width('100%')}
    }.width('100%').padding(12).backgroundColor(AppDesign.surface(this.appDark)).borderRadius(20)
  }
  @Builder
  sceneList() {
    Column({space:10}) {
          ForEach(this.rules,(rule:SceneRule)=>{
            Column({space:6}) {
              Row(){Text(rule.name).fontSize(15).maxLines(1).textOverflow({overflow:TextOverflow.Ellipsis}).fontWeight(FontWeight.Medium).fontColor(AppDesign.text(this.appDark)).layoutWeight(1);Toggle({type:ToggleType.Switch,isOn:rule.enabled}).onChange(v=>this.onToggle(rule.id,v))}.width('100%')
              Text((rule.repeat==='once'?rule.date:(rule.weekdays.length===7?'每天':'每周 '+rule.weekdays.map(d=>['日','一','二','三','四','五','六'][d]).join('')))+' · '+sceneClock(rule.start)+' · '+rule.timeoutMinutes+' 分钟').fontSize(13).fontColor(AppDesign.muted(this.appDark)).width('100%')
              Row({space:8}){this.action('卡片',()=>this.onEditCard(rule.targetId));this.action('时间',()=>this.edit(rule));Button('预览',{type:ButtonType.Capsule,buttonStyle:ButtonStyleMode.NORMAL}).height(40).fontSize(13).fontColor(AppDesign.text(this.appDark)).backgroundColor(AppDesign.control(this.appDark)).onClick(()=>this.onPreview(rule));Button({type:ButtonType.Circle,buttonStyle:ButtonStyleMode.NORMAL,role:ButtonRole.ERROR}){SymbolGlyph($r('sys.symbol.trash')).fontSize(18).fontColor(['#C43A35']).hitTestBehavior(HitTestMode.None)}.width(40).height(40).backgroundColor(Color.Transparent).accessibilityText('删除场景 '+rule.name).onClick(()=>this.onRemove(rule.targetId))}.width('100%')
            }.width('100%').padding(12).backgroundColor(AppDesign.surface(this.appDark)).borderRadius(20)
          },(rule:SceneRule)=>rule.id)
          Button('新建场景',{type:ButtonType.Capsule,buttonStyle:ButtonStyleMode.EMPHASIZED}).height(40).width('100%').fontColor(AppDesign.onSelected(this.appDark)).backgroundColor(AppDesign.selected(this.appDark)).enabled(this.scenes.length<12).onClick(this.onCreate)
          Text('到点展示中央卡片，点击或超时恢复。').fontSize(12).fontColor(AppDesign.muted(this.appDark)).width('100%')

    }.width('100%').padding({bottom:12})
  }
  build() {
    Column({space:10}) {
      SettingsSegmented({labels:['定时场景','画布轮换'],selectedIndex:this.tab,appDark:this.appDark,onSelect:i=>{this.tab=i;this.editingRule=false;}}).height(48)
      // Tabs owns the transition viewport; outgoing pages cannot resize or displace the navigation row.
      Tabs({index:this.tab}) {
        TabContent() {
          Scroll(this.contentScroller) {
            Column() {if(this.editingRule){this.timing()}else{this.sceneList()}}.width('100%').alignItems(HorizontalAlign.Start)
          }.width('100%').height('100%').align(Alignment.Top).scrollBar(BarState.Off)
        }
        TabContent() {
          Scroll() {this.rotationEditor()}.width('100%').height('100%').align(Alignment.Top).scrollBar(BarState.Off)
        }
      }.width('100%').layoutWeight(1).barHeight(0).scrollable(false).animationDuration(180).onChange((index:number)=>this.tab=index)
    }.width('100%').height('100%').padding({top:8,left:8,right:8,bottom:0})
  }
}
