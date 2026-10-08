/** Embedded inspector: no modal mask; preview and vertical layers share one stage. */
export class EditorWorkspace {
  wide:boolean=false;body:number=400;stageW:number=320;stageH:number=190;
  layersW:number=104;previewW:number=216;panelW:number=320;panelH:number=210;
}
export function editorWorkspace(w:number,h:number,top:number,bottom:number):EditorWorkspace {
  const v=new EditorWorkspace();v.body=Math.max(120,h-top-bottom-60);
  v.wide=w>=640&&w>=h*1.1;
  v.stageW=v.wide?Math.max(280,Math.min(w*.48,w-320)):w;
  v.stageH=v.wide?v.body:Math.max(48,v.body*.60);
  v.layersW=w<360?92:104;v.previewW=v.stageW-v.layersW-12;
  v.panelW=v.wide?w-v.stageW:w;v.panelH=v.wide?v.body:v.body-v.stageH;
  return v;
}
