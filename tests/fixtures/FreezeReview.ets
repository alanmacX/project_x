import { repairSubject } from '../model/SubjectShape';
import { processSubjectPixels } from '../model/SubjectWorker';
import { FridgeStore, FridgeCard } from '../model/FridgeModel';
import { fileIo } from '@kit.CoreFileKit';
@Entry
@Component
struct FreezeReview {
  @State beats: number = 0;
  @State taps: number = 0;
  @State status: string = '准备';
  @State gap: number = 0;
  @State elapsed: number = 0;
  @State result: string = '';
  private timer: number = -1;
  async aboutToAppear(): Promise<void> {
    const context = this.getUIContext().getHostContext(); if (context === undefined) return;
    const store = new FridgeStore();
    const mode = AppStorage.get<string>('freezeMode');
    try {
      if (mode === 'cleanup') {
        await store.init(context); store.removeCard('v5_freeze_local'); await store.save();
        this.status = '测试卡片已清理'; return;
      }
      const bytes = await context.resourceManager.getRawFileContent('freeze-local.png');
      const path = context.filesDir + '/freeze_local.png';
      const file = await fileIo.open(path, fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE);
      try { await fileIo.write(file.fd, bytes.buffer); } finally { fileIo.closeSync(file.fd); }
      if (mode === 'seed') {
        await store.init(context); store.removeCard('v5_freeze_local');
        const card = new FridgeCard(); card.id = 'v5_freeze_local'; card.shape = 'subject'; card.cutout = 'file://' + path;
        card.subjectVersion = 0; card.subjectPhoto = true; card.w = 200; card.h = 150; card.x = 12; card.y = 20;
        card.outline = [[{ x: 0, y: 0 }, { x: 1, y: 0 }, { x: 1, y: 1 }, { x: 0, y: 1 }]];
        store.addCard(card); await store.save(); this.status = '旧卡片已保存'; return;
      }
      let previous = Date.now(); const start = previous;
      this.timer = setInterval(() => { const now = Date.now(); this.gap = Math.max(this.gap, now - previous); previous = now; this.beats++; }, 50);
      this.status = '后台处理';
      for (let i = 0; i < 3; i++) {
        const output = await repairSubject('file://' + path, context.filesDir);
        this.result = '裁切比例 ' + output.aspect.toFixed(3) + ' / 轮廓 ' + output.outline[0].length;
        await fileIo.unlink(output.src.slice(7));
      }
      const rgba = new Uint8Array(256 * 256 * 4), mask = new Int32Array(256 * 256);
      for (let y = 32; y < 224; y++) for (let x = 32; x < 224; x++) {
        const n = y * 256 + x; mask[n] = 255; rgba[n * 4] = 180; rgba[n * 4 + 1] = 118; rgba[n * 4 + 2] = 65; rgba[n * 4 + 3] = 255;
      }
      const pixels = await processSubjectPixels(rgba, mask, 256, 256, false);
      this.result += ' / 传输结果 ' + pixels.width + '×' + pixels.height;
      this.elapsed = Date.now() - start; clearInterval(this.timer); this.timer = -1; this.status = '后台任务通过';
    } catch (e) { this.status = '失败：' + (e as Error).message; if (this.timer >= 0) clearInterval(this.timer); }
  }
  aboutToDisappear(): void { if (this.timer >= 0) clearInterval(this.timer); }
  build() {
    Column({ space: 24 }) {
      Text(this.status).fontSize(24)
      Text('心跳 ' + this.beats + ' / 最大间隔 ' + this.gap + 'ms').fontSize(18)
      Text('总耗时 ' + this.elapsed + 'ms').fontSize(18)
      Text(this.result).fontSize(16)
      Button('响应 ' + this.taps).onClick(() => { this.taps++; })
    }.width('100%').height('100%').justifyContent(FlexAlign.Center).backgroundColor(Color.White)
  }
}
