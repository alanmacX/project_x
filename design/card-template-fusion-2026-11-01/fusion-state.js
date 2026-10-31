/* Study-only state. Does not change native schema or write app data. */
(function(root){
 const initial=()=>({mode:'solo',canvasId:'study_canvas',cards:[{id:'study_clock',capability:{k:'clock',zone:'Asia/Shanghai'},design:{id:'photo-clock',version:1,revision:1,presentation:'photo',params:{depth:true,palette:'sage',subject:'pipi',scale:100,offset:0}}}]});
 function update(state,action,value){const next=structuredClone(state),clock=next.cards.find(c=>c.id==='study_clock');
  if(action==='mode')next.mode=value==='ensemble'?'ensemble':'solo';
  else if(action==='surface')clock.design.presentation=value==='bare'?'bare':'photo';
  else if(action==='depth')clock.design.params.depth=!!value;
  else if(action==='palette'&&['sage','lilac','sand'].includes(value))clock.design.params.palette=value;
  else if(action==='subject'&&['pipi','tabby'].includes(value))clock.design.params.subject=value;
  else if(action==='scale')clock.design.params.scale=Math.max(82,Math.min(106,Number(value)||100));
  else if(action==='offset')clock.design.params.offset=Math.max(-14,Math.min(14,Number(value)||0));
  else if(action==='add'&&['agenda','note'].includes(value)){next.mode='ensemble';if(!next.cards.some(c=>c.id==='study_'+value))next.cards.push({id:'study_'+value,capability:value==='agenda'?{k:'agenda',agendaSource:'imported',events:[]}:null,elements:value==='note'?[{kind:'text',text:'周末去看海'}]:[]});}
  else if(action==='remove')next.cards=next.cards.filter(c=>c.id==='study_clock'||c.id!=='study_'+value);
  else if(action==='reset')clock.design=initial().cards[0].design;
  return next;
 }
 root.FusionStudy={initial,update};
 if(typeof module!=='undefined')module.exports=root.FusionStudy;
})(globalThis);
