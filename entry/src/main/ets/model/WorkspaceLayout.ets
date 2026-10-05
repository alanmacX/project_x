/** Available-space layout, independent of phone/tablet names and orientation flags. */
export class WorkspaceLayout {
  margin:number=16; wide:boolean=false;
  boardX:number=16;boardY:number=16;boardW:number=320;boardH:number=320;
  panelX:number=16;panelY:number=352;panelW:number=320;panelH:number=300;
  previewW:number=320;previewH:number=200;layersH:number=64;inspectorW:number=320;
}
export function workspaceLayout(width:number,height:number,top:number,bottom:number,aspect:number):WorkspaceLayout {
  const out=new WorkspaceLayout();out.margin=width<360?12:width>=720?24:16;
  const m=out.margin,usableW=Math.max(160,width-2*m),usableH=Math.max(180,height-top-bottom-2*m),ratio=Math.max(.3,Math.min(3,aspect));
  out.wide=width>=640&&usableH>=220;
  const homeWide=out.wide;
  out.panelW=homeWide?Math.min(420,Math.max(300,width*.34)):usableW;
  const stageW=homeWide?Math.max(120,width-out.panelW-3*m):usableW;
  const reserve=homeWide?0:Math.min(360,Math.max(248,usableH*.42));
  out.boardW=Math.min(stageW,Math.max(96,usableH-reserve-12)*ratio);out.boardH=out.boardW/ratio;
  out.boardX=m+(stageW-out.boardW)/2;out.boardY=top+m;
  out.panelX=homeWide?width-m-out.panelW:m;out.panelY=homeWide?out.boardY:out.boardY+out.boardH+12;
  out.panelH=Math.max(128,height-bottom-m-out.panelY);
  const body=Math.max(120,height-top-bottom-76);
  out.previewW=out.wide?width-Math.min(400,Math.max(300,width*.4)):width;
  out.layersH=64;out.previewH=out.wide?Math.max(80,body-96):Math.min(220,Math.max(100,body*.27));
  out.inspectorW=out.wide?width-out.previewW:width;return out;
}
