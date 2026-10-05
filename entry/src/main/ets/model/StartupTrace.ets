import { hilog } from '@kit.PerformanceAnalysisKit';
let started: number = 0;
export function startStartupTrace(): void { started=Date.now(); }
/** Durations only: no canvas names, images or user content enter startup logs. */
export function startupMark(phase: string): void {
  if(started>0)hilog.info(0x0000,'FridgeStartup','%{public}s +%{public}dms',phase,Date.now()-started);
}
