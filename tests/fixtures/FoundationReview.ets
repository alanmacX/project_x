import { FridgeCard, typeLabel } from '../model/CardSchema';
import { ensureCapabilitySize, safeContentBox } from '../model/CanvasLayout';
import { repairSubject } from '../model/SubjectShape';
import { CardCanvas } from '../views/CardCanvas';
import { BoardCard } from '../views/BoardCard';
import { FridgeStore } from '../model/FridgeModel';
import { fileIo } from '@kit.CoreFileKit';
@Entry
@Component
struct FoundationReview {
  @StorageLink('reviewCap') cap: string = 'calendar';
  @State subject: FridgeCard = new FridgeCard();
  @State ready: boolean = false;
  @State error: string = '';
  async aboutToAppear(): Promise<void> {
    const context = this.getUIContext().getHostContext(); if (context === undefined) return;
    try {
      const bytes = await context.resourceManager.getRawFileContent('local-mask-stairs.png');
      const source = context.filesDir + '/review_local.png';
      const file = await fileIo.open(source, fileIo.OpenMode.CREATE | fileIo.OpenMode.READ_WRITE);
      try { await fileIo.write(file.fd, bytes.buffer); } finally { fileIo.closeSync(file.fd); }
      const result = await repairSubject('file://' + source, context.filesDir);
      const card = new FridgeCard(); card.shape = 'subject'; card.cutout = result.src; card.outline = result.outline;
      card.subjectVersion = 2; card.subjectInk = result.ink; card.subjectAspect = result.aspect; card.w = 200; card.h = 200 / result.aspect; card.capBox = safeContentBox(card);
      this.subject = card;
      if (this.cap === 'board') {
        const sample = JSON.parse(JSON.stringify(card)) as FridgeCard; sample.id = 'v4_local_foundation'; sample.subjectPhoto = true;
        sample.capability = { k: 'calendar' }; sample.capBox = safeContentBox(sample); ensureCapabilitySize(sample); sample.x = 12; sample.y = 20;
        const store = new FridgeStore(); await store.init(context); store.removeCard(sample.id); store.addCard(sample); await store.save();
        await this.getUIContext().getRouter().replaceUrl({ url: 'pages/Index' }); return;
      }
      this.ready = true;
    } catch (e) { this.error = (e as Error).message; }
  }
  private card(shape: string, photo: boolean = false): FridgeCard {
    const card = shape === 'subject' ? JSON.parse(JSON.stringify(this.subject)) as FridgeCard : new FridgeCard();
    card.id = shape + photo + this.cap; card.shape = shape; card.material = 'cream'; card.subjectPhoto = photo;
    card.capability = { k: this.cap, title: '下次旅行', date: '2026-10-20', city: '上海', temp: '23°', desc: '晴' };
    const aspect = card.w / card.h; card.w = 80; card.h = 80 / aspect;
    card.capBox = safeContentBox(card); ensureCapabilitySize(card); return card;
  }
  @Builder tile(shape: string, photo: boolean = false) {
    Column({ space: 8 }) {
      Text(shape + (shape === 'subject' ? (photo ? ' / 底图' : ' / 纯色') : '')).fontSize(12)
      Text(Math.ceil(this.card(shape, photo).w) + ' × ' + Math.ceil(this.card(shape, photo).h)).fontSize(10).fontColor('#666666')
      CardCanvas({ card: this.card(shape, photo), scaleFactor: 150 / this.card(shape, photo).w,
        tick: new Date(2026, 7, 31, 15, 42).getTime() })
        .width(150).height(150 * this.card(shape, photo).h / this.card(shape, photo).w)
        .shadow({ radius: 5, color: '#22000000', offsetY: 3 })
    }.width(150)
  }
  build() {
    Column({ space: 20 }) {
      Text(typeLabel(this.cap) + ' / foundation 检查').fontSize(19).margin({ top: 60 })
      if (this.ready) {
        Row({ space: 20 }) { this.tile('rect'); this.tile('blob'); }
        Row({ space: 20 }) { this.tile('round'); this.tile('pill'); }
        Row({ space: 20 }) { this.tile('subject'); this.tile('subject', true); }
        Text('本地蒙版测试 / 尺寸为实际最小值 / 图片按比例缩略\n台历固定六行月份；此页不代表系统分割成功').fontSize(10).fontColor('#666666')
      } else { Text(this.error || '正在处理本地蒙版').fontSize(12) }
    }.width('100%').height('100%').backgroundColor(Color.White)
  }
}
