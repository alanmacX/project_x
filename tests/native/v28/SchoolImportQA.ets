import { webview } from '@kit.ArkWeb';
import { util, taskpool } from '@kit.ArkTS';
import { fileIo } from '@kit.CoreFileKit';
import { SchoolImportDialog } from '../views/SchoolImportDialog';
import { WakeUpImportDialog } from '../views/WakeUpImportDialog';
import { schoolSnapshot } from '../model/SchoolImport';
import { parseSchoolText } from '../model/ScheduleFiles';
@Entry @Component
struct NativeV28QA {
  @State result:string='准备校验';
  private web:webview.WebviewController=new webview.WebviewController();
  private dialog:CustomDialogController|undefined=undefined;
  private loaded:boolean=false;
  private provider:string='schools/urp_jiaowu/urp_01.js';
  private async strong():Promise<void>{this.provider='school-qiangzhi.js';this.web.loadData('<html><body><table id="kbtable"><tr><th colspan="2">节次</th><th>星期一</th><th>星期二</th><th>星期三</th><th>星期四</th><th>星期五</th><th>星期六</th><th>星期日</th></tr><tr><td rowspan="2">上午</td><td>1</td><td></td><td></td><td><div class="kbcontent">数学<br><font title="老师">教师</font><br><font title="周次(节次)">1-8单周[1-2节]</font><br><font title="教室">A101</font></div></td><td></td><td></td><td></td><td></td></tr><tr><td>2</td><td></td><td></td><td><div class="kbcontent">英语<br><font title="周次(节次)">2-8双周[3-4节]</font></div></td></tr></table></body></html>','text/html','utf-8');setTimeout(()=>this.test(),400);}
  private html:string='<html><body><h1>URP 课表测试</h1><table><tr><th id="0_11">(20:00-20:45)</th><th id="0_12">(20:55-21:40)</th></tr><tr><td id="3_11"><div class="class_div"><p>高等数学</p><p>说明</p><p>教师</p><p>1-3,5-9单,10-11周</p><p>11-12节</p><p>A101</p></div></td></tr></table></body></html>';
  private async test():Promise<void> {
    try{
      const rm=this.getUIContext().getHostContext()!.resourceManager,decoder=new util.TextDecoder();
      const b=decoder.decodeToString(await rm.getRawFileContent('school-bridge.js')).replace('__TOKEN__','"qa"');
      const source=decoder.decodeToString(await rm.getRawFileContent(this.provider));
      await this.web.runJavaScript(b+'\n(function(){'+source+'})();');
      const first=schoolSnapshot(await this.web.runJavaScript('window.__fridgeSchool.snapshot()'));
      if(first.request?.kind!=='alert')throw new Error('未显示确认');
      await this.web.runJavaScript('window.__fridgeSchool.reply('+first.request.id+',true)');
      setTimeout(async()=>{
        try {const data=await this.web.runJavaScript('window.__fridgeSchool.snapshot()'),parsed=await taskpool.execute(new taskpool.Task(parseSchoolText,data,'原生 URP')) as string;
          this.result='PASS 原生 ArkWeb → '+this.provider+' → 本机预览';const ctx=this.getUIContext().getHostContext()!;const file=fileIo.openSync(ctx.filesDir+'/v28-qa.json',fileIo.OpenMode.CREATE|fileIo.OpenMode.WRITE_ONLY|fileIo.OpenMode.TRUNC);try{fileIo.writeSync(file.fd,parsed);}finally{fileIo.closeSync(file.fd);}}
        catch(e){this.result='FAIL '+(e as Error).message+' '+await this.web.runJavaScript('window.__fridgeSchool.snapshot()');}
      },300);
    }catch(e){this.result='FAIL '+(e as Error).message;}
  }
  build(){Column({space:20}){
    Text(this.result).fontSize(20)
    Button('学校目录').onClick(()=>{this.dialog=new CustomDialogController({builder:SchoolImportDialog({onRead:(v:string)=>this.result=v}),customStyle:true,autoCancel:false});this.dialog.open();})
    Button('导入入口').onClick(()=>{this.dialog=new CustomDialogController({builder:WakeUpImportDialog({}),customStyle:true});this.dialog.open();})
    Button('强智校验').onClick(()=>this.strong())
    Button('ArkWeb 校验').onClick(()=>this.test())
    Web({src:'about:blank',controller:this.web,incognitoMode:true}).width('100%').height(150).onPageEnd(()=>{if(!this.loaded){this.loaded=true;this.web.loadData(this.html,'text/html','utf-8');}})
  }.padding(50).width('100%').height('100%').backgroundColor('#FFFFFF')}
}
