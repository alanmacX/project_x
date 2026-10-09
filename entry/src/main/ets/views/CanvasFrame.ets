/** Approved stone recipe, baked offline. Eight tiles leave the center truly transparent. */
@Component
export struct CanvasFrame {
  @Prop square:boolean=false;
  @Prop style:string='auto';
  @Prop material:string='stone';
  @Prop widthVp:number=0;
  @Prop heightVp:number=0;
  onFrameSize:(width:number,height:number)=>void=()=>{};
  @State measuredWidth:number=0;
  @State measuredHeight:number=0;
  private frameWidth():number{return this.widthVp>0?this.widthVp:this.measuredWidth;}
  private frameHeight():number{return this.heightVp>0?this.heightVp:this.measuredHeight;}
  private edge():number{return this.frameWidth()*48/600;}
  private tiles():Resource[]{
    if(this.material==='stone'&&this.style==='light'&&!this.square)return [$r('app.media.frame_stone_light_round_tl'),$r('app.media.frame_stone_light_round_top'),$r('app.media.frame_stone_light_round_tr'),$r('app.media.frame_stone_light_round_left'),$r('app.media.frame_stone_light_round_right'),$r('app.media.frame_stone_light_round_bl'),$r('app.media.frame_stone_light_round_bottom'),$r('app.media.frame_stone_light_round_br')];
    if(this.material==='stone'&&this.style==='light'&&this.square)return [$r('app.media.frame_stone_light_square_tl'),$r('app.media.frame_stone_light_square_top'),$r('app.media.frame_stone_light_square_tr'),$r('app.media.frame_stone_light_square_left'),$r('app.media.frame_stone_light_square_right'),$r('app.media.frame_stone_light_square_bl'),$r('app.media.frame_stone_light_square_bottom'),$r('app.media.frame_stone_light_square_br')];
    if(this.material==='stone'&&this.style==='dark'&&!this.square)return [$r('app.media.frame_stone_dark_round_tl'),$r('app.media.frame_stone_dark_round_top'),$r('app.media.frame_stone_dark_round_tr'),$r('app.media.frame_stone_dark_round_left'),$r('app.media.frame_stone_dark_round_right'),$r('app.media.frame_stone_dark_round_bl'),$r('app.media.frame_stone_dark_round_bottom'),$r('app.media.frame_stone_dark_round_br')];
    if(this.material==='stone'&&this.style==='dark'&&this.square)return [$r('app.media.frame_stone_dark_square_tl'),$r('app.media.frame_stone_dark_square_top'),$r('app.media.frame_stone_dark_square_tr'),$r('app.media.frame_stone_dark_square_left'),$r('app.media.frame_stone_dark_square_right'),$r('app.media.frame_stone_dark_square_bl'),$r('app.media.frame_stone_dark_square_bottom'),$r('app.media.frame_stone_dark_square_br')];
    if(this.material==='stone'&&this.style==='auto'&&!this.square)return [$r('app.media.frame_stone_auto_round_tl'),$r('app.media.frame_stone_auto_round_top'),$r('app.media.frame_stone_auto_round_tr'),$r('app.media.frame_stone_auto_round_left'),$r('app.media.frame_stone_auto_round_right'),$r('app.media.frame_stone_auto_round_bl'),$r('app.media.frame_stone_auto_round_bottom'),$r('app.media.frame_stone_auto_round_br')];
    if(this.material==='stone'&&this.style==='auto'&&this.square)return [$r('app.media.frame_stone_auto_square_tl'),$r('app.media.frame_stone_auto_square_top'),$r('app.media.frame_stone_auto_square_tr'),$r('app.media.frame_stone_auto_square_left'),$r('app.media.frame_stone_auto_square_right'),$r('app.media.frame_stone_auto_square_bl'),$r('app.media.frame_stone_auto_square_bottom'),$r('app.media.frame_stone_auto_square_br')];
    if(this.material==='walnut'&&this.style==='light'&&!this.square)return [$r('app.media.frame_walnut_light_round_tl'),$r('app.media.frame_walnut_light_round_top'),$r('app.media.frame_walnut_light_round_tr'),$r('app.media.frame_walnut_light_round_left'),$r('app.media.frame_walnut_light_round_right'),$r('app.media.frame_walnut_light_round_bl'),$r('app.media.frame_walnut_light_round_bottom'),$r('app.media.frame_walnut_light_round_br')];
    if(this.material==='walnut'&&this.style==='light'&&this.square)return [$r('app.media.frame_walnut_light_square_tl'),$r('app.media.frame_walnut_light_square_top'),$r('app.media.frame_walnut_light_square_tr'),$r('app.media.frame_walnut_light_square_left'),$r('app.media.frame_walnut_light_square_right'),$r('app.media.frame_walnut_light_square_bl'),$r('app.media.frame_walnut_light_square_bottom'),$r('app.media.frame_walnut_light_square_br')];
    if(this.material==='walnut'&&this.style==='dark'&&!this.square)return [$r('app.media.frame_walnut_dark_round_tl'),$r('app.media.frame_walnut_dark_round_top'),$r('app.media.frame_walnut_dark_round_tr'),$r('app.media.frame_walnut_dark_round_left'),$r('app.media.frame_walnut_dark_round_right'),$r('app.media.frame_walnut_dark_round_bl'),$r('app.media.frame_walnut_dark_round_bottom'),$r('app.media.frame_walnut_dark_round_br')];
    if(this.material==='walnut'&&this.style==='dark'&&this.square)return [$r('app.media.frame_walnut_dark_square_tl'),$r('app.media.frame_walnut_dark_square_top'),$r('app.media.frame_walnut_dark_square_tr'),$r('app.media.frame_walnut_dark_square_left'),$r('app.media.frame_walnut_dark_square_right'),$r('app.media.frame_walnut_dark_square_bl'),$r('app.media.frame_walnut_dark_square_bottom'),$r('app.media.frame_walnut_dark_square_br')];
    if(this.material==='walnut'&&this.style==='auto'&&!this.square)return [$r('app.media.frame_walnut_auto_round_tl'),$r('app.media.frame_walnut_auto_round_top'),$r('app.media.frame_walnut_auto_round_tr'),$r('app.media.frame_walnut_auto_round_left'),$r('app.media.frame_walnut_auto_round_right'),$r('app.media.frame_walnut_auto_round_bl'),$r('app.media.frame_walnut_auto_round_bottom'),$r('app.media.frame_walnut_auto_round_br')];
    if(this.material==='walnut'&&this.style==='auto'&&this.square)return [$r('app.media.frame_walnut_auto_square_tl'),$r('app.media.frame_walnut_auto_square_top'),$r('app.media.frame_walnut_auto_square_tr'),$r('app.media.frame_walnut_auto_square_left'),$r('app.media.frame_walnut_auto_square_right'),$r('app.media.frame_walnut_auto_square_bl'),$r('app.media.frame_walnut_auto_square_bottom'),$r('app.media.frame_walnut_auto_square_br')];
    if(this.material==='oak'&&this.style==='light'&&!this.square)return [$r('app.media.frame_oak_light_round_tl'),$r('app.media.frame_oak_light_round_top'),$r('app.media.frame_oak_light_round_tr'),$r('app.media.frame_oak_light_round_left'),$r('app.media.frame_oak_light_round_right'),$r('app.media.frame_oak_light_round_bl'),$r('app.media.frame_oak_light_round_bottom'),$r('app.media.frame_oak_light_round_br')];
    if(this.material==='oak'&&this.style==='light'&&this.square)return [$r('app.media.frame_oak_light_square_tl'),$r('app.media.frame_oak_light_square_top'),$r('app.media.frame_oak_light_square_tr'),$r('app.media.frame_oak_light_square_left'),$r('app.media.frame_oak_light_square_right'),$r('app.media.frame_oak_light_square_bl'),$r('app.media.frame_oak_light_square_bottom'),$r('app.media.frame_oak_light_square_br')];
    if(this.material==='oak'&&this.style==='dark'&&!this.square)return [$r('app.media.frame_oak_dark_round_tl'),$r('app.media.frame_oak_dark_round_top'),$r('app.media.frame_oak_dark_round_tr'),$r('app.media.frame_oak_dark_round_left'),$r('app.media.frame_oak_dark_round_right'),$r('app.media.frame_oak_dark_round_bl'),$r('app.media.frame_oak_dark_round_bottom'),$r('app.media.frame_oak_dark_round_br')];
    if(this.material==='oak'&&this.style==='dark'&&this.square)return [$r('app.media.frame_oak_dark_square_tl'),$r('app.media.frame_oak_dark_square_top'),$r('app.media.frame_oak_dark_square_tr'),$r('app.media.frame_oak_dark_square_left'),$r('app.media.frame_oak_dark_square_right'),$r('app.media.frame_oak_dark_square_bl'),$r('app.media.frame_oak_dark_square_bottom'),$r('app.media.frame_oak_dark_square_br')];
    if(this.material==='oak'&&this.style==='auto'&&!this.square)return [$r('app.media.frame_oak_auto_round_tl'),$r('app.media.frame_oak_auto_round_top'),$r('app.media.frame_oak_auto_round_tr'),$r('app.media.frame_oak_auto_round_left'),$r('app.media.frame_oak_auto_round_right'),$r('app.media.frame_oak_auto_round_bl'),$r('app.media.frame_oak_auto_round_bottom'),$r('app.media.frame_oak_auto_round_br')];
    if(this.material==='oak'&&this.style==='auto'&&this.square)return [$r('app.media.frame_oak_auto_square_tl'),$r('app.media.frame_oak_auto_square_top'),$r('app.media.frame_oak_auto_square_tr'),$r('app.media.frame_oak_auto_square_left'),$r('app.media.frame_oak_auto_square_right'),$r('app.media.frame_oak_auto_square_bl'),$r('app.media.frame_oak_auto_square_bottom'),$r('app.media.frame_oak_auto_square_br')];
    return [];
  }
  @Builder
  tile(index:number,w:Length,h:Length,x:Length,y:Length){
    Image(this.tiles()[index]).width(w).height(h).objectFit(ImageFit.Fill).draggable(false).position({x:x,y:y}).hitTestBehavior(HitTestMode.None)
  }
  build(){
    Stack(){
      if(this.style!=='none'&&this.edge()>0&&this.frameHeight()>0){
        this.tile(0,this.edge(),this.edge(),0,0)
        this.tile(1,this.frameWidth()-this.edge()*2,this.edge(),this.edge(),0)
        this.tile(2,this.edge(),this.edge(),this.frameWidth()-this.edge(),0)
        this.tile(3,this.edge(),this.frameHeight()-this.edge()*2,0,this.edge())
        this.tile(4,this.edge(),this.frameHeight()-this.edge()*2,this.frameWidth()-this.edge(),this.edge())
        this.tile(5,this.edge(),this.edge(),0,this.frameHeight()-this.edge())
        this.tile(6,this.frameWidth()-this.edge()*2,this.edge(),this.edge(),this.frameHeight()-this.edge())
        this.tile(7,this.edge(),this.edge(),this.frameWidth()-this.edge(),this.frameHeight()-this.edge())
      }
    }.width('100%').height('100%').hitTestBehavior(HitTestMode.None)
      .onAreaChange((_old:Area,size:Area)=>{
        const width=Number(size.width),height=Number(size.height);
        if(width>0&&height>0&&(Math.abs(width-this.measuredWidth)>.1||Math.abs(height-this.measuredHeight)>.1)){
          this.measuredWidth=width;this.measuredHeight=height;this.onFrameSize(width,height);
        }
      })
  }
}
