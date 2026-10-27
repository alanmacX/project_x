import { FridgeCard } from './CardSchema';

/** Native Form timer cadence; local time readouts do not wake the provider. */
export function widgetProviderPeriod(cards:FridgeCard[]):number {
  let period=Infinity;
  for(const card of cards) {
    if(card.hidden)continue;
    const cap=card.capability;
    if(cap?.k==='battery')return 2000;
    if(cap?.k==='agenda'&&cap.agendaSource==='system')period=15*60000;
  }
  return Number.isFinite(period)?period:0;
}
