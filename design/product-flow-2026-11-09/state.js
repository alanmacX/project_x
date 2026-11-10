/* Prototype-only state. No native app storage is read or written. */
(function(root){
  const clone=value=>JSON.parse(JSON.stringify(value));
  const uid=()=> 'demo-'+(globalThis.crypto?.randomUUID?.() || Date.now()+'-'+Math.random().toString(36).slice(2));
  function begin(work){return clone(work)}
  function save(db,draft){
    const next=clone(db),work=clone(draft);work.updatedAt=Date.now();
    const index=next.works.findIndex(w=>w.id===work.id);
    if(index<0)next.works.unshift(work);else next.works[index]=work;
    return next;
  }
  function bind(db,workId){
    if(!db.works.some(w=>w.id===workId))throw Error('Save a work before binding');
    const next=clone(db);next.bindings.push({id:uid(),workId,createdAt:Date.now()});return next;
  }
  function unbind(db,instanceId){const next=clone(db);next.bindings=next.bindings.filter(b=>b.id!==instanceId);return next}
  function duplicate(work){const next=clone(work);next.id=uid();next.name+=' · 副本';next.legacy=false;return next}
  function materialUsage(db,asset){
    const wanted=new Set([asset.original,asset.foreground,...(asset.aliases||[])].filter(Boolean));
    function contains(value){if(typeof value==='string')return wanted.has(value);if(!value||typeof value!=='object')return false;return Object.values(value).some(contains)}
    return db.works.filter(work=>contains(work.state));
  }
  function archiveMaterial(db,id){const next=clone(db),asset=next.materials.find(a=>a.id===id);if(!asset)throw Error('Unknown material');asset.archived=!asset.archived;return next}
  function updateMaterial(db,id,fields){const next=clone(db),asset=next.materials.find(a=>a.id===id);if(!asset)throw Error('Unknown material');for(const key of ['name','collection','kind','title','artist','favorite'])if(fields[key]!==undefined)asset[key]=fields[key];return next}
  function switchPhotoMode(work,mode){const next=clone(work),t=next.state.cards[0].template;next.photoPoses=next.photoPoses||{};next.photoPoses[t.photoMode||'subject']={zoom:t.zoom,offsetX:t.offsetX,offsetY:t.offsetY,photoFraming:t.photoFraming};Object.assign(t,next.photoPoses[mode]||{zoom:1,offsetX:0,offsetY:0,photoFraming:mode==='photo'?'cover':'fit'});t.photoMode=mode;return next}
  root.DemoState={clone,uid,begin,save,bind,unbind,duplicate,materialUsage,archiveMaterial,updateMaterial,switchPhotoMode};
  if(typeof module!=='undefined')module.exports=root.DemoState;
})(globalThis);
