import { webview } from '@kit.ArkWeb';
import { taskpool, util } from '@kit.ArkTS';
import { parseSchoolText } from '../model/ScheduleFiles';
import { AppDesign } from '../model/AppDesign';
import { ImportSchool, SchoolAdapter, SchoolRequest, schoolUrl, schoolSnapshot, webString } from '../model/SchoolImport';
@CustomDialog
export struct SchoolImportDialog {
  controller:CustomDialogController;
  appDark:boolean=false;
  onRead:(json:string)=>void=()=>{};
  @State schools:ImportSchool[]=[];
  @State visible:ImportSchool[]=[];
  @State query:string='';
  @State adapters:SchoolAdapter[]=[];
  @State schoolName:string='';
  @State selected:SchoolAdapter|undefined=undefined;
  @State url:string='';
  @State page:string='';
  @State busy:boolean=false;
  @State progress:number=0;
  @State error:string='';
  @State message:string='登录教务后，打开需要导入的学期个人课表。';
  @State request:SchoolRequest|undefined=undefined;
  @State input:string='';
  @State ready:boolean=false;
  private web:webview.WebviewController=new webview.WebviewController();
  private alive:boolean=true;
  private timer:number=-1;
  private searchTimer:number=-1;
  private token:string='';
  private elapsed:number=0;
  private failedUrl:string='';
  @State frames:string[]=[];
  @State showFrames:boolean=false;
  private async pageReady(url:string):Promise<void> {
    this.ready=this.failedUrl!==url;this.url=url;this.showFrames=false;
    try{const result=await this.web.runJavaScript('JSON.stringify(Array.from(document.querySelectorAll("iframe,frame")).map(f=>f.src).filter(s=>/^https?:/.test(s)).slice(0,12))');if(this.alive&&this.url===url)this.frames=JSON.parse(webString(result)) as string[];}catch(_){this.frames=[];}
  }
  private display(value:string):string {return value.replace(/拾光课程表|拾光课表|轻屿课表/g,'本 App');}
  private frame(url:string):void {this.url=url;this.showFrames=false;this.open();}
  @State limit:number=40;
  private more():void {this.limit+=40;this.filter();}
  async aboutToAppear():Promise<void> {
    try{const bytes=await this.getUIContext().getHostContext()!.resourceManager.getRawFileContent('schools/catalog.json');const schools=JSON.parse(new util.TextDecoder().decodeToString(bytes)) as ImportSchool[];if(!this.alive)return;this.schools=schools;this.filter();}catch(_){if(this.alive)this.error='学校目录读取失败，请重新打开';}
  }
  aboutToDisappear():void {this.alive=false;this.stop();if(this.searchTimer>=0)clearTimeout(this.searchTimer);}
  private filter():void {const q=this.query.trim().toLowerCase();this.visible=this.schools.filter((s)=>!q||s.name.toLowerCase().includes(q)||s.id.toLowerCase().includes(q)).slice(0,this.limit);}
  private search(v:string):void {this.query=v;this.limit=40;if(this.searchTimer>=0)clearTimeout(this.searchTimer);this.searchTimer=setTimeout(()=>{if(this.alive)this.filter();},120);}
  private resetSchool():void {this.stop();this.page='';this.selected=undefined;this.adapters=[];this.schoolName='';this.frames=[];this.error='';this.message='登录教务后，打开需要导入的学期个人课表。';}
  private choose(s:ImportSchool|undefined):void {if(!s)return;this.schoolName=s.name;this.adapters=s.adapters;if(s.adapters.length===1)this.select(s.adapters[0]);}
  private select(a:SchoolAdapter):void {this.selected=a;this.url=a.url;this.error='';if(a.url)this.open();}
  private open():void {
    try{const url=schoolUrl(this.url);this.stop();this.error='';this.failedUrl='';this.ready=false;if(this.page){this.web.loadUrl(url);}else{this.page=url;}this.url=url;}
    catch(e){this.error=(e as Error).message;}
  }
  private stop():void {
    if(this.timer>=0)clearTimeout(this.timer);this.timer=-1;this.busy=false;this.request=undefined;this.token='';
    if(this.page)this.web.runJavaScript('if(window.__fridgeSchool)window.__fridgeSchool.cancel();').catch(()=>{});
  }
  private back():void {if(this.busy)return;try{if(this.web.accessBackward())this.web.backward();}catch(_) {}}
  private async run():Promise<void> {
    if(this.busy||!this.selected||!this.ready)return;
    this.busy=true;this.error='';this.elapsed=0;const token='read_'+Date.now();this.token=token;
    try{
      const rm=this.getUIContext().getHostContext()!.resourceManager;
      const bridge=await rm.getRawFileContent('school-bridge.js'),script=await rm.getRawFileContent(this.selected.script);
      if(!this.alive||this.token!==token)return;
      const decoder=new util.TextDecoder();
      const source=decoder.decodeToString(script);
      const names=(source.match(/\b(?:validate|validator)[A-Za-z0-9_]+/g)??[]).filter((v,i,arr)=>arr.indexOf(v)===i);
      const register=names.map((v)=>'if(typeof '+v+'==="function")window.__fridgeSchool.validators['+JSON.stringify(v)+']='+v+';').join('');
      await this.web.runJavaScript(decoder.decodeToString(bridge).replace('__TOKEN__',JSON.stringify(token))+'\n(function(){\nconst console={log(){},info(){},warn(){},error(){},debug(){}};\n'+source+'\n'+register+'\n})();');
      if(this.alive&&this.token===token)this.poll(token);
    }catch(_){if(this.alive&&this.token===token){this.stop();this.error='未能启动教务读取，请刷新页面后重试';}}
  }
  private async poll(token:string):Promise<void> {
    if(!this.alive||this.token!==token)return;
    try {
      const data=schoolSnapshot(await this.web.runJavaScript('window.__fridgeSchool?window.__fridgeSchool.snapshot():JSON.stringify({token:""})'));
      if(!this.alive||this.token!==token)return;
      if(data.token!==token)throw new Error('页面已跳转，请在个人课表页重新读取');
      if(data.error)throw new Error(data.error);
      if(data.done){const parsed=await taskpool.execute(new taskpool.Task(parseSchoolText,JSON.stringify(data),this.schoolName)) as string;if(!this.alive||this.token!==token)return;this.stop();this.onRead(parsed);this.controller.close();return;}
      if(data.request){if(this.request?.id!==data.request.id){this.request=data.request;this.input=data.request.value;}return;}
      if(data.message)this.message=data.message;
      if(++this.elapsed>360)throw new Error('读取超时，请确认已登录并打开个人课表；部分学校需要校园网');
      this.timer=setTimeout(()=>this.poll(token),250);
    }catch(e){if(this.alive&&this.token===token){this.stop();this.error=(e as Error).message;}}
  }
  private async reply(value:string|number|boolean):Promise<void> {
    if(!this.request)return;const token=this.token,id=this.request.id;
    try {const result=webString(await this.web.runJavaScript('window.__fridgeSchool.reply('+id+','+JSON.stringify(value)+')'));
      if(!this.alive||this.token!==token)return;if(result){this.error=result;return;}this.request=undefined;this.error='';this.poll(token);
    }catch(_){if(this.alive){this.stop();this.error='选择已失效，请重新读取';}}
  }
  @Builder
  action(label:string,run:()=>void,enabled:boolean=true) {
    Button(label,{type:ButtonType.Capsule, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL}).height(44).fontSize(14).fontColor(AppDesign.text(this.appDark)).backgroundColor(AppDesign.control(this.appDark)).enabled(enabled).onClick(run)
  }
  build() {
    Column({space:12}) {
      Row({space:10}) {
        this.action('关闭',()=>{this.stop();this.controller.close();})
        Text(this.schoolName||'从学校教务导入').fontSize(18).fontWeight(FontWeight.Medium).fontColor(AppDesign.text(this.appDark)).maxLines(1).textOverflow({overflow:TextOverflow.Ellipsis}).layoutWeight(1)
        if(this.page||this.selected||this.adapters.length>1){this.action('换学校',()=>this.resetSchool(),!this.busy)}
      }.width('100%')
      if(!this.page) {
        if(!this.selected) {
          TextInput({text:this.query,placeholder:'搜索学校全名或简称'}).height(44).borderRadius(12).backgroundColor(AppDesign.control(this.appDark)).fontColor(AppDesign.text(this.appDark)).placeholderColor(AppDesign.muted(this.appDark)).onChange((v:string)=>this.search(v))
          Text('学校专用适配与通用教务都可选择；未收录的学校可用通用教务并输入网址。').fontSize(12).fontColor(AppDesign.muted(this.appDark)).width('100%')
          if(this.adapters.length>1){
            ForEach(this.adapters,(a:SchoolAdapter)=>{this.action(a.name,()=>this.select(a))},(a:SchoolAdapter)=>a.id)
          }else{
            List({space:8}) {
              ForEach(this.visible,(s:ImportSchool)=>{ListItem(){
                Button({type:ButtonType.ROUNDED_RECTANGLE, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL}){Row(){Text(s.name).maxLines(1).textOverflow({overflow:TextOverflow.Ellipsis}).fontSize(15).fontColor(AppDesign.text(this.appDark)).layoutWeight(1).textAlign(TextAlign.Start);Text(s.id).fontSize(12).fontColor(AppDesign.muted(this.appDark))}.padding(14).width('100%')}.width('100%').backgroundColor(AppDesign.control(this.appDark)).onClick(()=>this.choose(s))
              }},(s:ImportSchool)=>s.id)
            }.width('100%').layoutWeight(1).scrollBar(BarState.Off)
            if(this.visible.length===this.limit){this.action('显示更多学校',()=>this.more())}
            if(!this.visible.length){Text('目录中没有匹配项，可选择通用教务并输入学校网址。').fontColor(AppDesign.muted(this.appDark)).fontSize(13)}
            Flex({wrap:FlexWrap.Wrap}) {
              ForEach(['qiangzhi_general','zhengfang_jiaowu','urp_jiaowu','qingguo_jiaowu','chaoxing_jiaowu'],(id:string,i:number)=>{
                Button(['强智','正方','URP','青果','超星'][i],{type:ButtonType.Capsule, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL}).height(44).fontSize(14).fontColor(AppDesign.text(this.appDark)).backgroundColor(AppDesign.control(this.appDark)).margin({right:8,bottom:8}).onClick(()=>this.choose(this.schools.find((s)=>s.id===id)))
              },(id:string)=>id)
            }.width('100%')
          }
        }else{
          Text(this.display(this.selected.description)).fontSize(14).fontColor(AppDesign.muted(this.appDark)).width('100%')
          TextInput({text:this.url,placeholder:'学校教务网址 https://…'}).height(48).borderRadius(12).backgroundColor(AppDesign.control(this.appDark)).fontColor(AppDesign.text(this.appDark)).placeholderColor(AppDesign.muted(this.appDark)).onChange((v:string)=>this.url=v)
          this.action('打开教务',()=>this.open())
          Blank()
        }
      }else{
        Row({space:8}) {this.action('返回',()=>this.back(),!this.busy);TextInput({text:this.url,placeholder:'教务网址'}).height(44).borderRadius(12).layoutWeight(1).backgroundColor(AppDesign.control(this.appDark)).fontColor(AppDesign.text(this.appDark)).placeholderColor(AppDesign.muted(this.appDark)).enabled(!this.busy).onChange((v:string)=>this.url=v);this.action('打开',()=>this.open(),!this.busy)}.width('100%')
        if(this.frames.length){this.action(this.showFrames?'收起子页面':'打开课表子页面',()=>this.showFrames=!this.showFrames,!this.busy)}
        if(this.showFrames){Scroll(){Column({space:8}){ForEach(this.frames,(url:string)=>{this.action(url,()=>this.frame(url))},(url:string)=>url)}.width('100%')}.height(120).width('100%')}
        Text(this.display(this.message)).fontSize(12).maxLines(2).fontColor(AppDesign.muted(this.appDark)).width('100%')
        if(this.progress<100){Progress({value:this.progress,total:100,type:ProgressType.Linear}).width('100%').height(2)}
        Stack({alignContent:Alignment.Center}) {
          Web({src:this.page,controller:this.web,incognitoMode:true}).javaScriptAccess(true).domStorageAccess(true).zoomAccess(true).fileAccess(false)
            .onPageBegin(()=>{this.ready=false;this.failedUrl='';if(this.busy){this.stop();this.error='页面已跳转，请在个人课表页重新读取';}})
            .onPageEnd((e)=>this.pageReady(e?.url??this.url))
            .onErrorReceive((e)=>{if(e?.request.isMainFrame()){this.failedUrl=e.request.getRequestUrl();this.ready=false;this.error='教务网页未能加载，请检查网络、校园网或网址后重试';}})
            .onHttpErrorReceive((e)=>{if(e?.request.isMainFrame()){this.failedUrl=e.request.getRequestUrl();this.ready=false;this.error='教务网站暂时不可用，可检查网址、切换校园网后重新打开';}})
            .onProgressChange((e)=>{this.progress=e?.newProgress??0;})
            .onLoadIntercept((e)=>{const url=e?.data.getRequestUrl()??'';return !/^https?:\/\//i.test(url)&&url!=='about:blank';})
            .width('100%').height('100%')
          if(this.request){
            Column({space:12}) {
              Text(this.display(this.request.title)).fontSize(18).fontColor(AppDesign.text(this.appDark)).width('100%')
              Scroll(){Text(this.display(this.request.content)).fontSize(13).fontColor(AppDesign.muted(this.appDark)).width('100%')}.constraintSize({maxHeight:140}).width('100%').scrollBar(BarState.Off)
              if(this.request.kind==='prompt'){TextInput({text:this.input}).onChange((v:string)=>this.input=v).borderRadius(12).backgroundColor(AppDesign.control(this.appDark)).fontColor(AppDesign.text(this.appDark)).placeholderColor(AppDesign.muted(this.appDark))}
              if(this.request.kind==='select'){
                Scroll(){Column({space:8}){ForEach(this.request.items,(v:string,i:number)=>{this.action(v,()=>this.reply(i))},(v:string,i:number)=>String(i))}.width('100%')}.constraintSize({maxHeight:200}).width('100%')
              }else{Row({space:10}){this.action('取消',()=>this.stop());this.action(this.request.kind==='prompt'?'确定':(this.request.value||'继续'),()=>this.reply(this.request?.kind==='prompt'?this.input:true))}}
            }.padding(20).width('90%').constraintSize({maxWidth:480}).borderRadius(20).backgroundColor(AppDesign.surface(this.appDark))
          }
        }.width('100%').layoutWeight(1).borderRadius(16).clip(true)
        Row({space:10}){if(this.busy){this.action('取消读取',()=>this.stop());}Button(this.busy?'正在读取':'读取当前课表',{type:ButtonType.Capsule, buttonStyle:ButtonStyleMode.EMPHASIZED, role:ButtonRole.NORMAL}).height(44).layoutWeight(1).fontSize(15).backgroundColor(AppDesign.selected(this.appDark)).fontColor(AppDesign.onSelected(this.appDark)).enabled(!this.busy&&this.ready).onClick(()=>this.run())}.width('100%')
      }
      if(this.error){Text(this.error).fontSize(12).fontColor('#B34735').width('100%').maxLines(3)}
      Text('登录仅在学校网页内进行；读取后的课程在本机预览，确认才保存。').fontSize(11).fontColor(AppDesign.muted(this.appDark)).width('100%')
    }.padding(16).width('96%').height('90%').constraintSize({maxWidth:1000}).borderRadius(24).backgroundColor(AppDesign.surface(this.appDark))
  }
}
