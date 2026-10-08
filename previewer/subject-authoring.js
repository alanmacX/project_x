/* Offline alpha inspection; preserves original image bytes and coordinate space. */
(function(global){
 'use strict';
 function analyzeRGBA(rgba,width,height){
  if(!Number.isInteger(width)||!Number.isInteger(height)||width<4||height<4||width*height>4194304||rgba.length!==width*height*4)throw Error('素材尺寸无效或超过 4MP，请先准备较小源图');
  if(Math.max(width,height)>1024)throw Error('请先将透明 PNG 等比缩小到长边 1024px 再提取轮廓；保留原始高清素材');
  const mask=new Int32Array(width*height);let solid=0,transparent=0,x0=width,y0=height,x1=-1,y1=-1;
  for(let y=0;y<height;y++)for(let x=0;x<width;x++){const a=rgba[(y*width+x)*4+3];mask[y*width+x]=a;if(a>=128)solid++;if(a<16)transparent++;if(a>=16){x0=Math.min(x0,x);y0=Math.min(y0,y);x1=Math.max(x1,x);y1=Math.max(y1,y);}}
  if(!solid)throw Error('素材没有可用的主体');if(!transparent)throw Error('图片没有透明背景；请先真正抠图，不可用矩形冒充主体');
  // Reject pathological noise before allocating the production tracer's edge graph.
  let edges=0;for(let y=0;y<height;y++)for(let x=0;x<width;x++)if(mask[y*width+x]>=128){if(y===0||mask[(y-1)*width+x]<128)edges++;if(y===height-1||mask[(y+1)*width+x]<128)edges++;if(x===0||mask[y*width+x-1]<128)edges++;if(x===width-1||mask[y*width+x+1]<128)edges++;if(edges>65536)throw Error('透明边缘碎片过多，请先整理素材后重试');}
  const outline=FridgeCore.load('SubjectGeometry').traceMask(mask,width,height),points=outline.reduce((sum,loop)=>sum+loop.length,0);
  if(!outline.length||points<3)throw Error('未能提取有效轮廓，请检查透明素材并重新准备工作图');
  if(outline.length>128||points>16384)throw Error('轮廓超过作品包上限，请整理素材的孤立碎片后重试');
  const contentBounds={x:x0/width,y:y0/height,w:(x1-x0+1)/width,h:(y1-y0+1)/height},warnings=[];
  if(contentBounds.w<.8||contentBounds.h<.8)warnings.push('透明留白偏大：先裁紧源图，再重新提取；不要只改轮廓坐标');
  if(outline.length>12)warnings.push('孤立部件或孔洞较多，检查是否有误抠碎片；不要一律删掉真实部件');
  if(solid/(width*height)<.1)warnings.push('主体较细或较小，检查目标尺寸下白边和能力是否挤占形状');
  return {outline,subjectAspect:width/height,contentBounds,points,loops:outline.length,coverage:solid/(width*height),warnings};
 }
 global.FridgeSubjectAuthoring={analyzeRGBA};
})(globalThis);
