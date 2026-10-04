import { CapBlock, ParcelItem, AgendaItem } from '../model/CardSchema';
import { pendingParcels, eventWhen } from '../model/CapabilityData';
import { AppDesign } from '../model/AppDesign';
import { pasteboard } from '@kit.BasicServicesKit';
import { ParcelImportDialog } from './ParcelImportDialog';
import { mergePickupParcels } from '../model/ParcelIntake';
/** Reading/doing surface, separate from artwork editing. Desktop links land here. */
@Component
export struct CapabilityDetails {
  @Prop cap:CapBlock={k:'parcel'};
  @Prop appDark:boolean=false;
  @Prop tick:number=0;
  onUpdate:(cap:CapBlock)=>void=()=>{};
  @State lastPicked:string='';
  private dialog:CustomDialogController|null=null;
  aboutToDisappear():void {this.dialog?.close();}
  private add():void {
    this.dialog=new CustomDialogController({builder:ParcelImportDialog({appDark:this.appDark,defaultPlace:this.cap.parcelPlace??'',onImport:(items:ParcelItem[])=>{
      const next=JSON.parse(JSON.stringify(this.cap)) as CapBlock;
      next.parcels=mergePickupParcels(next.parcels??[],items,next.parcelPlace??'',Date.now());this.onUpdate(next);
    }}),customStyle:true,autoCancel:true});this.dialog.open();
  }
  private picked(id:string,value:boolean):void {
    const next=JSON.parse(JSON.stringify(this.cap)) as CapBlock;
    for(const p of next.parcels??[])if(p.id===id)p.picked=value;
    this.lastPicked=value?id:'';this.onUpdate(next);
  }
  private async copy(code:string):Promise<void> {
    try{await pasteboard.getSystemPasteboard().setData(pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN,code));this.getUIContext().getPromptAction().showToast({message:'已复制取件码'});}
    catch(_){this.getUIContext().getPromptAction().showToast({message:'复制未完成，请重试'});}
  }
  private events():AgendaItem[] {return (this.cap.events??[]).filter((e)=>e.end>(this.tick||Date.now())).slice().sort((a,b)=>a.start-b.start);}
  build() {
    Column({space:12}) {
      if(this.cap.k==='parcel') {
        Row() {
          Text('待取 · '+pendingParcels(this.cap).length+' 件').fontSize(14).fontColor(AppDesign.muted(this.appDark)).layoutWeight(1)
          if(this.lastPicked) {Button('撤销已取',{type:ButtonType.Capsule, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL}).height(44).fontSize(13).backgroundColor(AppDesign.control(this.appDark)).fontColor(AppDesign.text(this.appDark)).onClick(()=>this.picked(this.lastPicked,false))}
          Button('添加通知',{type:ButtonType.Capsule, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL}).height(44).fontSize(13).backgroundColor(AppDesign.control(this.appDark)).fontColor(AppDesign.text(this.appDark)).margin({left:8}).onClick(()=>this.add())
        }.width('100%')
        if(!pendingParcels(this.cap).length) {Text('暂无待取包裹').fontSize(20).fontColor(AppDesign.text(this.appDark)).width('100%').padding(16)}
        ForEach(pendingParcels(this.cap),(p:ParcelItem)=>{
          Column({space:12}) {
            Row({space:12}) {
              Text(p.code).fontSize(26).minFontSize(18).maxFontSize(26).fontWeight(FontWeight.Medium).fontColor(AppDesign.text(this.appDark)).maxLines(1).textOverflow({overflow:TextOverflow.Ellipsis}).layoutWeight(1)
              Button('复制',{type:ButtonType.Capsule, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL}).height(44).fontSize(14).backgroundColor(AppDesign.control(this.appDark)).fontColor(AppDesign.text(this.appDark)).onClick(()=>this.copy(p.code))
            }.width('100%')
            Row({space:12}) {
              Text(p.place||'未填写取件地点').fontSize(14).fontColor(AppDesign.muted(this.appDark)).maxLines(2).layoutWeight(1)
              Button('已取',{type:ButtonType.Capsule, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL}).height(44).fontSize(14).backgroundColor(AppDesign.control(this.appDark)).fontColor(AppDesign.text(this.appDark)).onClick(()=>this.picked(p.id,true))
            }.width('100%')
          }.width('100%').padding(16).backgroundColor(AppDesign.surface(this.appDark)).borderRadius(20)
        },(p:ParcelItem)=>p.id)
      } else if(this.cap.k==='agenda') {
        if(!this.events().length) {Text('暂无日程').fontSize(20).fontColor(AppDesign.text(this.appDark)).width('100%').padding(16)}
        ForEach(this.events(),(e:AgendaItem)=>{
          Column({space:8}) {
            Text(eventWhen(e,this.tick||Date.now())).fontSize(12).fontColor(AppDesign.muted(this.appDark)).width('100%')
            Text(e.title).fontSize(18).fontWeight(FontWeight.Medium).fontColor(AppDesign.text(this.appDark)).maxLines(3).width('100%')
            if(e.location) {Text(e.location).fontSize(14).fontColor(AppDesign.muted(this.appDark)).maxLines(2).width('100%')}
          }.padding(16).width('100%').backgroundColor(AppDesign.surface(this.appDark)).borderRadius(20)
        },(e:AgendaItem)=>e.id)
      }
    }.width('100%')
  }
}
