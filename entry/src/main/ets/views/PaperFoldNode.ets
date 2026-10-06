import { image } from '@kit.ImageKit';
import { drawing, common2D } from '@kit.ArkGraphics2D';
import { NodeController, FrameNode, RenderNode, DrawContext, UIContext, AnimatorResult } from '@kit.ArkUI';
import { motionFrameRate } from '../model/MotionPolicy';
import { PaperFoldMesh } from '../model/PaperFoldMesh';

class PaperRenderNode extends RenderNode {
  private mesh:PaperFoldMesh;
  private brush:drawing.Brush=new drawing.Brush();
  private positions:common2D.Point[]=[];
  private texs:common2D.Point[]=[];
  private colors:number[]=[];
  private textureW:number;private textureH:number;
  active:boolean=true;
  constructor(bitmap:image.PixelMap,width:number,height:number,diameter:number) {
    super();this.mesh=new PaperFoldMesh(width,height,diameter);
    const info=bitmap.getImageInfoSync();this.textureW=info.size.width;this.textureH=info.size.height;
    this.brush.setAntiAlias(true);
    this.brush.setShaderEffect(drawing.ShaderEffect.createImageShader(bitmap,drawing.TileMode.CLAMP,drawing.TileMode.CLAMP,new drawing.SamplingOptions(drawing.FilterMode.FILTER_MODE_LINEAR)));
    for(let i=0;i<this.mesh.triangles.length*3;i++){this.positions.push({x:0,y:0});this.texs.push({x:0,y:0});this.colors.push(0xffffffff);}
    this.sample(0);
  }
  sample(progress:number):void {
    if(!this.active)return;
    this.mesh.update(progress);let index=0;
    for(const face of this.mesh.triangles) {
      const tone=Math.round(face.shade*255),color=(0xff000000|(tone<<16)|(tone<<8)|tone)>>>0;
      for(let corner=0;corner<3;corner++) {
        const point=this.mesh.vertices[corner===0?face.a:corner===1?face.b:face.c];
        this.positions[index].x=point.px;this.positions[index].y=point.py;
        this.texs[index].x=(point.u+1)*.5*this.textureW;this.texs[index].y=(point.v+1)*.5*this.textureH;
        this.colors[index]=color;index++;
      }
    }
    this.invalidate();
  }
  draw(context:DrawContext):void {
    if(!this.active)return;
    context.canvas.attachBrush(this.brush);
    context.canvas.drawVertices(drawing.VertexMode.TRIANGLES_VERTEXMODE,this.positions.length,this.positions,this.texs,this.colors,0,null,drawing.BlendMode.MODULATE);
    context.canvas.detachBrush();
  }
  stop():void {this.active=false;this.brush.setShaderEffect(null);}
}

/** Frame updates invalidate one render node; they never rebuild the ArkUI page or run layout. */
export class PaperFoldController extends NodeController {
  private node:PaperRenderNode|null=null;
  private frame:FrameNode|null=null;
  private animator:AnimatorResult|null=null;
  private bitmap:image.PixelMap|undefined=undefined;
  private width:number=0;private height:number=0;private density:number=1;
  configure(bitmap:image.PixelMap|undefined,width:number,height:number,density:number):void {this.bitmap=bitmap;this.width=width;this.height=height;this.density=density;}
  makeNode(context:UIContext):FrameNode|null {
    if(!this.bitmap)return null;
    this.frame=new FrameNode(context);
    this.node=new PaperRenderNode(this.bitmap,this.width*this.density,this.height*this.density,Math.min(44,Math.min(this.width,this.height)*.45)*this.density);
    this.node.frame={x:0,y:0,width:this.width,height:this.height};this.node.clipToFrame=false;
    const root=this.frame.getRenderNode();if(root){root.size={width:this.width,height:this.height};root.clipToFrame=false;root.appendChild(this.node);}return this.frame;
  }
  fold(context:UIContext,onDone:()=>void):void {
    if(!this.node){onDone();return;}
    this.animator=context.createAnimator({duration:360,easing:'linear',delay:0,fill:'forwards',direction:'normal',iterations:1,begin:0,end:1});
    this.animator.setExpectedFrameRateRange(motionFrameRate());
    this.animator.onFrame=(progress:number)=>this.node?.sample(progress);
    this.animator.onFinish=()=>{this.node?.sample(1);onDone();};this.animator.play();
  }
  stop():void {
    this.animator?.cancel();this.animator=null;this.node?.stop();this.node?.dispose();this.node=null;
    this.frame?.dispose();this.frame=null;this.bitmap=undefined;
  }
}
