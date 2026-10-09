/** Approved stone recipe, baked offline. Eight tiles leave the center truly transparent. */
@Component
export struct CanvasFrame {
  @Prop square:boolean=false;
  @Prop style:string='auto';
  @Prop material:string='stone';
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
  corner(index:number,id:string,rules:AlignRuleOption){
    Image(this.tiles()[index]).id(id).width('8%').aspectRatio(1).alignRules(rules)
      .objectFit(ImageFit.Fill).draggable(false).hitTestBehavior(HitTestMode.None)
  }
  @Builder
  strip(index:number,rules:AlignRuleOption){
    Image(this.tiles()[index]).alignRules(rules)
      .objectFit(ImageFit.Fill).draggable(false).hitTestBehavior(HitTestMode.None)
  }
  build(){
    // The native layout solver owns all eight rectangles in the same pass.
    // Corner width is 48/600 of the current container; aspectRatio makes it square.
    // Strips bind to corner edges, so no cached size, callback, flex or grid grammar
    // can move a perimeter edge away from the live container.
    RelativeContainer(){
      if(this.style!=='none'){
        this.corner(0,'frameTL',{left:{anchor:'__container__',align:HorizontalAlign.Start},top:{anchor:'__container__',align:VerticalAlign.Top}})
        this.corner(2,'frameTR',{right:{anchor:'__container__',align:HorizontalAlign.End},top:{anchor:'__container__',align:VerticalAlign.Top}})
        this.corner(5,'frameBL',{left:{anchor:'__container__',align:HorizontalAlign.Start},bottom:{anchor:'__container__',align:VerticalAlign.Bottom}})
        this.corner(7,'frameBR',{right:{anchor:'__container__',align:HorizontalAlign.End},bottom:{anchor:'__container__',align:VerticalAlign.Bottom}})
        this.strip(1,{left:{anchor:'frameTL',align:HorizontalAlign.End},right:{anchor:'frameTR',align:HorizontalAlign.Start},top:{anchor:'frameTL',align:VerticalAlign.Top},bottom:{anchor:'frameTL',align:VerticalAlign.Bottom}})
        this.strip(6,{left:{anchor:'frameBL',align:HorizontalAlign.End},right:{anchor:'frameBR',align:HorizontalAlign.Start},top:{anchor:'frameBL',align:VerticalAlign.Top},bottom:{anchor:'frameBL',align:VerticalAlign.Bottom}})
        this.strip(3,{left:{anchor:'frameTL',align:HorizontalAlign.Start},right:{anchor:'frameTL',align:HorizontalAlign.End},top:{anchor:'frameTL',align:VerticalAlign.Bottom},bottom:{anchor:'frameBL',align:VerticalAlign.Top}})
        this.strip(4,{left:{anchor:'frameTR',align:HorizontalAlign.Start},right:{anchor:'frameTR',align:HorizontalAlign.End},top:{anchor:'frameTR',align:VerticalAlign.Bottom},bottom:{anchor:'frameBR',align:VerticalAlign.Top}})
      }
    }.width('100%').height('100%').hitTestBehavior(HitTestMode.None)
  }
}
