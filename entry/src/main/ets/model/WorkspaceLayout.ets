/** Available-space layout, independent of phone/tablet names and orientation flags. */
export class WorkspaceLayout {
  margin:number=16; wide:boolean=false; floating:boolean=false;
  expandedBoardY:number=16;
  boardX:number=16;boardY:number=16;boardW:number=320;boardH:number=320;
  panelX:number=16;panelY:number=352;panelW:number=320;panelH:number=300;
  previewW:number=320;previewH:number=200;layersH:number=64;inspectorW:number=320;
}
export function workspaceLayout(width:number,height:number,top:number,bottom:number,aspect:number):WorkspaceLayout {
  const out=new WorkspaceLayout();out.margin=width<360?12:width>=720?24:16;
  const m=out.margin,usableW=Math.max(160,width-2*m),usableH=Math.max(180,height-top-bottom-2*m),ratio=Math.max(.3,Math.min(3,aspect));
  // Side-by-side needs horizontal space AND a wide window. Portrait tablets stay stacked.
  out.wide=width>=640&&usableH>=220&&usableW>=usableH*1.1;
  out.floating=Math.min(width,height)<600;
  const homeWide=out.wide;
  out.panelW=homeWide?Math.min(420,Math.max(300,width*.34)):usableW;
  const stageW=homeWide?Math.max(120,width-out.panelW-3*m):usableW;
  const reserve=out.floating?88:homeWide?0:Math.min(320,Math.max(248,usableH*.28));
  out.boardW=Math.min(stageW,Math.max(96,usableH-reserve-12)*ratio);out.boardH=out.boardW/ratio;
  out.boardX=m+(stageW-out.boardW)/2;out.boardY=top+m;out.expandedBoardY=out.boardY;
  if(out.floating){out.boardW=Math.min(usableW,Math.max(96,usableH-88)*ratio);out.boardH=out.boardW/ratio;out.boardX=m+(usableW-out.boardW)/2;out.boardY=top+m+Math.max(0,(usableH-88-out.boardH)/2);}
  out.panelX=homeWide?width-m-out.panelW:m;out.panelY=homeWide?out.boardY:out.boardY+out.boardH+12;
  out.panelH=Math.max(128,height-bottom-m-out.panelY);
  if(out.floating){out.panelW=Math.min(360,width-32);out.panelX=(width-out.panelW)/2;out.panelY=height-bottom-68;out.panelH=52;}
  const body=Math.max(120,height-top-bottom-76);
  out.previewW=out.wide?width-Math.min(400,Math.max(300,width*.4)):width;
  out.layersH=64;
  const stackedPreview=width>=600?Math.min(520,body*.42,width*.72):Math.min(220,body*.27);
  out.previewH=out.wide?Math.max(80,body-96):Math.max(100,Math.min(stackedPreview,body-64-12-56-180));
  out.inspectorW=out.wide?width-out.previewW:width;return out;
}
