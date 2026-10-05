import { FridgeState, FridgeCard, bounded } from './CardSchema';
export interface CapabilityAction { cardId: string; operation: string; }
export function parseCapabilityAction(event: string): CapabilityAction | null {
  try {
    const value = JSON.parse(event) as CapabilityAction;
    if (typeof value.cardId !== 'string' || !['previousMonth', 'nextMonth', 'currentMonth'].includes(value.operation)) return null;
    return { cardId: value.cardId, operation: value.operation };
  } catch (_) { return null; }
}
export function applyCalendarAction(card: FridgeCard, operation: string): boolean {
  if (card.capability?.k !== 'calendar' || !['previousMonth', 'nextMonth', 'currentMonth'].includes(operation)) return false;
  const offset = card.capability.calendarOffset ?? 0;
  card.capability.calendarOffset = operation === 'currentMonth' ? 0 : bounded(offset + (operation === 'previousMonth' ? -1 : 1), -120, 120, 0);
  return true;
}
