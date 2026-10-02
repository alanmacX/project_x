import { CapBlock } from './CardSchema';

export const WEATHER_REFRESH_MS: number = 30 * 60 * 1000;
export const WEATHER_RETRY_MS: number = 5 * 60 * 1000;
/** The system owns desktop scheduling; this gate deduplicates forms and foreground checks. */
export function weatherNeedsRefresh(cap: CapBlock | null, now: number = Date.now()): boolean {
  if (cap?.k !== 'weather' || (cap.city ?? '').trim().length === 0) return false;
  if (cap.refreshState === 'refreshing' && now - (cap.attemptedAt ?? 0) < 60000) return false;
  if (cap.refreshState === 'failed' && now - (cap.attemptedAt ?? 0) < WEATHER_RETRY_MS) return false;
  return !cap.temp || cap.temp === '--°' || !cap.updatedAt || now - cap.updatedAt >= WEATHER_REFRESH_MS;
}
