// Bundled adapters only receive a local preview bridge, never native file/network APIs.
(function(token){
  'use strict';
  const previous=window.__fridgeSchool;
  if(previous && previous.cancel)previous.cancel();
  const state={token,courses:[],slots:[],config:{},done:false,error:'',message:'',requests:[]};
  state.validators={};
  const pending=new Map();let next=0,alive=true;
  const ensure=()=>{if(!alive)throw Error('导入已结束');};
  const bounded=(json,max)=>{ensure();if(typeof json!=='string'||json.length>524288)throw Error('课程数据过大');const v=JSON.parse(json);if(max&&(!Array.isArray(v)||v.length>max))throw Error('课程数据条目过多');return v;};
  const ask=(kind,title,content,value,validator)=>new Promise((resolve,reject)=>{
    ensure();if(state.requests.length>=4)return reject(Error('请求过多'));
    const id=++next;pending.set(id,{resolve,reject,validator});
    state.requests.push({id,kind,title:String(title||'').slice(0,100),content:String(content||'').slice(0,4000),value:String(value??'').slice(0,200),items:[]});
  });
  const bridge={
    showToast(v){if(alive){state.message=String(v).slice(0,200);if(/失败|尚未登录|未检测到|未找到|无法|未能|取消/.test(state.message))state.error=state.message;}},
    notifyTaskCompletion(){ensure();state.done=true;}
  };
  const promise={
    showAlert(t,c,v){return ask('alert',t,c,v);},
    showConfirmDialog(t,c){return ask('confirm',t,c,'');},
    showPrompt(t,c,v,validator){return ask('prompt',t,c,v,validator);},
    showSingleSelection(t,json,index){
      const items=bounded(json,100);const p=ask('select',t,'',index);
      state.requests[state.requests.length-1].items=items.map(x=>String(x).slice(0,200));return p;
    },
    async saveImportedCourses(v){state.courses=bounded(v,128);return true;},
    async savePresetTimeSlots(v){state.slots=bounded(v,24);return true;},
    async saveCourseConfig(v){state.config=bounded(v,0);return true;}
  };
  state.reply=(id,value)=>{
    ensure();const p=pending.get(id);if(!p)return '请求已失效';
    if(typeof p.validator==='string'&&typeof state.validators[p.validator]==='function'){
      const error=state.validators[p.validator](value);if(error)return String(error).slice(0,200);
    }
    pending.delete(id);state.requests=state.requests.filter(r=>r.id!==id);p.resolve(value);return '';
  };
  const failure=e=>{if(alive)state.error='教务读取未完成，请确认已登录并打开个人课表，再重试。';};
  window.addEventListener('unhandledrejection',failure);
  state.cancel=()=>{alive=false;window.removeEventListener('unhandledrejection',failure);for(const p of pending.values())p.reject(Error('取消'));pending.clear();state.requests=[];};
  state.snapshot=()=>JSON.stringify({token,courses:state.done?state.courses:[],slots:state.done?state.slots:[],config:state.done?state.config:{},done:state.done,error:state.error,message:state.message,request:state.requests[0]||null});
  window.__fridgeSchool=state;
  window.AndroidBridge=window.shiguangBridge=bridge;
  window.AndroidBridgePromise=window.shiguangBridgePromise=promise;
})(__TOKEN__);
