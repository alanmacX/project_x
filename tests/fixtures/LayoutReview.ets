import { FridgeCard, CAPABILITIES, typeLabel, shapeRadius } from '../model/CardSchema';
import { PathShape } from '@kit.ArkUI';
import { CardCanvas } from '../views/CardCanvas';
@Entry
@Component
struct LayoutReview {
  @StorageLink('reviewCap') cap: string = 'clock';
  private card(shape: string): FridgeCard {
    const card = new FridgeCard(); card.id = shape + this.cap; card.shape = shape; card.material = 'cream';
    card.capability = { k: this.cap, title: '下次旅行', date: '2026-10-20', city: '上海', temp: '23°', desc: '晴' };
    if (shape === 'subject') {
      card.outline = [[{x:.1,y:.3},{x:.35,y:.3},{x:.35,y:.1},{x:.65,y:.1},{x:.65,y:.3},{x:.9,y:.3},{x:.9,y:.85},{x:.1,y:.85}]];
    }
    return card;
  }
  private subjectPath(): PathShape {
    const px = (n: number): number => this.getUIContext().vp2px(n * 153);
    return new PathShape({ commands: 'M' + px(.1) + ',' + px(.3) + ' L' + px(.35) + ',' + px(.3) + ' L' + px(.35) + ',' + px(.1) + ' L' + px(.65) + ',' + px(.1) + ' L' + px(.65) + ',' + px(.3) + ' L' + px(.9) + ',' + px(.3) + ' L' + px(.9) + ',' + px(.85) + ' L' + px(.1) + ',' + px(.85) + ' Z' });
  }
  build() {
    Column({ space: 24 }) {
      Text(typeLabel(this.cap) + ' / 原生排版检查').fontSize(20).margin({ top: 70 })
      Row({ space: 16 }) {
        Column({ space: 12 }) {
          Text('方形').fontSize(14)
          CardCanvas({ card: this.card('rect'), scaleFactor: 0.85, tick: Date.now() }).width(153).height(153).borderRadius(shapeRadius('rect')).clip(true).shadow({ radius: 10, color: '#18000000', offsetY: 4 })
        }
        Column({ space: 12 }) {
          Text('自由边角').fontSize(14)
          CardCanvas({ card: this.card('blob'), scaleFactor: 0.85, tick: Date.now() }).width(153).height(153).borderRadius(shapeRadius('blob')).clip(true).shadow({ radius: 10, color: '#18000000', offsetY: 4 })
        }
      }
      Row({ space: 16 }) {
        Column({ space: 12 }) {
          Text('椭圆').fontSize(14)
          CardCanvas({ card: this.card('round'), scaleFactor: 0.85, tick: Date.now() }).width(153).height(153).borderRadius(shapeRadius('round')).clip(true).shadow({ radius: 10, color: '#18000000', offsetY: 4 })
        }
        Column({ space: 12 }) {
          Text('主体内部区域').fontSize(14)
          CardCanvas({ card: this.card('subject'), scaleFactor: 0.85, tick: Date.now() }).width(153).height(153).borderRadius(shapeRadius('subject')).clip(true).clipShape(this.subjectPath()).shadow({ radius: 10, color: '#18000000', offsetY: 4 })
        }
      }
      Text('主体轮廓使用测试数据；不代表系统抠图成功。').fontSize(11).fontColor('#707070')
    }.width('100%').height('100%').backgroundColor(Color.White)
  }
}
