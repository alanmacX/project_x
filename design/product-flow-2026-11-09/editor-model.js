/* Prototype-only image treatment and cover constraints. Rendering stays in FridgeWeb. */
(function(root){
function coverPose(sourceAspect,canvasAspect,pose,region={x:0,y:0}){const zoom=Math.max(1,Math.min(4,Number(pose.zoom)||1));const h=300/canvasAspect,scale=Math.max(300/sourceAspect,h)*zoom;const maxX=Math.max(0,(scale*sourceAspect-300)/600),maxY=Math.max(0,(scale-h)/(2*h));return {zoom,photoFraming:'cover',offsetX:Math.max(-maxX-region.x/300,Math.min(maxX-region.x/300,Number(pose.offsetX)||0)),offsetY:Math.max(-maxY-region.y/h,Math.min(maxY-region.y/h,Number(pose.offsetY)||0))};}
function tintBackground(rgba,mask,tone){if(tone==='natural')return rgba;const colors={warm:[207,170,121],blue:[101,149,185],rose:[185,118,146]};for(let i=0;i<rgba.length;i+=4){const amount=1-mask[i+3]/255;if(!amount)continue;const lum=rgba[i]*.2126+rgba[i+1]*.7152+rgba[i+2]*.0722;for(let j=0;j<3;j++){const target=tone==='mono'?lum:lum*.48+colors[tone][j]*.52;rgba[i+j]=Math.round(rgba[i+j]*(1-amount)+target*amount);}}return rgba;}
root.DemoEditor={coverPose,tintBackground};if(typeof module!=='undefined')module.exports=root.DemoEditor;
})(globalThis);
