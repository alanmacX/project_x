import { image } from '@kit.ImageKit';
import { fileIo } from '@kit.CoreFileKit';
import { photoFrame, PhotoFrame } from '../model/PhotoCropGeometry';
import { AppDesign } from '../model/AppDesign';
@CustomDialog
export struct PhotoCrop {
  controller?: CustomDialogController;
  source: string = '';
  aspect: number = 1;
  appDark: boolean = false;
  onApply: (zoom: number, x: number, y: number) => void = () => {};
  @State sourceW: number = 1;
  @State sourceH: number = 1;
  @State ready: boolean = false;
  @State zoom: number = 1;
  @State x: number = 0;
  @State y: number = 0;
  private startX: number = 0;
  private startY: number = 0;
  private startZoom: number = 1;
  private alive: boolean = true;
  aboutToAppear(): void { this.load(); }
  aboutToDisappear(): void { this.alive = false; }
  private async load(): Promise<void> {
    let file: fileIo.File | null = null; let src: image.ImageSource | null = null;
    try { file = await fileIo.open(this.source.slice(7), fileIo.OpenMode.READ_ONLY); src = image.createImageSource(file.fd); const info = await src.getImageInfo();
      if (this.alive) { this.sourceW = info.size.width; this.sourceH = info.size.height; this.ready = true; }
    } catch (_) { if (this.alive) this.getUIContext().getPromptAction().showToast({ message: '照片无法读取，请重新选择' }); } finally { if (src !== null) await src.release(); if (file !== null) fileIo.closeSync(file.fd); }
  }
  private frame(): PhotoFrame { return photoFrame(this.sourceW, this.sourceH, 280, 280 / this.aspect, this.zoom, this.x, this.y); }
  private clamp(): void { const f = this.frame(); this.x = f.left - (280 - f.width) / 2; this.y = f.top - (280 / this.aspect - f.height) / 2; }
  build() {
    Column({ space: 16 }) {
      Text('调整背景照片').fontSize(20).fontWeight(FontWeight.Medium).fontColor(AppDesign.text(this.appDark))
      Text('框内即桌面画布 · 拖动位置，双指缩放').fontSize(13).fontColor(AppDesign.muted(this.appDark))
      Stack({ alignContent: Alignment.TopStart }) {
        if (this.ready) { Image(this.source).width(this.frame().width).height(this.frame().height).objectFit(ImageFit.Fill).draggable(false).hitTestBehavior(HitTestMode.None).position({ x: this.frame().left, y: this.frame().top }) }
      }.width(280).height(280 / this.aspect).borderRadius(24).clip(true).backgroundColor(AppDesign.background(this.appDark)).border({ width: 1, color: AppDesign.border(this.appDark) })
        .gesture(GestureGroup(GestureMode.Parallel,
          PanGesture({ fingers: 1, distance: 2 }).onActionStart(() => { this.startX = this.x; this.startY = this.y; }).onActionUpdate((e: GestureEvent) => { this.x = this.startX + e.offsetX; this.y = this.startY + e.offsetY; this.clamp(); }),
          PinchGesture({ fingers: 2 }).onActionStart(() => { this.startZoom = this.zoom; }).onActionUpdate((e: GestureEvent) => { this.zoom = Math.max(1, Math.min(5, this.startZoom * e.scale)); this.clamp(); })
        ))
      Row({ space: 8 }) {
        Button('重置', { type: ButtonType.Capsule, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL }).height(44).fontColor(AppDesign.text(this.appDark)).backgroundColor(AppDesign.background(this.appDark)).onClick(() => { this.zoom = 1; this.x = 0; this.y = 0; })
        Button('取消', { type: ButtonType.Capsule, buttonStyle:ButtonStyleMode.NORMAL, role:ButtonRole.NORMAL }).height(44).fontColor(AppDesign.text(this.appDark)).backgroundColor(AppDesign.background(this.appDark)).onClick(() => this.controller?.close())
        Button('使用照片', { type: ButtonType.Capsule, buttonStyle:ButtonStyleMode.EMPHASIZED, role:ButtonRole.NORMAL }).height(44).backgroundColor(AppDesign.selected(this.appDark)).fontColor(AppDesign.onSelected(this.appDark)).enabled(this.ready).onClick(() => { this.onApply(this.zoom, this.x, this.y); this.controller?.close(); })
      }
    }.padding(20).width('94%').constraintSize({ maxWidth: 440 }).backgroundColor(AppDesign.surface(this.appDark)).borderRadius(28)
  }
}
