import { FridgeCard, CAPABILITIES, typeLabel } from '../../../entry/src/main/ets/model/CardSchema';
import { FridgeStore } from '../../../entry/src/main/ets/model/FridgeModel';
import { capabilityMinimum } from '../../../entry/src/main/ets/model/CapabilityMetrics';
import { CapabilityView } from '../../../entry/src/main/ets/views/CapBlockView';
import { CardFace } from '../../../entry/src/main/ets/views/CardFace';
@Component
struct CompactSample {
  @Prop kind: string = 'clock';
  build() {
    Column({ space: 8 }) {
      Text(typeLabel(this.kind)).fontSize(12).fontColor('#727272')
      CapabilityView({ cap: { k: this.kind, title: '出发', date: '2026-10-20', city: '杭州', temp: '18°', desc: '晴' },
        contentWidth: capabilityMinimum({ k: this.kind }, true).w, contentHeight: capabilityMinimum({ k: this.kind }, true).h })
        .width(capabilityMinimum({ k: this.kind }, true).w).height(capabilityMinimum({ k: this.kind }, true).h)
    }.width(160).height(100).padding(8).backgroundColor('#FFFFFF').borderRadius(12)
  }
}
@Entry
@Component
struct CapabilityQA {
  @State plain: FridgeCard = new FridgeCard();
  @State borderCard: FridgeCard = new FridgeCard();
  @State ready: boolean = false;
  aboutToAppear(): void {
    const store = new FridgeStore(), context = this.getUIContext().getHostContext();
    if (context === undefined) return;
    store.init(context).then(() => {
      const source = store.state.cards.find((c: FridgeCard) => c.shape === 'subject');
      if (source === undefined) return;
      this.plain = JSON.parse(JSON.stringify(source)) as FridgeCard;
      this.plain.w = 150; this.plain.h = 165; this.plain.capability = { k: 'weather', city: '杭州', temp: '18°', desc: '晴' };
      this.plain.capBox = { x: .2, y: .2, w: .6, h: .5, rot: 0, opacity: 1 }; this.plain.elements = []; this.plain.subjectBorder = false;
      this.borderCard = JSON.parse(JSON.stringify(this.plain)) as FridgeCard; this.borderCard.subjectBorder = true; this.ready = true;
    });
  }
  build() {
    Column({ space: 12 }) {
      Text('紧凑布局检查').fontSize(18).fontWeight(FontWeight.Medium)
      ForEach([0, 1, 2, 3], (row: number) => {
        Row({ space: 12 }) { CompactSample({ kind: CAPABILITIES[row * 2] }); CompactSample({ kind: CAPABILITIES[row * 2 + 1] }) }
      })
      if (this.ready) {
        Row({ space: 20 }) {
          Column({ space: 8 }) { Text('窄边羽化').fontSize(12); CardFace({ card: this.plain }).width(150).height(165) }
          Column({ space: 8 }) { Text('轮廓白边').fontSize(12); CardFace({ card: this.borderCard }).width(150).height(165) }
        }
      }
    }.width('100%').height('100%').padding({ top: 56, bottom: 24 }).backgroundColor('#EFEFEF')
  }
}
