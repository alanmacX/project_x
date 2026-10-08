/** Shared local-only readout data. Native and independent preview use the same calculations. */
export function daysLeftOf(date: string, tick:number=Date.now()): number {
  const target = new Date(date + 'T00:00:00'), now = new Date(tick);
  return isNaN(target.getTime()) ? 0 : Math.round((target.getTime() - new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime()) / 86400000);
}
export function calendarCells(now: Date): number[] {
  const first = new Date(now.getFullYear(), now.getMonth(), 1).getDay();
  const count = new Date(now.getFullYear(), now.getMonth() + 1, 0).getDate();
  const cells: number[] = [];
  for (let i = 0; i < Math.ceil((first + count) / 7) * 7; i++) cells.push(i >= first && i < first + count ? i - first + 1 : 0);
  return cells;
}
export function progressOf(k: string, now: Date): number {
  if (k === 'dayprogress') return (now.getHours() * 60 + now.getMinutes()) / 1440;
  const start = new Date(now.getFullYear(), 0, 1), end = new Date(now.getFullYear() + 1, 0, 1);
  return (now.getTime() - start.getTime()) / (end.getTime() - start.getTime());
}
